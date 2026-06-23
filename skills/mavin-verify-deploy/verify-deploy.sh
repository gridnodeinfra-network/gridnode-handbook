#!/bin/bash
# verify-deploy.sh — verifies that live deploy matches local + lock
# Usage: bash verify-deploy.sh [max_wait_seconds]

set -e

LIVE_URL="${LIVE_URL:-https://gridnode.network}"
LOCAL_FILE="${LOCAL_FILE:-/workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED/gridnode-v1.3_post-phase-D_baseline.html}"
LOCK_URL="${LOCK_URL:-https://raw.githubusercontent.com/gridnodeinfra-network/gridnode-handbook/main/baseline.sha}"
MAX_WAIT="${1:-30}"

echo "═══════════════════════════════════════════════════════════════"
echo "  GRID//NODE DEPLOY VERIFICATION"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Live URL:  $LIVE_URL"
echo "Local:     $LOCAL_FILE"
echo "Lock:      $LOCK_URL"
echo ""

# Wait for CDN propagation (with timeout)
echo "⏳ Waiting ${MAX_WAIT}s for CDN propagation..."
sleep "$MAX_WAIT"

# Get all three SHAs
echo ""
echo "Fetching SHAs..."
LIVE_SHA=$(curl -s "$LIVE_URL" 2>/dev/null | sha256sum | cut -d' ' -f1)
LOCAL_SHA=$(sha256sum "$LOCAL_FILE" 2>/dev/null | cut -d' ' -f1)
LOCK_SHA=$(curl -s "$LOCK_URL" 2>/dev/null | grep -oE '[0-9a-f]{64}' | head -1)

# Get sizes
LIVE_SIZE=$(curl -s "$LIVE_URL" 2>/dev/null | wc -c)
LOCAL_SIZE=$(wc -c < "$LOCAL_FILE")

echo ""
echo "Local SHA:  ${LOCAL_SHA:0:16}..."
echo "Live SHA:   ${LIVE_SHA:0:16}..."
echo "Lock SHA:   ${LOCK_SHA:0:16}..."
echo ""
echo "Local size: $LOCAL_SIZE bytes"
echo "Live size:  $LIVE_SIZE bytes"
echo ""

# Verify local matches lock
if [ "$LOCAL_SHA" = "$LOCK_SHA" ]; then
    echo "✅ Local SHA matches lock pointer"
else
    echo "❌ Local SHA does NOT match lock pointer"
    echo "   Either: local was deployed but lock not updated"
    echo "   Or: lock was updated but local was not deployed"
    exit 1
fi

# Verify live matches lock
if [ "$LIVE_SHA" = "$LOCK_SHA" ]; then
    echo "✅ Live SHA matches lock pointer"
else
    echo "❌ Live SHA does NOT match lock pointer"
    echo "   Either: CDN not yet propagated (wait longer)"
    echo "   Or: deploy failed silently"
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅ DEPLOY VERIFIED"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Live: $LIVE_URL"
echo "Lock: $LOCK_SHA"
echo "Size: $LIVE_SIZE bytes"