
## [2026-06-28] — rc32 SHIPPED (Hermes session)

### Locked baseline
- **Live SHA:** `7e0d6d3be38de2e3a3a64ae248c35ced5fc788ae396126dc9c1be6bf27aeaf1f`
- **Live size:** 1,035,106 bytes
- **Live URL:** https://gridnode.network/ + https://gridnode.pages.dev/

### Confirmed by
- rc32 directive acceptance gates: USER_01 only in changelog comments, node --check clean
- 8/8 directive markers present in live HTML (signOutOverlay, openAuthUI, profAvaWrap, calcAndShowBMI, sndOn, etc.)
- Topbar uses correct 2-icon layout (sound + avatar) + brand wordmark

### Pending issues
- www.gridnode.network still returning 522 (DNS record points to apex in self-reference loop; needs write-scoped CF token to fix)

### Tools shipped in this session
- `/usr/local/bin/search-hermes` — web search via Bing + persistent Chromium (CDP)
- `/usr/local/bin/mavin-brief` — one-shot context reload from public sources
- `/usr/local/share/hermes-skills/mavin-brief/` — skill definition
- Cron jobs (delivered to Telegram):
  - `gridnode-drift-watch` (aabff693c6c5) — 4x daily at 08:00/12:00/16:00/20:00 ET
  - `gridnode-morning-brief` (0a3e11f356e9) — daily at 10:00 ET

### Open work (laptop-required)
See `/workspace/HERMES-CHECKLIST.md` for the host-side setup tasks.

---
# CHANGELOG

