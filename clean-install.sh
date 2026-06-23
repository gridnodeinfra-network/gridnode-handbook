#!/bin/bash
# GRID//NODE Mavis sandbox cleaner
# Removes all Mavin/Mavis tools and starts from scratch
#
# Usage: bash clean-install.sh [--dry-run] [--keep-baseline]
#
# What it does:
#   1. Removes /workspace/.skills/* (Mavis skills)
#   2. Removes /workspace/.gridnode-handoff/ (cloned handbook repo)
#   3. Removes /workspace/.gridnode-secrets/ (sandbox-local credentials)
#   4. Removes /workspace/builder-skill/ (builder skill clone)
#   5. Removes /workspace/builder-push/ (builder skill clone for pushes)
#   6. Removes /workspace/handbook-fix/ (handbook repo clone for fixes)
#   7. Optionally removes /workspace/gridnode-project/ (DESTRUCTIVE — see flags)
#   8. Optionally purges apt-installed tools (DESTRUCTIVE — see flags)
#   9. Optionally purges npm globals (DESTRUCTIVE — see flags)
#   10. Resets /root/.cache/ms-playwright/ (Playwright chromium cache)
#
# After this, the sandbox is "fresh" — only the OS, no Mavin state.

set -e

bold() { printf "\033[1m%s\033[0m\n" "$1"; }
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m⚠\033[0m %s\n" "$1"; }
err()  { printf "  \033[31m✗\033[0m %s\n" "$1"; }

DRY_RUN=false
KEEP_BASELINE=false
PURGE_TOOLS=false
PURGE_NPM=false

# Parse args
for arg in "$@"; do
  case $arg in
    --dry-run) DRY_RUN=true ;;
    --keep-baseline) KEEP_BASELINE=true ;;
    --purge-tools) PURGE_TOOLS=true ;;
    --purge-npm) PURGE_NPM=true ;;
    *) warn "Unknown arg: $arg" ;;
  esac
done

if [ "$DRY_RUN" = true ]; then
  bold "==> DRY RUN — nothing will be deleted. Just listing."
else
  bold "==> GRID//NODE sandbox cleaner"
fi
echo ""

