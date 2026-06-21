---
name: gridnode-handoff-loader
description: >
  GRID//NODE handoff loader — on activation, checks if /workspace/.gridnode-handoff/
  is present. If not, runs bootstrap.sh to clone the handbook repo, install
  Ponytail skills, and read the locked state. Auto-activates on every new Mavis
  session where Pipe is the user.
---

# GRID//NODE Handoff Loader

This skill makes the GRID//NODE project state survive across Mavis sessions.

## The problem

Mavis's persistence model is per-session. Memory topics, files in `/workspace/`, and skill installations all die when the session ends. A new session starts cold.

For a long-running project like GRID//NODE (26+ hours of consolidation work, locked baseline, codified methodology), this is unacceptable. The work needs to be reachable from any new session.

## The solution

This skill auto-runs on session activation. It checks if the GRID//NODE handoff is loaded locally. If not, it runs the bootstrap script to fetch it.

## What it does on activation

1. **Check for handoff:** `ls /workspace/.gridnode-handoff/GRIDNODE_HANDOFF.md`
2. **If present:** read the handoff, print the locked state summary
3. **If missing:** run `bootstrap.sh` from the handoff repo (clones the repo, installs Ponytail skills, prints the locked state)
4. **Always:** print the current locked baseline (filename, SHA, size, live URL)
5. **Always:** print the available Mavis skills related to the project (Ponytail, this loader, etc.)

## What it does NOT do

- It does NOT modify any user files
- It does NOT push to GitHub
- It does NOT make any decisions about the project
- It does NOT override user_profile or other persistent state

It only loads. It does not act.

## When to use

Auto-activates for any session where Pipe is the user and the project context is relevant. The skill fires once per session, on first interaction, not on every message.

## What success looks like

After activation, the next message from the user can be any of:

- "What is the locked baseline?" → assistant knows the SHA
- "Add a feature to GRID//NODE" → assistant applies the Flex Directive
- "Run an audit" → assistant uses Ponytail methodology
- "What methodology should I use?" → assistant cites Ponytail + Flex Directive

If the assistant can answer these without the user pasting context, the skill worked.

## Manual activation

If auto-activation fails for any reason, run:

```bash
curl -s https://raw.githubusercontent.com/gridnodeinfra-network/gridnode-handbook/main/bootstrap.sh | bash
```

That command does what this skill does, manually.

## What this skill replaces

This skill replaces the need to:

- Paste a long context primer at the start of every chat
- Re-derive the methodology from memory
- Re-install Ponytail manually
- Ask "what's the locked state?" at the start of every session

If this skill is installed and the bootstrap repo is public, the project state is one command away from any new session.

## Failure modes

- **Network unavailable:** bootstrap fails. Fall back to user-paste of `GRIDNODE_HANDOFF.md`.
- **Bootstrap script broken:** try `bash -x bootstrap.sh` for verbose error.
- **Skills not detected after install:** check `ls /workspace/.skills/ponytail-*/SKILL.md` (should be 6 files).
- **Baseline SHA mismatch:** the locked file in `/workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED/` doesn't match `baseline.sha`. Either update the file or update the SHA — don't ship a mismatch.

## Source

The handoff repo: `https://github.com/gridnodeinfra-network/gridnode-handbook`

The Ponytail upstream: `https://github.com/DietrichGebert/ponytail`
