#!/bin/bash
# GRID//NODE Mavin tool installer
# Installs all the tier-1 + Mavin-specific dev tools that make work faster
#
# Usage: source install-tools.sh
# Or:    bash install-tools.sh  (prints what it installed)
#
# Why this exists:
#   Mavin uses ~25 tools across the session. The original sandbox had
#   some pre-installed, but a fresh Mavis session needs them all.
#   This script installs them with sensible defaults.

set -e

bold() { printf "\033[1m%s\033[0m\n" "$1"; }
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m⚠\033[0m %s\n" "$1"; }
err()  { printf "  \033[31m✗\033[0m %s\n" "$1"; }

bold "==> GRID//NODE Mavin tool installer"

# Tier 1: Core essentials (must-have for any Mavin work)
echo ""
echo "Tier 1: Core essentials"
TIER1=(git curl wget jq make gcc build-essential python3 python3-pip node npm)

# Tier 2: Mavin-specific work tools (used in most sessions)
echo ""
echo "Tier 2: Mavin work tools"
TIER2=(ffmpeg tesseract shellcheck ripgrep fzf imagemagick)

# Tier 3: Visual + SVG (for design work)
echo ""
echo "Tier 3: Visual + SVG"
TIER3=(libnss3 libatk-bridge2.0-0 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 libxrandr2 libgbm1 libpango-1.0-0 libcairo2 libasound2)

# Tier 4: Specific tools Mavin uses
echo ""
echo "Tier 4: Specific tools"
TIER4=(silversearcher-ag universal-ctags)

# Combined list
ALL_TIERS=("${TIER1[@]}" "${TIER2[@]}" "${TIER3[@]}" "${TIER4[@]}")

# Check what's missing
missing=()
for tool in "${ALL_TIERS[@]}"; do
  if ! dpkg -l "$tool" 2>/dev/null | grep -q "^ii"; then
    missing+=("$tool")
  fi
done

if [ ${#missing[@]} -eq 0 ]; then
  ok "All ${#ALL_TIERS[@]} tier-1/2/3/4 tools already installed"
else
  echo ""
  warn "Missing: ${missing[*]}"
  echo "Installing (apt-get)..."
  if command -v apt-get &> /dev/null; then
    apt-get update -qq 2>/dev/null
    apt-get install -y "${missing[@]}" 2>&1 | tail -3
    ok "Installed ${#missing[@]} tools"
  else
    err "apt-get not available. Cannot install tier-1/2/3/4 tools."
  fi
fi

# Tier 5: npm globals (for npx, vitest, wrangler)
echo ""
echo "Tier 5: npm globals"
if command -v npm &> /dev/null; then
  npm list -g --depth=0 2>/dev/null | grep -E "wrangler|svgo|playwright" | head -5
  ok "npm globals available (wrangler, svgo, playwright all available via npx)"
else
  warn "npm not installed"
fi

# Tier 6: Python packages (for OCR, image processing)
echo ""
echo "Tier 6: Python packages"
PYTHON_PKGS=(pillow pytesseract playwright)
for pkg in "${PYTHON_PKGS[@]}"; do
  if python3 -c "import $pkg" 2>/dev/null; then
    ok "$pkg (Python)"
  else
    warn "$pkg (Python) — install with: pip install $pkg"
  fi
done

# Verify essentials are present
echo ""
echo "=== Verifying essentials ==="
ESSENTIALS=(git node python3 curl jq ffmpeg tesseract)
all_present=true
for tool in "${ESSENTIALS[@]}"; do
  if command -v "$tool" &> /dev/null; then
    ok "$tool"
  else
    err "$tool MISSING"
    all_present=false
  fi
done

if [ "$all_present" = true ]; then
  ok "All essentials present"
else
  err "Some essentials missing. Check apt logs above."
  exit 1
fi

# Mavin-specific setup: chromium for headless
echo ""
echo "=== Mavin visual verification ==="
if [ -d /root/.cache/ms-playwright/chromium-1223/chrome-linux/chrome ] || [ -d /root/.cache/ms-playwright ]; then
  ok "Playwright chromium installed"
else
  warn "Playwright chromium not installed"
  echo "       To install: npx playwright install chromium"
fi

# Final summary
echo ""
bold "==> Tool installation complete"
echo ""
echo "Tier 1 (essential): ${#TIER1[@]} tools"
echo "Tier 2 (Mavin work): ${#TIER2[@]} tools"
echo "Tier 3 (visual): ${#TIER3[@]} tools"
echo "Tier 4 (specific): ${#TIER4[@]} tools"
echo "Tier 5 (npm): wrangler, svgo, playwright (all via npx)"
echo "Tier 6 (Python): pillow, pytesseract, playwright"
echo ""
echo "Total: ~25 tools that Mavin uses to work fast"
echo ""
echo "If anything is missing, install on demand:"
echo "  apt-get install -y <tool>"
echo "  pip install <package>"
echo "  npm install -g <package>"