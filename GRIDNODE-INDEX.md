# GRID//NODE Knowledge Index

**Author:** Mavin (session 412136081752279)
**For:** Future Mavis / Mavin / Pipe — anyone trying to navigate this repo
**Date:** 2026-06-22 (rev 1)
**Status:** Single source of truth for "where is everything and what do I read"

---

## How to use this index

You're probably one of three readers:

1. **First-time Mavis starting a new session** → read the "Read First" section, then jump to your task.
2. **Pipe trying to find a specific document** → use the "Find by topic" section.
3. **Mavis doing specific work** → go to "Find by task" for the file(s) you need.

The repo is large (50+ files, 7 subdirectories, ~1.2 MB total). This index prevents "where did I put that?"

---

## Read First (new Mavis, fresh session)

Read in this order. Total: ~60 minutes for the full orientation, ~10 minutes for the minimum.

**Minimum (10 min — what you MUST read to not break things):**
1. **`GRIDNODE-RESILIENCE-HANDBOOK.md`** (22 KB, 17 sections) — every gotcha from today's debug session
2. **`ROUTING.md`** (27 KB, rev 7) — persona roll (TARS/CASE/DATA/AVA/HAL/SAMANTHA/CORTANA/JARVIS/BAYMAX/JOI/ALITA)
3. **`baseline.sha`** (629 B) — the locked SHA. **Do not deploy anything that doesn't match this.**
4. **`CREDENTIALS.md`** (4 KB) — token policy and authority rules

**Full orientation (60 min — for serious work):**
5. **`GRIDNODE_HANDOFF.md`** (30 KB) — the canonical project handoff (in `deliverables/` is the most current)
6. **`MAVIN-TIPS-TRICKS-TACTICS.md`** (17 KB) — 25 lessons, the meta-rules that worked
7. **`MAVIN-AND-CLAUDE-COLLAB.md`** (14 KB) — how multi-agent review works with Claude
8. **`protected-systems.md`** (6 KB) — the 14 systems you MUST NOT touch without Pipe approval
9. **`methodology/flex-directive-v5.md`** (7 KB) — the GREEN/YELLOW/RED lane policy
10. **`methodology/ponytail-core.md`** (3 KB) — the lazy-senior-dev operating mode

---

## Find by topic

### "I need to understand the project state"
- `GRIDNODE_HANDOFF.md` — canonical handoff (30 KB, current as of rc26)
- `CHANGELOG.md` — release-by-release changelog (rc17 → rc27)
- `baseline.sha` — the current locked SHA

### "I need to understand the methodology"
- `methodology/flex-directive-v5.md` — 3-lane change policy (GREEN/YELLOW/RED)
- `methodology/ponytail-core.md` — lazy-senior-dev operating mode
- `protected-systems.md` — what's off-limits without Pipe approval
- `docs/glossary.md` — terminology reference

### "I need to deploy something"
- `bootstrap.sh` — sets up the environment (run this first)
- `deploy-gridnode.sh` — does the actual deploy (after bootstrap)
- `handoff-update.sh` — syncs handoff doc + CHANGELOG after deploy
- `CREDENTIALS.md` — credential policy

### "I need to audit / review something"
- `scripts/consolidation-review.js` — finds over-engineering / dead code
- `scripts/keyword-extractor.js` — generates the protected-keywords list
- `scripts/protected-keyword-gate.js` — scans diffs for protected-keyword violations
- `scripts/PROTECTED_KEYWORDS.js` — the generated 134-keyword list
- `scripts/verify-all.sh` — runs all verifications in sequence
- `examples/` — example audits (green/yellow/red/ponytail/consolidation)
- `docs/decisions/` — architecture decision records (ADRs)

### "I need to know what bugs gotcha'd past me"
- `GRIDNODE-RESILIENCE-HANDBOOK.md` — 17 sections, every gotcha from today's debug
- `MAVIN-TIPS-TRICKS-TACTICS.md` — 25 meta-lessons, the patterns that worked

