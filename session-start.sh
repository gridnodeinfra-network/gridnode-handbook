#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# session-start.sh — THE fix. One command. No troubleshooting.
# ═══════════════════════════════════════════════════════════════════════════════
#
# THE PROBLEM THIS FIXES:
#   Every new Mavin chat has to troubleshoot because:
#     1. The handbook repo at /workspace/.gridnode-handoff/ is stale (or missing)
#     2. The 5 mavin-* skills aren't installed (or are wrong version)
#     3. verify-gridnode-candidate CLI isn't on PATH
#     4. Local baseline SHA doesn't match live (drift)
#     5. The handoff docs are split across 6 files, hard to find
#
# THE FIX:
#   One bash command. Pulls latest. Syncs state. Installs everything. Verifies.
#   Idempotent — re-running is safe. Auto-recovers from any starting state.
#   Exits loud with one specific error if anything's truly broken.
#
# USAGE:
#   bash <(curl -s https://raw.githubusercontent.com/gridnodeinfra-network/gridnode-handbook/main/session-start.sh)
#
# Or if you have the file locally:
#   bash /path/to/session-start.sh
#
# WHAT IT DOES (5 steps, atomic):
#   1. Clone or pull the handbook repo (forces fresh if stale)
#   2. Sync local baseline to live (fixes drift)
#   3. Install 5 mavin-* skills (idempotent, fast)
#   4. Install verify-gridnode-candidate CLI
#   5. Verify everything and tell you what to read
#
# DESIGN PRINCIPLE:
#   The Mavin should never have to think about setup. This script does the
#   thinking. If it fails, ONE error message, ONE fix. No cascading troubleshooting.
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# CRITICAL: Move to a safe directory FIRST. If the user ran this from inside
# /workspace/.gridnode-handoff/ (or any other dir we might nuke), staying
# there would break the script. Going to /workspace is safe.
cd /workspace

# Prevent concurrent runs (would corrupt state)
LOCK_FILE="/tmp/gridnode-session-start.lock"
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
    echo "Another session-start.sh is already running (lock: $LOCK_FILE)"
    echo "If you're sure no other instance is running, delete the lock file:"
    echo "  rm $LOCK_FILE"
    exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────
HANDBOOK_REPO="https://github.com/gridnodeinfra-network/gridnode-handbook.git"
HANDOFF_DIR="/workspace/.gridnode-handoff"
SKILLS_DIR="/workspace/.skills"
LIVE_URL="https://gridnode.network"
LOCAL_BASELINE="/workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED/gridnode-v1.3_post-phase-D_baseline.html"

