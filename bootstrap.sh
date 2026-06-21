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
echo "[5/7] Installing handoff loader skill..."
if [ -f "$HANDOFF_DIR/.skills/gridnode-handoff-loader/SKILL.md" ]; then
  cp "$HANDOFF_DIR/.skills/gridnode-handoff-loader/SKILL.md" \
     "$SKILLS_DIR/gridnode-handoff-loader/SKILL.md"
  ok "Installed: gridnode-handoff-loader"
else
  warn "handoff-loader skill not in handoff repo"
fi

# 6. Verify the install
echo ""
echo "[6/7] Verifying install..."
expected_skills=7
actual_skills=$(ls "$SKILLS_DIR"/{ponytail-*,gridnode-handoff-loader}/SKILL.md 2>/dev/null | wc -l)
if [ "$actual_skills" -eq "$expected_skills" ]; then
  ok "All $expected_skills skills installed (6 Ponytail + 1 handoff loader)"
else
  warn "Only $actual_skills of $expected_skills skills present"
fi

# 7. Run a smoke test
echo ""
echo "[7/7] Smoke test..."
if [ -x "$HANDOFF_DIR/scripts/keyword-extractor.js" ] && [ -n "$BASELINE_PATH" ] && [ -f "$BASELINE_PATH" ]; then
  # Run the keyword extractor and capture the count
  output=$(node "$HANDOFF_DIR/scripts/keyword-extractor.js" "$BASELINE_PATH" 2>&1)
  count=$(echo "$output" | grep -oE 'COUNT = [0-9]+' | grep -oE '[0-9]+')
  if [ -n "$count" ]; then
    ok "Keyword extractor: $count protected keywords (script output, not hand-typed)"
  else
    warn "Keyword extractor ran but no count found in output"
  fi
else
  echo "       (skipped — no baseline or no extractor)"
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
echo "Live URL:    https://gridnode.pages.dev"
echo "TinyURL:     https://tinyurl.com/25h4qg7x"
echo ""
echo "Default mode:  Ponytail full (lazy senior dev, smallest runnable check required)"
echo "Switch:        /ponytail lite|full|ultra"
echo "Disable:       stop ponytail / normal mode"
