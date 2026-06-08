#!/usr/bin/env bash
set -euo pipefail

HOST_PORT="${KESTRA_PORT:-8080}"
BASE_URL="${KESTRA_URL:-http://localhost:${HOST_PORT}}"
BASIC_AUTH_USERNAME="${KESTRA_BASIC_AUTH_USERNAME:-admin@assignment3.local}"
BASIC_AUTH_PASSWORD="${KESTRA_BASIC_AUTH_PASSWORD:-Assignment3}"
TENANT="${KESTRA_TENANT:-main}"
NAMESPACE="${KESTRA_NAMESPACE:-nsu.infobio.assignment3}"
FLOW_ID="${KESTRA_FLOW_ID:-mapping_quality_ont}"
POLL_SECONDS="${KESTRA_POLL_SECONDS:-5}"
MAX_POLLS="${KESTRA_MAX_POLLS:-180}"

response_file="$(mktemp)"
status_file="$(mktemp)"
trap 'rm -f "$response_file" "$status_file"' EXIT

curl -fsS \
  -u "${BASIC_AUTH_USERNAME}:${BASIC_AUTH_PASSWORD}" \
  -X POST \
  "${BASE_URL}/api/v1/${TENANT}/executions/${NAMESPACE}/${FLOW_ID}" \
  -o "$response_file"

execution_id="$(sed -n 's/.*"id":"\([^"]*\)".*/\1/p' "$response_file" | head -n 1)"
if [ -z "$execution_id" ]; then
  printf 'Failed to parse Kestra execution id.\n' >&2
  cat "$response_file" >&2
  exit 1
fi

printf 'Started Kestra execution: %s\n' "$execution_id"

for _ in $(seq 1 "$MAX_POLLS"); do
  curl -fsS \
    -u "${BASIC_AUTH_USERNAME}:${BASIC_AUTH_PASSWORD}" \
    "${BASE_URL}/api/v1/${TENANT}/executions/${execution_id}" \
    -o "$status_file"

  state="$(sed -n 's/.*"state":{"current":"\([^"]*\)".*/\1/p' "$status_file" | tail -n 1)"
  printf 'Execution state: %s\n' "${state:-UNKNOWN}"

  case "$state" in
    SUCCESS|FAILED|WARNING|KILLED|CANCELLED)
      printf 'Execution URL: %s/ui/%s/executions/%s/%s/%s\n' \
        "$BASE_URL" \
        "$TENANT" \
        "$NAMESPACE" \
        "$FLOW_ID" \
        "$execution_id"
      [ "$state" = "SUCCESS" ]
      exit
      ;;
  esac

  sleep "$POLL_SECONDS"
done

printf 'Timed out waiting for Kestra execution: %s\n' "$execution_id" >&2
exit 1
