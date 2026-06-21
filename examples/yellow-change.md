# Example: YELLOW-lane change

**Purpose:** Show a real YELLOW change done right, with the full standing report. For new AIs to copy the pattern.

**When to use this pattern:** New feature, touches shared scope, moderate size (1-5KB), OR reads from a protected system without modifying it.

---

## The change

**Task:** Add a "Weight Chart" panel to the RESULTS tab. Shows the user's weight records over the last 30 days as a simple sparkline (line chart, no axes, just the shape). Reads from `gn_settings` (protected) to get the weight unit (lb/kg), then displays the records.

**Why it's YELLOW:**
- New feature: a new panel, new visual element. ✓
- Touches shared scope: depends on the existing `getWeightRecords()` function and the protected `gn_settings` localStorage key.
- Size: ~2-3KB (HTML + CSS + JS for the sparkline).
- Reads from a protected system (`gn_settings`) but doesn't modify it.

**Why it's NOT RED:**
- Doesn't modify `gn_settings` (just reads).
- Doesn't modify `getWeightRecords` (just calls it).
- Doesn't touch any of the 14 protected systems directly.

---

## The 6-rung ladder (applied retroactively)

1. **YAGNI:** Pipe asked for it. ✓
2. **Stdlib:** the sparkline can be drawn with `<canvas>` + a 50-line custom plotter, OR a 200-line chart library. We pick the stdlib/custom route. ✓
3. **Native:** canvas is native. ✓
4. **Installed dep:** none. ✓
5. **One line:** the chart-draw function is one tight loop, ~10 lines. ✓
6. **Minimum code:** the implementation below. ✓

## The implementation

```html
<!-- added to the RESULTS tab, before its closing </section> -->
<div id="weight-chart-panel" class="chart-panel">
  <h3>Weight — last 30 days</h3>
  <canvas id="weight-sparkline" width="320" height="80"></canvas>
  <div id="weight-chart-label" class="chart-label"></div>
</div>
```

```css
/* appended to the existing <style> block */
.chart-panel { /* matches existing panel chrome */ }
.chart-label { color: var(--text-mid); font-size: 0.85rem; }
```

```js
// appended to a new <script> block after the existing results rendering
(function renderWeightSparkline() {
  // ponytail: reads from protected gn_settings (vault territory) but doesn't modify it
  const settings = JSON.parse(localStorage.getItem('gn_settings') || '{}');
  const unit = settings.weightUnit || 'lb';
  const records = getWeightRecords(); // protected system call, read-only

  const last30 = records
    .filter(r => r.date && new Date(r.date) > new Date(Date.now() - 30 * 86400000))
    .sort((a, b) => new Date(a.date) - new Date(b.date));

  if (last30.length < 2) {
    document.getElementById('weight-chart-label').textContent = 'Not enough data';
    return;
  }

  const canvas = document.getElementById('weight-sparkline');
  const ctx = canvas.getContext('2d');
  const values = last30.map(r => r.value);
  const min = Math.min(...values);
  const max = Math.max(...values);
  const range = max - min || 1;

  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.strokeStyle = '#00d4ff';
  ctx.lineWidth = 1.5;
  ctx.beginPath();
  last30.forEach((r, i) => {
    const x = (i / (last30.length - 1)) * canvas.width;
    const y = canvas.height - ((r.value - min) / range) * canvas.height;
    if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
  });
  ctx.stroke();

  document.getElementById('weight-chart-label').textContent =
    `${last30[0].value}${unit} → ${last30[last30.length - 1].value}${unit} (${last30.length} records)`;
})();
```

## The smallest runnable check

The change is bigger than a one-liner, so it ships with a self-check:

