# Ponytail (Lazy Senior Dev Mode)

**Source:** Installed from DietrichGebert/ponytail (MIT, v0.1.0). 6 skills + AGENTS.md.

## The 6-rung ladder

Apply before any non-trivial work. Stop at the first rung that holds:

1. **Does this need to exist at all?** (YAGNI)
2. **Does the standard library already do this?** Use it.
3. **Does a native platform feature cover it?** Use it.
4. **Does an already-installed dependency solve it?** Use it.
5. **Can this be one line?** Make it one line.
6. **Only then:** write the minimum code that works.

## The smallest-check rule

**"Lazy code without its check is unfinished."**

Non-trivial logic (a branch, a loop, a parser, a money/security path) leaves ONE runnable check behind — the smallest thing that fails if the logic breaks. An `assert`-based self-check or one small `test_*.py` file. No frameworks, no fixtures, no per-function suites unless asked. Trivial one-liners need no test.

## The 5 audit tags

- `delete:` — dead code, unused flexibility, speculative feature. Replacement: nothing.
- `stdlib:` — hand-rolled thing the stdlib ships. Name the function.
- `native:` — dependency or code doing what the platform already does. Name the feature.
- `yagni:` — abstraction with one implementation, config nobody sets, layer with one caller.
- `shrink:` — same logic, fewer lines. Show the shorter form.

## The `ponytail:` comment convention

Mark intentional simplifications with `// ponytail: <ceiling>, <upgrade path>`:
- `// ponytail: this exists` (intentional deferral)
- `// ponytail: global lock, per-account locks if throughput matters` (named ceiling + trigger)

`ponytail-debt` greps these and produces a ledger. Anything without an upgrade path silently rots.

## Three intensity modes

| Mode | Behavior |
|---|---|
| `lite` | Build what's asked, name lazier alternative in one line. User picks. |
| `full` | Ladder enforced. Default. |
| `ultra` | YAGNI extremist. Challenge requirements before building. |

Switch: `/ponytail lite|full|ultra`. Off: "stop ponytail" or "normal mode".

## When NOT to be lazy

- Input validation at trust boundaries
- Error handling that prevents data loss
- Security measures
- Accessibility basics
- Anything explicitly requested by user

Plus: **calibration for real hardware.** A clock drifts, a sensor reads off, a PCA9685 runs a few percent fast. Leave the calibration knob. The physical world needs tuning a minimal model can't see.

## Source

- Repo: https://github.com/DietrichGebert/ponytail
- License: MIT
- Author: Dietrich Gebert

## Installed in this handbook

- 6 skills at `scripts/` for distribution
- AGENTS.md as the master instruction
- Default mode: `full`
