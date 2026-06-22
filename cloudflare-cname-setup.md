# Cloudflare: Add CNAME for gridnode.network

**Time needed:** 1 minute
**What this does:** Tells Cloudflare's DNS to point `gridnode.network` to the Cloudflare Pages deployment (which currently serves at `gridnode.pages.dev`)

---

## Why this matters

You already:
- ✅ Added `gridnode.network` to Cloudflare (done)
- ✅ Cloudflare is now your DNS provider (done — SSL is active)
- ✅ Added `gridnode.network` as a custom domain to the Pages project (done by Mavin via API)

But Pages says "CNAME record not set." That's because Cloudflare DNS doesn't know to route `gridnode.network` to `gridnode.pages.dev` yet. We need to add a CNAME record.

---

## Step 1: Open Cloudflare DNS

1. Go to https://dash.cloudflare.com
2. Click **`gridnode.network`** in the list of sites
3. In the left sidebar, click **`DNS`** → **`Records`**

You should see a list of existing DNS records.

---

## Step 2: Add the CNAME record

1. Click **`+ Add record`** button
2. Fill in the form:
   - **Type:** `CNAME`
   - **Name:** `@` (this means the apex `gridnode.network` — if `@` doesn't work, try `gridnode.network` itself, but `@` is the standard)
   - **Target:** `gridnode.pages.dev`
   - **Proxy status:** `Proxied` (the orange cloud icon — NOT the grey "DNS only" cloud). This means Cloudflare routes traffic through its CDN/security.
   - **TTL:** Auto (or `3600` if you want to be explicit)
3. Click **`Save`**

---

## Step 3: Verify

After saving, wait 1-5 minutes for the record to propagate. Then:

1. The custom domain status in Pages should change from `pending` to `active`
2. Visiting `https://gridnode.network` should now serve the **new** GRID//NODE bundle (with the [BIP] fix, the PWA improvements, and the install modal)
3. Open the URL on your phone, hard refresh, test PWA install

---

## What you'll see when it works

**Before this CNAME is added:**
- `gridnode.network` serves the OLD Hostinger version (last modified June 14)
- Headers show `platform: hostinger, panel: hpanel`
- The newer features (install modal, [BIP] fix, etc.) are NOT visible

**After this CNAME is added:**
- `gridnode.network` serves the NEW Cloudflare Pages version (built today)
- Headers show `server: cloudflare` and Cloudflare's caching headers
- The newer features ARE visible
- Chrome's PWA install auto-prompt should now fire

---

## Common gotchas

**"I added the CNAME but it still shows pending"**
- Wait 5 minutes, refresh the Pages custom domains tab
- DNS propagation isn't instant

**"I get a 'Too many redirects' error in the browser"**
- This happens if the CNAME is set to "DNS only" instead of "Proxied"
- Change proxy status to the orange cloud

**"gridnode.network still shows the Hostinger page"**
- Make sure you typed the target correctly: `gridnode.pages.dev` (with the dot at the end or without, both work)
- Make sure the proxy status is the orange cloud

**"Cloudflare added a CNAME automatically, now there are two"**
- Sometimes when you add a custom domain in Pages, Cloudflare auto-adds the CNAME. If that happened, you don't need to add another one — just wait.

---

## TL;DR

1. Cloudflare dashboard → DNS → Records → + Add record
2. Type: CNAME | Name: @ | Target: gridnode.pages.dev | Proxy: orange cloud
3. Save
4. Wait 1-5 minutes
5. Test on your phone

Total time: 1 minute of clicking, then waiting.