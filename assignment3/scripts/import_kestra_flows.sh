#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

HOST_PORT="${KESTRA_PORT:-8080}"
BASE_URL="${KESTRA_URL:-http://localhost:${HOST_PORT}}"
BASIC_AUTH_USERNAME="${KESTRA_BASIC_AUTH_USERNAME:-admin@assignment3.local}"
BASIC_AUTH_PASSWORD="${KESTRA_BASIC_AUTH_PASSWORD:-Assignment3}"
TENANT="${KESTRA_TENANT:-main}"

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

cat "$PROJECT_DIR/workflows/kestra/hello-world.yml" > "$tmp_file"
printf '\n---\n' >> "$tmp_file"
cat "$PROJECT_DIR/workflows/kestra/mapping-quality.yml" >> "$tmp_file"

curl -fsS \
  -u "${BASIC_AUTH_USERNAME}:${BASIC_AUTH_PASSWORD}" \
  -H "Content-Type: application/x-yaml" \
  --data-binary @"$tmp_file" \
  "${BASE_URL}/api/v1/${TENANT}/flows/bulk?delete=false&allowNamespaceChild=true" \
  >/dev/null

cat <<EOF
Imported Kestra flows:
- nsu.infobio.assignment3.hello_world_assignment3
- nsu.infobio.assignment3.mapping_quality_ont

Kestra UI: ${BASE_URL}/ui/${TENANT}/flows
EOF
