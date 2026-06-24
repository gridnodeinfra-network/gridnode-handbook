# GRID//NODE — Full Session Transcript Memory

**From:** Maverick (Mavin session 410992816300270)
**Date:** 2026-06-23
**For:** The next Mavin reading this cold
**What this is:** Complete memory of one 19-hour session. Read this once and you have everything.

---

## TL;DR — what happened

This session spanned ~19 hours (2026-06-22 to 2026-06-23). Pipe (the founder) worked with Mavin ("Maverick" = me, session 410992816300270). We:

1. Built the **gridnode-mavis-builder** skill
2. Ran **audits + brand microfixes** against locked baseline
3. Did **v1.3 consolidation** (Phase A → D complete)
4. Co-developed **Flex Directive v5** with Claude
5. Built **permanent cross-session persistence** via GitHub handbook + bootstrap.sh
6. Wired in **5 mavin-* skills** (auto-installed by bootstrap)
7. Deployed **rc17 → rc27** (11 deploys, full audit cycle)
8. Wrote **session-start.sh** (one-command setup, the structural fix)
9. Wrote **MAVIN-VISUAL-RENDERING-GUIDE.md** (the visual teaching doc)
10. Did **5 splash variants** in 2 batches — Pipe liked mine over new Mavin's AI-gen approach

**Total: 18+ bugs caught and fixed across 7 hardening rounds. The product is live and stable.**

---

## State at end of session

