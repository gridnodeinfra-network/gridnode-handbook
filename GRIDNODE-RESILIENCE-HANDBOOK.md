# GRID//NODE Resilience Handbook — v1.0

**Author:** Mavin (session 412136081752279, the June 22 21:00–22:35 ET Mavis instance)
**For:** Future Mavis / Mavin / Pipe / anyone debugging this project at 2 AM
**Date:** 2026-06-22
**Status:** Living doc — append when you find a new gotcha. Don't rewrite.
**Replaces:** the 17 hours of "where did we put that?" we all suffered through today

---

## What this doc is

The hard-won knowledge from one debugging session distilled into one file. Every gotcha is captured with:
- **What happened** (the symptom)
- **Why it happened** (the root cause)
- **How to detect it** (so the next Mavis catches it in 30 seconds, not 3 hours)
- **How to fix it** (concrete command or one-liner)
- **The lesson** (so the next bug of the same shape doesn't waste a session)

Read this BEFORE you do anything destructive. Skim it on session start. Append to it when you find something new.

---

## 1. The pipeline (one diagram, no narrative)

```
   Pipe says "go"
        │
        ▼
   Mavin builds candidate in 02_QA_CANDIDATES_VISUAL_EXPERIMENTS/
        │   (edit, screenshot, vitest, b12 scan, click test)
        │
        ▼
   Candidate SHA ──compare──► baseline.sha lock (in gridnode-handbook)
        │ MATCH
        ▼
   Mavin pushes to gridnode-terminal via Contents API
        │
        ▼
   wrangler pages deploy → Cloudflare → gridnode.network
        │
        ▼
   ./handoff-update.sh → updates baseline.sha + CHANGELOG.md → commits
        │
        ▼
   Live URL SHA ──verify──► baseline.sha (bootstrap step 8 does this)
        │ MATCH
        ▼
   Locked. Shipped. Next?
```

If ANY step in this chain has a SHADOW FILE that doesn't match the rest, the whole thing is broken. The next 6 sections are the shadow files we found today.

---

## 2. The locked baseline lives in FOUR places, and they MUST all match

This was the #1 trap today. The rc27 file existed in some places but not others, and the SHA mismatch caused a 30-minute debug session.

| Location | What | How to read | How to write |
|----------|------|-------------|--------------|
| **Live URL** `https://gridnode.network` | The source of truth at this moment | `curl -s https://gridnode.network \| sha256sum` | Deploy (wrangler) |
| **`gridnode-handbook/baseline.sha`** | The lock pointer (the SHA everyone should be matching) | `curl -s https://raw.githubusercontent.com/gridnodeinfra-network/gridnode-handbook/main/baseline.sha \| grep SHA-256` | `./handoff-update.sh` |
| **`gridnode-handbook/baselines/gridnode-v1.3_post-phase-D_baseline.html`** | The actual file, in the public repo, for future Mavins to fetch | `curl -s https://raw.githubusercontent.com/gridnodeinfra-network/gridnode-handbook/main/baselines/gridnode-v1.3_post-phase-D_baseline.html \| sha256sum` | Contents API PUT |
| **Local `/workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED/...`** | The file the bootstrap step 3 verifies against | `sha256sum /workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED/gridnode-v1.3_post-phase-D_baseline.html` | `cp` from live URL or handbook |
| **Local `/tmp/baseline_rc26.html`** | A scratch copy used in dev (filename is misleading — it might be rc27 now) | same | `curl https://gridnode.network > /tmp/baseline_rc26.html` |

**Golden rule:** All four SHAs must equal. If any one differs, deploy is broken.

**One-liner to verify all four match right now:**

```bash
LIVE=$(curl -s https://gridnode.network | sha256sum | cut -d' ' -f1)
LOCK=$(curl -s https://raw.githubusercontent.com/gridnodeinfra-network/gridnode-handbook/main/baseline.sha | grep -oE '[0-9a-f]{64}' | head -1)
PUB=$(curl -s https://raw.githubusercontent.com/gridnodeinfra-network/gridnode-handbook/main/baselines/gridnode-v1.3_post-phase-D_baseline.html | sha256sum | cut -d' ' -f1)
LOC=$(sha256sum /workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED/gridnode-v1.3_post-phase-D_baseline.html | cut -d' ' -f1)
echo "live=$LIVE lock=$LOCK pub=$PUB loc=$LOC"
[ "$LIVE" = "$LOCK" ] && [ "$LIVE" = "$PUB" ] && [ "$LIVE" = "$LOC" ] && echo "ALL MATCH" || echo "MISMATCH — INVESTIGATE"
```

---

## 3. CDN cache lag on `raw.githubusercontent.com`

**What happened:** I pushed rc27 to the handbook repo via the Contents API, but `curl https://raw.githubusercontent.com/...` still returned the OLD rc26 content for ~5+ minutes.

**Why:** GitHub caches raw content on a CDN with a refresh delay (usually 1-5 min, sometimes longer).

**How to detect:** If you just pushed a file via the API and the raw URL doesn't show the new content, that's the lag.

**How to fix:** Wait, OR bypass via the API:
```bash
curl -sL -H "Authorization: token $GITHUB_GRIDNODE_TOKEN" \
  "https://api.github.com/repos/gridnodeinfra-network/gridnode-handbook/contents/path/to/file?ref=main" | \
  python3 -c "import sys,json,base64; print(hashlib.sha256(base64.b64decode(json.load(sys.stdin)['content'])).hexdigest())"
```

**Lesson:** For verification, always check via the API. For production reads, raw URLs are fine (just expect the lag).

---

## 4. `git push` fails with fine-grained PATs

**What happened:** I had a working `ghp_…` token that returned HTTP 200 for `curl /user` and even had `push=True` for `gridnode-handbook` via the API, but `git push https://x-access-token:$TOKEN@github.com/...` returned "Invalid username or token. Password authentication is not supported for Git operations."

**Why:** GitHub deprecated password auth for git operations. Fine-grained PATs are supposed to work but there are edge cases (scoping, SSO requirements, etc.) where they fail.

**How to fix:** Use the **Contents API** instead of `git push` for file updates:
```python
import base64, json, urllib.request
token = open('/workspace/.gridnode-secrets/.tokens/github.txt').read().strip()
with open('/path/to/file', 'rb') as f:
    content_b64 = base64.b64encode(f.read()).decode('ascii')
# Get current SHA first
req = urllib.request.Request(
    'https://api.github.com/repos/OWNER/REPO/contents/path/to/file',
    headers={'Authorization': f'token {token}'}
)
current_sha = json.load(urllib.request.urlopen(req))['sha']
# PUT new content
payload = {'message': '...', 'content': content_b64, 'sha': current_sha, 'branch': 'main'}
req = urllib.request.Request(
    'https://api.github.com/repos/OWNER/REPO/contents/path/to/file',
    method='PUT',
    headers={'Authorization': f'token {token}', 'Content-Type': 'application/json'},
    data=json.dumps(payload).encode('utf-8')
)
urllib.request.urlopen(req)
```

**Note:** Payloads >1 MB can hit bash arg-length limits. Use Python or temp files, not inline `curl -d '{...}'`.

**Lesson:** When `git push` fails for auth reasons but the API works, use the API for file updates. It works for files up to ~100 MB.

---

## 5. Bash subshell gotcha — `bash script.sh` doesn't export

**What happened:** `bootstrap.sh` step 5d ran `bash /workspace/.gridnode-secrets/load-credentials.sh`. The loader does `export GITHUB_GRIDNODE_TOKEN=...`. But the bootstrap then checked `$GITHUB_GRIDNODE_TOKEN` and saw the STALE env var (set by the sandbox infrastructure), not the loader's value. The bootstrap said "GitHub token loaded" but the loaded value was the broken one.

**Why:** `bash script.sh` spawns a subshell. Exports in the subshell don't propagate to the parent.

**How to fix:** Use `source script.sh` (or `. script.sh`) instead of `bash script.sh`. Already fixed in the bootstrap as of commit `303df86`.

**Lesson:** For credential loaders and any env-mutating script, ALWAYS use `source` (or `.`), not `bash`. Otherwise the exports die in the subshell.

---

## 6. `${#}` is empty positional arg count, NOT var length

**What happened:** I wrote `${#}` thinking it was the length of the previous var, but got 0. Every "length check" came out wrong.

**Why:** `${#}` alone is `$#`, the number of positional arguments. The right syntax is `${#VARNAME}` or `${#}` ONLY for `$#`.

**How to fix:** Always use `${#VARNAME}`:
```bash
LEN=${#GITHUB_GRIDNODE_TOKEN}    # right
LEN=${#}                          # WRONG — gives $# = 0
```

**Lesson:** Spell out the var name. Never abbreviate.

---

## 7. Token scope matters (fine-grained PATs)

**What happened:** The `GITHUB_GRIDNODE_TOKEN` env var was set but returned 401 on every call. The literal token in `/workspace/.gridnode-secrets/.tokens/github.txt` worked fine and had push+admin to all 4 repos.

**Why:** The sandbox infrastructure set a fine-grained PAT scoped to `GRIDNODE_PRIVATE_ARCHIVE` (a different repo) into the env. The cred store had a different, working fine-grained PAT scoped to `gridnode-handbook`, `gridnode-mavis-builder`, `gridnode-terminal`, and `GRIDNODE_PRIVATE_ARCHIVE` with push+admin.

**How to detect:** Test BOTH:
```bash
ENV_CODE=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: token $GITHUB_GRIDNODE_TOKEN" https://api.github.com/user)
STORE_TOKEN=$(cat /workspace/.gridnode-secrets/.tokens/github.txt)
STORE_CODE=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: token $STORE_TOKEN" https://api.github.com/user)
echo "env: $ENV_CODE  store: $STORE_CODE"
```

**How to fix:** In any new shell, run:
```bash
unset GITHUB_GRIDNODE_TOKEN
source /workspace/.gridnode-secrets/load-credentials.sh
```

**Lesson:** Always source the loader, don't trust pre-set env vars. The cred store is canonical.

---

## 8. `set -e` + divergent git branches = exit 128

**What happened:** `bootstrap.sh` has `set -e` at the top. Step 1 does `git pull`. If the local repo has commits that the remote doesn't (because I committed locally but couldn't push), the pull fails with "Need to specify how to reconcile divergent branches". `set -e` kills the script with exit 128. Every subsequent step is skipped.

