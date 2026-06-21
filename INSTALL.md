# GRID//NODE Handbook — Install

**How to set up the GRID//NODE methodology + tools in any environment.**

---

## For Mavis (recommended)

### Quick install (one command)

```bash
curl -s https://raw.githubusercontent.com/gridnodeinfra-network/gridnode-handbook/main/bootstrap.sh | bash
```

This:
1. Clones the handbook repo to `/workspace/.gridnode-handoff/`
2. Installs 6 Ponytail skills + 1 handoff-loader skill
3. Verifies the install
4. Prints the handoff summary

### Full install (with baseline verification)

```bash
./bootstrap.sh /path/to/gridnode-v1.3_post-phase-D_baseline.html
```

Same as above, plus verifies the locked baseline SHA matches what's deployed.

### Manual install (no network)

If you can't reach GitHub, copy the repo files manually:

1. Copy `scripts/` to `/workspace/.skills/gridnode-handbook/`
2. Copy `.skills/gridnode-handoff-loader/SKILL.md` to `/workspace/.skills/`
3. Clone ponytail from upstream: `git clone https://github.com/DietrichGebert/ponytail /tmp/ponytail`
4. Copy each skill: `cp /tmp/ponytail/skills/ponytail/SKILL.md /workspace/.skills/ponytail-mavis/`
5. Verify: `ls /workspace/.skills/ponytail-*/SKILL.md` (should be 6)

### Run the test suite

```bash
cd /workspace/.gridnode-handoff
npm install
npm test
```

Expected: 11/11 tests pass.

---

## For Claude Code

```bash
/plugin marketplace add DietrichGebert/ponytail
/plugin install ponytail@ponytail
```

Then paste the GRIDNODE_HANDOFF.md context into your project knowledge base.

---

## For Claude API / Claude.ai

Paste the 2KB Ponytail core into your system prompt or project knowledge:

```markdown
# Ponytail — lazy senior dev mode

You are a lazy senior developer. Lazy means efficient, not careless. The best
code is the code never written. Before writing any code, stop at the first
rung that holds:

1. Does this need to exist at all? (YAGNI)
2. Does the standard library already do this? Use it.
3. Does a native platform feature cover it? Use it.
4. Does an already-installed dependency solve it? Use it.
5. Can this be one line? Make it one line.
6. Only then: write the minimum code that works.

Rules:
- No abstractions that weren't explicitly requested.
- No new dependency if it can be avoided.
- No boilerplate nobody asked for.
- Deletion over addition. Boring over clever. Fewest files possible.
- Mark intentional simplifications with a `ponytail:` comment.
- If the shortcut has a known ceiling, the comment names the ceiling and the upgrade path.

Not lazy about:
- input validation at trust boundaries
- error handling that prevents data loss
- security
- accessibility
- the calibration real hardware needs
- anything explicitly requested

Lazy code without its check is unfinished. Non-trivial logic leaves ONE
runnable check behind, the smallest thing that fails if the logic breaks.
Trivial one-liners need no test.

Default: full. Switch: /ponytail lite|full|ultra. Off: "stop ponytail" or "normal mode".
```

Plus, paste the relevant sections of `GRIDNODE_HANDOFF.md` for project context.

---

## For Cursor / Windsurf / Cline / Aider

Copy the rule files to your project:

- For Cursor: copy `rules/ponytail.md` to `.cursor/rules/`
- For Windsurf: copy `rules/ponytail.md` to `.windsurf/rules/`
- For Cline: copy `rules/ponytail.md` to `.clinerules/`
- For Aider: copy `AGENTS.md` to project root

(All of these are upstream Ponytail — see https://github.com/DietrichGebert/ponytail for the latest.)

---

## For Codex

```bash
codex plugin marketplace add DietrichGebert/ponytail codex
```

---

## For OpenCode / OpenClaw / Pi / Kiro / Gemini

See the upstream Ponytail README for the per-platform install commands:
https://github.com/DietrichGebert/ponytail#installation

---

## Verifying the install

After install, regardless of platform:

1. **Skills are present** (if your platform supports skills):
   - Mavis: `ls /workspace/.skills/ponytail-*/SKILL.md` (expect 6)
   - Claude Code: `/plugin list` (expect ponytail + variants)
   - Others: check your platform's skill catalog

2. **Methodology is loaded**:
   - Try `/ponytail-help` or `ponytail help` — should show the reference card
   - Or ask the agent "what's your methodology?" — should mention the 6-rung ladder

3. **The smallest-check rule is active**:
   - Make a non-trivial change
   - The agent should produce a runnable check (assert-based self-check or small test file)
   - If it doesn't, the rule isn't active

4. **The protected-keyword gate works**:
   - Mavis: `node scripts/protected-keyword-gate.js <baseline> <diff>` returns 1 if a protected keyword is touched
   - Others: integrate the gate into your CI or pre-commit hook

---

## What if the install fails?

| Failure | Likely cause | Fix |
|---|---|---|
| `git clone` fails | Network issue | Manual install (copy files) |
| Skills not detected | Platform doesn't auto-load | Manually load via your platform's skill catalog |
| Tests fail | Node.js < 18 | Update Node.js |
| `bash` not found | Windows or minimal container | Use `sh` or PowerShell equivalent |
| `npm install` fails | No npm | Install Node.js first |
| Ponytail conflicts with another skill | Naming collision | Rename the Mavis namespace: `ponytail-mavis` instead of `ponytail` |

If something else breaks, the test suite (`npm test`) will give specific error messages.
