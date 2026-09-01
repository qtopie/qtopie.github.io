#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v d2 >/dev/null 2>&1; then
  echo "d2 CLI not found in PATH" >&2
  exit 1
fi

if command -v python3 >/dev/null 2>&1; then
  exec python3 "$ROOT_DIR/scripts/generate_d2.py" "$@"
else
  echo "python3 not found in PATH, required for D2 diagram processing" >&2
  exit 1
fi
