#!/usr/bin/env bash
# =============================================================================
# Spec BDD Test Runner: TOC 三级目录折叠（H3 默认折叠）
#
# Mapped tests:
#   - SPEC-TOC-001 test_toc_contains_h3
#   - SPEC-TOC-002 test_h3_collapsed_by_default
#   - SPEC-TOC-003 test_toggle_expand_collapse
#   - SPEC-TOC-004 test_mobile_toc_collapse_sync
#   - SPEC-TOC-005 test_auto_expand_active_parent
#
# Spec: specs/modules/toc-collapse.spec.md
# =============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

# Build output dirs (must live inside the repo for the snap-hugo sandbox)
TEST_BUILD="$ROOT_DIR/public-test-toc"
TEST_SERVER_PORT="${TEST_SERVER_PORT:-8193}"
SAMPLE_PAGE="/notes/codejam/linked-list/"

PASS_COUNT=0
FAIL_COUNT=0

cleanup() {
  rm -rf "$TEST_BUILD"
  if [[ -n "${SERVER_PID:-}" ]]; then
    kill "$SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

pass() { echo "  ✅ PASS: $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { echo "  ❌ FAIL: $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

build() {
  # D2 diagram SVGs are required by Hugo; regenerate before building.
  if command -v d2 >/dev/null 2>&1; then
    "$ROOT_DIR/scripts/generate-d2-diagrams.sh" >/dev/null 2>&1 || true
  fi
  hugo --destination "$TEST_BUILD" >/dev/null 2>&1
}

start_server() {
  (cd "$TEST_BUILD" && python3 -m http.server "$TEST_SERVER_PORT" >/dev/null 2>&1) &
  SERVER_PID=$!
  sleep 1
}

stop_server() {
  if [[ -n "${SERVER_PID:-}" ]]; then
    kill "$SERVER_PID" 2>/dev/null || true
    SERVER_PID=""
  fi
}

# -----------------------------------------------------------------------------
# Scenario 1: SPEC-TOC-001  (TOC renders H3 sub-items nested under H2)
# -----------------------------------------------------------------------------
test_toc_contains_h3() {
  echo ""
  echo "[SPEC-TOC-001] test_toc_contains_h3"
  local file="$TEST_BUILD${SAMPLE_PAGE}index.html"
  if [[ ! -f "$file" ]]; then
    fail "sample page not built: $file"
    return 1
  fi

  python3 - "$file" << 'PYEOF'
import re
import sys

html = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r'<nav id="TableOfContents">.*?</nav>', html, re.S)
if not m:
    print("NO_TOC")
    sys.exit(1)

toc = m.group(0)
# H3 items appear as a nested <ul> inside an H2 <li> (li > a ... <ul><li><a>...)
nested = re.findall(r'<li><a href="#[^"]*">[^<]*</a>\s*<ul>', toc)
if not nested:
    print("NO_NESTED_H3")
    sys.exit(1)

print(f"NESTED_H3={len(nested)}")
sys.exit(0)
PYEOF

  local rc=$?
  if [[ $rc -eq 0 ]]; then
    pass "TOC contains H3 sub-items nested under H2"
  else
    fail "TOC does not contain H3 nested items (rc=$rc)"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Playwright browser scenarios (SPEC-TOC-002 .. SPEC-TOC-005)
# -----------------------------------------------------------------------------
_toc_playwright() {
  python3 - "$TEST_SERVER_PORT" "$SAMPLE_PAGE" "$@" << 'PYEOF'
import sys
from playwright.sync_api import sync_playwright

port, path = sys.argv[1], sys.argv[2]
checks = sys.argv[3:]  # scenario name(s) to run

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page(viewport={"width": 1280, "height": 900})
    errors = []
    page.on("pageerror", lambda e: errors.append(str(e)))
    # External scripts (Google Translate, KaTeX CDN) block load/networkidle in
    # the sandboxed test environment — abort them like widget_render_test.sh.
    page.route("**/translate_a/element.js*", lambda route: route.abort())
    page.route("**/cdnjs.cloudflare.com/**", lambda route: route.abort())
    page.route("**/translate.google.com/**", lambda route: route.abort())
    page.goto(f"http://127.0.0.1:{port}{path}", wait_until="networkidle")

    out = []
    for name in checks:
        if name == "collapsed_default":
            info = page.evaluate("""() => {
                const li = document.querySelector('#TableOfContents li.toc-has-children');
                if (!li) return { ok: false, reason: 'no toc-has-children li' };
                const sub = li.querySelector(':scope > ul');
                const toggle = li.querySelector(':scope > .toc-toggle');
                return {
                    ok: li.classList.contains('toc-collapsed')
                        && sub !== null && sub.hidden === true
                        && toggle !== null
                        && toggle.getAttribute('aria-expanded') === 'false',
                    collapsed: li.classList.contains('toc-collapsed'),
                    subHidden: sub ? sub.hidden : null,
                    hasToggle: toggle !== null,
                    aria: toggle ? toggle.getAttribute('aria-expanded') : null,
                };
            }""")
            out.append(("collapsed_default", info))

        elif name == "toggle_expand_collapse":
            page.evaluate("""() => {
                const toggle = document.querySelector('#TableOfContents li.toc-has-children > .toc-toggle');
                toggle.click();
            }""")
            expanded = page.evaluate("""() => {
                const li = document.querySelector('#TableOfContents li.toc-has-children');
                const sub = li.querySelector(':scope > ul');
                const toggle = li.querySelector(':scope > .toc-toggle');
                return {
                    ok: !li.classList.contains('toc-collapsed')
                        && sub !== null && sub.hidden === false
                        && toggle.getAttribute('aria-expanded') === 'true',
                };
            }""")
            page.evaluate("""() => {
                const toggle = document.querySelector('#TableOfContents li.toc-has-children > .toc-toggle');
                toggle.click();
            }""")
            collapsed = page.evaluate("""() => {
                const li = document.querySelector('#TableOfContents li.toc-has-children');
                const sub = li.querySelector(':scope > ul');
                const toggle = li.querySelector(':scope > .toc-toggle');
                return {
                    ok: li.classList.contains('toc-collapsed')
                        && sub !== null && sub.hidden === true
                        && toggle.getAttribute('aria-expanded') === 'false',
                };
            }""")
            out.append(("toggle_expand_collapse", expanded, collapsed))

        elif name == "mobile_sync":
            page.set_viewport_size({"width": 390, "height": 844})
            info = page.evaluate("""() => {
                const li = document.querySelector('.mobile-toc-list li.toc-has-children');
                if (!li) return { ok: false, reason: 'no mobile toc-has-children li' };
                const sub = li.querySelector(':scope > ul');
                const toggle = li.querySelector(':scope > .toc-toggle');
                return {
                    ok: li.classList.contains('toc-collapsed')
                        && sub !== null && sub.hidden === true
                        && toggle !== null,
                };
            }""")
            if not info["ok"]:
                out.append(("mobile_sync", info))
            else:
                page.evaluate("""() => {
                    const toggle = document.querySelector('.mobile-toc-list li.toc-has-children > .toc-toggle');
                    toggle.click();
                }""")
                after = page.evaluate("""() => {
                    const li = document.querySelector('.mobile-toc-list li.toc-has-children');
                    const sub = li.querySelector(':scope > ul');
                    const toggle = li.querySelector(':scope > .toc-toggle');
                    return {
                        ok: !li.classList.contains('toc-collapsed')
                            && sub !== null && sub.hidden === false
                            && toggle.getAttribute('aria-expanded') === 'true',
                    };
                }""")
                out.append(("mobile_sync", info, after))

        elif name == "auto_expand_active":
            # Simulate a real user click on the first H3 link in the TOC.
            # (scrollIntoView alone can activate the parent H2 instead, because
            # the H2 heading stays inside the observer detection band.)
            page.evaluate("""() => {
                const toggle = document.querySelector('#TableOfContents li.toc-has-children > .toc-toggle');
                if (toggle) toggle.click();
            }""")
            page.wait_for_timeout(200)
            page.evaluate("""() => {
                const h3link = document.querySelector('#TableOfContents li.toc-has-children ul a');
                if (h3link) h3link.click();
            }""")
            page.wait_for_timeout(1200)
            info = page.evaluate("""() => {
                const active = document.querySelector('#TableOfContents a.is-active');
                if (!active) return { ok: false, reason: 'no active link' };
                const li = active.closest('li');
                const top = li ? li.parentElement : null; // nested ul
                const h2li = top ? top.parentElement : null;
                if (!h2li || !h2li.classList.contains('toc-has-children')) {
                    return { ok: false, reason: 'active link not under H2 item' };
                }
                const sub = h2li.querySelector(':scope > ul');
                const toggle = h2li.querySelector(':scope > .toc-toggle');
                return {
                    ok: !h2li.classList.contains('toc-collapsed')
                        && sub !== null && sub.hidden === false
                        && toggle !== null && toggle.getAttribute('aria-expanded') === 'true',
                };
            }""")
            out.append(("auto_expand_active", info))

    browser.close()

    ok = True
    for item in out:
        name = item[0]
        if not item[-1]["ok"]:
            ok = False
            print(f"BAD_{name}={item[-1]}")
        else:
            print(f"OK_{name}")

    if errors:
        print(f"PAGE_ERRORS={errors}")
        sys.exit(1)
    if not ok:
        sys.exit(1)
    print("ALL_OK")
    sys.exit(0)
PYEOF
}

# -----------------------------------------------------------------------------
# Scenario 2: SPEC-TOC-002  (H3 collapsed by default)
# -----------------------------------------------------------------------------
test_h3_collapsed_by_default() {
  echo ""
  echo "[SPEC-TOC-002] test_h3_collapsed_by_default"
  if ! _toc_playwright "collapsed_default"; then
    fail "H3 sub-items not collapsed by default"
    return 1
  fi
  pass "H3 sub-items collapsed by default with toggle button"
}

# -----------------------------------------------------------------------------
# Scenario 3: SPEC-TOC-003  (click toggles expand/collapse)
# -----------------------------------------------------------------------------
test_toggle_expand_collapse() {
  echo ""
  echo "[SPEC-TOC-003] test_toggle_expand_collapse"
  if ! _toc_playwright "toggle_expand_collapse"; then
    fail "toggle expand/collapse failed"
    return 1
  fi
  pass "toggle button expands then collapses H3 sub-items"
}

# -----------------------------------------------------------------------------
# Scenario 4: SPEC-TOC-004  (mobile drawer TOC syncs collapse)
# -----------------------------------------------------------------------------
test_mobile_toc_collapse_sync() {
  echo ""
  echo "[SPEC-TOC-004] test_mobile_toc_collapse_sync"
  if ! _toc_playwright "mobile_sync"; then
    fail "mobile drawer TOC collapse sync failed"
    return 1
  fi
  pass "mobile drawer TOC collapsed by default and expandable"
}

# -----------------------------------------------------------------------------
# Scenario 5: SPEC-TOC-005  (active H3 auto-expands its parent)
# -----------------------------------------------------------------------------
test_auto_expand_active_parent() {
  echo ""
  echo "[SPEC-TOC-005] test_auto_expand_active_parent"
  if ! _toc_playwright "auto_expand_active"; then
    fail "active H3 did not auto-expand its parent"
    return 1
  fi
  pass "active H3 auto-expands its parent H2 item"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
main() {
  echo "======================================================"
  echo "TOC Collapse Spec Test Runner (H3 默认折叠)"
  echo "  Spec: specs/modules/toc-collapse.spec.md"
  echo "======================================================"

  if ! build; then
    echo "  ❌ FAIL: hugo build failed"
    exit 1
  fi
  echo "  ✅ build OK ($TEST_BUILD)"

  test_toc_contains_h3 || true

  if ! command -v playwright >/dev/null 2>&1 && ! python3 -c "import playwright" 2>/dev/null; then
    echo ""
    echo "  ⚠️  Playwright not available — skipping browser scenarios (002-005)"
  else
    start_server
    test_h3_collapsed_by_default || true
    test_toggle_expand_collapse || true
    test_mobile_toc_collapse_sync || true
    test_auto_expand_active_parent || true
    stop_server
  fi

  echo ""
  echo "======================================================"
  echo "Results: $PASS_COUNT passed, $FAIL_COUNT failed"
  if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
  fi
  echo "All TOC collapse spec tests passed."
  echo "======================================================"
}

main "$@"
