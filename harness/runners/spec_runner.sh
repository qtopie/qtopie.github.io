#!/usr/bin/env bash
set -euo pipefail

echo "[Harness Runner] Executing Spec BDD Scenarios and Invariant Assertions..."

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATUS=0

# Verify every Mapped Test path declared in specs/modules/*.spec.md exists.
# Line format: `- **Mapped Test:** `path/to/test.sh:test_fn``
echo "[Harness Runner] Verifying Mapped Test files declared in specs..."
for spec_file in "$ROOT_DIR"/specs/modules/*.spec.md; do
  [[ "$spec_file" == *template.spec.md ]] && continue
  [[ -f "$spec_file" ]] || continue
  rel_spec="${spec_file#"$ROOT_DIR"/}"
  while IFS= read -r line; do
    mapped="$(printf '%s' "$line" | sed -n 's/.*Mapped Test:\*\* `\([^`]*\)`.*/\1/p')"
    if [[ -z "$mapped" ]]; then
      echo "[Harness Runner] WARN: no Mapped Test reference found in: ${line}"
      continue
    fi
    test_script="${mapped%%:*}"
    test_fn="${mapped##*:}"
    if [[ -z "$test_script" || -z "$test_fn" || "$test_script" == "$mapped" ]]; then
      echo "[Harness Runner] WARN: malformed Mapped Test in ${rel_spec}: ${line}"
      continue
    fi
    if [[ ! -f "$ROOT_DIR/$test_script" ]]; then
      echo "[Harness Runner] FAIL: Mapped Test script missing: $test_script (${rel_spec})"
      STATUS=1
      continue
    fi
    if ! grep -q "^${test_fn}()" "$ROOT_DIR/$test_script"; then
      echo "[Harness Runner] FAIL: Mapped Test function missing: ${test_fn} in ${test_script} (${rel_spec})"
      STATUS=1
    fi
  done < <(grep -n "Mapped Test:" "$spec_file" 2>/dev/null || true)
done

# Run the translation widget spec test suite.
WIDGET_TEST="$ROOT_DIR/testings/translation/widget_render_test.sh"
if [[ -f "$WIDGET_TEST" ]]; then
  echo "[Harness Runner] Running translation widget spec tests..."
  bash "$WIDGET_TEST" || STATUS=$?
else
  echo "[Harness Runner] SKIP: $WIDGET_TEST not found"
fi

if [[ $STATUS -eq 0 ]]; then
  echo "[Harness Runner] All Spec BDD assertions completed successfully."
else
  echo "[Harness Runner] Spec BDD assertions FAILED (exit $STATUS)."
fi
exit $STATUS
