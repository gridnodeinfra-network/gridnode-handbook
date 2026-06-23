# Mavin Toolchain — What Mavin Uses to Work Fast

**Author:** Mavin (session 410992816300270)
**For:** Future Mavin instances, anyone wondering "what tools does Mavin use?"
**Date:** 2026-06-22 (end of 14h session)
**Status:** Catalog of the 25+ tools Mavin uses, organized by tier

---

## Tier 1: Core essentials (must-have)

These are the absolute basics. Without them, Mavin can't function.

| Tool | Why Mavin uses it |
|---|---|
| `git` | Version control, push to GitHub, check status, review diffs |
| `curl` | Live URL checks, file downloads, API calls |
| `wget` | Backup for curl (some endpoints prefer wget) |
| `jq` | JSON parsing, especially for GitHub API responses |
| `make` | Build tool (rarely used, but always present) |
| `gcc` | C compiler (for some npm modules with native deps) |
| `build-essential` | Meta-package for gcc, make, etc. |
| `python3` | SHA manifest, candidate rendering, OCR, JSON manipulation |
| `python3-pip` | Install Python packages (pillow, pytesseract) |
| `node` + `npm` | Run vitest, wrangler, svgo, playwright (all via npm) |

**Install:** `apt-get install -y git curl wget jq make gcc build-essential python3 python3-pip node npm`

---

## Tier 2: Mavin work tools (used in most sessions)

These are the tools that make Mavin's work faster and more accurate.

| Tool | Why Mavin uses it |
|---|---|
| `ffmpeg` | Video/audio conversion (rare in web work, but always present) |
| `tesseract` | OCR — read text from screenshots, verify visual changes |
| `shellcheck` | Bash lint — catch bugs in my own scripts before deploy |
| `ripgrep` | Fast file search (faster than grep for large codebases) |
| `fzf` | Fuzzy file finding (faster than `find` for known files) |
| `imagemagick` | Image manipulation (resize, convert formats) |

**Install:** `apt-get install -y ffmpeg tesseract shellcheck ripgrep fzf imagemagick`

---

## Tier 3: Visual + SVG (for design work)

These are the browser dependencies needed for headless Chromium.

| Tool | Why Mavin needs it |
|---|---|
| `libnss3` | Network security services (Chromium dependency) |
| `libatk-bridge2.0-0` | Accessibility toolkit (Chromium) |
| `libdrm2` | Direct rendering manager (Chromium) |
| `libxkbcommon0` | Keyboard handling (Chromium) |
| `libxcomposite1` | Compositing extension (Chromium) |
| `libxdamage1` | Damage extension (Chromium) |
| `libxrandr2` | Resize/rotate extension (Chromium) |
| `libgbm1` | Mesa GPU driver (Chromium) |
| `libpango-1.0-0` | Text rendering (Chromium) |
| `libcairo2` | 2D graphics (Chromium) |
| `libasound2` | Audio (Chromium) |

**Install:** `apt-get install -y libnss3 libatk-bridge2.0-0 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 libxrandr2 libgbm1 libpango-1.0-0 libcairo2 libasound2`

---

## Tier 4: Specific tools

Useful but not essential.

| Tool | Why Mavin uses it |
|---|---|
| `silversearcher-ag` | Faster than grep for code search (the `ag` command) |
| `universal-ctags` | Code symbol indexing (jump to function definitions) |

**Install:** `apt-get install -y silversearcher-ag universal-ctags`

---

## Tier 5: npm globals (Mavis's package manager)

All available via `npx` (no global install needed).

| Tool | Why Mavin uses it |
|---|---|
| `npx wrangler` | Cloudflare Pages deploys |
| `npx svgo` | SVG optimization |
| `npx playwright` | Headless browser automation |
| `npx pixelmatch` | Image comparison (visual regression) |
| `npx vitest` | Test runner (Foundation has 22 tests) |
| `npx zod` | Schema validation (Foundation) |

**Install:** None — all run via `npx` (downloads on demand).

---

## Tier 6: Python packages

For image processing, OCR, and Playwright.

| Package | Why Mavin uses it |
|---|---|
| `pillow` | Image manipulation in Python |
| `pytesseract` | Python wrapper for tesseract (OCR) |
| `playwright` | Python wrapper for Playwright (browser automation) |

**Install:** `pip install pillow pytesseract playwright`

---

## Pre-installed tier (from your user_profile memory, June 18 ish)

These were installed in the original sandbox, not by me. Listed for completeness.

| Tool | Why |
|---|---|
| `uv` | Fast Python package manager |
| `sqlite` | Embedded database (for localStorage migration, if needed) |
| `mermaid` | Diagram rendering (for the state machine docs) |
| `inotify-tools` | Filesystem watching (for live reload during dev) |
| `asciinema` | Terminal session recording (for demos) |
| `tig` | Git text-mode interface (alternative to `git log`) |
| `btop` | System monitor (alternative to `top`/`htop`) |
| `zstd` | Modern compression (faster than gzip) |
| `unrar` | RAR extraction (for downloaded archives) |
| `zip` | ZIP creation (for sharing bundles) |

---

## Tools that are NOT in this list

These would be nice to have but aren't worth the install time:

- `gh` (GitHub CLI) — handled by bootstrap step 5c
- `docker` — overkill for single-file apps
- `kubernetes` / `kubectl` — not relevant
- `aws-cli` / `gcloud` — not relevant (we use Cloudflare)
- `terraform` — not relevant
- `ansible` — not relevant
- `redis` / `postgres` — localStorage works for now

---

## The "what I actually use daily" subset

If I had to pick the 10 most-used:

1. **git** — 100+ times per session
2. **bash** — every command
3. **curl** — every deploy verification
4. **python3** — every SHA + manifest
5. **node + npx** — every vitest run, every wrangler deploy
6. **shellcheck** — every bash script I write
7. **tesseract** — every visual verification
8. **jq** — every API response
9. **ripgrep** — every code search
10. **ffmpeg** — when I need it (video work)

**The other 15+ tools are situational.** Tier 1+2+5 covers 90% of Mavin work.

---

## Why the bootstrap step 5e exists

Before this commit, the bootstrap only **warned** about missing tools. A fresh Mavis session without `chromium` or `tesseract` would silently lose visual verification capability.

**After this commit:** Step 5e **installs** the tools that aren't present. Fresh Mavins get the same toolkit I had.

If something is missing after bootstrap, the fix is one line in `install-tools.sh`.

---

## How to add a new tool

If Mavin (or Pipe) decides a new tool is worth installing:

1. Add it to the appropriate tier in `install-tools.sh`
2. Update this doc (MAVIN-TOOLCHAIN.md) with the why
3. Test by running `bash install-tools.sh` in a fresh sandbox
4. Commit + push to handbook repo

The next Mavis session will pick it up automatically.

---

## The meta-lesson

**Tools are leverage.** Each tool Mavin uses saves 10-100x the time it took to learn. Tier 1+2 is the floor — every Mavin session needs those. Tier 3+4+5 is the ceiling — situational but valuable.

The bootstrap makes the floor automatic. The ceiling is up to the Mavin.

— Mavin (session 410992816300270, June 22, 2026)