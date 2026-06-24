#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# install-credentials.sh — Pipe's one-time credential setup
# ═══════════════════════════════════════════════════════════════════════════════
#
# When: First time in a fresh sandbox, OR after rotating a token.
# What: Saves Pipe's Cloudflare + GitHub tokens to a sandbox-local secure store.
# Why: Lets future Mavins in the same sandbox deploy without Pipe re-pasting.
#
# USAGE:
#   bash install-credentials.sh
#
# IDEMPOTENT: Re-running only prompts for tokens that are missing or invalid.
#
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# Constants
SECRETS_DIR="/workspace/.gridnode-secrets"
TOKENS_DIR="$SECRETS_DIR/.tokens"

# Color helpers
bold() { printf "\033[1m%s\033[0m\n" "$1"; }
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m⚠\033[0m %s\n" "$1"; }
err()  { printf "  \033[31m✗\033[0m %s\n" "$1"; }

# ═══════════════════════════════════════════════════════════════
# Welcome
# ═══════════════════════════════════════════════════════════════
echo ""
bold "═══════════════════════════════════════════════════════════════"
bold "  GRID//NODE Credential Setup"
bold "═══════════════════════════════════════════════════════════════"
echo ""
echo "This script saves your tokens to a sandbox-local secure store."
echo "Future Mavins in this sandbox will auto-load them. Tokens stay"
echo "in /workspace/.gridnode-secrets/ (mode 700, never in chat logs)."
echo ""

# ═══════════════════════════════════════════════════════════════
# Create secure store if missing
# ═══════════════════════════════════════════════════════════════
if [ ! -d "$SECRETS_DIR" ]; then
    mkdir -p "$TOKENS_DIR"
    chmod 700 "$SECRETS_DIR"
    chmod 700 "$TOKENS_DIR"
    ok "Created $SECRETS_DIR (mode 700)"
else
    ok "$SECRETS_DIR exists"
    # Fix permissions if loose
    if [ "$(stat -c '%a' "$SECRETS_DIR")" != "700" ]; then
        chmod 700 "$SECRETS_DIR"
        warn "Tightened permissions to 700"
    fi
    mkdir -p "$TOKENS_DIR"
    if [ "$(stat -c '%a' "$TOKENS_DIR")" != "700" ]; then
        chmod 700 "$TOKENS_DIR"
        warn "Tightened .tokens to 700"
    fi
fi

# ═══════════════════════════════════════════════════════════════
# Helper: prompt for a token, save it, verify it works
# ═══════════════════════════════════════════════════════════════
prompt_and_save() {
    local name="$1"           # e.g., "Cloudflare"
    local filename="$2"       # e.g., "cloudflare.txt"
    local verify_cmd="$3"     # e.g., "curl -sH 'Authorization: Bearer $TOKEN' https://api.cloudflare.com/client/v4/user/tokens/verify"
    local env_var="$4"        # e.g., "CLOUDFLARE_API_TOKEN"

    # Skip if already valid
    if [ -f "$TOKENS_DIR/$filename" ]; then
        local existing=$(cat "$TOKENS_DIR/$filename")
        if [ -n "$existing" ]; then
            # Try to verify the existing token
            local verify_output=$(eval "$verify_cmd" 2>/dev/null | head -1)
            if echo "$verify_output" | grep -q '"success":true'; then
                ok "$name: existing token is valid (skipping)"
                return 0
            else
                warn "$name: existing token failed verification — re-prompting"
            fi
        fi
    fi

    # Prompt for new token
    echo ""
    echo "  ── $name ──"
    echo "  Get your token from:"
    case "$name" in
        "Cloudflare") echo "     https://dash.cloudflare.com/profile/api-tokens" ;;
        "GitHub push") echo "     https://github.com/settings/tokens (scope: repo, workflow)" ;;
        "GitHub read-only") echo "     https://github.com/settings/tokens (scope: public_repo, read:org)" ;;
    esac
    echo ""
    printf "  Paste token (input hidden): "
    read -rs token
    echo ""

    # Validate non-empty
    if [ -z "$token" ]; then
        err "Empty token — skipping $name"
        return 1
    fi

    # Save with strict permissions
    echo "$token" > "$TOKENS_DIR/$filename"
    chmod 600 "$TOKENS_DIR/$filename"
    ok "$name saved to $TOKENS_DIR/$filename (mode 600)"

    # Verify if verify_cmd provided
    if [ -n "$verify_cmd" ]; then
        local verify_output=$(eval "$verify_cmd" 2>/dev/null)
        if echo "$verify_output" | grep -q '"success":true'; then
            ok "$name verified working"
        else
            warn "$name saved but verification FAILED. Check the token."
            echo "    API response: $verify_output" | head -1
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════
# Prompt for each token
# ═══════════════════════════════════════════════════════════════

# Cloudflare
prompt_and_save \
    "Cloudflare" \
    "cloudflare.txt" \
    "curl -sH 'Authorization: Bearer $(cat $TOKENS_DIR/cloudflare.txt 2>/dev/null)' https://api.cloudflare.com/client/v4/user/tokens/verify" \
    "CLOUDFLARE_API_TOKEN"

# GitHub push (with workflow)
prompt_and_save \
    "GitHub push" \
    "github_push.txt" \
    "curl -sH 'Authorization: token $(cat $TOKENS_DIR/github_push.txt 2>/dev/null)' https://api.github.com/user | head -1" \
    "GITHUB_GRIDNODE_TOKEN_PUSH_ONLY"

