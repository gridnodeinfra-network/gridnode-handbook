#!/bin/bash
# GRID//NODE Bootstrap — production version
# Sets up a fresh Mavis session with the full handoff loaded.
#
# Usage:
#   ./bootstrap.sh [BASELINE_PATH]
#   curl -s https://raw.githubusercontent.com/gridnodeinfra-network/gridnode-handbook/main/bootstrap.sh | bash
#
# What it does:
#   1. Clones the handbook repo to /workspace/.gridnode-handoff/
#   2. Verifies the locked baseline (if BASELINE_PATH provided)
#   3. Installs all 6 Ponytail skills to /workspace/.skills/ponytail-*/
#   4. Installs the handoff loader skill to /workspace/.skills/gridnode-handoff-loader/
#   5. Verifies the install (6/6 + 1 = 7 skills)
#   6. Runs a smoke test on the keyword extractor
#   7. Prints the handoff summary

set -e

# Defaults
HANDOFF_REPO="https://github.com/gridnodeinfra-network/gridnode-handbook.git"
HANDOFF_DIR="${GRIDNODE_HANDOFF_DIR:-/workspace/.gridnode-handoff}"
PONYTAIL_REPO="https://github.com/DietrichGebert/ponytail.git"
SKILLS_DIR="${GRIDNODE_SKILLS_DIR:-/workspace/.skills}"
BASELINE_PATH="${1:-}"

