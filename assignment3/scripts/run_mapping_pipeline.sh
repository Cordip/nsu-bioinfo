#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"

sra_accession=""
reads_fastq=""
reference_fasta=""
sample_name=""
work_dir="$project_dir"
threads="4"
preset="map-ont"
call_variants="0"

usage() {
  cat >&2 <<'USAGE'
usage: run_mapping_pipeline.sh --reference REF.fa [--sra-accession SRR...] [options]

Required:
  --reference PATH          Reference FASTA file.

Input, choose one:
  --sra-accession ACCESSION Download SRA, convert to FASTQ.GZ, then run pipeline.
  --reads-fastq PATH        Use an existing FASTQ/FASTQ.GZ file.

Options:
  --sample NAME             Output prefix. Defaults to accession or reads filename stem.
  --work-dir DIR            Project/work directory. Defaults to assignment3 directory.
  --threads N               Threads for minimap2. Defaults to 4.
  --preset PRESET           minimap2 preset. Defaults to map-ont.
  --call-variants           After OK mapping, run samtools sort/index and FreeBayes.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sra-accession)
      sra_accession="$2"
      shift 2
      ;;
    --reads-fastq)
      reads_fastq="$2"
      shift 2
      ;;
    --reference)
      reference_fasta="$2"
      shift 2
      ;;
    --sample)
      sample_name="$2"
      shift 2
      ;;
    --work-dir)
      work_dir="$2"
      shift 2
      ;;
    --threads)
      threads="$2"
      shift 2
      ;;
    --preset)
      preset="$2"
      shift 2
      ;;
    --call-variants)
      call_variants="1"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$reference_fasta" ]]; then
  printf 'missing required --reference\n' >&2
  usage
  exit 2
fi

if [[ -z "$sra_accession" && -z "$reads_fastq" ]]; then
  printf 'provide either --sra-accession or --reads-fastq\n' >&2
  usage
  exit 2
fi

if [[ -n "$sra_accession" && -n "$reads_fastq" ]]; then
  printf 'provide only one input source: --sra-accession or --reads-fastq\n' >&2
  usage
  exit 2
fi

if [[ ! -f "$reference_fasta" ]]; then
  printf 'reference FASTA does not exist: %s\n' "$reference_fasta" >&2
  exit 2
fi

mkdir -p "$work_dir/data/sra" "$work_dir/data/reads" "$work_dir/results"

if [[ -n "$sra_accession" ]]; then
  if [[ -z "$sample_name" ]]; then
    sample_name="$sra_accession"
  fi

  sra_dir="$work_dir/data/sra/$sra_accession"
  sra_file="$sra_dir/$sra_accession.sra"
  reads_fastq="$work_dir/data/reads/$sra_accession.fastq.gz"

  if [[ ! -f "$sra_file" ]]; then
    prefetch "$sra_accession" -O "$work_dir/data/sra"
  fi

  if [[ ! -f "$reads_fastq" ]]; then
    fasterq-dump "$sra_file" --split-spot --outdir "$work_dir/data/reads" --temp "${TMPDIR:-/tmp}"

    raw_fastq="$work_dir/data/reads/$sra_accession.fastq"
    if [[ ! -f "$raw_fastq" ]]; then
      printf 'fasterq-dump did not create expected FASTQ: %s\n' "$raw_fastq" >&2
      exit 1
    fi

    gzip -f "$raw_fastq"
  fi
else
  if [[ ! -f "$reads_fastq" ]]; then
    printf 'reads FASTQ does not exist: %s\n' "$reads_fastq" >&2
    exit 2
  fi

  if [[ -z "$sample_name" ]]; then
    reads_base="$(basename "$reads_fastq")"
    sample_name="${reads_base%.gz}"
    sample_name="${sample_name%.fastq}"
    sample_name="${sample_name%.fq}"
  fi
fi

results_dir="$work_dir/results/$sample_name"
mkdir -p "$results_dir"

reference_index="$results_dir/reference.mmi"
sam_file="$results_dir/$sample_name.sam"
bam_file="$results_dir/$sample_name.bam"
flagstat_file="$results_dir/$sample_name.flagstat.txt"
mapping_status_file="$results_dir/$sample_name.mapping_status.txt"
sorted_bam_file="$results_dir/$sample_name.sorted.bam"
vcf_file="$results_dir/$sample_name.vcf"
finished_file="$results_dir/$sample_name.finished.txt"

fastqc --outdir "$results_dir" "$reads_fastq"

minimap2 -x "$preset" -d "$reference_index" "$reference_fasta"

minimap2 -t "$threads" -ax "$preset" "$reference_index" "$reads_fastq" > "$sam_file"

samtools view -bS "$sam_file" -o "$bam_file"

samtools flagstat "$bam_file" > "$flagstat_file"

mapped_percent="$(python3 "$script_dir/parse_flagstat.py" "$flagstat_file")"
"$script_dir/evaluate_mapping.sh" "$flagstat_file" > "$mapping_status_file"
mapping_status="$(cat "$mapping_status_file")"

if [[ "$mapping_status" == "OK!" && "$call_variants" == "1" ]]; then
  if [[ ! -f "$reference_fasta.fai" ]]; then
    samtools faidx "$reference_fasta"
  fi

  samtools sort -o "$sorted_bam_file" "$bam_file"
  samtools index "$sorted_bam_file"
  freebayes -f "$reference_fasta" "$sorted_bam_file" > "$vcf_file"
fi

printf 'Finished\n' > "$finished_file"

printf 'sample=%s\n' "$sample_name"
printf 'reads=%s\n' "$reads_fastq"
printf 'reference=%s\n' "$reference_fasta"
printf 'results_dir=%s\n' "$results_dir"
printf 'flagstat=%s\n' "$flagstat_file"
printf 'mapped_percent=%s\n' "$mapped_percent"
printf 'mapping_status=%s\n' "$mapping_status"
if [[ "$call_variants" == "1" && -f "$vcf_file" ]]; then
  printf 'vcf=%s\n' "$vcf_file"
fi
