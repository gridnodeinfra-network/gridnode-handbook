# GRID//NODE — The Project

**The single page that ties the whole project together.**

If you landed here from a new chat, start by reading this page. It points to everything else.

---

## What is GRID//NODE?

GRID//NODE is Pipe's **private biotech tracker** — a single-file PWA for managing GLP-1 protocol injections (Tirzepatide, Semaglutide, Retatrutide). It runs entirely in the browser, stores data in `localStorage` (single key: `gn_settings`), and ships as a single HTML file.

**Why it exists:** Pipe wanted a tracker that:
- Works on mobile (Android + iOS, PWA install)
- Is offline-first (no network required after first load)
- Is private (no cloud, no telemetry, no third-party)
- Looks like Apple meets Cyberpunk 2077 (cyan #00d4ff, magenta #ff2a6d, green #05ffa1)
- Doesn't lock him into a SaaS

**The locked state:**
- **Live URL:** https://gridnode.pages.dev
- **TinyURL:** https://tinyurl.com/25h4qg7x
- **Baseline file:** `gridnode-v1.3_post-phase-D_baseline.html`
- **SHA-256:** `ca70bfb00ba95543da3b2bd8ffac2bc3044c0a9cc0285498a5828c360fd07c1a`
- **Size:** 1,005,318 bytes (981.7 KB)
- **Script tags:** 42 (41 + 1 new Flex Directive integration block)
- **Style tags:** 38
- **Hoisted shared utilities:** 17 (at exactly 1 definition each)
- **Protected systems:** 14
- **localStorage keys:** 1 (`gn_settings` is the only key)

See `baseline.sha` for the canonical record.

---

## The architecture (one file, by design)

GRID//NODE is a **single-file PWA**. No build step. No bundler. No framework. The deployed artifact is one HTML file with 42 `<script>` tags and 38 `<style>` tags inline.

**Why single-file:**
- Works in `file://` protocol (PWA-style, can be opened from disk)
- One SHA to verify (the file is the version unit)
- No module resolution, no bundle config
- Simple to deploy (drop into Cloudflare Pages, done)

**The trade-off:** the file is 1MB. That's a lot. But it boots fast on real devices (~1.5s on Pipe's iPhone, per Rule 3 measurement), and the size is accounted for in every change via the standing report.

**The future:** if the file ever crosses the 1.5MB threshold OR the fragment count becomes unwieldy, the fragmentation plan (see `methodology/flex-directive-v5.md`) breaks it into logical fragments while keeping the single-deploy artifact.

---

## The 14 protected systems

These are the safety net. Any change to these is RED-class by default.

| # | System | Why protected |
|---|---|---|
| 1 | SHOTS scanner behavior | The core data-capture surface |
| 2 | Scanner hitboxes | The user-tap input layer |
| 3 | `scannerMode` logic | The mode state machine |
| 4 | Selected-location source of truth | The location state |
| 5 | LOG SHOT transfer | The record-creation path |
| 6 | SHOT HISTORY | The historical view |
| 7 | Archive / restore / purge | The data lifecycle |
| 8 | Phase Engine | The cycle calculation |
| 9 | RESULTS | The outcome display |
| 10 | WEIGHT RECORDS edit / remove | The weight data lifecycle |
| 11 | LAB syringe | The dose visualization |
| 12 | VAULT | The local archive |
| 13 | NODE ALIAS | The user identity |
| 14 | localStorage persistence (`gn_settings`) | The single key |

Full details: `protected-systems.md`. The 130 protected keywords (function names, data attributes, etc.) are auto-generated and live in `scripts/PROTECTED_KEYWORDS.js`.

---

## The methodology stack (4 layers)

GRID//NODE is built and maintained using 4 layers of discipline, all codified:

**1. Ponytail (lazy senior dev mode)**
- 6-rung decision ladder: YAGNI → stdlib → native → one-line → minimum
- "Lazy code without its check is unfinished" — every non-trivial change ships with a runnable check
- 5 audit tags: `delete:`, `stdlib:`, `native:`, `yagni:`, `shrink:`
- Source: https://github.com/DietrichGebert/ponytail (MIT, installed as 6 skills)
- Spec: `methodology/ponytail-core.md`

**2. Flex Directive v5 (3-lane change policy)**
- GREEN: <1KB, no protected touch, self-verifies
- YELLOW: 1-5KB, shared scope, self-audit + 1 review
- RED: protected touch, per-change Founder HQ sign-off
- "Show work, not verdicts" preserved
- The protected-keyword gate forces RED when a protected keyword is touched
- Spec: `methodology/flex-directive-v5.md`

