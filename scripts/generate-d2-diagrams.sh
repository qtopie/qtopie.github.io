#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/static/diagrams"

if ! command -v d2 >/dev/null 2>&1; then
  echo "d2 CLI not found in PATH" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

process_file_and_track() {
  local file="$1"
  local escaped_file
  escaped_file="${file//\//_}"

  awk -v tmp_dir="$TMP_DIR" -v file_key="$escaped_file" '
    function parse_theme(header, m, t) {
      t = "0"
      if (match(header, /theme[[:space:]]*=[[:space:]]*"[^"]+"/)) {
        t = substr(header, RSTART, RLENGTH)
        sub(/^[^=]*=[[:space:]]*"/, "", t)
        sub(/"$/, "", t)
      } else if (match(header, /theme[[:space:]]*=[[:space:]]*[0-9]+/)) {
        t = substr(header, RSTART, RLENGTH)
        sub(/^[^=]*=[[:space:]]*/, "", t)
      }
      return t
    }

    BEGIN {
      in_block = 0
      block_id = 0
      theme = "0"
      block_file = ""
    }

    !in_block && $0 ~ /^```d2([[:space:]]*\{[^}]*\})?[[:space:]]*$/ {
      in_block = 1
      block_id++
      theme = parse_theme($0)
      block_file = sprintf("%s/%s_block_%d.d2", tmp_dir, file_key, block_id)
      next
    }

    in_block && $0 ~ /^```[[:space:]]*$/ {
      printf("%s\t%s\t%s\n", block_file, theme, block_id)
      in_block = 0
      theme = "0"
      block_file = ""
      next
    }

    in_block {
      print $0 >> block_file
    }
  ' "$file" | while IFS=$'\t' read -r block_file theme block_id; do
    local hash
    local out_file

    # Keep hashing stable across editors by normalizing CRLF, tabs, and outer blank lines.
    normalized_file="$TMP_DIR/normalized-${escaped_file}-${block_id}.d2"
    awk '
      {
        sub(/\r$/, "")
        gsub(/\t/, "    ")
        if (started || $0 !~ /^[[:space:]]*$/) {
          started = 1
          lines[++n] = $0
        }
      }
      END {
        while (n > 0 && lines[n] ~ /^[[:space:]]*$/) {
          n--
        }
        for (i = 1; i <= n; i++) {
          print lines[i]
        }
      }
    ' "$block_file" > "$normalized_file"

    hash="$({ cat "$normalized_file"; printf "|theme=%s" "$theme"; } | md5sum | awk '{print $1}')"
    out_file="$OUT_DIR/d2-${hash}.svg"

    if [[ -f "$out_file" ]]; then
      echo "skip: $file#$block_id (theme=$theme) -> $(basename "$out_file")"
      continue
    fi

    d2 --theme "$theme" "$normalized_file" "$out_file" >/dev/null
    echo "gen:  $file#$block_id (theme=$theme) -> $(basename "$out_file")"
  done
}

# Collect all expected output files in a temporary file
EXPECTED_FILES="$(mktemp)"
trap 'rm -rf "$TMP_DIR" "$EXPECTED_FILES"' EXIT

# Override process_file to append to EXPECTED_FILES
process_file_and_track() {
  local file="$1"
  local escaped_file
  escaped_file="${file//\//_}"

  awk -v tmp_dir="$TMP_DIR" -v file_key="$escaped_file" '
    function parse_theme(header, m, t) {
      t = "0"
      if (match(header, /theme[[:space:]]*=[[:space:]]*"[^"]+"/)) {
        t = substr(header, RSTART, RLENGTH)
        sub(/^[^=]*=[[:space:]]*"/, "", t)
        sub(/"$/, "", t)
      } else if (match(header, /theme[[:space:]]*=[[:space:]]*[0-9]+/)) {
        t = substr(header, RSTART, RLENGTH)
        sub(/^[^=]*=[[:space:]]*/, "", t)
      }
      return t
    }

    BEGIN {
      in_block = 0
      block_id = 0
      theme = "0"
      block_file = ""
    }

    !in_block && $0 ~ /^```d2([[:space:]]*\{[^}]*\})?[[:space:]]*$/ {
      in_block = 1
      block_id++
      theme = parse_theme($0)
      block_file = sprintf("%s/%s_block_%d.d2", tmp_dir, file_key, block_id)
      next
    }

    in_block && $0 ~ /^```[[:space:]]*$/ {
      printf("%s\t%s\t%s\n", block_file, theme, block_id)
      in_block = 0
      theme = "0"
      block_file = ""
      next
    }

    in_block {
      print $0 >> block_file
    }
  ' "$file" | while IFS=$'\t' read -r block_file theme block_id; do
    local hash
    local out_file

    # Keep hashing stable across editors by normalizing CRLF, tabs, and outer blank lines.
    normalized_file="$TMP_DIR/normalized-${escaped_file}-${block_id}.d2"
    awk '
      {
        sub(/\r$/, "")
        gsub(/\t/, "    ")
        if (started || $0 !~ /^[[:space:]]*$/) {
          started = 1
          lines[++n] = $0
        }
      }
      END {
        while (n > 0 && lines[n] ~ /^[[:space:]]*$/) {
          n--
        }
        for (i = 1; i <= n; i++) {
          print lines[i]
        }
      }
    ' "$block_file" > "$normalized_file"

    hash="$({ cat "$normalized_file"; printf "|theme=%s" "$theme"; } | md5sum | awk '{print $1}')"
    out_file="$OUT_DIR/d2-${hash}.svg"
    
    # Add to expected files list if variable is set
    if [[ -n "${EXPECTED_FILES:-}" ]]; then
      echo "d2-${hash}.svg" >> "$EXPECTED_FILES"
    fi

    if [[ -f "$out_file" ]]; then
      echo "skip: $file#$block_id (theme=$theme) -> $(basename "$out_file")"
      continue
    fi

    d2 --theme "$theme" "$normalized_file" "$out_file" >/dev/null
    echo "gen:  $file#$block_id (theme=$theme) -> $(basename "$out_file")"
  done
}

if [[ "$#" -gt 0 ]]; then
  for file in "$@"; do
    if [[ -f "$file" ]]; then
      process_file_and_track "$file"
    else
      echo "warn: file not found: $file" >&2
    fi
  done
  # When running on specific files, we DO NOT clean up others.
  exit 0
fi

while IFS= read -r file; do
  process_file_and_track "$file"
done < <(find "$ROOT_DIR/posts" "$ROOT_DIR/content" -type f -name '*.md' 2>/dev/null)

# Cleanup logic
echo "Cleaning up unused diagrams..."
# Find all svg files in OUT_DIR, compare with EXPECTED_FILES
# We use comm to find files unique to the directory (not in expected list)
# Both lists must be sorted for comm
if [[ -d "$OUT_DIR" ]]; then
  # List existing files (basenames only)
  existing_files="$(mktemp)"
  ls "$OUT_DIR" | grep '^d2-.*\.svg$' | sort > "$existing_files"
  
  # Sort expected files
  sorted_expected="$(mktemp)"
  sort "$EXPECTED_FILES" | uniq > "$sorted_expected"
  
  # Find files in existing but not in expected (comm -23: suppress col 2 (unique to file2) and col 3 (common))
  # file1: existing, file2: expected
  # result: files in existing but NOT expected
  unused_files="$(comm -23 "$existing_files" "$sorted_expected")"
  
  if [[ -n "$unused_files" ]]; then
    echo "$unused_files" | while read -r file; do
      if [[ -n "$file" ]]; then
        echo "rm:   $file (unused)"
        rm "$OUT_DIR/$file"
      fi
    done
  else
    echo "No unused diagrams found."
  fi
  
  rm "$existing_files" "$sorted_expected"
fi
