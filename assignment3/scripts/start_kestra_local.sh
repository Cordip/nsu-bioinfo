#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CONTAINER_NAME="${KESTRA_CONTAINER_NAME:-assignment3-kestra}"
IMAGE="${KESTRA_IMAGE:-kestra/kestra:latest}"
HOST_PORT="${KESTRA_PORT:-8080}"
CONTAINER_PROJECT_DIR="${KESTRA_PROJECT_DIR:-/workspace/infobio/assignment3}"
BASIC_AUTH_USERNAME="${KESTRA_BASIC_AUTH_USERNAME:-admin@assignment3.local}"
BASIC_AUTH_PASSWORD="${KESTRA_BASIC_AUTH_PASSWORD:-Assignment3}"
KESTRA_CONFIGURATION="$(cat <<EOF
kestra:
  server:
    basic-auth:
      enabled: true
      username: "${BASIC_AUTH_USERNAME}"
      password: "${BASIC_AUTH_PASSWORD}"
EOF
)"

container_exists() {
  docker ps -a --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"
}

container_running() {
  docker ps --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"
}

wait_for_ui() {
  if ! command -v curl >/dev/null 2>&1; then
    return 0
  fi

  for _ in $(seq 1 90); do
    if curl -fsS "http://localhost:${HOST_PORT}" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  printf 'Kestra container started, but UI did not answer within 90 seconds.\n' >&2
  return 1
}

if container_running; then
  printf 'Kestra container is already running: %s\n' "$CONTAINER_NAME"
elif container_exists; then
  docker start "$CONTAINER_NAME" >/dev/null
  printf 'Started existing Kestra container: %s\n' "$CONTAINER_NAME"
else
  docker run \
    --pull=missing \
    -d \
    --name "$CONTAINER_NAME" \
    -p "${HOST_PORT}:8080" \
    --user=root \
    -e KESTRA_CONFIGURATION="$KESTRA_CONFIGURATION" \
    -e KESTRA_SERVER_BASIC_AUTH_USERNAME="$BASIC_AUTH_USERNAME" \
    -e KESTRA_SERVER_BASIC_AUTH_PASSWORD="$BASIC_AUTH_PASSWORD" \
    -v assignment3_kestra_data:/app/storage \
    -v assignment3_kestra_db:/app/data \
    -v /tmp:/tmp \
    -v "$PROJECT_DIR:$CONTAINER_PROJECT_DIR" \
    "$IMAGE" \
    server local >/dev/null
  printf 'Created and started Kestra container: %s\n' "$CONTAINER_NAME"
fi

wait_for_ui

cat <<EOF
Kestra UI: http://localhost:${HOST_PORT}
Mounted project_dir for flow input: ${CONTAINER_PROJECT_DIR}
Local assignment3 path: ${PROJECT_DIR}
Container name: ${CONTAINER_NAME}
Basic auth username: ${BASIC_AUTH_USERNAME}
Basic auth password: ${BASIC_AUTH_PASSWORD}
EOF
