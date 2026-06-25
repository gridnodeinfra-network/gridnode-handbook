#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# nuke-drive.sh — Remove ALL Drive backup integration (full teardown)
# ═══════════════════════════════════════════════════════════════════════════════
#
# What it does:
#   1. Deletes the GRIDNODE/ folder tree from Drive
#   2. Removes rclone config from sandbox
#   3. Removes saved OAuth token from credential store
#   4. Removes the scripts themselves
#   5. Removes the hook from deploy-gridnode.sh
#
# Use when:
#   - You want to use a different Google account
#   - You want Drive backup disabled entirely
#   - You're cleaning up before re-setup
#
# Re-running setup-drive.sh after this will rebuild everything cleanly.
#
# ═══════════════════════════════════════════════════════════════════════════════

set -e

bold() { printf "\033[1m%s\033[0m\n" "$1"; }
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m⚠\033[0m %s\n" "$1"; }
err()  { printf "  \033[31m✗\033[0m %s\n" "$1"; }

bold "═══════════════════════════════════════════════════════════════"
bold "  Drive backup NUCLEAR OPTION"
bold "═══════════════════════════════════════════════════════════════"
echo ""
echo "  This removes ALL Drive backup integration:"
echo "    • GRIDNODE/ folder tree from your Drive"
echo "    • rclone OAuth token from sandbox"
echo "    • Saved credential file"
echo "    • setup-drive.sh + sync-to-drive.sh scripts"
echo "    • Drive sync hook from deploy-gridnode.sh"
echo ""
echo "  It does NOT touch any other Drive folder (Medical, Bitwarden, etc.)"
echo ""
printf "  Type 'yes nuke it' to confirm: "
read -r CONFIRM
echo ""

if [ "$CONFIRM" != "yes nuke it" ]; then
    err "Aborted. Nothing was removed."
    exit 1
fi

bold "  Removing..."
echo ""

# 1. Delete Drive folder
if command -v rclone >/dev/null 2>&1 && rclone listremotes 2>/dev/null | grep -q "^gdrive:$"; then
    if rclone lsd gdrive:GRIDNODE >/dev/null 2>&1; then
        warn "Deleting gdrive:GRIDNODE/ folder (and all contents)..."
        rclone purge gdrive:GRIDNODE 2>&1 | tail -2
        ok "Drive folder deleted"
    else
        warn "GRIDNODE/ folder not on Drive (already gone?)"
    fi
else
    warn "rclone not configured — skipping Drive deletion"
fi
echo ""

# 2. Remove rclone config
if [ -f ~/.config/rclone/rclone.conf ]; then
    warn "Removing rclone config..."
    rm -f ~/.config/rclone/rclone.conf
    ok "rclone config deleted"
else
    warn "rclone config not present"
fi
echo ""

# 3. Remove saved credential
if [ -f /workspace/.gridnode-secrets/.tokens/rclone.conf ]; then
    warn "Removing saved OAuth token..."
    rm -f /workspace/.gridnode-secrets/.tokens/rclone.conf
    ok "OAuth token deleted"
else
    warn "OAuth token not present"
fi
echo ""

# 4. Remove scripts (from handbook repo if present)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for f in setup-drive.sh sync-to-drive.sh; do
    if [ -f "$SCRIPT_DIR/$f" ]; then
        warn "Removing $f..."
        rm -f "$SCRIPT_DIR/$f"
        ok "$f deleted"
    fi
done
echo ""

# 5. Patch deploy-gridnode.sh (remove the Drive sync hook)
DEPLOY_SCRIPT="$SCRIPT_DIR/deploy-gridnode.sh"
if [ -f "$DEPLOY_SCRIPT" ] && grep -q "Drive backup sync" "$DEPLOY_SCRIPT"; then
    warn "Removing Drive sync hook from deploy-gridnode.sh..."
    DEPLOY_SCRIPT="$SCRIPT_DIR/deploy-gridnode.sh"
    awk '
        /^# Drive backup sync/ { in_block=1 }
        in_block && /Drive: backed up/ { in_block=0; next }
        !in_block { print }
    ' "$DEPLOY_SCRIPT" > "$DEPLOY_SCRIPT.tmp" && mv "$DEPLOY_SCRIPT.tmp" "$DEPLOY_SCRIPT"
    ok "deploy-gridnode.sh patched"
else
    warn "deploy-gridnode.sh hook not found"
fi

echo ""
bold "═══════════════════════════════════════════════════════════════"
bold "  ✓ NUCLEAR OPTION COMPLETE"
bold "═══════════════════════════════════════════════════════════════"
echo ""
echo "  Status:"
echo "    • Drive folder: deleted"
echo "    • OAuth token: deleted"
echo "    • Saved credential: deleted"
echo "    • Scripts: deleted"
echo "    • Deploy hook: removed"
echo ""
echo "  Re-enable any time by running:"
echo "    bash /workspace/.gridnode-handoff/scripts/setup-drive.sh"
echo "  (will pull from GitHub automatically)"
echo ""
echo "  Or to use a different Google account:"
echo "    1. Sign out of r3dp0is0n2012@gmail.com in any browser"
echo "    2. Re-run setup-drive.sh with new account email"
echo ""