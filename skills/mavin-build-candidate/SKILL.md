---
name: mavin-build-candidate
description: >
  Use this skill when Mavin needs to build a candidate HTML file from the
  locked baseline. The pattern: copy baseline → apply specific edits → 
  verify SHA → save as candidate. Used for every UI change that gets
  reviewed before deploy.

  Triggers: "create candidate", "build candidate", "make a candidate",
  "edit the baseline", "modify the locked file", "prepare for review",
  "build candidate for review", "make a draft version"
---

# Mavin Build Candidate Pattern

The pattern Mavin used for every UI change before deploying. Create a
candidate file in `02_QA_CANDIDATES_VISUAL_EXPERIMENTS/`, apply specific
edits, verify SHA, hand off to Pipe for review.

## When to use this

| Lane | Use this? | Why |
|---|---|---|
| 🟢 GREEN (UI tweak) | ✅ Yes | Even small changes get reviewed as candidates |
| 🟡 YELLOW (new feature) | ✅ Yes | Always as candidate first |
| 🔴 RED (protected system) | ⚠️ Yes, but with extra review | Still candidate, but Pipe reviews twice |

## The 6-step pattern

### Step 1: Backup the baseline (always)

```bash
DATE=$(date +%Y-%m-%d)
cp /workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED/gridnode-v1.3_post-phase-D_baseline.html \
   /workspace/gridnode-project/gridnode-GOOD-${DATE}_pre-{what}.html
ls -la /workspace/gridnode-project/gridnode-GOOD-${DATE}_pre-*.html
```

**Naming convention:** `gridnode-GOOD-YYYY-MM-DD_pre-{what}.html`
Examples:
- `gridnode-GOOD-2026-06-22_pre-dash-cta.html`
- `gridnode-GOOD-2026-06-22_pre-boot-redesign.html`
- `gridnode-GOOD-2026-06-22_pre-manifest-extract.html`

### Step 2: Copy baseline to candidate path

```bash
cp /workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED/gridnode-v1.3_post-phase-D_baseline.html \
   /workspace/gridnode-project/02_QA_CANDIDATES_VISUAL_EXPERIMENTS/gridnode-v1.3_{name}_microfix_v1.html
```

**Naming convention:** `gridnode-v1.3_{feature-or-purpose}_microfix_v{N}.html`
Examples:
- `gridnode-v1.3_dash_empty_cta_microfix_v1.html`
- `gridnode-v1.3_nav_condensation_syringe_units_microfix_v1.html`
- `gridnode-v1.3_boot_redesign_mock_c_microfix_v1.html`

### Step 3: Capture baseline SHA (for later verification)

```bash
BASELINE_SHA=$(sha256sum /workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED/gridnode-v1.3_post-phase-D_baseline.html | cut -d' ' -f1)
echo "Baseline SHA: $BASELINE_SHA"
```

### Step 4: Apply edits to candidate

Use `edit` tool with `oldText`/`newText` for precise changes. **Never use sed** for HTML edits (whitespace breaks).

**For each edit:**
1. Read the file to find the exact text
2. Use Edit tool with exact match
3. Verify the edit applied (check line numbers)

**Pattern for finding edits:**
```bash
# Find lines that contain what you want to change
grep -n "TAP THE + BUTTON" /workspace/gridnode-project/02_QA_CANDIDATES_VISUAL_EXPERIMENTS/gridnode-v1.3_dash_empty_cta_microfix_v1.html
```

**Pattern for verifying edits:**
```bash
# After edit, check the line was changed
sed -n '4293p' /workspace/gridnode-project/02_QA_CANDIDATES_VISUAL_EXPERIMENTS/gridnode-v1.3_dash_empty_cta_microfix_v1.html
```

### Step 5: Capture candidate SHA + size delta

```bash
CANDIDATE_FILE="/workspace/gridnode-project/02_QA_CANDIDATES_VISUAL_EXPERIMENTS/gridnode-v1.3_{name}_microfix_v1.html"
CANDIDATE_SHA=$(sha256sum "$CANDIDATE_FILE" | cut -d' ' -f1)
CANDIDATE_SIZE=$(wc -c < "$CANDIDATE_FILE")
BASELINE_SIZE=970160

echo "Candidate SHA: $CANDIDATE_SHA"
echo "Candidate size: $CANDIDATE_SIZE bytes"
echo "Size delta: $((CANDIDATE_SIZE - BASELINE_SIZE)) bytes"
```

**Expected: small deltas (10s to 1000s of bytes). Large deltas (>10KB) suggest something wrong.**

### Step 6: Report to Pipe

After creating candidate, tell Pipe:

```
Created candidate:
- Path: /workspace/gridnode-project/02_QA_CANDIDATES_VISUAL_EXPERIMENTS/gridnode-v1.3_{name}_microfix_v1.html
- SHA: {first 16 chars}...
- Size: {N} bytes (+{delta} vs baseline)
- Baseline SHA: {first 16 chars}...
- 3 changes:
  1. Line 1064: Added .empty-cta CSS rule
  2. Line 4293: Replaced text with <button>
  3. Line 6392: Same change in JS template literal

Review at your convenience. Once approved, deploy with:
  ./deploy-gridnode.sh "{name}" /path/to/candidate.html
```

