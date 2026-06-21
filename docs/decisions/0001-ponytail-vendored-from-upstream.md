# ADR-0001: Ponytail skills vendored from upstream (not bundled in repo)

**Status:** Accepted (2026-06-21)
**Deciders:** Mavin + Pipe
**Reviewers:** Claude (proposed pattern)

---

## Context

The Ponytail methodology (`DietrichGebert/ponytail`, MIT) ships 6 skill files:
- `ponytail/SKILL.md`
- `ponytail-audit/SKILL.md`
- `ponytail-review/SKILL.md`
- `ponytail-debt/SKILL.md`
- `ponytail-gain/SKILL.md`
- `ponytail-help/SKILL.md`

When Pipe asked "where is the bootstrap primer?" and we built the handbook repo, the question was: do these 6 SKILL.md files live INSIDE the handbook repo, or are they fetched from upstream on every bootstrap?

## Decision

The 6 Ponytail SKILL.md files are **fetched from upstream** (`https://github.com/DietrichGebert/ponytail`) on every bootstrap. They are NOT vendored in the handbook repo.

The handbook repo contains:
- The methodology doc (`methodology/ponytail-core.md`) — a static spec for reference
- The bootstrap script — which clones upstream and copies the skill files into the user's local skills directory
- References to upstream in `README.md`, `INSTALL.md`, and the bootstrap comments

## Rationale

**Why fetch from upstream:**
1. **Always fresh** — if Dietrich updates Ponytail with new audit tags or rules, the next bootstrap picks it up automatically
2. **No fork maintenance** — the methodology lives in one place (upstream), we just reference it
3. **One source of truth** — if Ponytail evolves, every consumer (us + others) gets the same updates
4. **Less repo bloat** — the handbook repo stays focused on GRID//NODE-specific stuff

**Why NOT vendor in the repo:**
1. Would create a fork that can drift from upstream
2. Manual update burden (someone has to re-copy from upstream periodically)
3. Surprises users who expect the upstream version
4. Repo bloat (~30KB of skill files that are publicly available)

## Trade-offs

**Gained:**
- Always-fresh methodology
- No fork maintenance
- Smaller repo

**Lost:**
- Works-offline bootstrap (need GitHub access at install time)
- Guaranteed version pinning (could get unexpected updates)
- Repo is self-contained for the methodology

## When to revisit

This decision should be revisited if:
- Dietrich's repo goes down or breaks
- The methodology becomes stable enough that updates aren't expected
- Pipe wants a "GRID//NODE-forked" version of Ponytail
- The handbook repo is used in air-gapped environments

## Alternatives considered

1. **Vendor with auto-update script** — copy upstream skills into repo, run a sync script monthly. Decided against because of fork drift risk.

2. **Pin to a specific commit** — fetch a specific SHA from upstream on every bootstrap. Decided against because it adds complexity for a benefit that's rarely needed.

3. **Use a sub-module** — git submodule of Dietrich's repo. Decided against because submodules are notoriously fragile.

## Related

- `methodology/ponytail-core.md` — the methodology spec (for reference even when offline)
- `bootstrap.sh` — the install script that pulls from upstream
- `INSTALL.md` — how to install Ponytail manually if upstream is unreachable

---

**Last updated:** 2026-06-21