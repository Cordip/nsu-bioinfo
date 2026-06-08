#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMPORT_SCRIPT="$ROOT_DIR/scripts/import_kestra_flows.sh"
RUN_SCRIPT="$ROOT_DIR/scripts/run_kestra_mapping.sh"

assert_contains() {
  local needle="$1"
  local file="$2"

  if ! grep -Fq -- "$needle" "$file"; then
    printf 'FAIL: expected %s to contain: %s\n' "$file" "$needle" >&2
    exit 1
  fi
}

for script in "$IMPORT_SCRIPT" "$RUN_SCRIPT"; do
  bash -n "$script"

  if [ ! -x "$script" ]; then
    printf 'FAIL: expected executable script: %s\n' "$script" >&2
    exit 1
  fi
done

assert_contains "/flows/bulk?delete=false&allowNamespaceChild=true" "$IMPORT_SCRIPT"
assert_contains "workflows/kestra/hello-world.yml" "$IMPORT_SCRIPT"
assert_contains "workflows/kestra/mapping-quality.yml" "$IMPORT_SCRIPT"
assert_contains "Assignment3" "$IMPORT_SCRIPT"

assert_contains "/executions/" "$RUN_SCRIPT"
assert_contains "mapping_quality_ont" "$RUN_SCRIPT"
assert_contains "POLL_SECONDS" "$RUN_SCRIPT"
assert_contains "Assignment3" "$RUN_SCRIPT"

printf 'Kestra helper script tests passed.\n'