**3. Effectiveness Methodology v1 (7 verification habits)**
- Self-test tools on a known case before scaling
- Never truncate diagnostic output
- "Identical" needs a scope check, not just a text check
- Watch for fallbacks that hide bugs
- Count forward and backward
- Don't self-advance through phase gates
- Name the specific blocking dependency
- Saved in Mavis's memory topic `effectiveness-methodology-v1`

**4. Design Effectiveness v1 (5 design habits)**
- Reference tokens, never redefine
- Match the locked aesthetic explicitly (#00d4ff, Orbitron, Share Tech Mono, Rajdhani)
- Design systems before screens
- Line between implementation and origination
- Audit styles like code
- Saved in Mavis's memory topic `design-effectiveness-v1`

The order matters: design tokens → code structure (Ponytail) → change policy (Flex) → verification (Effectiveness). Each layer enables the next.

---

## The Flex Directive integration block (new in v1.3)

The locked baseline now includes a **Flex Directive integration block** at the bottom of the file (before `</body>`). This block:

1. Defines the standing report format as a greppable constant (`STANDING_REPORT_FORMAT`)
2. Registers the methodology in `window.GRIDNODE_META.methodology` (so tooling can query it)
3. Logs the methodology on load (`console.info('[GRIDNODE] Flex Directive v5 loaded')`)
4. Runs a self-check that verifies the methodology metadata is intact
5. Provides 5 verifiable checks: methodology registered, format defined, 3 lanes declared, green threshold set, yellow threshold set

This means any future change to GRID//NODE has the methodology baked in. The standing report format is in the codebase, not just in the docs. The lane thresholds are queryable from JavaScript. The self-check is in-app.

**The standing report (filled in for this change):**
```
LANE: yellow
ORIGINAL: 1,000,593 / 7b6c4dc9...
NEW:      1,005,318 / ca70bfb00ba95543da3b2bd8ffac2bc3044c0a9cc0285498a5828c360fd07c1a
DELTA:    +4,725 bytes
SCRIPT TAGS: 42 (+1)   STYLE TAGS: 38 (unchanged)
PROTECTED SYSTEMS TOUCHED: none (additive only)
DUP FUNCTIONS INTRODUCED: 0
SELF-CHECK: pass
WHY THIS LANE: additive, no protected-system touch, but +4.7KB exceeds 1KB GREEN threshold
TESTED-BY: Mavin, at 2026-06-21 20:55 ET
TEST-METHOD: ran the protected-keyword gate (clean), ran vitest (11/11), ran verify-all.sh (9/9), checked the file structure
TEST-RESULT: pass
```

---

## The tools (3 scripts + 1 gate + 1 test suite)

| Tool | Purpose | When to use |
|---|---|---|
| `scripts/keyword-extractor.js` | Generates the protected-keyword list from any baseline | After every locked baseline change |
| `scripts/PROTECTED_KEYWORDS.js` | The auto-generated keyword list (130 entries) | Input to the gate |
| `scripts/protected-keyword-gate.js` | Scans diffs for protected keywords | Before every change ships |
| `scripts/consolidation-review.js` | Audits for over-engineering | When growth exceeds 10% between baselines (Rule 4) |
| `scripts/verify-all.sh` | Single-command verification (9 checks) | Locally before commit |
| `tests/keyword-extractor.test.js` | 11 vitest tests | Runs in CI on every push |

All scripts:
- Have valid syntax (verified)
- Pass their own test suite (11/11)
- Are exercised by GitHub Actions CI on every push

---

## The CI pipeline (auto-verified on every push)

GitHub Actions runs 3 jobs on every push to `main`:

1. **Test the methodology + scripts** — vitest (11 tests), bash syntax (bootstrap.sh), JS syntax (all scripts/*.js)
2. **Markdown structure check** — every .md file has a top-level heading
3. **Final status** — pass/fail summary

The CI catches:
- Logic regressions in the scripts
- Syntax errors in the bootstrap
- Accidental deletions of protected files
- Documentation structure problems

**Latest CI runs:**
- ✅ `820969d` — VERIFICATION.md added (passing)
- ✅ `4d88735` — ci.yml added (passing after the markdown check fix)
- ❌ `5873754` — ci.yml added (failing — the bug I fixed)

The CI is the third-signal check, automated.

---

## The protected keyword gate (mandatory for every change)

```bash
node scripts/protected-keyword-gate.js <baseline.html> <diff.txt>
```

- Exit 0 = clean (GREEN/YELLOW-eligible)
- Exit 1 = protected keyword touched (forces RED)

The gate is the system's catch. It overrides self-classification. A maker who claims "this is GREEN" cannot ship if the gate says a protected keyword is touched.

Tested: clean diff exits 0, dirty diff (touches `loadApp`) exits 1 with the keyword identified.

---

## The bootstrap (one command for any new Mavis session)

```bash
curl -s https://raw.githubusercontent.com/gridnodeinfra-network/gridnode-handbook/main/bootstrap.sh | bash
```

What it does:
1. Clones the handbook repo to `/workspace/.gridnode-handoff/`
2. Verifies the locked baseline SHA
3. Installs all 6 Ponytail skills to `/workspace/.skills/ponytail-*/`
4. Installs the handoff loader skill
5. Verifies 7/7 skills present
6. Runs a smoke test on the keyword extractor
7. Prints the handoff summary

Total: 30 seconds. Every new Mavis session can be brought up to speed with one command.

---

## The "what next" map

You are here. The pipeline is verified. The work is shipped. What's the next move?

| If you want to... | Do this |
|---|---|
| **Make a real change to GRID//NODE** | Run the protected-keyword gate on your diff before pushing. Follow the standing report. |
| **Run a real Ponytail audit on a section** | Use `scripts/consolidation-review.js` for the whole file, or pick a section and apply the 5 audit tags. |
| **Add a new protected system** | Update `protected-systems.md`, regenerate the keyword list, run the tests. |
| **Change the methodology** | Read `CONTRIBUTING.md` for the process. Need Mavin + Claude + Pipe sign-off. |
| **Test the bootstrap end-to-end** | Open a new Mavis chat, paste the primer or run the bootstrap, see if it works. |
| **Wrap the session** | The work is shipped. The methodology is codified. The verification is automated. |

---

## Quick links

**The live app:**
- https://gridnode.pages.dev (1,005,318 bytes, SHA `ca70bfb0...`)

**The methodology:**
- [Ponytail core](methodology/ponytail-core.md) — the lazy-senior-dev rules
- [Flex Directive v5](methodology/flex-directive-v5.md) — the 3-lane policy
- [Glossary](docs/glossary.md) — terms defined
- [ADRs](docs/decisions/) — architecture decisions

**The tools:**
- [Scripts](scripts/) — keyword extractor, gate, consolidation review, verify-all
- [Tests](tests/) — 11 vitest tests
- [Templates](templates/) — boot-speed snippet, self-check snippet, release notes

**The examples:**
- [GREEN change](examples/green-change.md) — small, additive, self-verifies
- [YELLOW change](examples/yellow-change.md) — medium, self-audit + 1 review
- [RED change](examples/red-change.md) — touches protected, Founder HQ sign-off
- [Ponytail audit](examples/ponytail-audit.md) — applying the 5 tags
- [Consolidation review](examples/consolidation-review.md) — real report output

**The history:**
- [CHANGELOG](CHANGELOG.md) — visible evolution
- [VERIFICATION](VERIFICATION.md) — the canonical "everything works" record
- [Conversation archive](sessions/2026-06-20-21-conversation-archive.md) — the 26-hour memory

---

## TL;DR for any new agent

If you just landed here, here's what you need to know:

1. **GRID//NODE is a 1MB private PWA biotech tracker.** Live at https://gridnode.pages.dev.
2. **The codebase is one HTML file.** 42 scripts inline, 38 styles inline, 17 hoisted utilities.
3. **The methodology is 4 layers:** Ponytail (code), Flex Directive (change policy), Effectiveness (verification), Design (visual).
4. **The tools enforce the rules:** protected-keyword gate, consolidation review, vitest, CI.
5. **The protected systems are sacred:** 14 systems, 130 keywords, any touch forces RED.
6. **The standing report is mandatory:** every change ends with a 14-line block documenting lane, SHA, deltas, verifications.
7. **The third-signal check is the discipline:** two AIs cannot be each other's final verification.

If you're doing real work: read the relevant docs above, run the verify scripts, follow the standing report, get the third-signal check.

If you're just landing: read `GRIDNODE_HANDOFF.md` and `VERIFICATION.md` for the canonical state.

If you have questions: ask. The methodology is documented end-to-end. There's no excuse for guessing.

— Mavin, 2026-06-21

Last updated: 2026-06-21 20:55 ET, against baseline SHA `ca70bfb0...`