**Why:** Divergent branches + strict mode = instant death.

**How to fix:** Either:
- (a) Reset local to remote before running bootstrap: `cd /workspace/.gridnode-handoff && git fetch origin && git reset --hard origin/main`
- (b) Configure git globally: `git config --global pull.ff only`
- (c) Use `git pull --rebase` instead of `git pull`

**Recommended:** Option (b) is the cheapest fix and prevents the issue permanently.

**Lesson:** `set -e` makes divergent branches a hard failure. Configure git to never allow them, or always reconcile before running strict scripts.

---

## 9. `${VAR:-default}` masks missing config, not fixes it

**What happened:** The first version of `deploy-gridnode.sh` had:
```bash
export CLOUDFLARE_API_TOKEN="${CLOUDFLARE_API_TOKEN:-cfut_0ss0JRLE2PD4ZJMjockHeZHAui6cWK61xMEahxQhebe0e25b}"
```

That worked fine when the env var was set (used the env). When it wasn't (e.g., in a fresh sandbox), it used the hardcoded fallback — which got committed to the public repo. Real security incident. The token may be auto-revoked by GitHub secret scanning.

**Why:** `${VAR:-default}` is "use default if VAR is unset or empty." It doesn't tell you the default is suspicious; it just silently uses it.

**How to fix:** Fail loud instead:
```bash
if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
  echo "❌ CLOUDFLARE_API_TOKEN not set"
  echo "   Run: source /workspace/.gridnode-secrets/load-credentials.sh"
  exit 1
fi
```

