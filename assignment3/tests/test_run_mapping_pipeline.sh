#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/assignment3-pipeline-test.XXXXXX")"
FAKE_BIN="$TMP_DIR/bin"
WORK_DIR="$TMP_DIR/work"
LOG_FILE="$TMP_DIR/calls.log"

mkdir -p "$FAKE_BIN" "$WORK_DIR"

assert_file() {
  local path="$1"

  if [[ ! -f "$path" ]]; then
    printf 'FAIL: expected file does not exist: %s\n' "$path" >&2
    printf 'test temp dir: %s\n' "$TMP_DIR" >&2
    exit 1
  fi
}

assert_not_file() {
  local path="$1"

  if [[ -f "$path" ]]; then
    printf 'FAIL: file should not exist: %s\n' "$path" >&2
    printf 'test temp dir: %s\n' "$TMP_DIR" >&2
    exit 1
  fi
}

assert_contains() {
  local needle="$1"
  local path="$2"

  if ! grep -Fq "$needle" "$path"; then
    printf 'FAIL: expected "%s" in %s\n' "$needle" "$path" >&2
    printf 'test temp dir: %s\n' "$TMP_DIR" >&2
    exit 1
  fi
}

assert_not_contains() {
  local needle="$1"
  local path="$2"

  if grep -Fq "$needle" "$path"; then
    printf 'FAIL: did not expect "%s" in %s\n' "$needle" "$path" >&2
    printf 'test temp dir: %s\n' "$TMP_DIR" >&2
    exit 1
  fi
}

make_fake_tool() {
  local name="$1"
  local body="$2"

  {
    printf '%s\n' '#!/usr/bin/env bash'
    printf '%s\n' 'set -euo pipefail'
    printf '%s\n' "$body"
  } > "$FAKE_BIN/$name"
  chmod +x "$FAKE_BIN/$name"
}

make_fake_tool prefetch '
echo "prefetch $*" >> "$PIPELINE_FAKE_LOG"
accession="$1"
out_dir="."
while [[ $# -gt 0 ]]; do
  case "$1" in
    -O)
      out_dir="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
mkdir -p "$out_dir/$accession"
printf "fake sra\n" > "$out_dir/$accession/$accession.sra"
'

make_fake_tool fasterq-dump '
echo "fasterq-dump $*" >> "$PIPELINE_FAKE_LOG"
sra_file="$1"
accession="$(basename "$sra_file" .sra)"
out_dir="."
while [[ $# -gt 0 ]]; do
  case "$1" in
    --outdir)
      out_dir="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
mkdir -p "$out_dir"
printf "@read1\nACGT\n+\n!!!!\n" > "$out_dir/$accession.fastq"
'

make_fake_tool gzip '
echo "gzip $*" >> "$PIPELINE_FAKE_LOG"
input="${@: -1}"
mv "$input" "$input.gz"
'

make_fake_tool fastqc '
echo "fastqc $*" >> "$PIPELINE_FAKE_LOG"
out_dir="."
while [[ $# -gt 0 ]]; do
  case "$1" in
    --outdir)
      out_dir="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
mkdir -p "$out_dir"
printf "fake fastqc\n" > "$out_dir/fastqc_report.txt"
'

make_fake_tool minimap2 '
echo "minimap2 $*" >> "$PIPELINE_FAKE_LOG"
index_path=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d)
      index_path="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
if [[ -n "$index_path" ]]; then
  printf "fake index\n" > "$index_path"
else
  printf "@HD\tVN:1.6\nread1\t0\tref\t1\t60\t4M\t*\t0\t0\tACGT\t!!!!\n"
fi
'

make_fake_tool samtools '
echo "samtools $*" >> "$PIPELINE_FAKE_LOG"
subcommand="$1"
shift
case "$subcommand" in
  view)
    out=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -o)
          out="$2"
          shift 2
          ;;
        *)
          shift
          ;;
      esac
    done
    printf "fake bam\n" > "$out"
    ;;
  flagstat)
    cat <<'"'"'FLAGSTAT'"'"'
100 + 0 in total (QC-passed reads + QC-failed reads)
100 + 0 primary
0 + 0 secondary
0 + 0 supplementary
0 + 0 duplicates
0 + 0 primary duplicates
99 + 0 mapped (99.00% : N/A)
99 + 0 primary mapped (99.00% : N/A)
0 + 0 paired in sequencing
0 + 0 read1
0 + 0 read2
0 + 0 properly paired (N/A : N/A)
0 + 0 with itself and mate mapped
0 + 0 singletons (N/A : N/A)
0 + 0 with mate mapped to a different chr
0 + 0 with mate mapped to a different chr (mapQ>=5)
FLAGSTAT
    ;;
  faidx)
    touch "$1.fai"
    ;;
  sort)
    out=""
    input=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -o)
          out="$2"
          shift 2
          ;;
        *)
          input="$1"
          shift
          ;;
      esac
    done
    cp "$input" "$out"
    ;;
  index)
    touch "$1.bai"
    ;;
  *)
    printf "unexpected samtools subcommand: %s\n" "$subcommand" >&2
    exit 1
    ;;
