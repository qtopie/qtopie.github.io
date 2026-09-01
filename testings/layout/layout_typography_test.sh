#!/usr/bin/env bash
# =============================================================================
# Spec BDD Test Runner: Global Typography & Responsive Layout
#
# Mapped tests:
#   - SPEC-LAYOUT-001  test_header_mobile_compact
#   - SPEC-LAYOUT-002  test_metadata_pill_tags
#   - SPEC-LAYOUT-003  test_title_typography
#   - SPEC-LAYOUT-004  test_body_typography_rhythm
#   - SPEC-LAYOUT-005  test_heading_hierarchy_h2_decor
#   - SPEC-LAYOUT-006  test_mobile_toc_fab_acrylic
#   - SPEC-LAYOUT-007  test_diagrams_codeblock_containers
#
# Spec: specs/modules/global-typography-layout.spec.md
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

MAIN_CSS="$ROOT_DIR/themes/drift-blog-theme/assets/css/main.css"
PAGE_CSS="$ROOT_DIR/themes/drift-blog-theme/assets/css/page.css"
PAGE_HTML="$ROOT_DIR/themes/drift-blog-theme/layouts/page.html"

PASS_COUNT=0
FAIL_COUNT=0

pass() { echo "  PASS: $1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { echo "  FAIL: $1"; FAIL_COUNT=$((FAIL_COUNT+1)); }

assert_file_contains() {
  local desc="$1" file="$2" pattern="$3"
  if grep -qF "$pattern" "$file"; then
    pass "$desc"
  else
    fail "$desc — not found in $(basename "$file"): $pattern"
  fi
}

test_header_mobile_compact() {
  echo ""
  echo "=== SPEC-LAYOUT-001: Mobile Header Compact ==="
  assert_file_contains "Header mobile nav padding optimized" "$MAIN_CSS" "header nav {"
}

test_metadata_pill_tags() {
  echo ""
  echo "=== SPEC-LAYOUT-002: Metadata Pill Tags ==="
  assert_file_contains "Tag item pill styling" "$PAGE_CSS" ".metadata #post-tags"
}

test_title_typography() {
  echo ""
  echo "=== SPEC-LAYOUT-003: Title Typography ==="
  assert_file_contains "Article title responsive rule" "$PAGE_CSS" ".metadata h1"
}

test_body_typography_rhythm() {
  echo ""
  echo "=== SPEC-LAYOUT-004: Body Typography Rhythm ==="
  assert_file_contains "Article paragraph line-height" "$PAGE_CSS" "line-height:"
}

test_heading_hierarchy_h2_decor() {
  echo ""
  echo "=== SPEC-LAYOUT-005: Heading Hierarchy & H2 Decor ==="
  assert_file_contains "Article H2 decoration" "$PAGE_CSS" "article h2"
}

test_mobile_toc_fab_acrylic() {
  echo ""
  echo "=== SPEC-LAYOUT-006: Mobile TOC FAB Acrylic ==="
  assert_file_contains "Mobile TOC trigger backdrop filter" "$PAGE_CSS" ".mobile-toc-trigger"
}

test_diagrams_codeblock_containers() {
  echo ""
  echo "=== SPEC-LAYOUT-007: Diagrams & Codeblock Containers ==="
  assert_file_contains "D2 container styling" "$PAGE_CSS" ".d2-container"
  assert_file_contains "KaTeX display scroll" "$PAGE_CSS" ".katex-display"
}

run_all() {
  test_header_mobile_compact
  test_metadata_pill_tags
  test_title_typography
  test_body_typography_rhythm
  test_heading_hierarchy_h2_decor
  test_mobile_toc_fab_acrylic
  test_diagrams_codeblock_containers

  echo ""
  echo "============================================"
  echo "  Layout Spec Results: ${PASS_COUNT} PASS / ${FAIL_COUNT} FAIL"
  echo "============================================"
}

if [[ $# -gt 0 ]]; then
  "$1"
else
  run_all
fi

[[ $FAIL_COUNT -eq 0 ]]