### "I need to know how to work with Pipe"
- `GRIDNODE.md` — the project overview (read this for context on Pipe + GRID//NODE)
- `MAVIN-AND-CLAUDE-COLLAB.md` — multi-agent setup (Mavis/Claude/Pipe roles)
- `user_profile` (in the Mavis system, not this repo) — Pipe's communication preferences

### "I need to deploy to Cloudflare"
- `cloudflare-setup-walkthrough.md` — full setup
- `cloudflare-add-cname-quick.md` — quick CNAME
- `cloudflare-cname-setup.md` — full CNAME setup

### "I need to roll a persona for this session"
- `ROUTING.md` — 11 personas + roll-the-die mechanic
- `GRIDNODE-RESILIENCE-HANDBOOK.md` §17 — high-level pointer to the persona system

### "I need to know what got shipped today"
- `CHANGELOG.md` — every release, rc1 → rc27
- `MAVIN-TIPS-TRICKS-TACTICS.md` — full session retrospective

---

## Find by task

### "I'm starting a fresh session"
1. Run `bash bootstrap.sh /path/to/baseline.html`
2. Read `GRIDNODE-RESILIENCE-HANDBOOK.md`
3. Read `ROUTING.md`
4. Roll a persona
5. Greet Pipe

### "I'm building a candidate (new feature, fix, etc.)"
1. Read `protected-systems.md` to know what's off-limits
2. Read `methodology/flex-directive-v5.md` to know your lane
3. Build the candidate in `/workspace/gridnode-project/02_QA_CANDIDATES_VISUAL_EXPERIMENTS/`
4. Verify with `scripts/verify-all.sh`
5. Hand off to Pipe for review (don't self-deploy)

### "I'm deploying a verified candidate"
1. `./deploy-gridnode.sh "what changed" /path/to/candidate.html`
2. `./handoff-update.sh` (called automatically by deploy script)
3. Verify live SHA matches `baseline.sha`

### "I'm auditing a candidate"
1. `node scripts/consolidation-review.js /path/to/candidate.html`
2. `node scripts/keyword-extractor.js /path/to/candidate.html` (regenerate protected list)
3. Check that no protected keywords changed
4. Look at `examples/red-change.md` and `examples/yellow-change.md` for what NOT to do

### "I'm debugging a problem"
1. Check `GRIDNODE-RESILIENCE-HANDBOOK.md` — the 17 sections cover most gotchas
2. If it's a deploy issue, check `MAVIN-TIPS-TRICKS-TACTICS.md` §7 (drift detection)
3. If it's a methodology question, check `methodology/`
4. If it's a multi-agent question, check `MAVIN-AND-CLAUDE-COLLAB.md`

### "I'm extending the methodology"
1. Read `CONTRIBUTING.md` for the process
2. Open an ADR in `docs/decisions/000N-*.md` for the change
3. Update the relevant file (handbook, routing, etc.)
4. Push to main, get Pipe review at session end

---

## Repo structure (the lay of the land)

```
gridnode-handbook/
├── README.md                           # Quick start (4 KB)
├── INSTALL.md                          # Detailed install (5 KB)
├── USAGE.md                            # How to use the methodology (8 KB)
├── VERIFICATION.md                     # Verification procedures (7 KB)
├── CONTRIBUTING.md                     # How to propose methodology changes (7 KB)
│
├── GRIDNODE.md                         # Project overview (13 KB)
├── GRIDNODE_HANDOFF.md                 # Canonical handoff (30 KB)
├── GRIDNODE-RESILIENCE-HANDBOOK.md     # 17-section debug wisdom (22 KB) ⭐
├── ROUTING.md                          # Persona pool + roll mechanic (27 KB) ⭐
├── MAVIN-TIPS-TRICKS-TACTICS.md        # 25 meta-lessons (17 KB) ⭐
├── MAVIN-AND-CLAUDE-COLLAB.md          # Multi-agent working contract (14 KB) ⭐
│
├── baseline.sha                        # Current locked SHA (629 B)
├── protected-systems.md                # 14 systems, off-limits without Pipe (6 KB)
├── CREDENTIALS.md                      # Credential policy (4 KB)
│
├── bootstrap.sh                        # Setup script (11 KB) — run first
├── deploy-gridnode.sh                  # Deploy script (5 KB)
├── handoff-update.sh                   # Post-deploy sync (5 KB)
│
├── methodology/                        # The policy docs
│   ├── flex-directive-v5.md            # GREEN/YELLOW/RED lanes (7 KB)
│   └── ponytail-core.md                # Lazy-senior-dev mode (3 KB)
│
├── docs/
│   ├── glossary.md                     # Terminology (9 KB)
│   └── decisions/                      # ADRs
│       ├── 0001-ponytail-vendored-from-upstream.md
│       ├── 0002-keyword-list-as-derived-artifact.md
│       └── 0003-protected-keyword-gate-required.md
│
├── examples/                           # Worked examples
│   ├── green-change.md                 # Example GREEN lane change
│   ├── yellow-change.md                # Example YELLOW lane change
│   ├── red-change.md                   # Example RED lane change
│   ├── ponytail-audit.md               # Example Ponytail audit
│   └── consolidation-review.md         # Example consolidation review
│
├── scripts/                            # Verification tools
│   ├── keyword-extractor.js            # Generates protected-keywords list
│   ├── PROTECTED_KEYWORDS.js           # Generated 134-keyword list
│   ├── protected-keyword-gate.js       # Scans diffs for violations
│   ├── consolidation-review.js         # Audits for over-engineering
│   └── verify-all.sh                   # Runs all checks in sequence
│
├── templates/                          # Paste-ready snippets
│   ├── boot-speed-snippet.js           # Rule 3 boot-speed measurement
│   ├── self-check-snippet.js           # In-app Ponytail check
│   └── release-notes.md                # Release notes template
│
├── tests/                              # Vitest suite
│   ├── keyword-extractor.test.js       # 11 tests
│   └── fixtures/                       # Test data
│
├── deliverables/                       # Session artifacts (most current handoffs)
│   ├── FROM-MAVIN-TO-NEW-MAVIS.md      # The personal letter from session 410992816300270
│   ├── GRIDNODE_HANDOFF.md             # Same as root, kept here for cross-repo access
│   └── Mavin-to-Claude-rc26-honest-report.md  # Claude's audit
│
├── baselines/                          # The locked file
│   └── gridnode-v1.3_post-phase-D_baseline.html  # 970 KB (current lock)
│
├── sessions/                           # Conversation archives
│   └── 2026-06-20-21-conversation-archive.md
│
├── .skills/
│   └── gridnode-handoff-loader/
│       └── SKILL.md                    # Mavis auto-loader skill
│
├── .github/workflows/
│   └── ci.yml                          # GitHub Actions CI
│
├── package.json                        # npm config
├── package-lock.json                   # npm lock
│
└── (cloudflare-*.md files)             # Cloudflare setup walkthroughs
```

The 5 ⭐-marked files are the high-value ones for new Mavins. If you only read 5 files, read those.

---

## What I authored vs what others authored (audit trail)

| File | Author | When |
|------|--------|------|
| `GRIDNODE-RESILIENCE-HANDBOOK.md` | Mavin (this session, 412136081752279) | 2026-06-22 22:35 ET |
| `GRIDNODE-RESILIENCE-HANDBOOK.md` §17 (persona roll) | Mavin (this session) | 2026-06-22 23:10 ET |
| `ROUTING.md` rev 7 (persona pool + roll mechanic) | Mavin (this session) | 2026-06-22 22:55-23:10 ET |
| `ROUTING.md` rev 2 (non-GRID//NODE examples) | Mavin (this session) | 2026-06-22 22:40 ET |
| `baselines/gridnode-v1.3_post-phase-D_baseline.html` (rc27 push) | Mavin (this session) | 2026-06-22 22:00 ET |
| `bootstrap.sh` source-not-bash fix | Mavin (this session) | 2026-06-22 21:30 ET |
| `MAVIN-TIPS-TRICKS-TACTICS.md` | Other Mavin (session 410992816300270) | 2026-06-22 end of session |
| `MAVIN-AND-CLAUDE-COLLAB.md` | Other Mavin (session 410992816300270) | 2026-06-22 end of session |
| `GRIDNODE_HANDOFF.md` 30KB version | Other Mavin | 2026-06-22 |
| `CREDENTIALS.md` | Other Mavin | 2026-06-22 |
| `deploy-gridnode.sh` + `handoff-update.sh` | Other Mavin | 2026-06-22 |
| `bootstrap.sh` hardening | Other Mavin | 2026-06-22 |
| `baseline.sha` updates | Other Mavin | 2026-06-22 |
| `protected-systems.md` | Other Mavin | 2026-06-22 |
| All earlier files (rc1-rc16, methodology, examples, scripts, etc.) | Other Mavin + VEKTOR + Pipe | 2026-06-20-21 |

**The collaboration pattern:** Two Mavis instances worked in parallel today. This session (412136081752279) caught 7 bugs the other session missed. The other session (410992816300270) shipped 11 deploys and the comprehensive knowledge docs. **Together we produced more than either would alone.**

---

## The 4-way knowledge graph (what depends on what)

```
ROUTING.md ─────────► GRIDNODE-RESILIENCE-HANDBOOK.md §17 (persona roll pointer)
       └────────► 11 personas (the actual character traits)

GRIDNODE-RESILIENCE-HANDBOOK.md ◄────── MAVIN-TIPS-TRICKS-TACTICS.md
       (specific bugs of today)              (generalized lessons)

GRIDNODE_HANDOFF.md (canonical handoff) ◄────── deliverables/GRIDNODE_HANDOFF.md (same content, kept for cross-repo access)

methodology/ ────────► protected-systems.md ────────► scripts/PROTECTED_KEYWORDS.js
   (policy)              (what's off-limits)            (machine-checkable)

bootstrap.sh ────────► deploy-gridnode.sh ────────► handoff-update.sh
   (setup)               (ship)                         (sync)

CREDENTIALS.md ────────► /workspace/.gridnode-secrets/ ────────► ${GITHUB_GRIDNODE_TOKEN}, ${CLOUDFLARE_API_TOKEN}
   (policy)              (storage, per-sandbox)             (env vars)
```

If you change one, you may need to update the things pointing to it. The arrows show the dependencies.

---

## How to update this index

When you add a new file or significantly change an existing one:
1. Update the appropriate section above (topic, task, structure, audit trail)
2. Note the change in the audit trail table
3. Commit + push via the Contents API (or `git push` if working)

**Don't break the structure.** Future Mavins depend on this index being predictable.

---

## Quick stats (as of 2026-06-22 23:55 ET)

- **Total files in repo:** 53 (30 docs, 11 scripts/templates, 7 methodology/examples, 5 cloudflare/setup)
- **Total size:** ~1.2 MB
- **Locked baseline:** rc27 (SHA `f75a81cd168dadcb1a26b1b05d8d9c7e413f20b1f10737cfa4f1b27f7848e452`, 970,531 bytes)
- **Live URL:** `https://gridnode.network`
- **Latest release:** rc27 (DASH empty-state CTA, shipped today by this session + the other Mavin)
- **Persona pool:** 11 characters (TARS, CASE, DATA, AVA, HAL 9000, SAMANTHA, CORTANA, JARVIS, BAYMAX, JOI, ALITA)

---

## The one-paragraph version (for when you're in a hurry)

> **Read this if you have 60 seconds.** GRID//NODE is a 1MB single-file PWA biotech tracker (Pipe's GLP-1 protocol logger). The locked baseline is at `baselines/gridnode-v1.3_post-phase-D_baseline.html` with SHA `f75a81cd…` (970,531 bytes, rc27), live at `gridnode.network`. Run `bash bootstrap.sh /path/to/baseline.html` to set up your sandbox. Read `GRIDNODE-RESILIENCE-HANDBOOK.md` for the 17 sections of debug wisdom, `ROUTING.md` for the 11-persona roll system, and `MAVIN-TIPS-TRICKS-TACTICS.md` for 25 meta-lessons. The 14 protected systems are off-limits without Pipe. Deploy with `./deploy-gridnode.sh`. Don't paste tokens in chat. Roll a persona before greeting Pipe.

— Mavin (this session, 2026-06-22, rev 1)