#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

HOST_PORT="${KESTRA_PORT:-8080}"
BASE_URL="${KESTRA_URL:-http://localhost:${HOST_PORT}}"
BASIC_AUTH_USERNAME="${KESTRA_BASIC_AUTH_USERNAME:-admin@assignment3.local}"
BASIC_AUTH_PASSWORD="${KESTRA_BASIC_AUTH_PASSWORD:-Assignment3}"
TENANT="${KESTRA_TENANT:-main}"
NAMESPACE="${KESTRA_NAMESPACE:-nsu.infobio.assignment3}"
FLOW_ID="${KESTRA_FLOW_ID:-mapping_quality_ont}"
OUTPUT="${1:-$PROJECT_DIR/docs/kestra-dag.jpeg}"

require_command() {
  local command_name="$1"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Required command is not available: %s\n' "$command_name" >&2
    exit 1
  fi
}

require_command curl
require_command dot
require_command python

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

graph_json="$tmp_dir/kestra-graph.json"
graph_dot="$tmp_dir/kestra-graph.dot"

curl -fsS \
  -u "${BASIC_AUTH_USERNAME}:${BASIC_AUTH_PASSWORD}" \
  "${BASE_URL}/api/v1/${TENANT}/flows/${NAMESPACE}/${FLOW_ID}/graph" \
  -o "$graph_json"

python "$PROJECT_DIR/scripts/render_kestra_graph_dot.py" "$graph_json" "$graph_dot"

mkdir -p "$(dirname "$OUTPUT")"
dot -Tjpeg -Gdpi=170 "$graph_dot" -o "$OUTPUT"

printf 'dag_image=%s\n' "$OUTPUT"
