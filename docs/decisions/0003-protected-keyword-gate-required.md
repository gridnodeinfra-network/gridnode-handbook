# ADR-0003: Protected-keyword gate is required (not optional) for all changes

**Status:** Accepted (2026-06-21)
**Deciders:** Mavin + Claude
**Triggered by:** Phase 3.3 consolidation work + the 76-error runtime failure

---

## Context

During Phase A→D consolidation, the first dedupe attempt produced 76 runtime errors. The cause: identical-looking function bodies in different IIFE scopes. The deduplication looked safe and was approved, but the actual runtime behavior broke.

After the recovery (Phase 3.5: hoist + scope check + staging), the team formalized the **protected-keyword gate**: any change touching a protected keyword must be classified RED, regardless of what lane the maker proposed.

## Decision

The protected-keyword gate (`scripts/protected-keyword-gate.js`) is **mandatory for every change**, regardless of lane:

- GREEN: gate runs, exits 0 → ship
- YELLOW: gate runs, exits 0 → ship
- RED: gate runs, exits 1 (because protected keyword is touched) → follow RED discipline

The gate **overrides self-classification**. A maker who claims "this is GREEN" cannot ship if the gate says a protected keyword is touched. The gate is the system's catch; the maker's claim is the maker's claim.

## Rationale

**Why mandatory:**
1. **Proven failure mode** — the 76-error failure was exactly the case where self-classification was wrong
2. **Catches scope errors** — the gate uses anchored regex matching that the maker might not think to check
3. **Independent of maker intent** — the gate doesn't care why the change was made, just whether it touches protected code
4. **Auditable** — the gate's exit code is in the standing report

**Why not optional:**
- Optional = the maker can skip it = back to the 76-error failure mode
- "I'll check manually" doesn't scale; the gate does
- The gate is fast (sub-second on most baselines); cost is low

## Implementation

```bash
node scripts/protected-keyword-gate.js <baseline.html> <diff.txt>
```

Exit codes:
- `0` — clean (no protected keyword touched)
- `1` — protected keyword touched (forces RED)
- `2` — error (file not found, etc.)

## Trade-offs

**Gained:**
- Catches scope errors automatically
- Forces RED classification when warranted
- Auditable in the standing report

**Lost:**
- Maker can't claim "I know what I'm doing" and override the gate
- False positives are possible (e.g., a comment mentions a protected keyword) → would force RED when GREEN would be appropriate

**Mitigations for false positives:**
- The gate uses whole-word matching (`\bkeyword\b`), not substring
- Comments in code don't typically mention protected function names verbatim
- If a false positive occurs, the standing report's "WHY THIS LANE" sentence can override

## The role in the Flex Directive

The protected-keyword gate is one of three required gates in the Flex Directive:
1. **Self-check** (the smallest runnable check, per Ponytail)
2. **Protected-keyword gate** (this ADR)
3. **Audit formula** (for YELLOW+ changes)

Skipping any of the three = the change goes out under-verified. The Flex Directive is the policy; this ADR is the implementation detail for one of the three gates.

## When to revisit

This decision should be revisited if:
- False positives become common (e.g., comments mentioning protected keywords)
- The gate's regex matching becomes a bottleneck
- The methodology evolves beyond "protected keyword = RED"

## Related

- `scripts/protected-keyword-gate.js` — the gate
- `scripts/PROTECTED_KEYWORDS.js` — the input (derived artifact per ADR-0002)
- `examples/red-change.md` — uses the gate to force RED
- `methodology/flex-directive-v5.md` — the policy

## Evidence

The 76-error failure was the trigger. The recovery (Phase 3.5) introduced the gate. The Flex Directive v3-v5 formalized it as a required step. This ADR codifies the lesson: the gate is mandatory because self-classification is unreliable for protected-system work.

---

**Last updated:** 2026-06-21