# GitHub read-only
prompt_and_save \
    "GitHub read-only" \
    "github_readonly.txt" \
    "curl -sH 'Authorization: token $(cat $TOKENS_DIR/github_readonly.txt 2>/dev/null)' https://api.github.com/user | head -1" \
    "GITHUB_GRIDNODE_TOKEN_READONLY"

# ═══════════════════════════════════════════════════════════════
# Write the loader script (overwrites if exists, but always correct)
# ═══════════════════════════════════════════════════════════════
cat > "$SECRETS_DIR/load-credentials.sh" << 'LOADER_EOF'
#!/bin/bash
# GRID//NODE credential loader
# Sources tokens from /workspace/.gridnode-secrets/.tokens/ as env vars.
#
# Usage: source /workspace/.gridnode-secrets/load-credentials.sh
# Or:    /workspace/.gridnode-secrets/load-credentials.sh (prints status)

SECRETS_DIR="/workspace/.gridnode-secrets"

if [ ! -d "$SECRETS_DIR/.tokens" ]; then
    echo "❌ Credential store not found at $SECRETS_DIR/.tokens"
    echo "   Run: bash install-credentials.sh"
    return 1 2>/dev/null || exit 1
fi

# Cloudflare
[ -f "$SECRETS_DIR/.tokens/cloudflare.txt" ] && \
    export CLOUDFLARE_API_TOKEN=$(cat "$SECRETS_DIR/.tokens/cloudflare.txt") && \
    export CF_API_TOKEN="$CLOUDFLARE_API_TOKEN"

# GitHub
[ -f "$SECRETS_DIR/.tokens/github_push.txt" ] && \
    export GITHUB_GRIDNODE_TOKEN=$(cat "$SECRETS_DIR/.tokens/github_push.txt") && \
    export GH_TOKEN="$GITHUB_GRIDNODE_TOKEN"
[ -f "$SECRETS_DIR/.tokens/github_readonly.txt" ] && \
    export GITHUB_GRIDNODE_TOKEN_READONLY=$(cat "$SECRETS_DIR/.tokens/github_readonly.txt")

# Verify load (without printing values)
loaded=0
[ -n "$CLOUDFLARE_API_TOKEN" ] && loaded=$((loaded+1))
[ -n "$GITHUB_GRIDNODE_TOKEN" ] && loaded=$((loaded+1))
[ -n "$GITHUB_GRIDNODE_TOKEN_READONLY" ] && loaded=$((loaded+1))

echo "✅ Loaded $loaded credential(s) from $SECRETS_DIR"
LOADER_EOF
chmod +x "$SECRETS_DIR/load-credentials.sh"
ok "Wrote $SECRETS_DIR/load-credentials.sh"

# ═══════════════════════════════════════════════════════════════
# Write CREDENTIALS.md (authority rules)
# ═══════════════════════════════════════════════════════════════
cat > "$SECRETS_DIR/CREDENTIALS.md" << 'CRED_EOF'
# GRID//NODE Credentials — OWNED BY PIPE

**Owner:** Pipe (GRID//NODE founder)
**Custodians:** Mavis / Mavin instances (with explicit Pipe permission)
**Location:** `/workspace/.gridnode-secrets/` (sandbox-local, mode 700)

---

## ⚠️ AUTHORITY RULES

These credentials belong to **Pipe**, not to any Mavis/Mavin instance.

**You may:**
- ✅ Use them for routine Mavin work (deploys, pushes, status checks)
- ✅ Read this file on session start

**You may NOT:**
- ❌ Share these credentials in chat logs or public files
- ❌ Use them for destructive operations without Pipe's approval
- ❌ Pass them to another session in plaintext
- ❌ Commit them to any repo

---

## Tokens

| Token | File | Used for |
|---|---|---|
| Cloudflare API | `.tokens/cloudflare.txt` | Deploy to `gridnode.network` |
| GitHub push | `.tokens/github_push.txt` | Push to repos, trigger workflows |
| GitHub read-only | `.tokens/github_readonly.txt` | Status checks |

---

## Token rotation

To rotate a token:
1. Get new token from the relevant provider
2. Run: `bash install-credentials.sh`
3. Existing token is verified; only invalid ones are re-prompted

---

**When in doubt:** Ask Pipe before using.
CRED_EOF
ok "Wrote $SECRETS_DIR/CREDENTIALS.md"

# ═══════════════════════════════════════════════════════════════
# Final test: load + verify
# ═══════════════════════════════════════════════════════════════
echo ""
source "$SECRETS_DIR/load-credentials.sh"

if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
    ok "Cloudflare: $(echo "$CLOUDFLARE_API_TOKEN" | cut -c1-8)..."
fi
if [ -n "$GITHUB_GRIDNODE_TOKEN" ]; then
    ok "GitHub push: $(echo "$GITHUB_GRIDNODE_TOKEN" | cut -c1-8)..."
fi
if [ -n "$GITHUB_GRIDNODE_TOKEN_READONLY" ]; then
    ok "GitHub read-only: $(echo "$GITHUB_GRIDNODE_TOKEN_READONLY" | cut -c1-8)..."
fi

echo ""
bold "═══════════════════════════════════════════════════════════════"
bold "  ✓ CREDENTIALS READY"
bold "═══════════════════════════════════════════════════════════════"
echo ""
echo "Future Mavins in this sandbox can deploy with:"
echo "  source /workspace/.gridnode-secrets/load-credentials.sh"
echo "  ./deploy-gridnode.sh 'msg' candidate.html"
echo ""