## Full example: Build DASH empty CTA candidate

```bash
# 1. Backup
DATE=$(date +%Y-%m-%d)
cp /workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED/gridnode-v1.3_post-phase-D_baseline.html \
   /workspace/gridnode-project/gridnode-GOOD-${DATE}_pre-dash-cta.html

# 2. Copy
cp /workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED/gridnode-v1.3_post-phase-D_baseline.html \
   /workspace/gridnode-project/02_QA_CANDIDATES_VISUAL_EXPERIMENTS/gridnode-v1.3_dash_empty_cta_microfix_v1.html

# 3. Capture baseline SHA (for later)
BASELINE_SHA=$(sha256sum /workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED/gridnode-v1.3_post-phase-D_baseline.html | cut -d' ' -f1)
echo "Baseline SHA: $BASELINE_SHA"

# 4. Apply edits using Edit tool (NOT sed)
# Edit 1: Add CSS rule
# Edit 2: Replace static text
# Edit 3: Replace JS template literal

# 5. Verify
CANDIDATE_FILE="/workspace/gridnode-project/02_QA_CANDIDATES_VISUAL_EXPERIMENTS/gridnode-v1.3_dash_empty_cta_microfix_v1.html"
CANDIDATE_SHA=$(sha256sum "$CANDIDATE_FILE" | cut -d' ' -f1)
CANDIDATE_SIZE=$(wc -c < "$CANDIDATE_FILE")
echo "Candidate SHA: $CANDIDATE_SHA"
echo "Candidate size: $CANDIDATE_SIZE bytes"
echo "Size delta: $((CANDIDATE_SIZE - 970160)) bytes"

# 6. Report to Pipe
```

## Where to save candidates

```
/workspace/gridnode-project/02_QA_CANDIDATES_VISUAL_EXPERIMENTS/
├── gridnode-v1.3_nav_condensation_syringe_units_microfix_v1.html (1MB older version)
├── gridnode-v1.3_dash_empty_cta_microfix_v1.html (970KB rc27 candidate)
├── gridnode-v1.3_boot_redesign_mock_c_microfix_v1.html (future boot work)
└── ...
```

## Naming convention (strict)

`<feature>_<purpose>_microfix_v<version>.html`

- `<feature>`: what area (dash, boot, splash, etc.)
- `<purpose>`: what it does (empty_cta, redesign_mock_c, etc.)
- `_microfix_v<N>`: this is a small fix, version N
- Always `.html`

## Why this pattern works

1. **Baseline is never modified** — every change is a copy
2. **Backup with date + purpose** — easy to find old versions
3. **Candidate path shows intent** — `02_QA_CANDIDATES_VISUAL_EXPERIMENTS/`
4. **Version suffix allows iteration** — `_v1.html`, `_v2.html`
5. **SHA capture enables verification** — at deploy time, compare SHAs

## Common mistakes to avoid

❌ **Don't** edit the baseline file directly (always work on a copy)
❌ **Don't** use sed for HTML edits (breaks on whitespace)
❌ **Don't** skip the backup (you'll need it for rollback)
❌ **Don't** create candidates in `/tmp/` (they'll be lost on session end)
❌ **Don't** forget to verify the SHA at the end

✅ **Do** always backup before copying
✅ **Do** use the Edit tool for precise changes
✅ **Do** verify each change applied (check line numbers)
✅ **Do** capture both baseline and candidate SHAs
✅ **Do** save candidates in `02_QA_CANDIDATES_VISUAL_EXPERIMENTS/`

## When SHA matters

| SHA matches between | Means |
|---|---|
| Your candidate and Pipe's candidate | Same content, same diff |
| Candidate and baseline (after edit) | Edit didn't apply (something wrong) |
| Local file and live URL | Deploy succeeded |
| baseline.sha and live URL | No drift, healthy state |

**Always capture SHAs. Always verify them.**

## The "candidate" vs "deploy" distinction

| Stage | Where it lives | Who reviews |
|---|---|---|
| **Candidate** | `02_QA_CANDIDATES_VISUAL_EXPERIMENTS/` | Pipe reviews on phone |
| **Locked baseline** | `01_SOURCE_TRUTH_LOCKED/` | The source of truth |
| **Live** | Cloudflare Pages | Users |

Candidates are **drafts**. Locked baseline is **truth**. Live is **what users see**.

The flow:
```
Baseline (truth)
  ↓ + edits
Candidate (draft, Pipe reviews)
  ↓ Pipe approves
Deployed (live, users see)
```

## Why not just edit and deploy directly?

| Concern | Why candidate-first fixes it |
|---|---|
| What if it breaks visually? | Pipe catches it on candidate review |
| What if the diff is wrong? | Visible in candidate before deploy |
| What if rollback is needed? | Dated backup + candidate already exist |
| What if SHA doesn't match? | Caught at build, not at deploy |

**Candidate-first is the safety net for the "ship by default" Velocity Directive.**

## Related patterns

- `mavin-verify-deploy` — verifies live matches lock after deploy
- `mavin-visual-render` — captures screenshots of candidate for review
- `deploy-gridnode.sh` — deploys candidate to live

---

**The next Mavin reads this and knows exactly how to build a candidate for Pipe's review.**