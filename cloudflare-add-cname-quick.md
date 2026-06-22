# Cloudflare: Add CNAME for gridnode.network (simplest possible)

**You're on:** Cloudflare dashboard with the "Welcome to the new DNS experience" popup
**Goal:** Add 1 CNAME record. That's it.

---

## Click-by-click (no thinking required)

1. **Tap the blue "Got it" button** at the bottom of the popup
   - It dismisses the welcome screen
   - You should see the actual DNS records page

2. **Look for the "+ Add record" button**
   - It's usually at the **top right** of the records list
   - Or it might say **"Add record"** in a button

3. **Tap "+ Add record"**
   - A form slides in or appears

4. **Fill in the form. Exactly these values:**

| Field | What to type |
|---|---|
| **Type** | `CNAME` (tap the dropdown if needed, scroll to find CNAME) |
| **Name** | `@` |
| **Target** (or "Content") | `gridnode.pages.dev` |
| **Proxy status** | Make sure the cloud icon is **orange** (proxied). If it's grey, tap it. |
| **TTL** | Leave default (Auto or 3600) |

5. **Tap "Save"** (usually a checkmark ✓ or "Save" button)

**Done. That's the whole thing.**

---

## Wait 1-5 minutes

DNS records propagate. Don't refresh immediately. Set a timer for 5 minutes if you want, then test.

---

## How to verify it worked

Open a browser (incognito if you want to be sure) and go to:

**`https://gridnode.network`**

**What you should see:**

- The page loads
- It looks like the new GRID//NODE (not the old Hostinger version)
- Browser DevTools → Network → response should come from `gridnode.pages.dev` or show Cloudflare headers

**If it still shows the old Hostinger page:**
- Wait 5 more minutes
- Try in an incognito window
- Clear browser cache

---

## How to verify PWA install works on phone

1. Open Chrome on Android phone
2. Go to `https://gridnode.network`
3. **Pull down to hard refresh** (or close/reopen the tab)
4. Wait 5-15 seconds
5. **Branded install banner appears** at the bottom with cyan INSTALL button
6. Tap INSTALL → Chrome's install dialog
7. Tap Add → home screen icon
8. Tap home screen icon → **app opens full-screen, no browser chrome, looks like a real native app** ✅

If the banner doesn't appear or shows the fallback "Use browser menu" copy:
- Wait longer (Chrome sometimes takes a moment)
- Try in incognito
- Clear Chrome's site data for gridnode.network

---

## TL;DR

1. Got it button (dismiss popup)
2. + Add record
3. CNAME | @ | gridnode.pages.dev | orange cloud
4. Save
5. Wait 5 min
6. Test on phone

Total clicks: 5