# Color helpers
bold() { printf "\033[1m%s\033[0m\n" "$1"; }
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m⚠\033[0m %s\n" "$1"; }
err()  { printf "  \033[31m✗\033[0m %s\n" "$1"; }
fail() { err "$1"; echo ""; echo "FIX: $2"; exit 1; }

# ─────────────────────────────────────────────────────────────────────────────
# Welcome
# ─────────────────────────────────────────────────────────────────────────────
echo ""
bold "═══════════════════════════════════════════════════════════════"
bold "  GRID//NODE SESSION START"
bold "═══════════════════════════════════════════════════════════════"
echo ""
echo "This script does the full setup. Should take <30 seconds."
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Step 1: Clone or pull handbook repo
# ─────────────────────────────────────────────────────────────────────────────
echo "[1/5] Setting up handbook repo at $HANDOFF_DIR..."

# If exists but is stale, broken, or diverged, nuke and re-clone. Don't try to be clever.
NEED_CLONE=false
if [ ! -d "$HANDOFF_DIR" ]; then
    NEED_CLONE=true
elif [ ! -d "$HANDOFF_DIR/.git" ]; then
    warn "Directory exists but is not a git repo — removing and re-cloning"
    rm -rf "$HANDOFF_DIR"
    NEED_CLONE=true
else
    # CRITICAL: Fetch FIRST so origin/main is current. Without this,
    # the local origin/main ref is stale and we can't detect divergence.
    cd "$HANDOFF_DIR"
    if ! git fetch origin 2>/dev/null; then
        warn "Cannot fetch from origin (network issue?)"
        warn "Will try to use existing local clone, but it may be stale"
    fi
    # Now check: local HEAD must match origin/main HEAD.
    # If local is behind (older commit), nuke + re-clone gets latest.
    # If local is ahead (has local-only commits), nuke + re-clone gets latest.
    # If local has diverged (mix of ahead + behind), nuke + re-clone gets latest.
    ORIGIN_MAIN=$(git rev-parse origin/main 2>/dev/null)
    LOCAL_HEAD=$(git rev-parse HEAD 2>/dev/null)
    if [ -n "$ORIGIN_MAIN" ] && [ "$LOCAL_HEAD" != "$ORIGIN_MAIN" ]; then
        warn "Local clone is at ${LOCAL_HEAD:0:8}... but origin/main is at ${ORIGIN_MAIN:0:8}..."
        warn "Removing local clone and re-cloning fresh"
        cd /
        rm -rf "$HANDOFF_DIR"
        NEED_CLONE=true
    elif ! git pull --ff-only 2>/dev/null; then
        warn "git pull failed — removing and re-cloning fresh"
        cd /
        rm -rf "$HANDOFF_DIR"
        NEED_CLONE=true
    else
        # Even if HEAD matches, verify key files exist. A corrupted clone
        # (e.g., files manually deleted) should trigger a re-clone.
        if [ ! -f "$HANDOFF_DIR/session-start.sh" ] || [ ! -d "$HANDOFF_DIR/skills" ]; then
            warn "Local clone is at ${LOCAL_HEAD:0:8}... but key files are missing"
            warn "Removing local clone and re-cloning fresh"
            cd /
            rm -rf "$HANDOFF_DIR"
            NEED_CLONE=true
        else
            ok "Handbook repo up to date (matches origin/main, key files present)"
        fi
    fi
fi

if [ "$NEED_CLONE" = true ]; then
    mkdir -p "$(dirname "$HANDOFF_DIR")"
    if git clone --depth 1 "$HANDBOOK_REPO" "$HANDOFF_DIR" 2>/dev/null; then
        ok "Handbook repo cloned"
    else
        fail "Cannot clone handbook repo" \
             "Check network. The repo must be accessible at $HANDBOOK_REPO"
    fi
fi

# Verify clone worked
if [ ! -f "$HANDOFF_DIR/bootstrap.sh" ]; then
    fail "Handbook repo missing bootstrap.sh" \
         "Clone may be incomplete. Try: rm -rf $HANDOFF_DIR && re-run this script"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 2: Sync local baseline to live (prevents drift)
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "[2/5] Syncing local baseline to live..."

mkdir -p "$(dirname "$LOCAL_BASELINE")"

# Download live
LIVE_CONTENT=$(curl -s --max-time 10 "$LIVE_URL" 2>/dev/null) || {
    warn "Cannot reach $LIVE_URL — skipping drift sync"
    LIVE_CONTENT=""
}

if [ -n "$LIVE_CONTENT" ]; then
    LIVE_SHA=$(echo "$LIVE_CONTENT" | sha256sum | cut -d' ' -f1)
    echo "  Live SHA: ${LIVE_SHA:0:16}..."

    if [ -f "$LOCAL_BASELINE" ] || [ -L "$LOCAL_BASELINE" ]; then
        LOCAL_SHA=$(sha256sum "$LOCAL_BASELINE" 2>/dev/null | cut -d' ' -f1)
        if [ "$LIVE_SHA" != "$LOCAL_SHA" ]; then
            warn "Drift detected — local=${LOCAL_SHA:0:16}... live=${LIVE_SHA:0:16}..."
            # Handle broken symlinks (don't try to backup, just remove)
            if [ -L "$LOCAL_BASELINE" ] && [ ! -e "$LOCAL_BASELINE" ]; then
                rm "$LOCAL_BASELINE"
            else
                # Backup local first
                cp "$LOCAL_BASELINE" "$LOCAL_BASELINE.drift-backup-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
                rm -f "$LOCAL_BASELINE"
            fi
            # Pull live down
            if echo "$LIVE_CONTENT" > "$LOCAL_BASELINE"; then
                ok "Local now matches live (old version backed up)"
            else
                fail "Failed to write live to local" \
                     "Check disk space and write permissions on $LOCAL_BASELINE"
            fi
        else
            ok "Local already matches live"
        fi
    else
        # No local baseline — write live
        if echo "$LIVE_CONTENT" > "$LOCAL_BASELINE"; then
            ok "Local baseline = live (new install)"
        else
            fail "Failed to write live to local" \
                 "Check disk space and write permissions on $LOCAL_BASELINE"
        fi
    fi
else
    warn "Skipped drift check (live URL unreachable)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 3: Install mavin-* skills
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "[3/5] Installing mavin-* skills..."

mkdir -p "$SKILLS_DIR"

MAVIN_SKILLS=(
    "mavin-build-candidate"
    "mavin-visual-render"
    "mavin-verify-deploy"
    "mavin-runtime-verify"
    "mavin-debug-failure"
)

INSTALLED=0
for skill in "${MAVIN_SKILLS[@]}"; do
    src="$HANDOFF_DIR/skills/$skill/SKILL.md"
    dest="$SKILLS_DIR/$skill/SKILL.md"
    if [ -f "$src" ]; then
        mkdir -p "$SKILLS_DIR/$skill"
        cp "$src" "$dest"
        # Also copy companion scripts
        if [ -d "$HANDOFF_DIR/skills/$skill" ]; then
            shopt -s nullglob
            for f in "$HANDOFF_DIR/skills/$skill"/*.sh "$HANDOFF_DIR/skills/$skill"/*.py; do
                if [ -f "$f" ]; then
                    fname=$(basename "$f")
                    cp "$f" "$SKILLS_DIR/$skill/$fname"
                    chmod +x "$SKILLS_DIR/$skill/$fname" 2>/dev/null || true
                fi
            done
            shopt -u nullglob
        fi
        INSTALLED=$((INSTALLED + 1))
    else
        warn "Missing in handbook repo: $skill"
    fi
done

TOTAL=$(ls "$SKILLS_DIR"/mavin-*/SKILL.md 2>/dev/null | wc -l)
if [ "$TOTAL" -eq 5 ]; then
    ok "All 5 mavin-* skills present"
