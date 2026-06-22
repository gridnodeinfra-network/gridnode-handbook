# GRID//NODE — Cloudflare DNS Setup Walkthrough

**For:** Pipe (founder)
**Time needed:** ~15-20 minutes total
**Difficulty:** Easy (just clicking through menus)
**Goal:** Route `gridnode.network` to Cloudflare Pages so PWA install works on the real domain

---

## The big picture (in plain English)

Right now:
- `gridnode.network` is registered at **Porkbun** (where you bought it)
- `gridnode.network` is hosted on **Hostinger** (their nameservers, their files)
- The PWA at `gridnode.pages.dev` works, but Chrome won't show the install prompt because it's a subdomain

What we're doing:
- **Move the nameservers from Hostinger to Cloudflare** (Cloudflare takes over DNS)
- **Point `gridnode.network` to the Cloudflare Pages deployment** (where the PWA lives)
- **Result:** `gridnode.network` shows the PWA, Chrome's strict install criteria get met, real PWA install works

This is a one-time setup. Once it's done, you can deploy new versions of GRID//NODE just by running a command and Cloudflare handles the rest.

---

## What you need before starting

1. **Porkbun login** (where the domain was bought)
2. **Cloudflare account** (free — sign up at https://dash.cloudflare.com/sign-up if you don't have one)
3. **A cup of coffee** ☕

That's it. No terminal, no code, no command line.

---

## Part 1: Add the site to Cloudflare (5 minutes)

1. Go to https://dash.cloudflare.com
2. Click the **+ Add a Site** button (top right area)
3. Type `gridnode.network` in the box
4. Click **Continue**
5. Cloudflare will scan for existing DNS records — click **Continue** to skip past the scan results (we'll set up records later)
6. **Choose the Free plan** ($0/month) — click **Continue**
7. Cloudflare will give you **two nameserver addresses** that look like:
   ```
   aria.ns.cloudflare.com
   jay.ns.cloudflare.com
   ```
   (The exact names will be different — copy them exactly)
8. **Don't close this tab.** Keep these two nameservers visible. You'll need them in Part 2.

---

## Part 2: Change nameservers at Porkbun (3 minutes)

1. Open a new tab and go to https://porkbun.com
2. Log in to your account
3. Click **Domain Portfolio** (or **My Domains**)
4. Find `gridnode.network` in the list
5. Click on it to open the domain details
6. Look for **Nameservers** or **DNS Records** section
7. Click **Edit** (or the pencil icon ✏️ next to nameservers)
8. You'll see something like:
   ```
   ns1.hostinger.com
   ns2.hostinger.com
   ```
   (The current Hostinger nameservers)
9. **Replace those two with the two Cloudflare nameservers** from Part 1
   - Delete `ns1.hostinger.com`, paste `aria.ns.cloudflare.com` (or whatever Cloudflare gave you)
   - Delete `ns2.hostinger.com`, paste `jay.ns.cloudflare.com` (or whatever Cloudflare gave you)
10. Click **Save** or **Submit**
11. Porkbun will show a confirmation — click confirm

**That's it for Part 2.** Now we wait for the nameserver change to propagate (5 minutes to 24 hours, usually 10-30 minutes).

---

## Part 3: Verify Cloudflare is now in charge (5-30 minutes after Part 2)

1. Go back to the Cloudflare tab (the one from Part 1)
2. Cloudflare will be checking if the nameservers have updated
3. When it confirms (it'll show a success page with a "Done!" button), click it
4. You're now in the Cloudflare dashboard for `gridnode.network`
5. The free plan is active, DNS is managed by Cloudflare now

**While you wait:** You don't need to do anything. The nameserver change is automatic. Cloudflare will email you when it's confirmed, or you can just check the dashboard.

---

## Part 4: Add `gridnode.network` to the Cloudflare Pages project (5 minutes)

1. In Cloudflare dashboard, click **Workers & Pages** in the left sidebar
2. Find the **`gridnode`** project (the one I deployed to earlier) and click on it
3. Click the **Custom domains** tab
4. Click **+ Set up a custom domain**
5. Type `gridnode.network` in the box
6. Click **Continue**
7. Cloudflare will:
   - Add a CNAME record pointing `gridnode.network` → `gridnode.pages.dev`
   - Provision an SSL certificate automatically (takes 1-5 minutes)
8. Wait for the SSL cert to be "Active" (you'll see a green checkmark)

**Note:** If you want to keep `www.gridnode.network` working too, add it as a second custom domain.

---

## Part 5: Test on your phone (the moment of truth)

1. Open Chrome on your Android phone
2. Go to `https://gridnode.network` (note: https, not http)
3. The GRID//NODE app should load — same as `gridnode.pages.dev` but on your real domain
4. **Wait 5-15 seconds** for the install banner to appear
5. The banner should say **"INSTALL GRID//NODE"** with a cyan INSTALL button (not the fallback "Use browser menu" copy)
6. Tap INSTALL
7. Chrome's native install dialog appears with the proper GRID//NODE icon
8. Tap **Add** (or **Install**)
9. **GRID//NODE appears on your home screen as a real app**
10. Tap the home screen icon → **app opens full-screen, no browser chrome, no address bar** — looks like a native app

If the banner shows the fallback copy ("Use browser menu → Add to Home screen") instead of the native install:
- Hard refresh (pull-to-refresh on mobile, Cmd+Shift+R on desktop)
- Wait 30 seconds
- Make sure you're on `https://gridnode.network` not `http://`

If it still doesn't work, the issue might be a Chrome caching the old PWA state — clear Chrome's site data for `gridnode.network` and try again.

---

## Part 6: Test on iPhone (your girlfriend can do this)

1. Open Safari on iPhone
2. Go to `https://gridnode.network`
3. After ~8 seconds, the iOS guide overlay appears
4. Tap the **Share** button (bottom of Safari)
5. Tap **Add to Home Screen**
6. Tap **Add**
7. GRID//NODE appears on home screen, opens full-screen

This should work the same as it does on `gridnode.pages.dev` (the iOS path was already working — we proved that).

---

## What you do AFTER it's all set up

Going forward, deploying new versions of GRID//NODE is one command:

```bash
npx wrangler pages deploy . --project-name=gridnode
```

Cloudflare Pages automatically:
- Serves the new version at `gridnode.pages.dev`
- Serves the new version at `gridnode.network` (your custom domain)
- Provisions/renews SSL certificates
- Distributes globally via CDN

You don't need to touch Hostinger or Porkbun ever again for GRID//NODE.

---

## How to undo (if it goes wrong)

If you want to go back to the old setup:

1. **Cloudflare dashboard** → **DNS** → **Records** → delete the CNAME for `gridnode.network`
2. **Cloudflare dashboard** → **Workers & Pages** → **gridnode** → **Custom domains** → remove `gridnode.network`
3. **Porkbun** → change nameservers back to Hostinger's:
   - `ns1.hostinger.com`
   - `ns2.hostinger.com`

Wait 30 minutes, the old Hostinger page comes back. Nothing is lost.

---

## Common things that might confuse you

**"Porkbun says the nameservers are still Hostinger"**
- Wait. DNS propagation takes 5 minutes to 24 hours. Just check back in 30 min.

**"Cloudflare says 'nameservers not updated'"**
- Same thing. The nameserver change hasn't propagated yet. Just wait.

**"I get a 'too many redirects' error in Chrome"**
- The SSL certificate isn't ready yet. Wait 5-10 minutes for it to provision.

**"I get 'site not secure' warning"**
- The SSL certificate isn't ready yet. Same as above.

**"I see Hostinger's old page on gridnode.network"**
- DNS hasn't fully propagated. The nameserver change is propagating, but some DNS servers might still be pointing to Hostinger. Wait 30-60 minutes.

**"Chrome shows a 'Reset PWA' option"**
- Chrome remembers the old PWA state. Go to Chrome menu → Settings → Site Settings → gridnode.network → Clear & reset. Then refresh.

---

## The order matters

1. ✅ **Part 1 first** (Cloudflare account + add site) — you need the nameservers from this step
2. ✅ **Part 2 second** (Porkbun nameserver change) — uses the nameservers from Part 1
3. ⏳ **Wait for propagation** (5-30 minutes)
4. ✅ **Part 3 third** (verify Cloudflare is in charge) — confirms Part 2 worked
5. ✅ **Part 4 fourth** (add custom domain to Pages) — only after Part 3 is done
6. ⏳ **Wait for SSL** (1-5 minutes)
7. ✅ **Part 5 fifth** (test on your phone)
8. ✅ **Part 6 sixth** (test on iPhone)

Don't try to skip ahead. Each step depends on the previous one being complete.

---

## What I'll do once you're set up

When you wake up tomorrow:

1. **Tell me it's done** — I'll verify the deployment and run the verification script
2. **Test the PWA install** — confirm the native banner shows (not the fallback)
3. **Move to Supabase auth** (Priority 4) — the data layer with isolated Supabase calls
4. **Build features at full speed** — the Velocity Directive says ship by default

---

## If you get stuck

Open a new chat and tell me where you're stuck. I'll walk you through it.

Common gotchas:
- **Nameservers don't change instantly** — wait 30 min, don't panic
- **SSL takes a few minutes** — be patient, don't keep refreshing
- **Cached PWA state in Chrome** — clear site data if the old PWA keeps appearing
- **Hostinger still serves the old page** — propagation issue, wait 30-60 min

---

## TL;DR

1. Add `gridnode.network` to Cloudflare (5 min) — copy the 2 nameservers
2. Paste those 2 nameservers into Porkbun (3 min)
3. Wait 10-30 min for propagation
4. Add `gridnode.network` as custom domain in Cloudflare Pages (5 min)
5. Wait 1-5 min for SSL
6. Test on your phone — Chrome PWA install should now work natively
7. Tell me when it's done, I move to Supabase

**Total time: 20-30 minutes, mostly waiting.**

---

**If you want to skip Porkbun entirely and just use Cloudflare nameservers** (which is what we're doing), here's the short version:

Porkbun → click your domain → Nameservers → "Custom" → paste Cloudflare's two nameservers → save.

That's the whole 3-minute step.

Good night. 🛏️
