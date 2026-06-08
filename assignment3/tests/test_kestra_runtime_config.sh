#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/scripts/start_kestra_local.sh"

assert_contains() {
  local needle="$1"

  if ! grep -Fq -- "$needle" "$SCRIPT"; then
    printf 'FAIL: expected start script to contain: %s\n' "$needle" >&2
    exit 1
  fi
}

assert_contains "assignment3-kestra"
assert_contains "kestra/kestra:latest"
assert_contains "/workspace/infobio/assignment3"
assert_contains '-v "$PROJECT_DIR:$CONTAINER_PROJECT_DIR"'
assert_contains 'KESTRA_CONFIGURATION='
assert_contains 'KESTRA_SERVER_BASIC_AUTH_USERNAME'
assert_contains 'KESTRA_SERVER_BASIC_AUTH_PASSWORD'
assert_contains 'basic-auth:'
assert_contains 'admin@assignment3.local'
assert_contains 'Assignment3'
assert_contains "server local"
assert_contains 'http://localhost:${HOST_PORT}'

if grep -Fq -- "/var/run/docker.sock" "$SCRIPT"; then
  printf 'FAIL: start script must not mount /var/run/docker.sock\n' >&2
  exit 1
fi

printf 'Kestra runtime config test passed.\n'