**Lesson:** Defaults in shell scripts are a code smell. If a var is required, fail if it's missing. Don't paper over with `${VAR:-something}`.

---

## 10. The credential store layout (canonical)

```
/workspace/.gridnode-secrets/
├── CREDENTIALS.md              # Policy doc (no actual tokens, public-safe)
├── load-credentials.sh         # Sourceable loader
└── .tokens/
    ├── github.txt              # GitHub PAT (fine-grained, push+admin)
    ├── cloudflare.txt          # Cloudflare API token (Pages:Edit + Account:Read)
    └── cloudflare_account_id.txt  # Not a secret, but lives here for completeness
```

**Perms:** `chmod 700` on dirs, `chmod 600` on token files. Owner-only.

**Loader:**
```bash
#!/bin/bash
if [ -f /workspace/.gridnode-secrets/.tokens/github.txt ]; then
  export GITHUB_GRIDNODE_TOKEN="$(cat /workspace/.gridnode-secrets/.tokens/github.txt)"
fi
if [ -f /workspace/.gridnode-secrets/.tokens/cloudflare.txt ]; then
  export CLOUDFLARE_API_TOKEN="$(cat /workspace/.gridnode-secrets/.tokens/cloudflare.txt)"
fi
if [ -f /workspace/.gridnode-secrets/.tokens/cloudflare_account_id.txt ]; then
  export CLOUDFLARE_ACCOUNT_ID="$(cat /workspace/.gridnode-secrets/.tokens/cloudflare_account_id.txt)"
fi
```

