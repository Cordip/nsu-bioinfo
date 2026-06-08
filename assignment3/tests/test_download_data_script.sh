#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/download_data.sh"

assert_file() {
  local path="$1"

  if [[ ! -f "$path" ]]; then
    printf 'FAIL: missing file: %s\n' "$path" >&2
    exit 1
  fi
}

assert_executable() {
  local path="$1"

  if [[ ! -x "$path" ]]; then
    printf 'FAIL: file is not executable: %s\n' "$path" >&2
    exit 1
  fi
}

assert_contains() {
  local needle="$1"
  local path="$2"

  if ! grep -Fq -- "$needle" "$path"; then
    printf 'FAIL: expected %s to contain: %s\n' "$path" "$needle" >&2
    exit 1
  fi
}

assert_file "$SCRIPT"
assert_executable "$SCRIPT"

bash -n "$SCRIPT"

assert_contains "GCF_000005845.2_ASM584v2_genomic.fna.gz" "$SCRIPT"
assert_contains "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/" "$SCRIPT"
assert_contains "SRR25637830" "$SCRIPT"
assert_contains "prefetch" "$SCRIPT"
assert_contains "fasterq-dump" "$SCRIPT"
assert_contains "gzip -dkf" "$SCRIPT"
assert_contains "gzip -f" "$SCRIPT"
assert_contains "--reference-only" "$SCRIPT"
assert_contains "--reads-only" "$SCRIPT"
assert_contains "--force" "$SCRIPT"

printf 'Download data script tests passed.\n'
