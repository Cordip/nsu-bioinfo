#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW="$ROOT_DIR/workflows/kestra/mapping-quality.yml"

assert_contains() {
  local needle="$1"

  if ! grep -Fq -- "$needle" "$WORKFLOW"; then
    printf 'FAIL: expected workflow to contain: %s\n' "$needle" >&2
    exit 1
  fi
}

assert_not_contains() {
  local needle="$1"

  if grep -Fq -- "$needle" "$WORKFLOW"; then
    printf 'FAIL: workflow should not contain: %s\n' "$needle" >&2
    exit 1
  fi
}

assert_contains "id: mapping_quality_ont"
assert_contains "namespace: nsu.infobio.assignment3"

assert_contains "id: sra_accession"
assert_contains "defaults: SRR25637830"
assert_contains "id: sample_name"
assert_contains "defaults: SRR25637830_kestra"
assert_contains "id: call_variants"
assert_contains "defaults: false"

assert_contains "id: download_sra"
assert_contains "prefetch"
assert_contains "id: fastq_dump"
assert_contains "fasterq-dump"
assert_contains "id: compress_fastq"
assert_contains "gzip -f"
assert_contains "id: fastqc"
assert_contains "id: index_reference"
assert_contains "id: map_reads"
assert_contains "id: sam_to_bam"
assert_contains "id: flagstat"
assert_contains "id: evaluate_mapping"
assert_contains "id: branch_by_mapping_quality"
assert_contains "id: maybe_call_variants"

assert_contains "cd \"{{ inputs.project_dir }}\""
assert_contains 'export PATH="{{ inputs.project_dir }}/.pixi/envs/default/bin:$PATH"'
assert_contains "taskRunner:"
assert_contains "type: io.kestra.plugin.core.runner.Process"
assert_contains "data/sra/{{ inputs.sra_accession }}/{{ inputs.sra_accession }}.sra"
assert_contains "data/reads/{{ inputs.sra_accession }}.fastq.gz"
assert_contains "{{ outputs.evaluate_mapping.vars.mapping_status == \"OK!\" }}"
assert_contains "{{ inputs.call_variants == true }}"

assert_not_contains "id: reads_fastq"
assert_not_contains "pixi run"

commands_count="$(grep -Fc "type: io.kestra.plugin.scripts.shell.Commands" "$WORKFLOW")"
process_runner_count="$(grep -Fc "type: io.kestra.plugin.core.runner.Process" "$WORKFLOW")"

if [ "$commands_count" -ne "$process_runner_count" ]; then
  printf 'FAIL: expected every shell Commands task to use Process runner; Commands=%s Process=%s\n' \
    "$commands_count" \
    "$process_runner_count" >&2
  exit 1
fi

printf 'Kestra mapping workflow structure test passed.\n'
