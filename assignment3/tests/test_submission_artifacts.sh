#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

require_file() {
  local path="$1"

  if [ ! -s "$ROOT_DIR/$path" ]; then
    printf 'FAIL: missing or empty artifact: %s\n' "$path" >&2
    exit 1
  fi
}

require_contains() {
  local path="$1"
  local needle="$2"

  if ! grep -Fq -- "$needle" "$ROOT_DIR/$path"; then
    printf 'FAIL: expected %s to contain: %s\n' "$path" "$needle" >&2
    exit 1
  fi
}

require_file "docs/kestra-run-SRR25637830.md"
require_file "docs/kestra-run-SRR25637830.log.txt"
require_file "docs/kestra-dag.jpeg"
require_file "docs/dag-visualization.md"
require_file "scripts/download_data.sh"
require_file "scripts/generate_kestra_dag.sh"
require_file "scripts/render_kestra_graph_dot.py"

require_contains "docs/kestra-run-SRR25637830.md" "execution_state=SUCCESS"
require_contains "docs/kestra-run-SRR25637830.md" "mapped_percent=99.72"
require_contains "docs/kestra-run-SRR25637830.md" "mapping_status=OK!"
require_contains "docs/kestra-run-SRR25637830.log.txt" "execution_id: 2mVaKnb1TUn8eazPHuAHs3"
require_contains "docs/kestra-run-SRR25637830.log.txt" "Using task runner 'io.kestra.plugin.core.runner.Process'"
require_contains "docs/dag-visualization.md" "docs/kestra-dag.jpeg"
require_contains "docs/dag-visualization.md" "отличия"
require_contains "README.md" "Чеклист требований GitHub"
require_contains "README.md" "[docs/kestra-dag.jpeg](docs/kestra-dag.jpeg)"
require_contains "README.md" "[scripts/download_data.sh](scripts/download_data.sh)"
require_contains "README.md" "[scripts/generate_kestra_dag.sh](scripts/generate_kestra_dag.sh)"
require_contains "docs/dag-visualization.md" "[docs/kestra-dag.jpeg](kestra-dag.jpeg)"
require_contains "docs/dag-visualization.md" "[workflows/kestra/mapping-quality.yml](../workflows/kestra/mapping-quality.yml)"
require_contains "docs/dag-visualization.md" "Kestra graph API"
require_contains "docs/dag-visualization.md" "[scripts/generate_kestra_dag.sh](../scripts/generate_kestra_dag.sh)"
require_contains "scripts/generate_kestra_dag.sh" "/graph"
require_contains "scripts/generate_kestra_dag.sh" "dot -Tjpeg"
require_contains "pixi.toml" "graphviz"
require_contains "pixi.toml" "curl"
require_contains "pixi.toml" "gzip"
require_contains "README.md" "pixi install"
require_contains "README.md" "https://pixi.sh/latest/installation/"
require_contains "scripts/download_data.sh" "SRR25637830"
require_contains "scripts/download_data.sh" "GCF_000005845.2_ASM584v2_genomic.fna.gz"

printf 'Submission artifact tests passed.\n'