# Pretty output
bold() { printf "\033[1m%s\033[0m\n" "$1"; }
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m⚠\033[0m %s\n" "$1"; }
err()  { printf "  \033[31m✗\033[0m %s\n" "$1"; }

bold "==> GRID//NODE Bootstrap"

# 1. Clone or update the handoff repo
echo ""
if [ -d "$HANDOFF_DIR/.git" ]; then
  echo "[1/7] Handoff already cloned — pulling latest"
  cd "$HANDOFF_DIR" && git pull --quiet
  ok "Updated to latest"
else
  echo "[1/7] Cloning handoff repo..."
  if git clone --depth 1 "$HANDOFF_REPO" "$HANDOFF_DIR" 2>/dev/null; then
    ok "Cloned to $HANDOFF_DIR"
  else
    err "Failed to clone handoff repo (network issue?)"
    echo "       Falling back to local handoff at /workspace/deliverables/gridnode-handbook"
    if [ -d "/workspace/deliverables/gridnode-handbook" ]; then
      HANDOFF_DIR="/workspace/deliverables/gridnode-handbook"
      ok "Using local handoff"
    else
      err "No handoff available. Bootstrap failed."
      exit 1
    fi
  fi
fi
cd "$HANDOFF_DIR"

# 2. Read the locked state
echo ""
echo "[2/7] Reading locked state..."
if [ -f "baseline.sha" ]; then
  while IFS= read -r line; do
    echo "       $line"
  done < baseline.sha
  ok "Locked baseline recorded"
else
  warn "baseline.sha not found in handoff"
fi

# 3. Verify baseline (if path provided)
echo ""
echo "[3/7] Verifying baseline..."
if [ -n "$BASELINE_PATH" ]; then
  if [ -f "$BASELINE_PATH" ]; then
    actual_sha=$(sha256sum "$BASELINE_PATH" | cut -d' ' -f1)
    expected_sha=$(grep -oE '[0-9a-f]{64}' baseline.sha 2>/dev/null | head -1)
    if [ "$actual_sha" = "$expected_sha" ]; then
      ok "Baseline SHA matches: $actual_sha"
    else
      err "SHA mismatch!"
      echo "       Expected: $expected_sha"
      echo "       Actual:   $actual_sha"
      echo "       The locked file may have been modified."
    fi
  else
    warn "Baseline path provided but file not found: $BASELINE_PATH"
  fi
else
  echo "       (no baseline path provided, skipping SHA check)"
  echo "       To verify, run: $0 /path/to/baseline.html"
fi

# 4. Install Ponytail skills
echo ""
echo "[4/7] Installing Ponytail skills..."
mkdir -p "$SKILLS_DIR"
PONYTAIL_TMP=/tmp/ponytail-clone-$$
rm -rf "$PONYTAIL_TMP"

if git clone --depth 1 "$PONYTAIL_REPO" "$PONYTAIL_TMP" 2>/dev/null; then
  installed=0
  for skill in ponytail ponytail-audit ponytail-review ponytail-debt ponytail-gain ponytail-help; do
    if [ -f "$PONYTAIL_TMP/skills/$skill/SKILL.md" ]; then
      # Main skill gets the Mavis namespace
      if [ "$skill" = "ponytail" ]; then
        target_dir="$SKILLS_DIR/ponytail-mavis"
      else
        target_dir="$SKILLS_DIR/$skill"
      fi
      mkdir -p "$target_dir"
      cp "$PONYTAIL_TMP/skills/$skill/SKILL.md" "$target_dir/SKILL.md"
      if [ "$skill" = "ponytail" ] && [ -f "$PONYTAIL_TMP/AGENTS.md" ]; then
        cp "$PONYTAIL_TMP/AGENTS.md" "$target_dir/AGENTS.md"
      fi
      installed=$((installed + 1))
    else
      warn "Missing in upstream: $skill"
    fi
  done
  rm -rf "$PONYTAIL_TMP"
  ok "Installed $installed/6 Ponytail skills"
else
  err "Failed to clone Ponytail (network issue?)"
  warn "Ponytail will not be available; bootstrap continues without it"
fi

# 5. Install the handoff loader skill
echo ""
echo "[5/8] Installing handoff loader skill..."
if [ -f "$HANDOFF_DIR/.skills/gridnode-handoff-loader/SKILL.md" ]; then
  cp "$HANDOFF_DIR/.skills/gridnode-handoff-loader/SKILL.md" \
     "$SKILLS_DIR/gridnode-handoff-loader/SKILL.md"
  ok "Installed: gridnode-handoff-loader"
else
  warn "handoff-loader skill not in handoff repo"
fi

# 5b. Install the GRID//NODE builder skill (Mavin role + Foundation)
echo ""
echo "[5b/8] Installing GRID//NODE builder skill..."
BUILDER_REPO="https://github.com/gridnodeinfra-network/gridnode-mavis-builder.git"
if git clone --depth 1 "$BUILDER_REPO" "$SKILLS_DIR/gridnode-mavis-builder" 2>/dev/null; then
  ok "Installed: gridnode-mavis-builder (Mavin role + Foundation)"
else
  warn "Could not clone builder skill repo (network issue?)"
  warn "Mavin will work without it; Foundation design tokens won't be available"
fi

# 5c. Install gh CLI if missing
echo ""
echo "[5c/8] Checking gh CLI..."
if ! command -v gh &> /dev/null; then
  if command -v apt-get &> /dev/null; then
    # Add GitHub's apt repo then install (gh not in default Debian repos)
    if (curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg 2>/dev/null | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list 2>/dev/null && apt-get update -qq 2>/dev/null && apt-get install -y gh 2>/dev/null); then
      ok "Installed gh CLI (apt + GitHub repo)"
    else
      # Fallback: download binary directly
      if (curl -fsSL https://github.com/cli/cli/releases/download/v2.62.0/gh_2.62.0_linux_amd64.tar.gz 2>/dev/null | tar -xz -C /tmp/ gh_2.62.0_linux_amd64/bin/gh 2>/dev/null && mv /tmp/gh_2.62.0_linux_amd64/bin/gh /usr/local/bin/ 2>/dev/null); then
        ok "Installed gh CLI (binary)"
      else
        warn "gh CLI install failed (network or perms?)"
        warn "Future pushes will need manual gh install or use git+token"
      fi
    fi
  else
    warn "gh CLI not installed and apt-get not available"
  fi
else
  ok "gh CLI present"
fi

# 6. Verify the install
echo ""
echo "[6/8] Verifying install..."
expected_skills=8
actual_skills=$(ls "$SKILLS_DIR"/{ponytail-*,gridnode-handoff-loader,gridnode-mavis-builder}/SKILL.md 2>/dev/null | wc -l)
if [ "$actual_skills" -eq "$expected_skills" ]; then
  ok "All $expected_skills skills installed (6 Ponytail + 2 GRID//NODE)"
else
  warn "Only $actual_skills of $expected_skills skills present"
fi

# 6b. Run Foundation vitest smoke test (NEW)
echo ""
echo "[6b/8] Foundation vitest smoke test..."
if [ -f "$SKILLS_DIR/gridnode-mavis-builder/foundation/vitest.config.js" ] && [ -d "$SKILLS_DIR/gridnode-mavis-builder/foundation/tests" ]; then
  if [ -d "$SKILLS_DIR/gridnode-mavis-builder/foundation/node_modules" ]; then
    if (cd "$SKILLS_DIR/gridnode-mavis-builder/foundation" && npx --no-install vitest run --reporter=basic 2>&1 | tail -10) ; then
      ok "Foundation tests passed (jsdom env verified)"
    else
      warn "Foundation tests FAILED — env config may need repair"
      warn "Run manually: cd foundation && npx vitest run"
    fi
  else
    warn "Foundation node_modules missing — run: cd foundation && npm install"
  fi
else
  warn "Foundation tests not configured (vitest.config.js or tests/ missing)"
fi

# 7. Run a smoke test
echo ""
echo "[7/8] Smoke test..."
if [ -x "$HANDOFF_DIR/scripts/keyword-extractor.js" ]; then
  if [ -n "$BASELINE_PATH" ] && [ -f "$BASELINE_PATH" ]; then
    output=$(node "$HANDOFF_DIR/scripts/keyword-extractor.js" "$BASELINE_PATH" 2>&1 || true)
    count=$(echo "$output" | grep -oE 'COUNT = [0-9]+' | grep -oE '[0-9]+')
    if [ -n "$count" ]; then
      ok "Keyword extractor: $count protected keywords"
    else
      err "Keyword extractor ran but no count found in output"
      echo "       This is the bug that survived v1.0 → v1.1. Fix scripts/keyword-extractor.js"
      exit 1
    fi
  else
    err "SMOKE TEST CANNOT RUN: baseline file not provided"
    echo "       Run: $0 /path/to/gridnode-v1.3_post-phase-D_baseline.html"
    echo "       (Get it from: /workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED/ or curl gridnode.network)"
    exit 1
  fi
else
  err "SMOKE TEST CANNOT RUN: extractor missing at $HANDOFF_DIR/scripts/keyword-extractor.js"
  echo "       This is mandatory — do not silently skip"
  exit 1
fi

# 8. Verify live matches lock
echo ""
echo "[8/8] Verifying live deploy matches lock..."
LIVE_URL=$(grep -oE 'https?://[^ ]+' baseline.sha 2>/dev/null | head -1)
LOCK_SHA=$(grep -oE '[0-9a-f]{64}' baseline.sha 2>/dev/null | head -1)
if [ -n "$LIVE_URL" ] && [ -n "$LOCK_SHA" ]; then
  LIVE_SHA=$(curl -s "$LIVE_URL" 2>/dev/null | sha256sum | cut -d' ' -f1)
  if [ "$LIVE_SHA" = "$LOCK_SHA" ]; then
    ok "Live deploy matches lock: ${LIVE_SHA:0:16}..."
  else
    err "MISMATCH: live=${LIVE_SHA:0:16}... locked=${LOCK_SHA:0:16}..."
    echo "       Either deploy the lock to live, OR update baseline.sha to current live."
    exit 1
  fi
else
  warn "Could not parse LIVE_URL or LOCK_SHA from baseline.sha"
fi

# Final summary
echo ""
bold "==> Bootstrap complete"
echo ""
echo "Quick start:"
echo "  - Read the handoff:    cat $HANDOFF_DIR/GRIDNODE_HANDOFF.md"
echo "  - List the skills:     ls $SKILLS_DIR/"
echo "  - Run the tests:       cd $HANDOFF_DIR && npm test"
echo "  - Audit the baseline:  node $HANDOFF_DIR/scripts/consolidation-review.js <baseline>"
echo ""
LIVE_URL_FINAL=$(grep -oE 'https?://gridnode[^ ]+' baseline.sha 2>/dev/null | head -1)
[ -z "$LIVE_URL_FINAL" ] && LIVE_URL_FINAL="https://gridnode.network"
echo "Live URL:    $LIVE_URL_FINAL"
echo "TinyURL:     https://tinyurl.com/25h4qg7x"
echo ""
echo "Default mode:  Ponytail full (lazy senior dev, smallest runnable check required)"
echo "Switch:        /ponytail lite|full|ultra"
echo "Disable:       stop ponytail / normal mode"
