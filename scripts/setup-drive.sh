#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# setup-drive.sh — One-time Google Drive setup for GRID//NODE backups
# ═══════════════════════════════════════════════════════════════════════════════
#
# USAGE:
#   bash setup-drive.sh          # Standard setup (if browser available locally)
#   bash setup-drive.sh url      # Print the OAuth URL only (then user pastes code)
#
# ═══════════════════════════════════════════════════════════════════════════════

set -e

bold() { printf "\033[1m%s\033[0m\n" "$1"; }
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m⚠\033[0m %s\n" "$1"; }
err()  { printf "  \033[31m✗\033[0m %s\n" "$1"; }

bold "═══════════════════════════════════════════════════════════════"
bold "  GRID//NODE → Google Drive setup"
bold "═══════════════════════════════════════════════════════════════"

# Check rclone
if ! command -v rclone >/dev/null 2>&1; then
    err "rclone not installed. Run:"
    echo "    curl https://rclone.org/install.sh | bash"
    exit 1
fi
ok "rclone $(rclone version | head -1 | awk '{print $2}')"

REMOTE_NAME="${GRIDNODE_DRIVE_NAME:-gdrive}"

# Check if already configured and working
if rclone listremotes 2>/dev/null | grep -q "^${REMOTE_NAME}:$"; then
    if rclone lsd "$REMOTE_NAME:" --max-depth 1 >/dev/null 2>&1; then
        ok "Remote '$REMOTE_NAME' already configured and working"
        exit 0
    else
        warn "Remote exists but not working. Removing..."
        rclone config delete "$REMOTE_NAME" 2>/dev/null || true
    fi
fi

echo ""
echo "  Account: r3dp0is0n2012@gmail.com"
echo "  Remote:  $REMOTE_NAME"
echo ""

# If "url" arg, just print the auth URL and exit
if [ "${1:-}" = "url" ]; then
    bold "  STEP 1: Open this URL in your browser:"
    echo ""
    # rclone authorize prints the URL when run
    timeout 30 rclone authorize drive --auth-no-open-browser 2>&1 | head -20 &
    RCLONE_PID=$!
    sleep 5
    kill -9 $RCLONE_PID 2>/dev/null
    wait 2>/dev/null
    exit 0
fi

bold "═══════════════════════════════════════════════════════════════"
bold "  To complete setup, you have 2 options:"
bold "═══════════════════════════════════════════════════════════════"
echo ""
echo "  OPTION A (RECOMMENDED): Run on YOUR LOCAL machine"
echo "  ────────────────────────────────────────────────"
echo "  1. SSH or open a terminal on your Mac/PC"
echo "  2. Install rclone:  curl https://rclone.org/install.sh | bash"
echo "  3. Run:  rclone config create gdrive drive scope=drive"
echo "  4. Browser opens, sign in to r3dp0is0n2012@gmail.com"
echo "  5. Allow access, then quit config (q)"
echo "  6. Copy the config to the sandbox:"
echo "       scp ~/.config/rclone/rclone.conf mavin@sandbox:~/.config/rclone/"
echo ""
echo "  OPTION B (Manual in sandbox):"
echo "  ────────────────────────────────────────────────"
echo "  1. Run: bash setup-drive.sh url"
echo "  2. Copy the printed URL to your browser"
echo "  3. Sign in and allow access"
echo "  4. Copy the verify code from your browser"
echo "  5. Edit ~/.config/rclone/rclone.conf and add:"
echo "       token = \"{\\\"access_token\\\":\\\"YOUR_CODE\\\"}\""
echo ""

# Try to run authorize in background and capture URL
echo "  Attempting to get OAuth URL..."
echo ""
( timeout 5 rclone authorize drive --auth-no-open-browser 2>&1 | head -10 ) &
sleep 4
pkill -9 rclone 2>/dev/null
echo ""
echo "  If you saw a URL above, open it. Otherwise use OPTION A."
