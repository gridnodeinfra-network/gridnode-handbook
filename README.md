# GRID//NODE Handbook

**The single source of truth for the GRID//NODE project — Pipe's biotech tracker.**

This repo is the cross-session anchor for the work. It survives every Mavis/Claude/other-agent session, because it lives on GitHub, not in any session.

---

## Quick start

### For Pipe (founder) on a fresh Mavis session

Paste this at the start of any new chat:

```
You are Mavin/Claude working on GRID//NODE with Pipe (founder).
- Live URL: https://gridnode.pages.dev
- Locked baseline: gridnode-v1.3_post-phase-D_baseline.html, SHA 7b6c4dc9..., 1,000,593 bytes
- Default mode: Ponytail full (lazy senior dev, smallest runnable check required)
- Default policy: Flex Directive 3-lane system (GREEN/YELLOW/RED)
- Protected systems: 14 systems, see protected-systems.md
- Verification: any "this is done" claim needs a runnable check, not just a status report
- Third-signal check: mandatory for any canonical artifact
```

If the agent doesn't have the methodology details, paste relevant sections from `GRIDNODE_HANDOFF.md`.

### For Mavis automation (recommended)

Run the bootstrap script:

```bash
curl -s https://raw.githubusercontent.com/gridnodeinfra-network/gridnode-handbook/main/bootstrap.sh | bash
```

Or with a baseline path to verify the locked file:

```bash
./bootstrap.sh /path/to/gridnode-v1.3_post-phase-D_baseline.html
```

That command:
1. Clones this repo to `/workspace/.gridnode-handoff/`
2. Verifies the locked baseline SHA (if path provided)
3. Installs all 6 Ponytail skills to `/workspace/.skills/ponytail-*/`
4. Installs the handoff-loader skill
5. Verifies 7/7 skills present
6. Runs a smoke test on the keyword extractor
7. Prints the handoff summary

After running, you have a fresh Mavis session with:
- The full handoff doc available locally
- The locked baseline filename + SHA
- All 6 Ponytail skills installed
- The methodology stack loaded

---

## What this repo contains

