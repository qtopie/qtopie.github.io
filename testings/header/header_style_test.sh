#!/usr/bin/env bash
# =============================================================================
# Spec BDD Test Runner: Header UI（Fluent UI + Drift 风格）
#
# Mapped tests:
#   - SPEC-HEADER-001  test_header_sticky_acrylic
#   - SPEC-HEADER-002  test_header_brand_gradient
#   - SPEC-HEADER-003  test_body_font_family
#   - SPEC-HEADER-004  test_header_ipad_breakpoint
#
# Spec: specs/modules/header-ui.spec.md
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

THEME_CSS="$ROOT_DIR/themes/drift-blog-theme/assets/css/main.css"
TEST_BUILD="$ROOT_DIR/public-test-header"

PASS_COUNT=0
FAIL_COUNT=0

cleanup() {
  rm -rf "$TEST_BUILD"
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Helpers — single-line grep (no multiline regex needed)
# ---------------------------------------------------------------------------
pass() { echo "  PASS: $1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { echo "  FAIL: $1"; FAIL_COUNT=$((FAIL_COUNT+1)); }

assert_line() {
  # assert_line "description" "literal-or-regex" [grep-flags]
  local desc="$1" pattern="$2" flags="${3:--F}"
  if grep -q $flags "$pattern" "$THEME_CSS"; then
    pass "$desc"
  else
    fail "$desc — not found: $pattern"
  fi
}

assert_build_ok() {
  local out
  out=$(hugo --source "$ROOT_DIR" --destination "$TEST_BUILD" --quiet 2>&1)
  local exit_code=$?
  if [[ $exit_code -eq 0 ]]; then
    pass "Hugo build succeeds after header CSS changes"
  else
    fail "Hugo build failed (exit $exit_code): $out"
  fi
}

# ---------------------------------------------------------------------------
# SPEC-HEADER-001: Sticky Acrylic Header
# ---------------------------------------------------------------------------
test_header_sticky_acrylic() {
  echo ""
  echo "=== SPEC-HEADER-001: Sticky Acrylic Header ==="

  assert_line "header has position:sticky"            "  position: sticky;"
  assert_line "header has z-index:100"                "  z-index: 100;"
  assert_line "header has backdrop-filter blur(16px)" "  backdrop-filter: blur(16px);"
  assert_line "header has -webkit-backdrop-filter"    "  -webkit-backdrop-filter: blur(16px);"
  assert_line "header has semi-transparent background" \
    "  background: rgba(255,255,255,0.85);"
  assert_line "header has bottom border divider" \
    "  border-bottom: 1px solid rgba(0,0,0,0.06);"
}

# ---------------------------------------------------------------------------
# SPEC-HEADER-002: Drift 渐变品牌标题
# ---------------------------------------------------------------------------
test_header_brand_gradient() {
  echo ""
  echo "=== SPEC-HEADER-002: Drift Brand Gradient ==="

  assert_line "h1 has Drift gradient #005AF0" \
    "  background: linear-gradient(135deg, #005AF0 0%, #00DCC0 100%);"
  assert_line "h1 has -webkit-background-clip:text" \
    "  -webkit-background-clip: text;"
  assert_line "h1 has background-clip:text" \
    "  background-clip: text;"
  assert_line "h1 has color:transparent" \
    "  color: transparent;"
  assert_line "h1 has -webkit-text-fill-color:transparent" \
    "  -webkit-text-fill-color: transparent;"
  assert_line "h1 has font-weight:800" \
    "  font-weight: 800;"
  assert_line "desktop h1 font-size 1.6rem" \
    "  header nav h1 { font-size: 1.6rem; }"
  assert_line "mobile h1 font-size 1.25rem" \
    "  header nav h1 { font-size: 1.25rem; font-weight: 800; }"
}

# ---------------------------------------------------------------------------
# SPEC-HEADER-003: Global Fluent font-family
# ---------------------------------------------------------------------------
test_body_font_family() {
  echo ""
  echo "=== SPEC-HEADER-003: Global Fluent font-family ==="

  assert_line ":root has --font-family-base variable" \
    '  --font-family-base: "Segoe UI"'
  assert_line "body uses font-family var(--font-family-base)" \
    "  font-family: var(--font-family-base);"
  assert_line "Segoe UI in font stack" \
    '"Segoe UI"'
}

# ---------------------------------------------------------------------------
# SPEC-HEADER-004: iPad breakpoint (768-1023px)
# ---------------------------------------------------------------------------
test_header_ipad_breakpoint() {
  echo ""
  echo "=== SPEC-HEADER-004: iPad Breakpoint ==="

  assert_line "iPad breakpoint declaration present" \
    "@media (min-width: 768px) and (max-width: 1023px) {"
  assert_line "iPad h1 font-size 1.4rem" \
    "  header nav h1 { font-size: 1.4rem; }"
  assert_line "iPad search-box max-width 480px" \
    "  .search-box { max-width: 480px; }"
  assert_line "iPad search-root flex shrink" \
    "  .search-root { flex: 0 1 480px; }"
}

# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------
run_all() {
  test_header_sticky_acrylic
  test_header_brand_gradient
  test_body_font_family
  test_header_ipad_breakpoint

  # -------------------------------------------------------------------------
  # Hugo build check
  # -------------------------------------------------------------------------
  echo ""
  echo "=== Hugo Build Check ==="
  assert_build_ok

  # -------------------------------------------------------------------------
  # Summary
  # -------------------------------------------------------------------------
  echo ""
  echo "============================================"
  echo "  Results: ${PASS_COUNT} PASS / ${FAIL_COUNT} FAIL"
  echo "============================================"
}

# Allow running a single scenario by function name, otherwise run all.
if [[ $# -gt 0 ]]; then
  "$1"
else
  run_all
fi

[[ $FAIL_COUNT -eq 0 ]]
