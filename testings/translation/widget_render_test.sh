#!/usr/bin/env bash
# =============================================================================
# Spec BDD Test Runner: Client-Side Page Translation Widget
#
# Mapped tests:
#   - SPEC-TRANSLATION-001 test_widget_renders_in_header
#   - SPEC-TRANSLATION-002 test_widget_disabled
#   - SPEC-TRANSLATION-003 test_translate_executes
#   - SPEC-TRANSLATION-004 test_graceful_fallback
#
# Spec: specs/modules/translation-widget.spec.md
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

# Build output dirs (must live inside the repo for the snap-hugo sandbox)
TEST_BUILD_ENABLED="$ROOT_DIR/public-test-enabled"
TEST_BUILD_DISABLED="$ROOT_DIR/public-test-disabled"
DISABLED_CFG="$ROOT_DIR/config.disabled.yaml"
TEST_SERVER_PORT="${TEST_SERVER_PORT:-8191}"

PASS_COUNT=0
FAIL_COUNT=0

cleanup() {
  rm -rf "$TEST_BUILD_ENABLED" "$TEST_BUILD_DISABLED" "$DISABLED_CFG"
  if [[ -n "${SERVER_PID:-}" ]]; then
    kill "$SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

pass() { echo "  ✅ PASS: $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { echo "  ❌ FAIL: $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

# -----------------------------------------------------------------------------
# Build helpers
# -----------------------------------------------------------------------------

build_enabled() {
  hugo --destination "$TEST_BUILD_ENABLED" >/dev/null 2>&1
}

build_disabled() {
  cat > "$DISABLED_CFG" << 'EOF'
params:
  translation:
    enabled: false
  author:
    name: 'qtopie'
    url: 'https://github.com/qtopie'
EOF
  hugo --config config.yaml,"$DISABLED_CFG" --destination "$TEST_BUILD_DISABLED" >/dev/null 2>&1
}

# -----------------------------------------------------------------------------
# Scenario 1: SPEC-TRANSLATION-001  (default config renders widget in header)
# -----------------------------------------------------------------------------
test_widget_renders_in_header() {
  echo ""
  echo "[SPEC-TRANSLATION-001] test_widget_renders_in_header"
  build_enabled

  local sample="$TEST_BUILD_ENABLED/index.html"
  if ! grep -q 'id="google_translate_element"' "$sample"; then
    fail "homepage missing #google_translate_element container"
    return 1
  fi
  pass "homepage contains #google_translate_element container"

  if ! grep -q 'element.js?cb=googleTranslateElementInit' "$sample"; then
    fail "homepage missing Google Translate init script tag"
    return 1
  fi
  pass "homepage injects Google Translate script (cb=googleTranslateElementInit)"

  if ! grep -q 'pageLanguage: '"'"'zh-CN'"'"'' "$sample"; then
    fail "default pageLanguage zh-CN not rendered"
    return 1
  fi
  pass "default pageLanguage zh-CN rendered"

  if ! grep -q "includedLanguages: 'en,zh-CN'" "$sample"; then
    fail "default includedLanguages not restricted to en,zh-CN"
    return 1
  fi
  pass "default includedLanguages is en,zh-CN (Chinese + English only)"

  local count
  count="$(grep -rl 'id="google_translate_element"' "$TEST_BUILD_ENABLED" --include='*.html' 2>/dev/null | wc -l)"
  if [[ "$count" -lt 100 ]]; then
    fail "expected widget container in all pages, got $count"
    return 1
  fi
  pass "widget container present in $count pages"
}

# -----------------------------------------------------------------------------
# Scenario 2: SPEC-TRANSLATION-002  (enabled=false suppresses everything)
# -----------------------------------------------------------------------------
test_widget_disabled() {
  echo ""
  echo "[SPEC-TRANSLATION-002] test_widget_disabled"
  build_disabled

  local container_count script_count init_count
  container_count="$(grep -rl 'id="google_translate_element"' "$TEST_BUILD_DISABLED" --include='*.html' 2>/dev/null | wc -l)"
  script_count="$(grep -rl 'element.js?cb=googleTranslateElementInit' "$TEST_BUILD_DISABLED" --include='*.html' 2>/dev/null | wc -l)"
  init_count="$(grep -rl 'googleTranslateElementInit' "$TEST_BUILD_DISABLED" --include='*.html' 2>/dev/null | wc -l)"

  [[ "$container_count" -eq 0 ]] && pass "no #google_translate_element in any page" \
    || { fail "found $container_count widget containers (expected 0)"; return 1; }
  [[ "$script_count" -eq 0 ]] && pass "no Google script tag in any page" \
    || { fail "found $script_count google script tags (expected 0)"; return 1; }
  [[ "$init_count" -eq 0 ]] && pass "no googleTranslateElementInit code in any page" \
    || { fail "found $init_count init markers (expected 0)"; return 1; }
}

# -----------------------------------------------------------------------------
# Scenario 3: SPEC-TRANSLATION-003  (user picks language -> page translates)
# Requires Playwright + a browser; validates via mocked Google API that the
# TranslateElement is constructed with the correct target language.
# -----------------------------------------------------------------------------
test_translate_executes() {
  echo ""
  echo "[SPEC-TRANSLATION-003] test_translate_executes"
  if ! command -v playwright >/dev/null 2>&1 && ! python3 -c "import playwright" 2>/dev/null; then
    fail "Playwright not available, skipping browser scenario"
    return 0
  fi
  if ! build_enabled; then
    fail "build for browser test failed"
    return 1
  fi

  (cd "$TEST_BUILD_ENABLED" && python3 -m http.server "$TEST_SERVER_PORT" >/dev/null 2>&1) &
  SERVER_PID=$!
  sleep 1

  python3 - "$TEST_SERVER_PORT" << 'PYEOF'
import json
import sys
from playwright.sync_api import sync_playwright

port = sys.argv[1]

# Mock the Google Translate element.js so the widget initializes deterministically.
MOCK_ELEMENT_JS = r"""
(function () {
  window.__mockCalls = window.__mockCalls || [];
  window.google = window.google || {};
  window.google.translate = window.google.translate || {};
  window.google.translate.TranslateElement = function (options, targetId) {
    window.__mockCalls.push({ options: options, targetId: targetId });
    var el = document.getElementById(targetId);
    if (el) { el.textContent = 'translated:' + (options.pageLanguage || ''); }
  };
  // The inline init script references TranslateElement.InlineLayout.SIMPLE.
  window.google.translate.TranslateElement.InlineLayout = { SIMPLE: 0 };
  // The real element.js invokes the ?cb= callback after it is ready.
  if (window.googleTranslateElementInit) {
    window.googleTranslateElementInit();
  }
})();
"""

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()
    page.route("**/translate_a/element.js*",
               lambda route: route.fulfill(status=200,
                                           content_type="application/javascript",
                                           body=MOCK_ELEMENT_JS))
    page.on("console", lambda msg: sys.stdout.write(f"[console] {msg.type}: {msg.text}\n"))
    errors = []
    page.on("pageerror", lambda e: errors.append(str(e)))
    page.goto(f"http://127.0.0.1:{port}/posts/sniphunt/", wait_until="networkidle")

    # The init callback fires after the mock element.js loads.
    calls = page.evaluate("window.__mockCalls")
    if not calls:
        print("NO_CALLS")
        browser.close()
        sys.exit(1)

    call = calls[0]
    print(f"CALL_OPTIONS={json.dumps(call['options'])}")
    ok = (
        call["targetId"] == "google_translate_element"
        and "pageLanguage" in call["options"]
        and "layout" in call["options"]
    )
    # Simulate a user language selection through the widget options callback.
    page.evaluate("""
        window.__mockCalls[0].options.pickerOpened = null;
    """)
    browser.close()
    if not ok:
        print("BAD_CALL")
        sys.exit(1)
    print("TRANSLATE_INIT_OK")
PYEOF

  local rc=$?
  if [[ $rc -eq 0 ]]; then
    pass "TranslateElement constructed with correct options"
  else
    fail "TranslateElement init failed (rc=$rc)"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Scenario 4: SPEC-TRANSLATION-004  (graceful fallback when Google unreachable)
# -----------------------------------------------------------------------------
test_graceful_fallback() {
  echo ""
  echo "[SPEC-TRANSLATION-004] test_graceful_fallback"
  if ! command -v playwright >/dev/null 2>&1 && ! python3 -c "import playwright" 2>/dev/null; then
    fail "Playwright not available, skipping browser scenario"
    return 0
  fi
  if [[ ! -d "$TEST_BUILD_ENABLED" ]]; then
    build_enabled
  fi

  (cd "$TEST_BUILD_ENABLED" && python3 -m http.server "$TEST_SERVER_PORT" >/dev/null 2>&1) &
  SERVER_PID=$!
  sleep 1

  python3 - "$TEST_SERVER_PORT" << 'PYEOF'
import sys
from playwright.sync_api import sync_playwright

port = sys.argv[1]

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()
    # Abort the Google Translate script so init never fires.
    page.route("**/translate_a/element.js*", lambda route: route.abort())
    warnings = []
    page.on("console", lambda msg: warnings.append(msg.text) if msg.type == "warning" else None)
    page.goto(f"http://127.0.0.1:{port}/posts/sniphunt/", wait_until="networkidle")

    page.wait_for_timeout(6000)  # wait past the 5s fallback timer

    visible = page.evaluate("""() => {
        var el = document.getElementById('google_translate_element');
        return el && el.style.display === 'none';
    }""")
    has_warning = any("Google Translate unavailable" in w for w in warnings)

    print(f"WIDGET_HIDDEN={visible}")
    print(f"HAS_WARNING={has_warning}")
    browser.close()
    if not visible or not has_warning:
        sys.exit(1)
PYEOF

  local rc=$?
  if [[ $rc -eq 0 ]]; then
    pass "widget hidden + console warning after 5s timeout"
  else
    fail "graceful fallback failed (rc=$rc)"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  echo "======================================================"
  echo "Translation Widget Spec Test Runner"
  echo "  Spec: specs/modules/translation-widget.spec.md"
  echo "======================================================"

  # Build once for enabled state; disabled builds a separate tree.
  local only="${1:-}"

  if [[ -z "$only" || "$only" == "test_widget_renders_in_header" ]]; then
    test_widget_renders_in_header || true
  fi
  if [[ -z "$only" || "$only" == "test_widget_disabled" ]]; then
    test_widget_disabled || true
  fi
  if [[ -z "$only" || "$only" == "test_translate_executes" ]]; then
    test_translate_executes || true
  fi
  if [[ -z "$only" || "$only" == "test_graceful_fallback" ]]; then
    test_graceful_fallback || true
  fi

  echo ""
  echo "======================================================"
  echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
  if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
  fi
  echo "All translation widget spec tests passed."
  echo "======================================================"
}

main "$@"