# Step 1: Mavis skills
echo "Step 1: Mavis skills"
if [ -d /workspace/.skills ]; then
  for skill in /workspace/.skills/*; do
    if [ -d "$skill" ]; then
      skill_name=$(basename "$skill")
      if [ "$DRY_RUN" = true ]; then
        echo "  [DRY] Would remove: /workspace/.skills/$skill_name"
      else
        rm -rf "$skill"
        ok "Removed: /workspace/.skills/$skill_name"
      fi
    fi
  done
else
  warn "/workspace/.skills/ not present"
fi
echo ""

# Step 2: Handoff dir
echo "Step 2: Handbook repo (cloned)"
for dir in /workspace/.gridnode-handoff /workspace/handbook-fix; do
  if [ -d "$dir" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "  [DRY] Would remove: $dir"
    else
      rm -rf "$dir"
      ok "Removed: $dir"
    fi
  fi
done
echo ""

# Step 3: Credential store
echo "Step 3: Credential store (sandbox-local tokens)"
if [ -d /workspace/.gridnode-secrets ]; then
  if [ "$DRY_RUN" = true ]; then
    echo "  [DRY] Would remove: /workspace/.gridnode-secrets/ (4 token files)"
  else
    rm -rf /workspace/.gridnode-secrets
    ok "Removed: /workspace/.gridnode-secrets/ (tokens will need to be re-bootstrapped)"
  fi
fi
echo ""

# Step 4-6: Various clones
echo "Step 4-6: Various Mavis working directories"
for dir in /workspace/builder-skill /workspace/builder-push /workspace/deliverables; do
  if [ -d "$dir" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "  [DRY] Would remove: $dir"
    else
      rm -rf "$dir"
      ok "Removed: $dir"
    fi
  fi
done
echo ""

# Step 7: Gridnode project (DESTRUCTIVE)
echo "Step 7: /workspace/gridnode-project/ (locked baseline + dated backups + candidates)"
if [ "$KEEP_BASELINE" = true ]; then
  warn "KEEP_BASELINE=true — preserving locked baseline"
  if [ "$DRY_RUN" = true ]; then
    echo "  [DRY] Would remove everything EXCEPT 01_SOURCE_TRUTH_LOCKED/"
  else
    find /workspace/gridnode-project -mindepth 1 -maxdepth 1 \
      ! -name "01_SOURCE_TRUTH_LOCKED" -exec rm -rf {} \;
    ok "Removed work dirs, preserved 01_SOURCE_TRUTH_LOCKED/"
  fi
else
  warn "DESTRUCTIVE — will remove the entire gridnode-project directory"
  warn "  including: 01_SOURCE_TRUTH_LOCKED/, candidates, dated backups, deploy scripts"
  warn "  You can re-clone from: https://github.com/gridnodeinfra-network/gridnode-terminal"
  if [ "$DRY_RUN" = true ]; then
    echo "  [DRY] Would remove: /workspace/gridnode-project/"
  else
    rm -rf /workspace/gridnode-project
    ok "Removed: /workspace/gridnode-project/"
  fi
fi
echo ""

# Step 8: Purge apt-installed tools (DESTRUCTIVE)
echo "Step 8: Purge apt-installed Mavin tools"
if [ "$PURGE_TOOLS" = true ]; then
  warn "DESTRUCTIVE — will uninstall ffmpeg, tesseract, shellcheck, ripgrep, etc."
  if [ "$DRY_RUN" = true ]; then
    echo "  [DRY] Would apt-get purge: ffmpeg, tesseract-ocr, shellcheck, ripgrep, fzf, silversearcher-ag, imagemagick, chromium-deps"
  else
    apt-get purge -y ffmpeg tesseract-ocr shellcheck ripgrep fzf silversearcher-ag imagemagick 2>/dev/null || true
    apt-get autoremove -y 2>/dev/null || true
    ok "Purged apt tools"
  fi
else
  warn "PURGE_TOOLS not set — keeping apt tools"
  echo "       To purge: add --purge-tools flag"
fi
echo ""

# Step 9: Purge npm globals (DESTRUCTIVE)
echo "Step 9: Purge npm globals (wrangler, svgo, etc.)"
if [ "$PURGE_NPM" = true ]; then
  warn "DESTRUCTIVE — will uninstall npm globals"
  if [ "$DRY_RUN" = true ]; then
    echo "  [DRY] Would npm uninstall -g: wrangler, svgo, playwright, pixelmatch, vitest, zod"
  else
    npm uninstall -g wrangler svgo 2>/dev/null || true
    # playwright, vitest, zod, pixelmatch are typically used via npx, no global needed
    ok "Purged npm globals"
  fi
else
  warn "PURGE_NPM not set — keeping npm globals"
fi
echo ""

# Step 10: Playwright cache
echo "Step 10: Playwright chromium cache"
if [ -d /root/.cache/ms-playwright ]; then
  if [ "$DRY_RUN" = true ]; then
    echo "  [DRY] Would remove: /root/.cache/ms-playwright/"
  else
    rm -rf /root/.cache/ms-playwright
    ok "Removed: /root/.cache/ms-playwright/ (will re-download on first use)"
  fi
fi
echo ""

# Final summary
bold "==> Cleanup complete"
echo ""
echo "Remaining /workspace/ contents:"
ls -la /workspace/ 2>/dev/null | grep -v "^total" | head -20
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "This was a DRY RUN. To actually delete, run without --dry-run."
else
  echo "Sandbox is now fresh. To restore Mavin state, run:"
  echo "  bash bootstrap.sh"
  echo ""
  echo "Or to re-clone + bootstrap from scratch:"
  echo "  curl -s https://raw.githubusercontent.com/gridnodeinfra-network/gridnode-handbook/main/bootstrap.sh | bash -s -- /path/to/baseline.html"
fi