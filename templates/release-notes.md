# Release Notes Template

**Purpose:** Use this template when locking a new GRID//NODE baseline. Fill in the placeholders, save as `releases/vX.Y.Z.md`, commit, push.

---

## Version

**vX.Y.Z** — YYYY-MM-DD

## What changed

[1-3 paragraphs describing the changes in this baseline. What features were added, what bugs were fixed, what was refactored.]

## The diff

**Previous baseline:** [filename], SHA [old-sha], [old-size] bytes
**New baseline:** [filename], SHA [new-sha], [new-size] bytes
**Delta:** [+/- bytes]
**Files changed:** [count]
**Lines added:** [count]
**Lines removed:** [count]

## Lane summary

| Lane | Count | Notes |
|---|---|---|
| GREEN | [N] | [list or note] |
| YELLOW | [N] | [list or note] |
| RED | [N] | [list or note, with Founder HQ sign-offs] |

## Protected systems touched

[None, OR list the protected systems that were modified.]

If any protected system was touched, include the per-change Founder HQ sign-off:

```
Sign-off: [Founder HQ name], YYYY-MM-DD HH:MM:SS TZ
For: [protected system name]
Change: [one-line description]
Trace: [path to the trace doc]
Test result: pass
```

## Verification results

- [ ] All 11 vitest tests pass
- [ ] Protected-keyword gate clean (or forced RED where expected)
- [ ] Consolidation review run (if applicable, e.g., >10% growth)
- [ ] Self-check on the smallest runnable check
- [ ] One verification pass per YELLOW change
- [ ] Independent verification per RED change
- [ ] Staging deploy verified (for YELLOW/RED)
- [ ] Live deploy verified (for all)
- [ ] Bootstrap one-liner still works (test on a clean session if possible)

## Self-check (the smallest runnable check)

Paste the output of the in-app self-check (`templates/self-check-snippet.js`) on the live URL:

```
[GRIDNODE self-check] OK: N/N checks passed
  ✓ localStorage reachable
  ✓ gn_settings readable
  ✓ function loadApp exists
  ... etc
```

If any check failed, document why and what's being done.

## Ponytail audit (if run)

[Output of the audit, or "Not run this release."]

## Consolidation review (if run)

[Output of the review, or "Not run this release."]

## Known issues

[None, OR list known issues carried over from previous baseline or introduced by this one.]

## Next steps

- [ ] [Future work item 1]
- [ ] [Future work item 2]
- [ ] [Future work item 3]

## Acknowledgments

- [Anyone who contributed to this release]
- [Special thanks if applicable]

---

## The boilerplate (use for every release)

> Released under the GRID//NODE Methodology (Ponytail + Flex Directive + Effectiveness + Design).
> Live at https://gridnode.pages.dev.
> Source code in private repositories.
> This release notes file is part of the handbook repo at github.com/gridnodeinfra-network/gridnode-handbook.

---

## Examples

See `CHANGELOG.md` for the actual entries from v1.0.0 and v1.1.0. They follow this template with the placeholders filled in.

---

## Why this template exists

Per the Flex Directive, every locked baseline ships with:
- A clear before/after state (bytes, SHA, lines)
- The standing report for each lane
- Verification results
- The self-check output

This template is the standardized format. Future Mavin/Claude sessions can find the previous release notes and know exactly what to expect when they lock a new baseline.

The discipline: **every release is auditable**. The next session can read this file, compare against the deployed SHA, and know whether the deployment is current.