esac
'

make_fake_tool freebayes '
echo "freebayes $*" >> "$PIPELINE_FAKE_LOG"
printf "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n"
'

printf ">ref\nACGT\n" > "$TMP_DIR/reference.fa"

MAPPING_ONLY_LOG="$TMP_DIR/calls-mapping-only.log"
MAPPING_ONLY_WORK="$TMP_DIR/work-mapping-only"

PIPELINE_FAKE_LOG="$MAPPING_ONLY_LOG" \
PATH="$FAKE_BIN:$PATH" \
  "$ROOT_DIR/scripts/run_mapping_pipeline.sh" \
    --sra-accession ONLY123 \
    --reference "$TMP_DIR/reference.fa" \
    --sample mapping_only \
    --work-dir "$MAPPING_ONLY_WORK" \
    --threads 2 \
    > "$TMP_DIR/stdout-mapping-only.txt"

MAPPING_ONLY_RESULTS="$MAPPING_ONLY_WORK/results/mapping_only"

assert_file "$MAPPING_ONLY_RESULTS/mapping_only.flagstat.txt"
assert_file "$MAPPING_ONLY_RESULTS/mapping_only.mapping_status.txt"
assert_file "$MAPPING_ONLY_RESULTS/mapping_only.finished.txt"
assert_not_file "$MAPPING_ONLY_RESULTS/mapping_only.sorted.bam"
assert_not_file "$MAPPING_ONLY_RESULTS/mapping_only.vcf"
assert_contains "mapping_status=OK!" "$TMP_DIR/stdout-mapping-only.txt"
assert_not_contains "freebayes" "$MAPPING_ONLY_LOG"

PIPELINE_FAKE_LOG="$LOG_FILE" \
PATH="$FAKE_BIN:$PATH" \
  "$ROOT_DIR/scripts/run_mapping_pipeline.sh" \
    --sra-accession TEST123 \
    --reference "$TMP_DIR/reference.fa" \
    --sample test_sample \
    --work-dir "$WORK_DIR" \
    --threads 2 \
    --call-variants \
    > "$TMP_DIR/stdout.txt"

RESULTS_DIR="$WORK_DIR/results/test_sample"

assert_file "$WORK_DIR/data/sra/TEST123/TEST123.sra"
assert_file "$WORK_DIR/data/reads/TEST123.fastq.gz"
assert_file "$RESULTS_DIR/reference.mmi"
assert_file "$RESULTS_DIR/test_sample.sam"
assert_file "$RESULTS_DIR/test_sample.bam"
assert_file "$RESULTS_DIR/test_sample.flagstat.txt"
assert_file "$RESULTS_DIR/test_sample.mapping_status.txt"
assert_file "$TMP_DIR/reference.fa.fai"
assert_file "$RESULTS_DIR/test_sample.sorted.bam"
assert_file "$RESULTS_DIR/test_sample.sorted.bam.bai"
assert_file "$RESULTS_DIR/test_sample.vcf"
assert_file "$RESULTS_DIR/test_sample.finished.txt"

assert_contains "OK!" "$RESULTS_DIR/test_sample.mapping_status.txt"
assert_contains "mapped_percent=99.00" "$TMP_DIR/stdout.txt"
assert_contains "mapping_status=OK!" "$TMP_DIR/stdout.txt"

assert_contains "prefetch TEST123 -O $WORK_DIR/data/sra" "$LOG_FILE"
assert_contains "fasterq-dump $WORK_DIR/data/sra/TEST123/TEST123.sra" "$LOG_FILE"
assert_contains "fastqc --outdir $RESULTS_DIR $WORK_DIR/data/reads/TEST123.fastq.gz" "$LOG_FILE"
assert_contains "minimap2 -x map-ont -d $RESULTS_DIR/reference.mmi $TMP_DIR/reference.fa" "$LOG_FILE"
assert_contains "minimap2 -t 2 -ax map-ont $RESULTS_DIR/reference.mmi $WORK_DIR/data/reads/TEST123.fastq.gz" "$LOG_FILE"
assert_contains "samtools view -bS $RESULTS_DIR/test_sample.sam -o $RESULTS_DIR/test_sample.bam" "$LOG_FILE"
assert_contains "samtools flagstat $RESULTS_DIR/test_sample.bam" "$LOG_FILE"
assert_contains "samtools faidx $TMP_DIR/reference.fa" "$LOG_FILE"
assert_contains "samtools sort -o $RESULTS_DIR/test_sample.sorted.bam $RESULTS_DIR/test_sample.bam" "$LOG_FILE"
assert_contains "samtools index $RESULTS_DIR/test_sample.sorted.bam" "$LOG_FILE"
assert_contains "freebayes -f $TMP_DIR/reference.fa $RESULTS_DIR/test_sample.sorted.bam" "$LOG_FILE"

printf 'Full mapping pipeline smoke test passed.\n'
