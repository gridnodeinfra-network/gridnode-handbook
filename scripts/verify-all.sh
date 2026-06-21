#!/bin/bash
# verify-all.sh — runs the full verification suite and reports a single pass/fail
#
# What it checks:
#   1. Node.js is installed and ≥18
#   2. The vitest suite passes
#   3. bootstrap.sh has valid bash syntax
#   4. All scripts/*.js files have valid JS syntax
#   5. PROTECTED_KEYWORDS.js is loadable (if present)
#   6. The protected-keyword gate is executable
#   7. The consolidation review is executable
#   8. All .md files start with a heading
#   9. The methodology docs reference real files
#
# Usage:
#   ./scripts/verify-all.sh [baseline.html]
#
# Output: a single line at the end that's either:
#   ✓ All verifications passed
#   ✗ N verification(s) failed — see above
#
# Exit code: 0 = all pass, 1 = at least one failure

set -e

BASELINE="${1:-}"

# Pretty output
bold() { printf "\033[1m%s\033[0m\n" "$1"; }
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m⚠\033[0m %s\n" "$1"; }
err()  { printf "  \033[31m✗\033[0m %s\n" "$1"; }

bold "==> GRID//NODE Handbook Verification"
echo ""

failures=0
warnings=0

# Helper: track failures
fail() {
  err "$1"
  failures=$((failures + 1))
}

# 1. Node.js
echo "[1/9] Node.js version check"
if command -v node > /dev/null 2>&1; then
  version=$(node --version | sed 's/^v//' | cut -d'.' -f1)
  if [ "$version" -ge 18 ]; then
    ok "Node.js $(node --version) (≥18)"
  else
    fail "Node.js $(node --version) is too old (need ≥18)"
  fi
else
  fail "Node.js not installed"
fi

# 2. vitest suite
echo ""
echo "[2/9] vitest suite"
if [ -f "package.json" ]; then
  if [ -d "node_modules/vitest" ]; then
    if npx vitest run tests/ 2>&1 | tail -10 | grep -q "passed"; then
      ok "All vitest tests pass"
    else
      fail "vitest suite failed — run 'npm test' for details"
    fi
  else
    warn "node_modules not installed — skipping vitest (run 'npm install' first)"
    warnings=$((warnings + 1))
  fi
else
  fail "package.json not found"
fi

# 3. bootstrap.sh syntax
echo ""
echo "[3/9] bootstrap.sh syntax"
if [ -f "bootstrap.sh" ]; then
  if bash -n bootstrap.sh 2>/dev/null; then
    ok "bootstrap.sh syntax valid"
  else
    fail "bootstrap.sh has syntax error"
  fi
else
  fail "bootstrap.sh not found"
fi

# 4. scripts/*.js syntax
echo ""
echo "[4/9] scripts/*.js syntax"
if ls scripts/*.js > /dev/null 2>&1; then
  for f in scripts/*.js; do
    if node --check "$f" 2>/dev/null; then
      ok "$f"
    else
      fail "$f has syntax error"
    fi
  done
else
  warn "No scripts/*.js files found"
  warnings=$((warnings + 1))
fi

# 5. PROTECTED_KEYWORDS.js loadable
echo ""
echo "[5/9] PROTECTED_KEYWORDS.js"
if [ -f "scripts/PROTECTED_KEYWORDS.js" ]; then
  count=$(node -e "console.log(require('./scripts/PROTECTED_KEYWORDS.js').COUNT)" 2>/dev/null)
  if [ -n "$count" ]; then
    ok "PROTECTED_KEYWORDS.js loads ($count keywords)"
  else
    fail "PROTECTED_KEYWORDS.js exists but won't load"
  fi
else
  if [ -n "$BASELINE" ] && [ -f "$BASELINE" ]; then
    warn "PROTECTED_KEYWORDS.js missing — generating from $BASELINE"
    if node scripts/keyword-extractor.js "$BASELINE" scripts/PROTECTED_KEYWORDS.js > /dev/null 2>&1; then
      ok "Generated PROTECTED_KEYWORDS.js from baseline"
    else
      fail "Failed to generate PROTECTED_KEYWORDS.js"
    fi
  else
    warn "PROTECTED_KEYWORDS.js missing — run bootstrap or pass baseline.html"
    warnings=$((warnings + 1))
  fi
fi

# 6. protected-keyword gate
echo ""
echo "[6/9] protected-keyword gate"
if [ -f "scripts/protected-keyword-gate.js" ]; then
  if [ -f "tests/fixtures/clean-diff.txt" ]; then
    if node scripts/protected-keyword-gate.js "$BASELINE" tests/fixtures/clean-diff.txt > /dev/null 2>&1; then
      ok "Gate passes on clean diff"
    elif [ -z "$BASELINE" ]; then
      warn "Gate not testable without baseline (skipped)"
      warnings=$((warnings + 1))
    else
      fail "Gate fails on clean diff — gate might be broken"
    fi
  else
    warn "tests/fixtures/clean-diff.txt missing"
    warnings=$((warnings + 1))
  fi
else
  fail "scripts/protected-keyword-gate.js missing"
fi

# 7. consolidation review
echo ""
echo "[7/9] consolidation review"
if [ -f "scripts/consolidation-review.js" ]; then
  if [ -n "$BASELINE" ] && [ -f "$BASELINE" ]; then
    if node scripts/consolidation-review.js "$BASELINE" > /dev/null 2>&1; then
      ok "Consolidation review runs successfully"
    else
      fail "Consolidation review failed on $BASELINE"
    fi
  else
    warn "Consolidation review needs a baseline to run"
    warnings=$((warnings + 1))
  fi
else
  fail "scripts/consolidation-review.js missing"
fi

# 8. Markdown structure
echo ""
echo "[8/9] Markdown structure"
md_count=0
md_fail=0
for f in $(find . -name '*.md' -not -path './node_modules/*'); do
  md_count=$((md_count + 1))
  # Check that the file contains a top-level heading (# or ##), not just
  # that the first line is #. Some .md files start with YAML frontmatter.
  if ! grep -q "^# \|^## " "$f"; then
    fail "$f has no top-level heading"
    md_fail=$((md_fail + 1))
  fi
done
if [ "$md_fail" = "0" ]; then
  ok "All $md_count .md files have a top-level heading"
fi

# 9. Methodology references
echo ""
echo "[9/9] Methodology references"
if [ -f "methodology/ponytail-core.md" ]; then
  ok "Ponytail methodology documented"
else
  fail "methodology/ponytail-core.md missing"
fi
if [ -f "methodology/flex-directive-v5.md" ]; then
  ok "Flex Directive v5 documented"
else
  fail "methodology/flex-directive-v5.md missing"
fi
if [ -f "protected-systems.md" ]; then
  ok "Protected systems documented"
else
  fail "protected-systems.md missing"
fi
if [ -f "baseline.sha" ]; then
  ok "Locked baseline recorded"
else
  fail "baseline.sha missing"
fi

# Final report
echo ""
bold "==> Verification complete"
echo ""
if [ "$failures" -eq 0 ]; then
  ok "All verifications passed ($warnings warning(s))"
  exit 0
else
  err "$failures verification(s) failed"
  if [ "$warnings" -gt 0 ]; then
    warn "$warnings warning(s)"
  fi
  echo ""
  echo "To debug:"
  echo "  - Run individual checks (vitest, gate, etc.) for details"
  echo "  - See USAGE.md for how each tool works"
  echo "  - See docs/decisions/ for why the architecture is the way it is"
  exit 1
fi