else
    fail "Only $TOTAL/5 mavin-* skills installed" \
         "Check that $HANDOFF_DIR/skills/ has all 5 skill directories"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 4: Install verify-gridnode-candidate CLI
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "[4/5] Installing verify-gridnode-candidate CLI..."

VERIFY_SRC="$HANDOFF_DIR/skills/mavin-runtime-verify/verify-candidate.sh"
if [ -f "$VERIFY_SRC" ]; then
    if cp "$VERIFY_SRC" /usr/local/bin/verify-gridnode-candidate 2>/dev/null; then
        chmod +x /usr/local/bin/verify-gridnode-candidate
        ok "verify-gridnode-candidate installed to /usr/local/bin/"
    else
        # Try alternative install location: $HOME/.local/bin/
        ALT_DIR="$HOME/.local/bin"
        mkdir -p "$ALT_DIR"
        if cp "$VERIFY_SRC" "$ALT_DIR/verify-gridnode-candidate" 2>/dev/null; then
            chmod +x "$ALT_DIR/verify-gridnode-candidate"
            warn "Could not write to /usr/local/bin/. Installed to $ALT_DIR/ instead"
            warn "Add $ALT_DIR to your PATH: export PATH=\"$ALT_DIR:\$PATH\""
        else
            fail "Cannot install verify-gridnode-candidate" \
                 "Tried /usr/local/bin/ and $ALT_DIR/. Check disk space and permissions."
        fi
    fi
else
    fail "verify-candidate.sh not found in handbook repo" \
         "Check $HANDOFF_DIR/skills/mavin-runtime-verify/"
fi

if ! command -v verify-gridnode-candidate &> /dev/null; then
    fail "verify-gridnode-candidate not on PATH" \
         "Check that the install location is in your PATH"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 5: Verify + tell Mavin what to read
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "[5/5] Final verification..."

# Self-test: verify-gridnode-candidate runs without crashing
# (We don't audit the baseline itself — it has many duplicate function defs by design)
echo "  Testing verify-gridnode-candidate runs..."
TEST_FILE="/tmp/verify-test-$RANDOM.html"
cat > "$TEST_FILE" <<EOF
<!DOCTYPE html><html><body><script>
function clean() { return 1; }
function clean2() { return 2; }
</script></body></html>
EOF
if verify-gridnode-candidate "$TEST_FILE" >/dev/null 2>&1; then
    ok "verify-gridnode-candidate runs (use it on candidates before deploy)"
else
    warn "verify-gridnode-candidate returned non-zero (check installation)"
fi
rm -f "$TEST_FILE"

# Final state report
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  STATE"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  Live:         ${LIVE_SHA:0:16}..."
echo "  Local:        $(sha256sum "$LOCAL_BASELINE" 2>/dev/null | cut -d' ' -f1 | cut -c1-16)... (or N/A)"
echo "  Skills:       $(ls $SKILLS_DIR/mavin-*/SKILL.md 2>/dev/null | wc -l)/5 mavin-* installed"
echo "  Verify CLI:   $(command -v verify-gridnode-candidate 2>/dev/null || echo 'NOT ON PATH')"
echo "  Handbook:     $HANDOFF_DIR"
echo ""

# What to read next
echo "═══════════════════════════════════════════════════════════════"
echo "  READ FIRST"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  cat $HANDOFF_DIR/docs/MAVIN-START-HERE.md"
echo ""
echo "  That's it. One file. ~9KB. Tells you everything."
echo ""

bold "═══════════════════════════════════════════════════════════════"
bold "  ✓ READY"
bold "═══════════════════════════════════════════════════════════════"
echo ""
echo "To re-run this setup anytime: bash session-start.sh"
echo "To verify a candidate before deploy: verify-gridnode-candidate <file>"
echo ""