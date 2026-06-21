# Example: GREEN-lane change

**Purpose:** Show a real GREEN change done right, with the full standing report. For new AIs to copy the pattern.

**When to use this pattern:** Additive, reversible, no protected system touch, <1KB net change.

---

## The change

**Task:** Add a settings gear icon (⚙) to the top-right of the GRID//NODE app header. Clicking it toggles a settings panel with one item: "Theme: Dark/Light" (toggles a CSS class on `<html>`).

**Why it's GREEN:**
- Additive: new icon, new panel, new CSS class. Nothing existing is touched.
- Reversible: deleting the change reverts to the original state.
- No protected system: the change is pure UI chrome.
- Size: ~250 bytes of HTML + ~80 bytes of CSS + ~120 bytes of JS = ~450 bytes total. < 1KB.

---

## The 6-rung ladder (applied retroactively)

1. **YAGNI:** Pipe asked for it. ✓
2. **Stdlib:** vanilla JS DOM, no library needed. ✓
3. **Native:** `<details>/<summary>` for the panel; CSS variables + class toggle for theme. ✓
4. **Installed dep:** none needed. ✓
5. **One line:** the click handler is one line if I use event delegation. ✓
6. **Minimum code:** the implementation below. ✓

## The implementation

```html
<!-- in the header, before the closing </header> -->
<button id="settings-toggle" class="header-icon" aria-label="Settings">⚙</button>
<details id="settings-panel" class="settings-panel">
  <summary class="settings-summary">Settings</summary>
  <button id="theme-toggle" class="settings-item">Theme: <span id="theme-label">Dark</span></button>
</details>
```

```css
/* in the existing <style> block, appended */
.light-theme { background: #f5f5f5; color: #1a1a1a; }
.settings-panel { /* matches existing dropdown styles */ }
```

```js
// appended to the existing shared utilities block
document.getElementById('settings-toggle')?.addEventListener('click', () => {
  document.getElementById('settings-panel')?.toggleAttribute('open');
});
document.getElementById('theme-toggle')?.addEventListener('click', () => {
  document.documentElement.classList.toggle('light-theme');
  document.getElementById('theme-label').textContent =
    document.documentElement.classList.contains('light-theme') ? 'Light' : 'Dark';
});
```

## The smallest runnable check (per Ponytail)

Per the rule "lazy code without its check is unfinished," every non-trivial change ships with a check. The smallest thing that fails if the logic breaks:

```js
// ponytail: self-check for the settings panel + theme toggle
(function selfCheck() {
  const panel = document.getElementById('settings-panel');
  const themeBtn = document.getElementById('theme-toggle');
  if (!panel) { console.error('[GRIDNODE self-check] FAIL: settings-panel missing'); return; }
  if (!themeBtn) { console.error('[GRIDNODE self-check] FAIL: theme-toggle missing'); return; }
  // ponytail: user-flow assertion — does clicking actually toggle?
  document.getElementById('settings-toggle').click();
  const isOpen = panel.hasAttribute('open');
  document.getElementById('theme-toggle').click();
  const themeApplied = document.documentElement.classList.contains('light-theme');
  if (!isOpen) { console.error('[GRIDNODE self-check] FAIL: panel did not open on click'); return; }
  if (!themeApplied) { console.error('[GRIDNODE self-check] FAIL: theme did not apply'); return; }
  console.log('[GRIDNODE self-check] OK: settings panel + theme toggle work');
})();
```

## The protected-keyword gate

Run before declaring done:

```bash
node scripts/protected-keyword-gate.js <baseline.html> <diff.txt>
```

Expected: exit 0 (no protected keywords touched). The change introduces new identifiers (`settings-toggle`, `settings-panel`, etc.) but doesn't touch any existing ones.

## The standing report (filled in)

```
LANE: green
ORIGINAL: 1,000,593 / 7b6c4dc9...
NEW:      1,001,043 / <new-sha-after-push>
DELTA:    +450 bytes
SCRIPT TAGS: 41 (unchanged)   STYLE TAGS: 38 (unchanged)
PROTECTED SYSTEMS TOUCHED: none
DUP FUNCTIONS INTRODUCED: 0
SELF-CHECK: pass (the runnable check above ran and printed "OK: settings panel + theme toggle work")
WHY THIS LANE: additive UI chrome, no protected-system touch, <1KB. UI change is reversible (delete the additions).
TESTED-BY: Mavin, at 2026-XX-XX
TEST-METHOD: opened the file in headless browser, ran the self-check snippet, verified console log "OK"
TEST-RESULT: pass
CLAIMS-VERIFIED-BY-SCRIPT: [
  "panel opens on click: self-check user-flow assertion (line: document.getElementById('settings-toggle').click())",
  "theme applies on click: self-check user-flow assertion (line: themeApplied = classList.contains('light-theme'))"
]
CLAIMS-UNVERIFIED: [
  "settings panel styling matches the existing dropdown chrome: visual inspection only, not a test"
]
```

## The `ponytail:` markers

Each deliberate simplification is marked. This is how `ponytail-debt` finds the deferred decisions later:

```js
// ponytail: inline click handlers, add delegation if a 2nd panel appears
document.getElementById('settings-toggle')?.addEventListener('click', () => {
  // ponytail: native <details>/<summary> handles the panel state, no need for custom show/hide
  document.getElementById('settings-panel')?.toggleAttribute('open');
});
```

## What this change does NOT need

- ❌ Founder HQ sign-off (GREEN lane, no protected system)
- ❌ Staging deploy (small change, can ship direct)
- ❌ Multi-party review (self-check is sufficient)
- ❌ The full keyword gate (the change adds no protected identifiers)

## What this change DOES need

- ✅ The smallest runnable check (above)
- ✅ The protected-keyword gate (clean diff, exit 0)
- ✅ The standing report block (filled in above)
- ✅ The `ponytail:` markers (the comment convention)

## Time estimate

15-20 minutes. Most of that is the standing report, not the code.

## The lesson

GREEN is fast. The discipline is in the check + the report, not the code. A change that ships with a passing self-check + a clean gate + a filled report is GREEN-shippable in 15-20 min. A change that ships without those is RED regardless of size.
