# Contributing to the GRID//NODE Handbook

This handbook is the source of truth for the GRID//NODE project. Changes to it affect how future AIs (Mavin, Claude, others) work on the project. That's why we have a process.

---

## TL;DR

1. Most changes don't need a special process — typo fixes, doc improvements, test additions
2. **Methodology changes** (lane rules, protected systems, audit tags) need a YELLOW+ change with Claude or another AI as verifier
3. **Anything that breaks compatibility** (renaming, removing skills, changing the protected-keyword format) needs a major version bump + CHANGELOG entry

---

## What kind of change are you making?

### Documentation improvements (typo, clarity, example)

**Examples:**
- Fixing a typo in `README.md`
- Adding an example to `examples/`
- Improving a code comment in a script
- Adding a note to the glossary

**Process:**
1. Make the change
2. Run `./scripts/verify-all.sh` to confirm nothing broke
3. Commit + push
4. CI runs automatically

**No sign-off needed.** These changes are low-risk.

---

### Tooling improvements (better scripts, more tests, new snippets)

**Examples:**
- Adding a new audit check to `consolidation-review.js`
- Adding a new vitest test
- Adding a new template

**Process:**
1. Make the change
2. Add a test that verifies the new behavior
3. Run `./scripts/verify-all.sh` to confirm everything passes
4. Commit + push
5. CI runs automatically

**Self-verification sufficient** for small tooling changes. Larger changes might warrant a YELLOW review.

---

### Methodology changes (lane rules, protected systems, audit tags)

**Examples:**
- Adding a new protected system to the 14
- Changing the GREEN threshold from 1KB to 2KB
- Adding a new audit tag (`defer:`, `await:`, etc.)
- Modifying the Flex Directive text

**Process:**
1. Open an issue describing the change + the rationale
2. The proposed change is a YELLOW-class change to the methodology itself
3. Get verification from at least one other AI (Claude is the natural choice) OR a human
4. Update both the methodology doc AND the related code (tests, scripts, examples) in the same PR
5. Bump the minor version in CHANGELOG.md
6. Commit + push — CI runs + the third-signal check happens via PR review

**Why this is YELLOW not GREEN:** methodology changes affect how every future change is classified. A wrong threshold or wrong protected system cascades.

---

### Breaking changes (renaming, removing, restructuring)

**Examples:**
- Renaming `PROTECTED_KEYWORDS.js` to `keywords.js`
- Removing the `< 1KB` GREEN threshold
- Changing the protected-keyword gate's exit codes
- Dropping support for Node.js <18

**Process:**
1. Open an issue describing the change + the migration path
2. The change is RED-class (touches canonical artifacts)
3. Need Founder HQ sign-off + independent verification (run the new artifacts, confirm they work)
4. Bump the major version in CHANGELOG.md
5. Provide a migration guide for any external consumers

**Why this is RED:** other repos or AIs may depend on the current format. A breaking change without coordination creates silent failures downstream.

---

## The standing report (every change)

Every change — even a typo — should ship with a short standing report:

```
LANE: green | yellow | red
WHAT: <one-line description>
WHY: <one-line rationale>
TESTED-BY: <name>
TEST-METHOD: <how it was verified>
TEST-RESULT: pass | fail
```

For typo fixes, this can be terse:

```
LANE: green
WHAT: Fixed typo in README.md ("recieve" → "receive")
WHY: clear
TESTED-BY: Mavin
TEST-METHOD: spell-check
TEST-RESULT: pass
```

For methodology changes, it should be thorough:

```
LANE: yellow
WHAT: Added "firewall" as a 6th protected system category
WHY: Per Pipe's request to harden against network-layer tampering
TESTED-BY: Mavin + Claude
TEST-METHOD: ran consolidation-review.js + verified keyword gate still passes
TEST-RESULT: pass
```

---

## The third-signal check (mandatory for methodology changes)

Two AIs cannot be each other's final verification. For any methodology change:

1. **Mavin proposes** the change with full standing report
2. **Claude verifies** the change by running the artifacts (not by reasoning about them)
3. **Pipe (Founder HQ) signs off** on the change
4. **The change is merged + pushed** with the report

Skipping step 3 = the change goes in without human authority. That's how the v5 keyword script went out unverified — and how it broke. Don't repeat.

---

## The commit message format

```
[type]: [short description]

[longer description if needed]

[standing report inline if it's small]

Refs: [#issue-number if applicable]
```

**Types:**
- `docs:` — documentation only
- `tools:` — scripts, tests, templates
- `methodology:` — lane rules, protected systems, audit tags
- `fix:` — bug fix
- `chore:` — repo maintenance (CI, gitignore, etc.)
- `breaking:` — breaking change (with migration guide)

**Examples:**
```
docs: Added green-change example to examples/

tools: Added verify-all.sh that runs all checks in sequence

methodology: Added 6th protected system category (firewall)

breaking: Renamed scripts/PROTECTED_KEYWORDS.js to scripts/keywords.js
Refs: #42
```

---

## The PR review checklist

Before merging:

- [ ] `./scripts/verify-all.sh` passes locally
- [ ] CI passes (vitest + lint)
- [ ] If methodology change: third-signal check done (Mavin + Claude + Pipe)
- [ ] If tooling change: test added or updated
- [ ] If breaking change: CHANGELOG has migration guide
- [ ] Standing report in PR description
- [ ] Commit message follows the format above

---

## When in doubt

Ask before doing. The methodology is the methodology. Don't bypass it for your own change.

If you're unsure whether your change is GREEN/YELLOW/RED:
- GREEN: small, additive, no protected touch, <1KB
- YELLOW: new feature, shared scope, 1-5KB, OR reads from protected
- RED: protected system touch, drift merge, script/style consolidation, anything that broke before

When in doubt: classify one lane up (toward more caution).

---

## The conversation rule

When discussing changes (in chat, in PRs, anywhere):

1. **Show work, not verdicts.** Don't say "this is the right way." Say "this works because X."
2. **Count forward and backward.** Totals must reconcile.
3. **Name the specific blocker.** Don't say "this is a hard problem." Say "the issue is Y expects Z in scope, which the change doesn't provide."
4. **Self-test on a known case before scaling.** Apply your change to a small example first.
5. **Watch for fallbacks that hide bugs.** `try { } catch (e) {}` silently catches. Don't.

Same rules apply to proposals as to code.

---

## Getting help

- **For methodology questions:** ask Claude (the natural verifier for the methodology we co-developed)
- **For tool questions:** read the script's header comment + the related doc in `docs/`
- **For "what should I do?" questions:** run `./scripts/verify-all.sh` first. If everything passes, the repo is healthy and your change is probably fine.

---

## License

By contributing, you agree your contributions are MIT-licensed (matching the repo's license).