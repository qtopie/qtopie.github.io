#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

if ! command -v hugo >/dev/null 2>&1; then
  echo "hugo CLI not found in PATH" >&2
  exit 1
fi

if ! command -v d2 >/dev/null 2>&1; then
  echo "warn: d2 CLI not found in PATH, skipping diagram generation" >&2
  exec hugo "$@"
fi

"$ROOT_DIR/scripts/generate-d2-diagrams.sh"
exec hugo "$@"