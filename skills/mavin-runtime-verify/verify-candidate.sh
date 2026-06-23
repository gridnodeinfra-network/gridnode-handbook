#!/bin/bash
# verify-candidate.sh — comprehensive pre-deploy checks for GRID//NODE candidates
# Usage: bash verify-candidate.sh <candidate.html>

set -e

CANDIDATE="${1:?Usage: bash verify-candidate.sh <candidate.html>}"

if [ ! -f "$CANDIDATE" ]; then
    echo "❌ Candidate not found: $CANDIDATE"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════════"
echo "  GRID//NODE CANDIDATE VERIFICATION"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "File: $CANDIDATE"
echo "Size: $(wc -c < "$CANDIDATE") bytes"
echo ""

FAIL=0

# 1. Find duplicate function definitions
echo "1/6 Checking for duplicate function definitions..."
duplicates=$(grep -nE "function [a-zA-Z_][a-zA-Z_0-9]*\s*\(|window\.[a-zA-Z_][a-zA-Z_0-9]*\s*=\s*function" "$CANDIDATE" 2>/dev/null | \
    sed -E 's/.*function ([a-zA-Z_][a-zA-Z_0-9]*).*/\1/; s/.*window\.([a-zA-Z_][a-zA-Z_0-9]*).*=.*/\1/' | \
    sort | uniq -c | sort -rn | awk '$1 > 1 {print "    "$0}' | head -10)

if [ -n "$duplicates" ]; then
    echo "  ⚠️  Functions with multiple definitions found:"
    echo "$duplicates"
    echo "  ACTION: Find the LAST definition (which runs in production)"
    echo "          Test that one, not the first"
    echo ""
    echo "  Functions to check:"
    echo "$duplicates" | awk '{print "    grep -n function "$2" '"$CANDIDATE"' | tail -1"}'
    FAIL=1
else
    echo "  ✅ No duplicate function definitions"
fi
echo ""

# 2. Count setTimeout/setInterval/Promise bodies
echo "2/6 Counting async bodies..."
timeouts=$(grep -cE "setTimeout|setInterval" "$CANDIDATE" 2>/dev/null | head -1)
[ -z "$timeouts" ] && timeouts=0
promises=$(grep -cE "\.then\s*\(|\.catch\s*\(|\.finally\s*\(|new Promise" "$CANDIDATE" 2>/dev/null | head -1)
[ -z "$promises" ] && promises=0
echo "  setTimeout/setInterval: $timeouts"
echo "  Promise bodies: $promises"
if [ "$timeouts" -gt 0 ] || [ "$promises" -gt 0 ]; then
    echo "  ACTION: Runtime-test these async bodies, not just syntax-check"
    echo "          Common bug: ReferenceError inside setTimeout callback"
fi
echo ""

# 3. Count IIFEs (potential scope boundaries)
echo "3/6 Counting IIFEs (potential scope boundaries)..."
iifes=$(grep -cE "\(function\s*\(" "$CANDIDATE" 2>/dev/null | head -1)
[ -z "$iifes" ] && iifes=0
echo "  IIFEs: $iifes"
if [ "$iifes" -gt 5 ]; then
    echo "  ⚠️  Many IIFEs — high risk of scope leaks"
    echo "  ACTION: Verify functions defined inside IIFEs aren't called outside"
fi
echo ""

# 4. SHA delta check
echo "4/6 Checking size delta..."
baseline_path="/workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED/gridnode-v1.3_post-phase-D_baseline.html"
if [ -f "$baseline_path" ]; then
    baseline_size=$(wc -c < "$baseline_path")
    candidate_size=$(wc -c < "$CANDIDATE")
    delta=$((candidate_size - baseline_size))
    echo "  Baseline: $baseline_size bytes"
    echo "  Candidate: $candidate_size bytes"
    echo "  Delta: $delta bytes"
    if [ $delta -gt 10000 ]; then
        echo "  ⚠️  Large delta (>10KB) — review for unintended changes"
    fi
    # Note: a smaller candidate isn't necessarily bad (could be a cleanup).
    # Only fail if the candidate is suspiciously small (<10% of baseline).
    if [ $delta -lt -1000 ] && [ "$candidate_size" -lt $((baseline_size / 10)) ]; then
        echo "  ⚠️  Candidate is <10% of baseline size — verify this is intentional"
        FAIL=1
    elif [ $delta -lt -1000 ]; then
        echo "  ℹ️  Candidate is smaller than baseline (delta: $delta bytes)"
    fi
else
    echo "  ⚠️  Baseline not found: $baseline_path"
fi
echo ""

# 5. Count protected keywords (sanity check)
echo "5/6 Counting protected keywords..."
protected_keywords=0
for kw in "scannerMode" "gn_settings" "Phase Engine" "SHOT HISTORY" "VAULT"; do
    count=$(grep -c "$kw" "$CANDIDATE" 2>/dev/null | head -1)
    [ -z "$count" ] && count=0
    if [ "$count" -gt 0 ]; then
        protected_keywords=$((protected_keywords + count))
    fi
done
echo "  Protected keyword references: $protected_keywords"
if [ "$protected_keywords" -lt 50 ]; then
    echo "  ⚠️  Low count — possible missing systems"
fi
echo ""

# 6. Browser test (if Playwright available)
echo "6/6 Browser test..."
if command -v python3 &> /dev/null && python3 -c "import playwright" 2>/dev/null; then
    # Check if browsers are installed first
    if ! python3 -c "from playwright.sync_api import sync_playwright; p = sync_playwright().start(); p.chromium.launch(headless=True).close(); p.stop()" 2>/dev/null; then
        echo "  ⚠️  Playwright installed but browsers missing"
        echo "  Install with: playwright install chromium"
        echo "  Skipping browser test (not a candidate issue)"
    else
        python3 -c "
from playwright.sync_api import sync_playwright
import sys
try:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_context(viewport={'width': 375, 'height': 812}).new_page()
        
        errors = []
        page.on('pageerror', lambda e: errors.append(str(e)))
        page.on('console', lambda m: errors.append(f'console.{m.type}: {m.text}') if m.type == 'error' else None)
        
        page.goto('file://$CANDIDATE', wait_until='networkidle')
        page.wait_for_timeout(2000)
        
        # Check for window.errors
        win_errors = page.evaluate('window.errors || []')
        all_errors = errors + win_errors
        
        if all_errors:
            print('  ❌ Errors during load:')
            for e in all_errors[:10]:
                print(f'    {e[:200]}')
            sys.exit(1)
        else:
            print('  ✅ No errors during load')
        browser.close()
except Exception as e:
    print(f'  ⚠️  Browser test error: {e}')
    sys.exit(1)
" 2>&1 | head -20
    BROWSER_RESULT=$?
    if [ "$BROWSER_RESULT" -ne 0 ]; then
        FAIL=1
    fi
    fi  # Close "browsers installed" check
else
    echo "  ⚠️  Playwright not available, skipping browser test"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
if [ $FAIL -eq 0 ]; then
    echo "  ✅ ALL CHECKS PASSED"
    echo "  Safe to deploy with:"
    echo "    ./deploy-gridnode.sh '<message>' $CANDIDATE"
    exit 0
else
    echo "  ❌ CHECKS FAILED — DO NOT DEPLOY YET"
    echo "  Fix the issues above and re-run this verification"
    exit 1
fi
echo "═══════════════════════════════════════════════════════════════"