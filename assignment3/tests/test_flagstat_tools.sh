#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

assert_eq() {
  local expected="$1"
  local actual="$2"
  local label="$3"

  if [[ "$actual" != "$expected" ]]; then
    printf 'FAIL: %s\nexpected: %s\nactual:   %s\n' "$label" "$expected" "$actual" >&2
    exit 1
  fi
}

ok_percent="$(python3 "$ROOT_DIR/scripts/parse_flagstat.py" "$ROOT_DIR/data/examples/flagstat_ok.txt")"
assert_eq "99.83" "$ok_percent" "parse mapped percent from high-quality flagstat"

not_ok_percent="$(python3 "$ROOT_DIR/scripts/parse_flagstat.py" "$ROOT_DIR/data/examples/flagstat_not_ok.txt")"
assert_eq "85.00" "$not_ok_percent" "parse mapped percent from low-quality flagstat"

ok_status="$("$ROOT_DIR/scripts/evaluate_mapping.sh" "$ROOT_DIR/data/examples/flagstat_ok.txt")"
assert_eq "OK!" "$ok_status" "evaluate high-quality mapping"

not_ok_status="$("$ROOT_DIR/scripts/evaluate_mapping.sh" "$ROOT_DIR/data/examples/flagstat_not_ok.txt")"
assert_eq "not OK..." "$not_ok_status" "evaluate low-quality mapping"

printf 'All flagstat tool tests passed.\n'
