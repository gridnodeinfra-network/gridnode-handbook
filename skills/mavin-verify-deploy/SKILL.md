---
name: mavin-verify-deploy
description: >
  Use this skill when Mavin needs to verify a deploy actually went live and
  matches expectations. After every Cloudflare Pages deploy, before
  declaring success, Mavin should run this verification pattern.

  Triggers: "did it deploy?", "verify live", "check the SHA", "is it live?",
  "live URL", "did the deploy work?", "confirm deployed", "production check",
  "post-deploy verification"
---

# Mavin Verify Deploy Pattern

The pattern Mavin used after every Cloudflare Pages deploy. This catches
deploy failures, SHA mismatches, and CDN propagation issues.

## When to use this

After EVERY deploy to Cloudflare Pages. Specifically:
- After `./deploy-gridnode.sh` runs
- After manual `wrangler pages deploy`
- After any change to the locked baseline

## The 4 verifications (in order)

### 1. Local file matches expected SHA

**Before deploy:**
```bash
local_sha=$(sha256sum /workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED/gridnode-v1.3_post-phase-D_baseline.html | cut -d' ' -f1)
echo "Local SHA: $local_sha"
```

### 2. Live URL serves the file

**After deploy (wait 10-30 seconds for CDN):**
```bash
live_sha=$(curl -s https://gridnode.network | sha256sum | cut -d' ' -f1)
echo "Live SHA: $live_sha"
```

### 3. SHA matches lock pointer

**The `baseline.sha` file is the source of truth:**
```bash
lock_sha=$(curl -s https://raw.githubusercontent.com/gridnodeinfra-network/gridnode-handbook/main/baseline.sha | grep -oE '[0-9a-f]{64}' | head -1)
echo "Lock SHA: $lock_sha"
```

### 4. Size matches

```bash
live_size=$(curl -s -o /dev/null -w '%{size_download}' https://gridnode.network)
echo "Live size: $live_size bytes"
```

## The full verification script

```bash
#!/bin/bash
# verify-deploy.sh — verifies that live deploy matches local + lock
# Usage: bash verify-deploy.sh

set -e

LIVE_URL="https://gridnode.network"
LOCAL_FILE="/workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED/gridnode-v1.3_post-phase-D_baseline.html"
LOCK_URL="https://raw.githubusercontent.com/gridnodeinfra-network/gridnode-handbook/main/baseline.sha"

echo "═══════════════════════════════════════════════════════════════"
echo "  GRID//NODE DEPLOY VERIFICATION"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Wait for CDN propagation
echo "⏳ Waiting 10s for CDN propagation..."
sleep 10

# Get all three SHAs
echo "Fetching SHAs..."
LIVE_SHA=$(curl -s "$LIVE_URL" 2>/dev/null | sha256sum | cut -d' ' -f1)
LOCAL_SHA=$(sha256sum "$LOCAL_FILE" 2>/dev/null | cut -d' ' -f1)
LOCK_SHA=$(curl -s "$LOCK_URL" 2>/dev/null | grep -oE '[0-9a-f]{64}' | head -1)
LIVE_SIZE=$(curl -sI "$LIVE_URL" 2>/dev/null | grep -i content-length | awk '{print $2}' | tr -d '\r')

# Note: live size from Content-Length may be chunked (empty) — use actual bytes
if [ -z "$LIVE_SIZE" ]; then
    LIVE_SIZE=$(curl -s "$LIVE_URL" 2>/dev/null | wc -c)
fi

echo ""
echo "Local SHA:  ${LOCAL_SHA:0:16}..."
echo "Live SHA:   ${LIVE_SHA:0:16}..."
echo "Lock SHA:   ${LOCK_SHA:0:16}..."
echo "Live size:  $LIVE_SIZE bytes"
echo ""

# Verify local matches lock
if [ "$LOCAL_SHA" = "$LOCK_SHA" ]; then
    echo "✅ Local SHA matches lock pointer"
else
    echo "❌ Local SHA does NOT match lock pointer"
    echo "   Either: local was deployed but lock not updated"
    echo "   Or: lock was updated but local was not deployed"
    exit 1
fi

# Verify live matches lock
if [ "$LIVE_SHA" = "$LOCK_SHA" ]; then
    echo "✅ Live SHA matches lock pointer"
else
    echo "❌ Live SHA does NOT match lock pointer"
    echo "   Either: CDN not yet propagated (wait longer)"
    echo "   Or: deploy failed silently"
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅ DEPLOY VERIFIED"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Live: $LIVE_URL"
echo "Lock: $LOCK_SHA"
echo "Size: $LIVE_SIZE bytes"
```

