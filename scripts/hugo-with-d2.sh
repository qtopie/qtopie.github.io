#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

if ! command -v hugo >/dev/null 2>&1; then
  echo "hugo CLI not found in PATH" >&2
  exit 1
fi

# If not starting a server, just generate and build
if [[ "$*" != *"server"* ]]; then
  if command -v d2 >/dev/null 2>&1; then
    "$ROOT_DIR/scripts/generate-d2-diagrams.sh"
  fi
  exec hugo "$@"
fi

# --- Server mode: generate, watch, and serve ---

if command -v d2 >/dev/null 2>&1; then
  echo "Generating D2 diagrams..."
  "$ROOT_DIR/scripts/generate-d2-diagrams.sh"
else
  echo "warn: d2 CLI not found in PATH, D2 diagrams won't be generated" >&2
fi

# Start Hugo in background
hugo server "$@" &
HUGO_PID=$!

# Watch for markdown changes and regenerate D2 diagrams
if command -v d2 >/dev/null 2>&1; then
  MARKER="$(mktemp)"
  touch "$MARKER"
  (
    trap 'rm -f "$MARKER"' EXIT
    while true; do
      sleep 2
      recent_files=$(find "$ROOT_DIR/posts" "$ROOT_DIR/content" -type f -name '*.md' -newer "$MARKER" 2>/dev/null | head -20 || true)
      if [[ -n "$recent_files" ]]; then
        touch "$MARKER"
        "$ROOT_DIR/scripts/generate-d2-diagrams.sh" $recent_files 2>/dev/null || true
      fi
    done
  ) &
  WATCH_PID=$!
fi

# Wait for Hugo to exit, then clean up
wait $HUGO_PID 2>/dev/null || true
[[ -n "${WATCH_PID:-}" ]] && kill $WATCH_PID 2>/dev/null || true