All notable changes to this repository are documented here. The format is based on [Keep a Changelog](https://keepachangelog.com/) and this project adheres to [Semantic Versioning](https://semver.org/).

---

## [1.1.0] — 2026-06-21

### Added

- **Examples folder** with 6 real-world examples showing the methodology in action:
  - `examples/green-change.md` — settings gear icon (UI chrome)
  - `examples/yellow-change.md` — weight chart panel (new feature reading protected data)
  - `examples/red-change.md` — scannerMode persistence fix (touches protected system)
  - `examples/ponytail-audit.md` — audit of a 200-line helper module
  - `examples/consolidation-review.md` — real consolidation review output
  - All examples follow the `gridnode-collab-format-v1` template

- **GitHub Actions CI** (`.github/workflows/ci.yml`):
  - Runs vitest on every push and PR
  - Validates bash + JS syntax of all scripts
  - Verifies Markdown structure
  - Final pass/fail status

- **`scripts/verify-all.sh`** — one-command verification:
  - 9 checks in sequence
  - Single pass/fail output
  - Detailed error messages for debugging
  - Optional baseline.html argument for full coverage

- **`CHANGELOG.md`** (this file) — visible evolution of the repo

- **`CONTRIBUTING.md`** — process for proposing methodology changes

- **`docs/glossary.md`** — terminology reference (Ponytail, Flex Directive, etc.)

- **`docs/decisions/`** — Architecture Decision Records:
  - `0001-ponytail-vendored-from-upstream.md`
  - `0002-keyword-list-as-derived-artifact.md`
  - `0003-protected-keyword-gate-required.md`

- **`templates/release-notes.md`** — template for the next locked baseline

### Changed

- `scripts/verify-all.sh` includes checks for the new files
- `bootstrap.sh` color-coded output (green/yellow/red status)
- `protected-systems.md` reorganized with verified-function table

### Fixed

- N/A (initial release of additions)

### Notes

- All additions are backward-compatible
- No changes to existing files' content (additive only)
- Repository size: ~250KB (was 209KB)

---

## [1.0.0] — 2026-06-21

### Added

- **Initial release of the GRID//NODE handbook**

**The handoff (Pipe can pick up the work):**
- `GRIDNODE_HANDOFF.md` — the master handoff doc
- `INSTALL.md`, `USAGE.md`, `README.md` — full documentation
- `protected-systems.md` — the 14 protected systems
- `baseline.sha` — locked baseline record (1,000,593 bytes, SHA `7b6c4dc9...`)

**The methodology (rules for working):**
- `methodology/ponytail-core.md` — Ponytail lazy-senior-dev mode
- `methodology/flex-directive-v5.md` — 3-lane change policy (GREEN/YELLOW/RED)

**The tools (scripts that enforce the rules):**
- `scripts/keyword-extractor.js` — generates PROTECTED_KEYWORDS from any baseline
- `scripts/PROTECTED_KEYWORDS.js` — auto-generated keyword list (130 entries)
- `scripts/protected-keyword-gate.js` — scans diffs for protected keywords
- `scripts/consolidation-review.js` — audits for over-engineering
- `scripts/verify-all.sh` — single-command full verification (added in 1.1.0)
- `tests/keyword-extractor.test.js` — 11 vitest tests, all passing

**The skill (Mavis integration):**
- `.skills/gridnode-handoff-loader/SKILL.md` — auto-loader skill

**The templates (paste-ready snippets):**
- `templates/boot-speed-snippet.js` — Rule 3 boot-speed measurement
- `templates/self-check-snippet.js` — in-app Ponytail smallest-check

**The bootstrap (one command for fresh sessions):**
- `bootstrap.sh` — clones repo, installs Ponytail, runs smoke test

**Configuration:**
- `package.json` + `package-lock.json` — npm config

### Verification

- ✅ 11/11 vitest tests pass
- ✅ bootstrap.sh syntax valid
- ✅ All scripts/*.js files have valid JS syntax
- ✅ PROTECTED_KEYWORDS.js loads (130 keywords)
- ✅ Methodology docs complete

### Provenance

This repository was created during the consolidation work of 2026-06-21, after the locked baseline `gridnode-v1.3_post-phase-D_baseline.html` was finalized at SHA `7b6c4dc9025aa07bb336edd0eb28cf76a3bd14cff7393aa19a01cb26428e6660` (1,000,593 bytes).

The methodology was co-developed with Claude (Anthropic) over 5 rounds of convergence. See `methodology/flex-directive-v5.md` for the full history.

---

## Versioning

- **Major version (1.x → 2.x):** methodology breaks (new lane added, protected systems change)
- **Minor version (1.0 → 1.1):** additive features (new docs, new tools, new examples)
- **Patch version (1.1.0 → 1.1.1):** bug fixes, copy edits, no behavior change

When bumping versions:
1. Update this CHANGELOG.md
2. Update the version field in any relevant docs
3. Commit with a clear message: "Bump to v1.x.y"
4. Push — CI will run automatically
## [1.3.0] — 2026-06-22 (rc26)

### Changed

- **Locked baseline updated** to `875f7a9f8d8a529037c8746a1137ff55d67f1927c2c18670a47ff556d7ef20a5` (970,160 bytes, rc26)
- **Live URL** updated to `https://gridnode.network` (with `gridnode.pages.dev` as legacy alias)
- **9 deploys shipped today** (rc17 → rc26):
  - Splash v2: 1-line value + 1 CTA, removed 4-line headline + 4 mini-pills + dual CTAs
  - Wordmark centering (4 SVG locations)
  - Boot redesign: terminal log streaming + scan reveal + pixel-stream progress
  - PWA install foundation: real `/sw.js`, real `/manifest.json`, real icon-192.png + icon-512.png
  - LAB mobile text overlap fix
  - Click delay / text-selection-on-tap fix (4 passive:true listeners)
  - VAULT SYSTEM card: CHECK FOR UPDATES / REFRESH DATA / RELOAD APP buttons
  - VAULT buttons wired to window.* (was inside IIFE)
- **Handoff doc overhauled**: added founder profile + tone guide + autonomy manifesto + drift prevention
- **Added** `deploy-gridnode.sh` (one-command deploy + auto-handoff sync)
- **Added** `handoff-update.sh` (drift detector between live and local)
- **Added** git `post-commit` hook (auto-runs handoff-update on baseline changes)

### Fixed

- SHA drift between local lock and live deploy (was `5316f405...` 1,006,248 bytes vs `875f7a9f...` 970,160 bytes)
- Stale handoff doc references


## [1.3.1] — 2026-06-23 (rc27)

### Added

- **DASH empty-state CTA** — replaced "TAP THE + BUTTON" text with a real `<button class="btn-full btn-primary empty-cta" onclick="handleShotFab()">LOG YOUR FIRST SHOT</button>` in both the static initial HTML and the JS template literal in `renderLog()`. Mobile tap target now meets 44px minimum. Auto-opens the shot log modal on click. Includes `aria-label` for screen readers.

### Changed

- **Locked baseline updated** to `f75a81cd168dadcb1a26b1b05d8d9c7e413f20b1f10737cfa4f1b27f7848e452` (970,531 bytes, rc27)
- Size delta: +371 bytes from rc26

### Fixed

- New users had no clear path to log their first shot — the empty state showed text but no actual button. The DASH page just looked dead.