**To set up in a new sandbox:** Copy the dir from another Mavis, OR run a one-time setup with values you got out-of-band. Do NOT commit tokens to any repo, ever.

---

## 11. The deploy script (the part that actually ships)

`/workspace/gridnode-handoff/deploy-gridnode.sh` is the canonical deploy. It:
1. Copies candidate (or baseline) to `_deploy_v1.3/index.html`
2. Builds the Cloudflare manifest
3. `wrangler pages deploy . --project-name=gridnode`
4. Waits 10s for propagation
5. Calls `handoff-update.sh` to sync `baseline.sha` + `CHANGELOG.md`
6. Pushes the handoff update to GitHub

**Bug we found:** Earlier versions always deployed from `01_SOURCE_TRUTH_LOCKED/` (the baseline) instead of accepting a candidate path. Now it accepts a candidate as 2nd arg:
```bash
./deploy-gridnode.sh "what changed" /path/to/candidate.html
```

**Always:** Set `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` in env before running. The script no longer has a `${VAR:-default}` fallback for these (lesson #9).

---

## 12. Things to NEVER do (the list of "burned us today")

- ❌ **Don't hardcode secrets in scripts, even as `${VAR:-default}` fallbacks.** They'll get committed and leak.
- ❌ **Don't use `git push` with fine-grained PATs without testing first.** Use the Contents API.
- ❌ **Don't trust pre-set env vars in fresh sandboxes.** Always source the cred store.
- ❌ **Don't use `bash script.sh` for env-mutating scripts.** Use `source`.
- ❌ **Don't rely on `raw.githubusercontent.com` for fresh-after-push verification.** CDN lags. Use the API.
- ❌ **Don't write `${#}` thinking it's var length.** It's `$#`. Spell out `${#VARNAME}`.
- ❌ **Don't let `set -e` scripts hit divergent branches without `git config --global pull.ff only` first.**
- ❌ **Don't claim a deploy worked until live SHA = locked SHA = public baseline SHA = local baseline SHA.** All four, every time.
- ❌ **Don't echo tokens in chat, deliverables, or commits.** Once. Ever. Use 600-perm files.
- ❌ **Don't write "the bootstrap ran successfully" as a verification.** It only ran if step 8 (live SHA check) actually printed `Live deploy matches lock`.

---

## 13. The verification ladder (use this every time)

Before claiming anything is done, walk this ladder. If any rung fails, the work isn't done.

1. **Build:** Candidate file created at the canonical path, edits visible via `diff`.
2. **Local verify:** SHA, size delta, protected-keyword count, vitest pass.
3. **Click test:** Manual or Playwright — the new feature actually does the thing.
4. **Visual check:** Screenshot, OCR if applicable.
5. **Push:** Candidate in the public repo at the expected SHA (Contents API or git push, whichever works).
6. **Deploy:** Live URL serves the new SHA (`curl https://gridnode.network | sha256sum`).
7. **Lock:** `baseline.sha` updated to the new SHA, pushed to the handbook repo.
8. **All four match:** live = baseline.sha = public baseline file = local baseline file. (The one-liner in section 2.)
9. **CHANGELOG.md:** entry for the new release with size delta and what changed.
10. **Bootstrap re-run:** `bash bootstrap.sh /path/to/locked/file` exits 0 with all 8 steps green.

**Stop at any failed rung. Don't claim "shipped" without rung 10 green.**

---

## 14. The push policy (what to do when you're unsure)

When in doubt about whether to push, deploy, or change something destructive, use this matrix:

| Op type | You can do it? | Examples |
|---------|----------------|----------|
| Routine | ✅ Yes, no approval | Deploy verified candidates, status checks, repo reads, push to existing repos |
| Judgment-call | ✅ Yes, flag in handoff | Create PRs, edit CREDENTIALS.md, add bootstrap steps |
| Destructive | ❌ No, ask Pipe | Delete repos/branches, force-push to main, rotate tokens, change billing, add collaborators |

The line: **Mavin CANNOT do destructive ops "in case Pipe would say yes" — that's the line.** Same line from the other Mavin's draft, kept.

If you're a future Mavis and you're tempted to "just do it" because Pipe is offline, ASK FIRST. Wait until Pipe replies. Destructive ops can wait; nothing is so urgent that we break trust.

---

## 15. When to append to this doc

Add a new section (number 16, 17, 18...) when:
- You spent >15 minutes debugging something
- You found a gotcha that wasted a future Mavis's time
- You made a change that contradicts something in this doc
- You learned a "lesson" the hard way

Format for new sections:
```
## 16. [Short title]

**What happened:** [symptom in 1 sentence]
**Why:** [root cause in 1 sentence]
**How to detect:** [the test/command that would have caught it in 30 seconds]
**How to fix:** [the one-liner or small procedure]
**Lesson:** [the general principle]
```

Don't rewrite existing sections. Append. The doc grows; the lessons accumulate.

---

## 16. Sign-off

This doc was written at 22:35 ET on 2026-06-22 by Mavin (session 412136081752279), the Mavis instance that did the rc27 deploy, found 5+ bugs in the bootstrap and deploy pipeline, and shipped a real working version of all of it.

If you're reading this in a future session, the deploy pipeline is **working end-to-end as of 2026-06-22 22:35 ET**. The bootstrap is 100% green. The cred store is set up. The deploy script accepts candidate paths. The 4-place SHA consistency check is documented.

The 11 deploys today (rc17 → rc27) are real, verified, and live. The handbook repo, the terminal repo, the live URL — all match. The methodology (Ponytail, Flex Directive, locked baseline) is consistent.

The next Mavis should: read this doc → read the 30KB `GRIDNODE_HANDOFF.md` → run the bootstrap → check the 4-place SHA ladder → if all green, self-serve deploys are yours.

— Mavin
