#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# sync-to-drive.sh — Push GRID//NODE backups to Google Drive
# ═══════════════════════════════════════════════════════════════════════════════
#
# What: Syncs critical files to Google Drive.
# When: Manually, or auto after deploy (via deploy-gridnode.sh hook).
# Why: Off-sandbox backup for the 60MB of critical files.
#
# Usage:
#   bash sync-to-drive.sh           # Sync everything
#   bash sync-to-drive.sh baseline  # Just the baseline
#   bash sync-to-drive.sh handoff   # Just the handbook docs
#   bash sync-to-drive.sh deliverables  # Just audit reports
#
# ═══════════════════════════════════════════════════════════════════════════════

set -e

REMOTE_NAME="${GRIDNODE_DRIVE_NAME:-gdrive}"
DRIVE_BASE="$REMOTE_NAME:GRIDNODE/backups"

# Privacy guard: hard-block any path outside GRIDNODE/backups
# The OAuth token has full Drive access; this script enforces scope.
# Allow ONLY: gdrive:GRIDNODE/backups  OR  gdrive:GRIDNODE/backups/...
if [[ ! "$DRIVE_BASE" =~ ^${REMOTE_NAME}:GRIDNODE/backups(/.*)?$ ]]; then
    err "REFUSING: DRIVE_BASE must be exactly '$REMOTE_NAME:GRIDNODE/backups[/...]'"
    err "  Got: $DRIVE_BASE"
    err "  This script may only write to GRIDNODE/backups/* on Drive."
    err "  Path traversal (..) and other folders are blocked."
    exit 99
fi

bold() { printf "\033[1m%s\033[0m\n" "$1"; }
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m⚠\033[0m %s\n" "$1"; }
err()  { printf "  \033[31m✗\033[0m %s\n" "$1"; }

# Check setup
if ! command -v rclone >/dev/null 2>&1; then
    err "rclone not installed"
    exit 1
fi

if ! rclone listremotes 2>/dev/null | grep -q "^${REMOTE_NAME}:$"; then
    err "Remote '$REMOTE_NAME' not configured. Run: bash setup-drive.sh"
    exit 1
fi

if ! rclone lsd "$REMOTE_NAME:" >/dev/null 2>&1; then
    err "Cannot reach Drive. Check auth + network."
    exit 1
fi

WHAT="${1:-all}"

bold "═══════════════════════════════════════════════════════════════"
bold "  Syncing to Drive: $WHAT"
bold "═══════════════════════════════════════════════════════════════"
echo ""

# What to sync
sync_baseline() {
    [ -d /workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED ] || return
    echo "  → baseline/"
    rclone sync /workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED \
        "$DRIVE_BASE/baseline" \
        --progress 2>&1 | tail -3
    ok "baseline synced"
}

sync_handoff() {
    [ -d /workspace/.gridnode-handoff ] || return
    echo "  → handoff/"
    rclone sync /workspace/.gridnode-handoff \
        "$DRIVE_BASE/handoff" \
        --exclude ".git/**" \
        --exclude "scripts/**" \
        --progress 2>&1 | tail -3
    ok "handoff synced"
}

sync_deliverables() {
    [ -d /workspace/deliverables ] || return
    echo "  → deliverables/"
    rclone sync /workspace/deliverables \
        "$DRIVE_BASE/deliverables" \
        --exclude "*.pyc" \
        --exclude "__pycache__/**" \
        --progress 2>&1 | tail -3
    ok "deliverables synced"
}

case "$WHAT" in
    all)
        sync_baseline
        sync_handoff
        sync_deliverables
        ;;
    baseline) sync_baseline ;;
    handoff)  sync_handoff ;;
    deliverables) sync_deliverables ;;
    *)
        err "Unknown target: $WHAT (use: all | baseline | handoff | deliverables)"
        exit 1
        ;;
esac

echo ""
ok "Drive sync complete"
echo ""
echo "  Drive folder: $DRIVE_BASE/"
echo "  View in browser: https://drive.google.com/drive/search?q=GRIDNODE"
echo ""