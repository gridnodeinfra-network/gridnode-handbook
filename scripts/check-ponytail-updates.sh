#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# check-ponytail-updates.sh — Ponytail version checker (one-shot)
# ═══════════════════════════════════════════════════════════════════════════════
#
# What: Checks GitHub for latest Ponytail release, compares to local.
# When: Called by session-start.sh on bootstrap, OR manually by Mavin.
# Why: Knows when upstream has changes worth pulling. Does NOT auto-update.
#
# Usage: bash check-ponytail-updates.sh
#
# Exit codes:
#   0 = up to date OR network unreachable (graceful degrade)
#   1 = local clone is missing
#   2 = new version available
#
# ═══════════════════════════════════════════════════════════════════════════════

set -e

REPO="DietrichGebert/ponytail"
LOCAL_DIR="/workspace/ponytail"

# ─── Local check ───
if [ ! -d "$LOCAL_DIR/.git" ]; then
    echo "⚠️  Local Ponytail clone not found at $LOCAL_DIR"
    echo "   To set up: git clone --depth 1 https://github.com/$REPO.git $LOCAL_DIR"
    exit 1
fi

# ─── Fetch latest tag (graceful degrade on network error) ───
LATEST_TAG=$(curl -sf "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null | \
    python3 -c "import sys,json; print(json.load(sys.stdin).get('tag_name','unknown'))" 2>/dev/null || echo "unknown")

if [ "$LATEST_TAG" = "unknown" ]; then
    echo "ℹ️  Could not reach GitHub (network issue?). Skipping check."
    exit 0
fi

# ─── Local commit ───
LOCAL_HASH=$(cd "$LOCAL_DIR" && git rev-parse HEAD 2>/dev/null || echo "unknown")

# ─── Fetch latest commit hash ───
LATEST_HASH=$(curl -sf "https://api.github.com/repos/$REPO/commits/main" 2>/dev/null | \
    python3 -c "import sys,json; print(json.load(sys.stdin).get('sha','unknown'))" 2>/dev/null || echo "unknown")

# ─── Compare ───
if [ "$LOCAL_HASH" = "$LATEST_HASH" ]; then
    echo "✓ Ponytail up to date ($LATEST_TAG @ $LOCAL_HASH)"
    exit 0
fi

# ─── Behind — show what ───
echo "📦 Ponytail update available"
echo "   Local:    $LOCAL_HASH"
echo "   Upstream: $LATEST_HASH ($LATEST_TAG)"
echo ""
echo "Recent upstream commits:"
curl -sf "https://api.github.com/repos/$REPO/commits?per_page=5" 2>/dev/null | \
    python3 -c "
import sys, json
try:
    for c in json.load(sys.stdin)[:5]:
        msg = c['commit']['message'].splitlines()[0][:60]
        print(f\"  {c['sha'][:8]} {c['commit']['author']['date'][:10]} {msg}\")
except: pass
" 2>/dev/null
echo ""
echo "To update: cd $LOCAL_DIR && git pull"
exit 2