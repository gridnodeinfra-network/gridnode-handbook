# Flex Directive v5 (3-Lane Change Policy)

**Source:** Co-developed by Claude (VEKTOR role) and Mavin, with 5 rounds of convergence. Ratified 2026-06-21.

## Core principle

> **Match the process to the risk, not the task to the maximum process.**

Most changes are low-risk. They've been paying a high-risk tax. This directive stops that. Rigor where it earns its keep, light where it doesn't.

## The three lanes

Every change is classified GREEN, YELLOW, or RED **before work starts**. The person making the change proposes the lane; if unsure, it defaults up (toward more caution), never down.

### 🟢 GREEN — just do it

**Definition:** Additive, reversible, touches no protected system, under 1KB net change, has one user-flow assertion in the self-check.

**Examples:** new color/copy, a self-contained helper function in the shared block, a new manifest row, a tooltip, a non-protected UI tweak.

**Process:**
1. Make the change
2. Run the standing self-check (the smallest runnable check)
3. Run the protected-keyword gate
4. Report the standing report block (below)
5. Done — no Founder HQ, no staging gate

**Verification:** the standing self-check (per Ponytail's smallest-check rule) plus the protected-keyword gate. That's it.

### 🟡 YELLOW — verify, then ship

**Definition:** New feature, touches shared scope, moderate size (1-5KB), OR anything that *reads* from a protected system without modifying it.

**Examples:** a new tab, a new scanner mode that reads `scannerMode` but doesn't change its logic, a new results chart, a CSV field.

**Process:**
1. Mavin self-runs the saved audit formula (dup-function check + scope check) **before** sending
2. Run the protected-keyword gate
3. One verification pass (Claude or self-verified against the checklist)
4. Staging check, then deploy
5. Full stat-block report

**Verification:** audit formula + self-check + protected-keyword gate + one review. No Founder HQ unless it touches a protected boundary.

### 🔴 RED — full process, gated

**Definition:** Protected systems, drift merges, script/style consolidation, anything that broke before, anything irreversible.

**Protected systems:** SHOTS scanner behavior, scanner hitboxes, `scannerMode` logic, selected-location source of truth, LOG SHOT transfer, SHOT HISTORY, archive/restore/purge, Phase Engine, RESULTS, WEIGHT RECORDS edit/remove, LAB syringe, VAULT, NODE ALIAS, localStorage persistence.

**Process:** the full discipline used in the Phase A→D work:
1. Trace first, no edits (show the trace, not a conclusion)
2. Classify drift true vs cosmetic
3. Founder HQ sign-off (per-change human)
4. Staging before live
5. Count forward and backward
6. Full stat-block report + independent verification

**This lane does NOT get lighter.** Per-change human sign-off is required. The decision to proceed on each protected-system change stays with a human.

## The protected-keyword scan (mandatory for all lanes)

Before any change is classified, run a static grep against the diff for protected-system identifiers (`scannerMode`, `loadApp`, `showScreen`, `vaultEdit*`, scanner hitbox handlers, Phase Engine functions, localStorage keys, etc.). Any hit forces the change to **RED**, regardless of what lane the maker proposed.

```bash
node scripts/protected-keyword-gate.js <baseline.html> <diff.txt>
```

Exit 0 = clean. Exit 1 = protected keyword touched (forces RED).

## The standing report (all lanes)

Every change, regardless of lane, ends with this block. GREEN gets the short form; YELLOW/RED get the full form.

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
TEST-METHOD: <one-line description of how it was tested>
TEST-RESULT: pass | fail | partial
CLAIMS-VERIFIED-BY-SCRIPT: <list of "I ran X and got Y" claims, with the command>
CLAIMS-UNVERIFIED: <list of "I observed X" or "I reasoned Y" claims, no script>
```

No verdict without the numbers behind it.

## What does NOT change

- **"Show work, not verdicts"** stays. A clean-looking report is still a claim until verified.
- **Count forward and backward.** Totals must reconcile.
- **Protected systems** stay protected, full RED process.
- **Self-test tools on a known case before scaling.**
- **Phase gates** for RED work.
- **The audit formula** (dup-function + scope check) stays exactly as saved.
- **The collaboration format** stays (from the original Directive v2).

## The size model (replaces hard number targets)

**Rule 1 — No silent bytes:** every change states its byte cost in the standing report. Growth is *accounted for*, not *capped*.

**Rule 2 — Per-lane growth budgets:**
- GREEN: <1KB (already set)
- YELLOW: state the cost, justify if >5KB
- RED: any size, fully gated

**Rule 3 — Boot performance is the real ceiling:** the thing size actually threatens is load time on a real mid-range Android. N is set by running `templates/boot-speed-snippet.js` 10 times on the real device, taking the 90th percentile, adding 20% headroom.

**Rule 4 — Growth-rate trip wire:** if the file grows more than 10% between two consecutive locked baselines, a mandatory consolidation review fires (run `scripts/consolidation-review.js`).

## The third-signal check (mandatory for canonical artifacts)

A model checking its own output verifies the part it was thinking about and misses the part it wasn't. The blind spot moves — but there is always a blind spot. The only thing that catches it is a second party running the actual code.

For any "this is canonical" claim:
- Run the script (if it's a script)
- Read the count (if it's a list)
- Check the file (if it's a file)

Self-declared canonical is not canonical. It's a claim pending verification.

## Source-of-truth artifact verification

Any artifact that claims to be a source of truth (a script, a config, a schema, a test harness) must be run by a party other than its author against the real target. The output must match the author's claim. The diff is the verification. Self-declared source-of-truth is not source-of-truth.

**"I built a script" is YELLOW-class by default, not utility-class.** A script that emits results other code depends on is a feature, not a utility.

## Why this exists

The original directives treated every change the same — a one-line color tweak went through the same gates as touching the scanner. The uniform heaviness slowed everything. This directive stops that, with rigor matched to risk.

The methodology stack (Ponytail + Flex Directive + Effectiveness + Design) is one system. Approve them together. Approve the tooling (this repo's scripts and skills) and the policy (this document) as one unit.
