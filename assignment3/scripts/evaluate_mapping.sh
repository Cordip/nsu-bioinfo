#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $(basename "$0") FLAGSTAT_TXT" >&2
  exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mapped_percent="$(python3 "$script_dir/parse_flagstat.py" "$1")"

if awk -v mapped="$mapped_percent" 'BEGIN { exit !(mapped > 90) }'; then
  echo "OK!"
else
  echo "not OK..."
fi
