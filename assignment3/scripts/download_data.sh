#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

WORK_DIR="$PROJECT_DIR"
SRA_ACCESSION="${SRA_ACCESSION:-SRR25637830}"
REFERENCE_NAME="${REFERENCE_NAME:-GCF_000005845.2_ASM584v2_genomic.fna}"
REFERENCE_URL="${REFERENCE_URL:-https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz}"
DOWNLOAD_REFERENCE=1
DOWNLOAD_READS=1
FORCE=0

usage() {
  cat <<USAGE
Usage: scripts/download_data.sh [options]

Download the assignment3 reference genome and selected ONT reads.

Options:
  --work-dir DIR          Project work directory (default: script parent)
  --sra-accession ACC     SRA run accession (default: SRR25637830)
  --reference-url URL     Reference FASTA .gz URL
  --reference-name NAME   Local decompressed reference FASTA name
  --reference-only        Download only the reference genome
  --reads-only            Download only SRA reads
  --force                 Re-download/re-create existing files
  -h, --help              Show this help
USAGE
}

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

require_command() {
  local name="$1"

  if ! command -v "$name" >/dev/null 2>&1; then
    fail "required command is missing: $name"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --work-dir)
      WORK_DIR="$2"
      shift 2
      ;;
    --sra-accession)
      SRA_ACCESSION="$2"
      shift 2
      ;;
    --reference-url)
      REFERENCE_URL="$2"
      shift 2
      ;;
    --reference-name)
      REFERENCE_NAME="$2"
      shift 2
      ;;
    --reference-only)
      DOWNLOAD_REFERENCE=1
      DOWNLOAD_READS=0
      shift
      ;;
    --reads-only)
      DOWNLOAD_REFERENCE=0
      DOWNLOAD_READS=1
      shift
      ;;
    --force)
      FORCE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown option: $1"
      ;;
  esac
done

download_reference() {
  local reference_dir="$WORK_DIR/data/reference"
  local reference_fasta="$reference_dir/$REFERENCE_NAME"
  local reference_gz="$reference_fasta.gz"

  mkdir -p "$reference_dir"

  if [[ "$FORCE" -eq 1 || ! -f "$reference_fasta" ]]; then
    if [[ "$FORCE" -eq 1 || ! -f "$reference_gz" ]]; then
      require_command curl
      curl -L --fail --show-error --output "$reference_gz" "$REFERENCE_URL"
    fi

    require_command gzip
    gzip -dkf "$reference_gz"
  fi

  [[ -s "$reference_fasta" ]] || fail "reference FASTA was not created: $reference_fasta"
  printf 'reference=%s\n' "$reference_fasta"
}

download_reads() {
  local sra_dir="$WORK_DIR/data/sra"
  local reads_dir="$WORK_DIR/data/reads"
  local sra_file="$sra_dir/$SRA_ACCESSION/$SRA_ACCESSION.sra"
  local raw_fastq="$reads_dir/$SRA_ACCESSION.fastq"
  local reads_fastq="$raw_fastq.gz"

  mkdir -p "$sra_dir" "$reads_dir"

  if [[ "$FORCE" -eq 1 || ! -f "$sra_file" ]]; then
    require_command prefetch
    prefetch "$SRA_ACCESSION" -O "$sra_dir"
  fi

  [[ -s "$sra_file" ]] || fail "SRA file was not created: $sra_file"

  if [[ "$FORCE" -eq 1 || ! -f "$reads_fastq" ]]; then
    require_command fasterq-dump
    require_command gzip

    fasterq-dump \
      "$sra_file" \
      --split-spot \
      --outdir "$reads_dir" \
      --temp "${TMPDIR:-/tmp}"

    [[ -s "$raw_fastq" ]] || fail "FASTQ file was not created: $raw_fastq"
    gzip -f "$raw_fastq"
  fi

  [[ -s "$reads_fastq" ]] || fail "compressed FASTQ was not created: $reads_fastq"
  printf 'reads=%s\n' "$reads_fastq"
}

if [[ "$DOWNLOAD_REFERENCE" -eq 1 ]]; then
  download_reference
fi

if [[ "$DOWNLOAD_READS" -eq 1 ]]; then
  download_reads
fi