```js
// ponytail: self-check for the weight sparkline
(function selfCheck() {
  const canvas = document.getElementById('weight-sparkline');
  const label = document.getElementById('weight-chart-label');
  if (!canvas) { console.error('[GRIDNODE self-check] FAIL: sparkline canvas missing'); return; }
  if (!label) { console.error('[GRIDNODE self-check] FAIL: sparkline label missing'); return; }
  // ponytail: user-flow assertion — does rendering produce visible output?
  // Trigger a re-render and check the canvas got pixels
  renderWeightSparkline();
  const ctx = canvas.getContext('2d');
  const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
  const nonTransparent = imageData.data.some((_, i) => i % 4 === 3 && imageData.data[i] > 0);
  if (!nonTransparent) { console.error('[GRIDNODE self-check] FAIL: sparkline has no pixels'); return; }
  console.log('[GRIDNODE self-check] OK: weight sparkline rendered');
})();
```

## The protected-keyword gate

This change **reads** from `gn_settings` and `getWeightRecords` but doesn't modify them. The gate should still pass (the diff doesn't change those identifiers' definitions):

```bash
node scripts/protected-keyword-gate.js <baseline.html> <diff.txt>
```

Expected: exit 0. (If the gate flagged this, it would mean the change accidentally touched a definition — that would force RED.)

## The audit formula check (mandatory for YELLOW)

Before sending, run the saved audit formula:

1. **Duplicate function check:** does this change introduce any function with a duplicate name? (e.g., a second `renderWeightSparkline`)
2. **Scope check:** does this change touch any IIFE-local functions in a way that breaks scope? (Most new functions are added to a fresh IIFE or the shared scope, so this is usually clean.)

Both checks: pass.

## The standing report (filled in)

```
LANE: yellow
ORIGINAL: 1,000,593 / 7b6c4dc9...
NEW:      1,003,156 / <new-sha-after-push>
DELTA:    +2,563 bytes
SCRIPT TAGS: 42 (+1 new)   STYLE TAGS: 38 (unchanged)
PROTECTED SYSTEMS TOUCHED: [WEIGHT RECORDS (read-only), VAULT (read-only via gn_settings)]
DUP FUNCTIONS INTRODUCED: 0
SELF-CHECK: pass
WHY THIS LANE: new feature that reads from protected systems (WEIGHT RECORDS, VAULT) without modifying them. 2.5KB, touches shared scope.
TESTED-BY: Mavin, at 2026-XX-XX
TEST-METHOD: opened the file, added the change, ran self-check, verified canvas has pixels, verified label updates
TEST-RESULT: pass
REVIEWED-BY: Claude, at 2026-XX-XX (one verification pass)
REVIEW-METHOD: ran the protected-keyword gate, ran the audit formula, checked the standing report
CLAIMS-VERIFIED-BY-SCRIPT: [
  "sparkline has visible pixels: self-check imageData scan (line: ctx.getImageData)",
  "label updates with record count: self-check textContent check"
]
CLAIMS-UNVERIFIED: [
  "sparkline looks good visually: visual inspection only, not a test",
  "30-day window is correct: edge case for timezones not exhaustively tested"
]
```

## What this change does NOT need

- ❌ Founder HQ sign-off (YELLOW, no protected-system modification)
- ❌ Full Phase A→D discipline (that's RED)
- ❌ Multi-party review (one verification pass is enough)
- ❌ Trace first (no drift involved)

## What this change DOES need

- ✅ The smallest runnable check (above)
- ✅ The protected-keyword gate (clean diff, exit 0)
- ✅ The audit formula check (no duplicate functions, no scope issues)
- ✅ One verification pass (Claude or self)
- ✅ The full standing report (filled in above)
- ✅ The `ponytail:` markers (the comment convention)

## Time estimate

30-45 minutes. The code is ~20 min; the report + check + gate is ~20 min.

## The lesson

YELLOW is the workhorse. Most real features go here. The discipline is in the audit formula + the gate + the verification pass, not in the code. A change that ships with all three is YELLOW-shippable in 30-45 min. A change that ships without them is RED regardless of size.