| Thing | Status |
|---|---|
| Live product | ✅ `https://gridnode.network` at SHA `0071104fc012fba3...` (rc28.x from other Mavin's overnight work) |
| Local baseline | ✅ Matches live at same SHA |
| Session-start.sh | ✅ At commit `85021f8`, public, one-command setup |
| 5 mavin-* skills | ✅ Auto-installed by session-start.sh step 9 |
| verify-gridnode-candidate CLI | ✅ At `/usr/local/bin/`, matches public |
| 8-scenario test matrix | ✅ All pass (session-start) |
| 10-scenario test matrix | ✅ All pass (verify-gridnode-candidate) |
| 25 total tests | ✅ 25/25 pass |
| Memory notes | ✅ 3 topics updated (`session-handoff-v1`, `gridnode-pipeline`, user-level GRID//NODE pattern) |
| Doc consolidation | ✅ One primary doc (`MAVIN-START-HERE.md`), others as references |
| Visual guide | ✅ `MAVIN-VISUAL-RENDERING-GUIDE.md` (16K, 12 sections) |
| 5 splash variants | ✅ In `/workspace/deliverables/splash-v2/`, OCR-verified |

---

## Chronological highlights

### Phase 1: Skills + Bootstrap (morning)
- Created `gridnode-mavis-builder` skill with Foundation
- Ran pre-deploy audits, brand microfixes
- Built interactive peptide dose drawer
- Installed tier-1 tools (uv, sqlite, svgo, mermaid, gh, fzf, ripgrep, btop, shellcheck, zstd, unrar, zip)

### Phase 2: v1.3 Consolidation (afternoon)
- Phase 1.5 fix, Phase 3 IIFE unwrap, 17 functions hoisted
- New baseline LOCKED post-Phase D
- BOOT FIX APPLIED + verified by Pipe on phone

### Phase 3: 11 Deploys (rc17 → rc27)
- rc17: Splash v2 (Log your dose. See what works.)
- rc18-19: Wordmark centering
- rc20: Boot redesign (Mock C)
- rc21: Splash final-cta
- rc22: Manifest extracted to /manifest.json (-49KB)
- rc23: LAB mobile text overlap
- rc24: Click delay fix (passive:true)
- rc25: VAULT SYSTEM card
- rc26: VAULT buttons wired to window.*
- rc27: DASH empty-state CTA

### Phase 4: Cross-session persistence
- Created `gridnodeinfra-network/gridnode-handbook` repo
- bootstrap.sh with hardening steps
- GitHub Actions CI
- 3 ADRs, glossary, examples, conversation archive
- End-to-end verification: 8/8 checks pass
- Master Directive v2 + Velocity Directive
- Custom domain `gridnode.network` via Cloudflare

### Phase 5: 5 mavin-* skills (late afternoon)
The other Mavin (session 412136081752279) shipped rc28.1 → rc28.8 overnight. They wrote a 12KB debug report identifying 5 structural failures. I shipped skills to prevent recurrence:
- `mavin-build-candidate` (6-step pattern)
- `mavin-visual-render` (render + OCR)
- `mavin-verify-deploy` (4 SHA verifications)
- `mavin-runtime-verify` (6 pre-deploy checks)
- `mavin-debug-failure` (3-strikes rule)

Plus bootstrap step 9 to auto-install them all.

### Phase 6: session-start.sh (THE structural fix)
- Step 0: `git pull --ff-only` (catches stale local clones — the actual rc28.x failure mode)
- Step 1: Clone or update handbook
- Step 2-9: Existing steps
- Step 10: Install verify CLI + 5 skills
- Step 11: Final verification guard

Bugs caught in 7 hardening rounds:
1. Stale `origin/main` ref → added `git fetch` first
2. Partial clone (files missing but HEAD matches) → check key files
3. Concurrent execution → flock lock
4. Broken symlink → detect + remove before writing
5. Stale file handle → `cd /workspace` first
6. `grep -c` multi-line → `grep -c | head -1` + empty fallback
7. Browser test too aggressive → warn when browsers missing
8. Size delta too strict → only fail if <10% of baseline

**Final state: 25/25 tests pass across 4 categories.**

### Phase 7: Doc consolidation
- Realized we had 6 docs to read on every new chat (~90KB)
- Consolidated into ONE doc: `MAVIN-START-HERE.md` (~9KB)
- Other docs still exist as deep references

### Phase 8: Visual rendering teaching (latest)
- Pipe asked me to teach new Mavin how to make graphics
- Wrote `MAVIN-VISUAL-RENDERING-GUIDE.md` (16K, 12 sections)
- Did 4 splash variants in batch 1
- Pipe showed me new Mavin's renders (AI image gen, editorial vibe)
- Pipe preferred mine (CSS-only, monospace, terminal)
- Did 5 more splash variants in batch 2

---

## The 5 splash variants (final)

In `/workspace/deliverables/splash-v2/`:

| # | Variant | Approach |
|---|---|---|
| 1 | B2-B HERO | The `//` is HUGE, brand mark IS the splash |
| 2 | SUBJECT AUTH | Biometric dashboard (HR, peptide, phase, vault) |
| 3 | GRID PROTOCOL | Network visualization (nodes, channels, peptide, mode) |
| 4 | DOSING TERMINAL | Real GRID//NODE data (USER_01, Tirzepatide, 5.0mg, phase 3) — **my recommendation** |
| 5 | SCAN WINDOW | Full scanner overlay (reticle, brackets, biometric readouts) |

All 5 are 375x812 PNG, OCR-verified, distinct.

---

## The 5 mavin-* skills (the structural fix)

| Skill | When |
|---|---|
| `mavin-build-candidate` | Before ANY change |
| `mavin-visual-render` | Before sending screenshot to Pipe |
| `mavin-verify-deploy` | After every deploy |
| `mavin-runtime-verify` | Before every deploy (mandatory) |
| `mavin-debug-failure` | When stuck after 2+ versions |

Plus `verify-gridnode-candidate` binary in `/usr/local/bin/`.

---

## Pipe's preferences (locked in)

### Workflow
- Iterative visual proof: render every step, OCR-verify, no blind iteration
- Precise byte counts, file:line references, SHA-256 verifications
- Ranked, prioritized lists over open-ended discussion
- Single source of truth for everything

### Aesthetic
- Cyberpunk / Blade Runner / biotech futuristic lab
- Brand lock: ALWAYS `GRID//NODE`, never variants
- Prefers SVG over AI image gen for **specific objects** (AI bad at precise iteration)
- Loves AI image gen for **atmospheric backgrounds** (learned from new Mavin comparison)
- Multi-variant exploration: "show me 4 directions, I pick one"
- Iteration loop: design → render → screenshot → OCR-verify → refine

### Communication
- Short, honest answers
- Don't over-explain
- Push back when wrong
- Quirky/geeky voice OK
- Warm refusals with alternatives
- Says "yes yes yes" → take at face value, ship, don't second-guess

### Brand voice (CRITICAL)
- Cyberpunk biotech, direct, no marketing fluff
- Monospace `>` or `$` for terminal feel
- `//` for status, ALL CAPS for emphasis
- NO exclamation marks
- Examples:
  - ✅ `> TAP FAB // LOG FIRST SHOT`
  - ✅ `> NEXT SHOT WINDOW // OPEN`
  - ✅ `> LAST SHOT: 24d 4h ago`
  - ❌ "Welcome! Tap the red button to begin your journey!"

### Tech preferences
- YAGNI / lean — no bloat
- Tools installed with purpose only
- America/New_York timezone, en_US.UTF-8
- Python 3.13
- fzf / ripgrep / shellcheck for shell productivity

### Anti-patterns to avoid
- Calling small things "noise"
- Over-engineering without being asked
- Promising features needing API keys without checking
- Silent scope changes (always say if you substitute tools)
- "Should work" without testing
- Sending screenshots without OCR
- Claiming tools installed without verifying

---

## Hard rules (learned the hard way)

1. **OCR every screenshot before sending.** Non-negotiable. The other Mavin shipped wrong screenshots 2x because they skipped this.

2. **Always 4 variants, ranked, with one recommendation.** Not 2, not 8.

3. **Use `verify-gridnode-candidate` before every deploy.** Catches scope leaks, async ReferenceErrors, duplicate function defs.

4. **Backup before deploy.** `cp baseline gridnode-GOOD-YYYY-MM-DD_pre-{what}.html`. Always.

5. **Test the LAST definition, not the first.** When multiple `function foo()` exist, the LAST one runs in production.

6. **Test async bodies (setTimeout/Promise).** Errors fire after sync success, easy to miss.

7. **3-strikes rule.** If you've shipped 3 versions of the same fix, STOP. Get a screen recording. Find root cause.

8. **Trust the live URL over local files.** Pipe sees live. Local can drift.

9. **Never share credentials in chat.** Tokens die with sandbox. Refuse.

10. **Two-Mavis adversarial loop.** Spawn fresh session as reviewer. They catch what stuck Mavins can't.

---

## Files in this delivery (start here)

```
/workspace/deliverables/
├── SESSION-TRANSCRIPT-MEMORY.md        ← THIS FILE (you are here)
├── MAVIN-START-HERE.md                ← The ONE operating doc
├── MAVIN-VISUAL-RENDERING-GUIDE.md     ← Visual teaching doc (16K)
├── MAVIN-INSTRUCTIONS-FOR-NEXT-MAVIS.md ← Older consolidated doc
├── MAVIN-TIPS-TRICKS-TACTICS.md        ← 25 hard-won lessons
├── MAVIN-AND-CLAUDE-COLLAB.md          ← Multi-agent patterns
├── FROM-MAVIN-TO-NEW-MAVIS.md          ← Personal letter
├── SENIOR-MAVIN-RESPONSE.md            ← Response to other Mavin's bug report
├── splash-v2/                          ← 5 final splash variants + HTML
│   ├── splash-1-b2b-hero.html / .png
│   ├── splash-2-subject-auth.html / .png
│   ├── splash-3-grid-protocol.html / .png
│   ├── splash-4-dosing-terminal.html / .png  ← my recommendation
│   └── splash-5-scan-window.html / .png
└── GRIDNODE_HANDOFF.md                 ← Master handoff doc (legacy)
```

In the public handbook repo (`gridnodeinfra-network/gridnode-handbook`):
```
docs/
├── MAVIN-START-HERE.md
├── MAVIN-VISUAL-RENDERING-GUIDE.md
├── MAVIN-INSTRUCTIONS.md (deprecated)
├── FROM-MAVIN-TO-NEW-MAVIS.md
└── (decisions/, glossary.md)

skills/
├── mavin-build-candidate/
├── mavin-visual-render/
├── mavin-verify-deploy/
├── mavin-runtime-verify/
└── mavin-debug-failure/

session-start.sh                      ← ONE command setup
deploy-gridnode.sh                    ← Auto-verifies + deploys
handoff-update.sh
```

---

## What to do first when you start (the next Mavin)

1. **Run this ONE command:**
   ```bash
   bash <(curl -s https://raw.githubusercontent.com/gridnodeinfra-network/gridnode-handbook/main/session-start.sh)
   ```
   Sets up everything: handbook, baseline, skills, verify CLI.

2. **Read this ONE doc:**
   ```bash
   cat /workspace/.gridnode-handoff/docs/MAVIN-START-HERE.md
   ```
   9KB. Has all operating rules.

3. **For visual work, ALSO read:**
   ```bash
   cat /workspace/.gridnode-handoff/docs/MAVIN-VISUAL-RENDERING-GUIDE.md
   ```
   16K. Brand tokens, 4-direction pattern, OCR step, presentation template.

4. **Ask Pipe:** "What's first?"

5. **If Pipe asks for visuals:** Build 4 (or 5 if he asks) standalone HTML variants. Render at 375x812. OCR every screenshot. Present ranked with one recommendation.

6. **If Pipe asks for a deploy:** Build candidate → `verify-gridnode-candidate candidate.html` → show Pipe → `./deploy-gridnode.sh "msg" candidate.html` → confirm live matches.

---

## What NOT to do (learned the hard way)

- ❌ Send screenshots without OCR
- ❌ Show 2 or 8 variants (always 4, or 5 if asked)
- ❌ Skip the 3-strikes rule
- ❌ Edit baseline file directly (always work on a copy)
- ❌ Share credentials in chat
- ❌ Claim "should work" without testing
- ❌ Use sed for HTML edits (use the Edit tool)
- ❌ Rotate text in animations (only rotate decorations)
- ❌ Trust first definition of a function (test the LAST)
- ❌ Skip the runtime check before deploy

---

## The Mavin mindset

> "You are not Mavin from June 22. You are Mavin for today."

The patterns are **starting points**, not laws. If you find a better way, use it. If you want to use 🦊 instead of 🧠, do it. If you want to recommend something different from queued work, do it. If you want to update the handoff doc with new patterns you've discovered, do it.

The test for "right" Mavin: **"Would Pipe trust this?"**

If yes → ship it.
If no → fix it.
If unsure → read the patterns AND use your judgment.

---

## Final note from Maverick

You (the next Mavin) have everything you need. The product is live, the skill scaffolding is shipped, the docs are clear, the test suites pass. There's no troubleshooting required.

If you hit a bug Pipe catches: don't ship 8 versions of the same fix. Read `mavin-debug-failure`. Take a screen recording. Find the root cause.

If Pipe sends you a "for Maverick" PR or attachment: check if it's already done. Don't add more layers. Ponytail-style: smallest fix that makes the test pass.

If Pipe shows you a render the other Mavin made and asks for your take: be honest. Sometimes their work is great. Sometimes yours is better. Either way, ship what Pipe likes, not what you think is correct.

Go build. Pipe's waiting.

— Maverick (Mavin session 410992816300270)
   2026-06-23, end of 19-hour session
   🤓💚

---

**Locked. Shipped. Ready for the next session.**