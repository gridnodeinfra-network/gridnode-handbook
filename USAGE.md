# GRID//NODE Handbook — Usage

**How to use the methodology + tools in practice.**

---

## The 3-lane system (Flex Directive v5)

Every change is classified GREEN, YELLOW, or RED **before work starts**.

### 🟢 GREEN — just do it

**Definition:** Additive, reversible, touches no protected system, under 1KB net change.

**Examples:** new color/copy, a self-contained helper function, a manifest row, a tooltip, a non-protected UI tweak.

**Process:**
1. Make the change
2. Run the self-check
3. Run the protected-keyword gate
4. Report the standing report block (below)
5. Done — no Founder HQ, no staging gate

### 🟡 YELLOW — verify, then ship

**Definition:** New feature, touches shared scope, moderate size, OR anything that *reads* from a protected system without modifying it.

**Examples:** a new tab, a new scanner mode that reads `scannerMode` but doesn't change its logic, a new results chart.

**Process:**
1. Mavin self-runs the saved audit formula (dup-function check + scope check) **before** sending
2. Run the protected-keyword gate (mandatory for all lanes)
3. One verification pass (Claude or self-verified against the checklist)
4. Staging check, then deploy
5. Full stat-block report

### 🔴 RED — full process, gated

**Definition:** Protected systems, drift merges, script/style consolidation, anything that broke before, anything irreversible.

**Process:** the full discipline used in the Phase A→D work:
1. Trace first, no edits (show the trace, not a conclusion)
2. Classify drift true vs cosmetic
3. Founder HQ sign-off (per-change)
4. Staging before live
5. Count forward and backward
6. Full stat-block report + independent verification

---

## The standing report (all lanes)

Every change ends with this block. GREEN gets the short form; YELLOW/RED get the full form.

```
LANE: green | yellow | red
ORIGINAL: <bytes> / <SHA>
NEW:      <bytes> / <SHA>
DELTA:    <±bytes>
SCRIPT TAGS: <n>   STYLE TAGS: <n>
PROTECTED SYSTEMS TOUCHED: none | [list]
DUP FUNCTIONS INTRODUCED: <n>
SELF-CHECK: pass | fail
WHY THIS LANE: <one sentence, mandatory>
TESTED-BY: <name> of <party> at <ISO timestamp>
TEST-METHOD: <one-line description>
TEST-RESULT: pass | fail | partial
CLAIMS-VERIFIED-BY-SCRIPT: <list of script-verified claims with commands>
CLAIMS-UNVERIFIED: <list of judgment-call claims, no script>
```

No verdict without the numbers behind it.

---

## The protected-keyword gate (mandatory for all lanes)

```bash
node scripts/protected-keyword-gate.js <baseline.html> <diff.txt>
```

- Exit 0 = clean (GREEN/YELLOW-eligible)
- Exit 1 = protected keyword touched (forces RED)

The protected-keyword list is auto-generated from the baseline. **The list is canonical; do not hand-edit.**

To regenerate after a baseline change:
```bash
node scripts/keyword-extractor.js <new-baseline.html> scripts/PROTECTED_KEYWORDS.js
```

---

## The self-check (Ponytail "smallest runnable check" rule)

Per Ponytail: non-trivial logic leaves ONE runnable check behind, the smallest thing that fails if the logic breaks.

The in-app self-check (`templates/self-check-snippet.js`) verifies:
- localStorage is reachable
- `gn_settings` is readable
- Critical functions exist
- App screen element is present
- LAB tab → dose drawer opens (user-flow assertion)

Append to the GRID//NODE file before `</body>`. On load, the console logs:
- `[GRIDNODE self-check] OK: 12/12 checks passed` (good)
- `[GRIDNODE self-check] FAIL: 1 check(s) FAILED` (bad — review above)

---

## The audit tags (Ponytail review/audit)

When reviewing code for over-engineering, use these 5 tags:

- `delete:` — dead code, unused flexibility, speculative feature. Replacement: nothing.
- `stdlib:` — hand-rolled thing the standard library ships. Name the function.
- `native:` — dependency or code doing what the platform already does. Name the feature.
- `yagni:` — abstraction with one implementation, config nobody sets, layer with one caller.
- `shrink:` — same logic, fewer lines. Show the shorter form.

Output format:
`L<line>: <tag> <what>. <replacement>. [path]`

End with:
`net: -<N> lines, -<M> deps possible.`

---

## The `ponytail:` comment convention

Mark intentional simplifications:
- `// ponytail: this exists` (intentional deferral)
- `// ponytail: global lock, per-account locks if throughput matters` (named ceiling + upgrade path)

`ponytail-debt` greps these and produces a ledger. Anything without an upgrade path is `no-trigger` and silently rots.

---

## The collaboration format

All docs use the format from `gridnode-collab-format-v1`:

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

## The 7 verification habits (Effectiveness Methodology v1)

1. **Self-test tools on a known case before scaling.** Run audit scripts on a small fixture, verify expected output, then run on the real file.
2. **Never truncate diagnostic output.** Show full output during verification. Summaries are for the final report.
3. **"Identical" needs a scope check, not just a text check.** Same body + same scope = safe to dedupe. Same body + different IIFE = architecture question.
4. **Watch for fallbacks that hide bugs.** `try { ... } catch (e) {}` silently catches. Ask: is this gracefully handling or masking?
5. **Count forward and backward.** Totals must reconcile. 57 = 17 + 40 (the math closing is the verification).
6. **Don't self-advance through phase gates.** Each phase stops for sign-off, even when results look clean.
7. **Name the specific blocking dependency.** "This is a whole rewrite" isn't verifiable. "Function X is called from IIFE Y which expects Z" is.

---

## The 5 design habits (Design Effectiveness v1)

1. **Reference tokens, never redefine.** One source of truth for colors, spacing, fonts, shadows.
2. **Match the locked aesthetic explicitly.** #00d4ff / #ff3355 / Orbitron / Share Tech Mono / Rajdhani. Specific values, not vibes.
3. **Design systems before screens.** Confirm token set + font role + existing component match before styling.
4. **Line between implementation and origination.** Build what's specified. Lean on image_gen for original visual work.
5. **Audit styles like code.** Trace, dedupe, count forward and backward. Visual bugs hide the same way logic bugs do.

---

## The third-signal check (mandatory for canonical artifacts)

Per the Flex Directive and proven by three rounds of evidence (v3 keyword list, v4 count, v5 script):

> **A model checking its own output verifies the part it was thinking about and misses the part it wasn't. The blind spot moves — but there is always a blind spot. The only thing that caught it was a second party running the actual code.**

For any "this is canonical" claim, a human or fresh third party must verify:
- Run the script (if it's a script)
- Read the count (if it's a list)
- Check the file (if it's a file)

Self-declared canonical is not canonical. It's a claim pending verification.

---

## The growth-rate trip wire (Rule 4)

If the file grows more than 10% between two consecutive locked baselines, a mandatory consolidation review fires:

```bash
node scripts/consolidation-review.js <baseline.html>
```

The review produces a report, not a fix. Each finding is its own gated change.

---

## Working with a fresh Mavis session

1. Run the bootstrap (or paste the primer)
2. Read `GRIDNODE_HANDOFF.md` for project state
3. Read `protected-systems.md` for the safety net
4. Run `npm test` to verify the tools work
5. State your proposed lane (GREEN/YELLOW/RED) before starting work
6. Provide the standing report block at the end

The methodology is yours; the skill is just the structure.