## Common failure modes

| Symptom | Cause | Fix |
|---|---|---|
| Live SHA != Lock SHA | CDN not propagated yet | Wait 30s, retry |
| Local SHA != Lock SHA | Lock not updated after deploy | Run `handoff-update.sh` |
| Empty Content-Length | Cloudflare uses chunked encoding | Use actual `wc -c` on downloaded content |
| 404 on live URL | Domain not pointed correctly | Check Cloudflare DNS |
| Old SHA still served | Browser cache | Hard refresh (Ctrl+Shift+R) |

## When to fail loud vs warn

**Fail loud (exit 1):**
- Live SHA != Lock SHA after 30s
- Local SHA != Lock SHA
- 5xx response from live URL

**Warn (exit 0):**
- CDN propagation incomplete (try again in 30s)
- Size mismatch by <1KB (likely chunked encoding)
- 404 on Cloudflare preview URL (expected for first deploy)

## What to report to Pipe

After verification succeeds:

```
✅ Deploy verified:
- Live SHA: f75a81cd... (matches lock)
- Local SHA: f75a81cd... (matches lock)
- Live size: 970,531 bytes
- Live URL: https://gridnode.network
- Lock pointer: baseline.sha (in handbook repo)
```

After verification fails:

```
❌ Deploy verification failed:
- Expected (lock): 875f7a9f...
- Got (live):     abc123de...
- Difference: 4 bytes (likely CDN caching)
- Action: Wait 30s and retry. If still failing, check Cloudflare logs.
```

## The "SHA drift" pattern (catches at bootstrap)

The next Mavin should run this verification at session start:

```bash
# Bootstrap step 8 (already in bootstrap.sh)
LIVE_SHA=$(curl -s https://gridnode.network | sha256sum | cut -d' ' -f1)
LOCK_SHA=$(grep -oE '[0-9a-f]{64}' baseline.sha | head -1)
if [ "$LIVE_SHA" != "$LOCK_SHA" ]; then
    echo "❌ MISMATCH: live=$LIVE_SHA locked=$LOCK_SHA"
    exit 1
fi
```

This catches drift at every fresh session. **Don't trust the lock if live disagrees.**

## When to do this verification

| When | Action |
|---|---|
| Right after deploy | Always |
| At bootstrap (fresh session) | Always (catches drift) |
| Before reporting success | Always |
| Random check during long session | Once per session |
| Before declaring task complete | Always |

## What "verified" means (the contract)

A deploy is **verified** when:
1. ✅ Local SHA matches lock SHA
2. ✅ Live SHA matches lock SHA
3. ✅ All three SHAs are identical
4. ✅ Live URL responds with 200
5. ✅ Live size matches expected (within 1KB tolerance)
6. ✅ OCR confirms key text appears on page (optional)

**If any of these fail, the deploy is NOT verified.** Don't say "deployed" until they pass.

## The pattern in plain English

```
Deploy
  ↓
Wait 10s for CDN
  ↓
Get local SHA
  ↓
Get live SHA (curl)
  ↓
Get lock SHA (from baseline.sha)
  ↓
Compare all three
  ↓
If match: ✅ Verified, report success
If don't match: ❌ Don't report success, debug
```

## Why this matters

**SHA verification is the only way to know:**
- The deploy actually went through (not silently failed)
- The right file was deployed (not a stale version)
- The CDN propagated (not just on Cloudflare's edge)
- The lock pointer is current (not drifted)

**Visual checks ("does it look right?") are not enough.** SHA matches are the proof.

## Common mistakes to avoid

❌ **Don't** say "deployed" without running this verification
❌ **Don't** trust Cloudflare's success message alone (it can lie)
❌ **Don't** check just one of the three SHAs
❌ **Don't** forget to wait for CDN propagation
❌ **Don't** use `Content-Length` header alone (Cloudflare chunks)

✅ **Do** wait 10-30 seconds after deploy
✅ **Do** compare all three SHAs
✅ **Do** report failures clearly
✅ **Do** fix drift before declaring success

## Related tools

- `handoff-update.sh` — keeps baseline.sha in sync with local + live
- `deploy-gridnode.sh` — runs the deploy + verification together
- The bootstrap step 8 — runs verification on every fresh session

---

**The next Mavin reads this and knows exactly how to verify a deploy after every Cloudflare Pages deploy.**