| File | Purpose |
|---|---|
| `README.md` | This file — installation + usage |
| `INSTALL.md` | Detailed install instructions per platform |
| `USAGE.md` | How to use the methodology + tools in practice |
| `GRIDNODE_HANDOFF.md` | The handoff doc — single source of truth |
| `protected-systems.md` | The 14 protected systems, full details |
| `baseline.sha` | The locked baseline filename, SHA-256, and size |
| `bootstrap.sh` | One-command setup for fresh Mavis sessions |
| `package.json` | npm config (vitest + scripts) |
| `scripts/keyword-extractor.js` | Generates PROTECTED_KEYWORDS from a baseline (Node.js) |
| `scripts/PROTECTED_KEYWORDS.js` | Auto-generated keyword list (the gate's input) |
| `scripts/protected-keyword-gate.js` | Scans a diff for protected keywords |
| `scripts/consolidation-review.js` | Audits a baseline for over-engineering |
| `templates/boot-speed-snippet.js` | Browser snippet for Rule 3 measurement |
| `templates/self-check-snippet.js` | In-app runnable check (per Ponytail) |
| `tests/keyword-extractor.test.js` | vitest suite (11 tests, all passing) |
| `.skills/gridnode-handoff-loader/SKILL.md` | Mavis auto-loader skill |
| `methodology/` | The full methodology stack (Ponytail, Flex Directive, etc.) |

---

## The methodology stack

The tools and rules in this repo implement four layers of discipline, all locked:

**1. Ponytail (lazy senior dev mode)**
- 6-rung decision ladder (YAGNI → stdlib → native → one-line → minimum)
- "Lazy code without its check is unfinished" rule
- 5 audit tags (delete/stdlib/native/yagni/shrink)
- `ponytail:` comment convention
- Source: https://github.com/DietrichGebert/ponytail (MIT)

**2. Flex Directive v5 (3-lane change policy)**
- GREEN (<1KB, no protected touch)
- YELLOW (medium, self-audit + 1 review)
- RED (protected, per-change human sign-off)
- "Show work not verdicts" preserved
- Source: this repo's `GRIDNODE_HANDOFF.md` + Claude collaboration

**3. Effectiveness Methodology v1 (7 verification habits)**
- Self-test on known case before scaling
- Never truncate diagnostic output
- "Identical" needs scope check, not just text check
- Watch for fallbacks that hide bugs
- Count forward and backward
- Don't self-advance through phase gates
- Name the specific blocking dependency

**4. Design Effectiveness v1 (5 design habits)**
- Reference tokens, never redefine
- Match locked aesthetic explicitly
- Design systems before screens
- Line between implementation and origination
- Audit styles like code

The order matters: design tokens → code structure (Ponytail) → change policy (Flex) → verification (Effectiveness). Each layer enables the next.

---

## The locked state

**Live URL:** https://gridnode.pages.dev
**TinyURL:** https://tinyurl.com/25h4qg7x
**Baseline file:** `gridnode-v1.3_post-phase-D_baseline.html`
**SHA-256:** `7b6c4dc9025aa07bb336edd0eb28cf76a3bd14cff7393aa19a01cb26428e6660`
**Size:** 1,000,593 bytes

See `baseline.sha` for the canonical record.

---

## The 14 protected systems

**These are the safety net. Any change to these is RED-class by default.**

1. SHOTS scanner behavior
2. Scanner hitboxes
3. `scannerMode` logic
4. Selected-location source of truth
5. LOG SHOT transfer
6. SHOT HISTORY
7. Archive / restore / purge
8. Phase Engine
9. RESULTS
10. WEIGHT RECORDS edit / remove
11. LAB syringe
12. VAULT
13. NODE ALIAS
14. localStorage persistence (`gn_settings` is the only key)

Full details in `protected-systems.md`.

---

## The 130 verified protected keywords

Generated by `scripts/keyword-extractor.js` against the locked baseline. Both AIs (Mavin + Claude) ran the script; both got 130. (The earlier hand-verified 99 was an undercount — the same kind of error as v3's 47/86.)

The list is auto-generated; hand-edits are forbidden. To regenerate:

```bash
node scripts/keyword-extractor.js /path/to/baseline.html scripts/PROTECTED_KEYWORDS.js
```

---

## How to use the tools

### Run the test suite

```bash
npm install
npm test
```

11 tests verify the keyword extractor, gate, and consolidation review.

### Generate the keyword list from a baseline

```bash
node scripts/keyword-extractor.js /path/to/baseline.html
```

Output: a JS array with the count. Exit code = count.

### Scan a diff for protected keywords

```bash
node scripts/protected-keyword-gate.js /path/to/baseline.html /path/to/diff.txt
```

Exit code 0 = clean (GREEN/YELLOW-eligible). Exit code 1 = protected keyword touched (forces RED).

### Audit a baseline for over-engineering

```bash
node scripts/consolidation-review.js /path/to/baseline.html
```

Output: a report with findings (delete/stdlib/native/yagni/shrink tags), ranked by potential line savings. The report lists findings; it does NOT apply fixes.

### Measure boot time (Rule 3)

Open the GRID//NODE app on a real device, paste `templates/boot-speed-snippet.js` into DevTools, reload. The console logs the boot time in ms. Run 10 times, take the 90th percentile + 20% headroom = N.

### Add the self-check to the app (Change 3)

Append `templates/self-check-snippet.js` to the GRID//NODE file before the `</body>` tag. On every load, the console logs `[GRIDNODE self-check] OK: 12/12 checks passed` (or similar).

---

## The collaboration format

All docs in this repo use the same format (locked from Claude's Flex Directive v2):

- `# <Title> v<n>` with Author/For/Status/Supersedes/Date
- `## Why this exists` opening
- `## Core principle` rule
- Numbered sections with `##` headers
- `## What does NOT change` preservation clause
- `## Open questions for <X>` assigned
- `## TL;DR for the relay` paste-ready summary
- `## What's still open` with owners
- Sign-off: `— <Author>`

---

## How to update the handoff

When a new baseline is locked, or the methodology changes, or the project state shifts:

1. Update `GRIDNODE_HANDOFF.md` to reflect the new state
2. Update `baseline.sha` if the baseline file changed
3. Re-run `keyword-extractor.js` to regenerate `PROTECTED_KEYWORDS.js`
4. Run `npm test` to verify the scripts still work
5. Commit + push to `main`
6. The next Mavis session that runs `bootstrap.sh` will pull the latest

**The repo IS the source of truth. Memory topics, session state, and individual skill files are session-locked and don't survive. The repo does.**

---

## The 26-hour history (TL;DR)

The session that produced this repo:
- Phase A→D consolidation work (17 functions hoisted, IIFE unwrap, patch strip)
- Boot fix (silent catch → guarded transition)
- New baseline locked at SHA `7b6c4dc9...`
- Live deployed to Cloudflare Pages
- Ponytail methodology installed (6 skills)
- Flex Directive co-developed with Claude (5 rounds of convergence)
- Keyword list audited (script generated 130, replacing the hand-verified 99 undercount)
- Script failure caught (v5 script was broken; principle held, implementation needed work)
- Handoff codified (this repo)

---

## License

The handoff doc, methodology, and scripts are MIT-licensed. The GRID//NODE app code is Pipe's IP.
