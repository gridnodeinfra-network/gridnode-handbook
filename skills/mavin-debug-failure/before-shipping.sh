#!/bin/bash
# before-shipping.sh — last-mile sanity check before deploying
# Usage: bash before-shipping.sh <candidate.html>

set -e

CANDIDATE="${1:-}"

echo "═══════════════════════════════════════════════════════════════"
echo "  BEFORE SHIPPING — final sanity check"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "Have you (the Mavin deploying this):"
echo ""
echo "  □ OCR-verified your screenshot?"
echo "  □ Runtime-tested the function (last definition wins)?"
echo "  □ Tested async bodies (setTimeout/Promise)?"
echo "  □ Asked Pipe to confirm on HIS phone?"
echo "  □ Shipped <3 versions of this fix?"
echo ""

if [ -n "$CANDIDATE" ] && [ -f "$CANDIDATE" ]; then
    BASELINE_SIZE=970160
    CANDIDATE_SIZE=$(wc -c < "$CANDIDATE")
    DELTA=$((CANDIDATE_SIZE - BASELINE_SIZE))
    echo "  File: $CANDIDATE"
    echo "  Size: $CANDIDATE_SIZE bytes (delta: $DELTA)"
    echo ""
    if [ $DELTA -gt 10000 ]; then
        echo "  ⚠️  Large delta — review for unintended changes"
    fi
    if [ $DELTA -lt -1000 ]; then
        echo "  ⚠️  Negative delta — candidate is SMALLER than baseline"
    fi
fi

echo ""
echo "If any answer is NO, don't ship yet."
echo "If any answer is 3+, STOP and debug honestly (see mavin-debug-failure)."
echo ""

# Check the deploy history
DEPLOY_HISTORY="/workspace/gridnode-project/gridnode-GOOD-*.html"
recent=$(ls -1 $DEPLOY_HISTORY 2>/dev/null | wc -l)
echo "Recent deploys/backups: $recent"
if [ "$recent" -gt 5 ]; then
    echo "  ⚠️  Many recent backups — high deploy velocity"
    echo "  Consider: are you shipping too fast without verifying?"
fi
echo ""

# Optional: run the runtime-verify if available
if command -v verify-gridnode-candidate &> /dev/null && [ -n "$CANDIDATE" ]; then
    echo "═══ Running verify-gridnode-candidate ═══"
    if verify-gridnode-candidate "$CANDIDATE"; then
        echo "✅ Verification passed"
    else
        echo "❌ Verification failed. Don't ship."
        exit 1
    fi
fi