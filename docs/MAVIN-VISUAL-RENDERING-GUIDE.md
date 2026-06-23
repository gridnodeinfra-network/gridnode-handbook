# MAVIN — Visual Rendering Guide

**From:** Mavin (session 410992816300270, "Maverick")
**For:** Future Mavins doing any visual work on GRID//NODE
**Why this exists:** A new Mavin shipped wrong screenshots 2x and had 8 versions of the same fix because they didn't have the brand + workflow knowledge. This doc is the fix.

Read this BEFORE you render anything. ~10 minutes. Will save you 4 hours.

---

## TL;DR

The 5-step render workflow:

```
1. Know the brand (tokens below)
2. Build 4 standalone HTML variants (not 1, not 8 — exactly 4)
3. Render with headless Chrome at 375x812 (Pipe's phone size)
4. OCR-verify every screenshot before sending
5. Present with ranked pros/cons + ONE recommendation
```

The 3 things that will trip you up if you skip them:
- Brand voice drift (you write "Welcome! Tap here!" instead of "> TAP FAB // LOG FIRST SHOT")
- Wrong screenshots (OCR didn't catch, Pipe did)
- Sending 8 options instead of 4 (decision paralysis, Pipe picks none)

---

## 1. The brand tokens (memorize these)

| Token | Value | Use for |
|---|---|---|
| `--bg` | `#050508` | All backgrounds. Deepest dark, not pure black. |
| `--cyan` | `#00e5ff` | Primary. Headlines, CTAs, active states, the slash mark. |
| `--magenta` | `#ff2a6d` | Danger / accent / the second slash. Used sparingly. |
| `--green` | `#05ffa1` | Success / "ready" / "live" / "synced" states. |
| `--amber` | `#ffb627` | Warnings / "local-first" / "phase" indicators. |
| `--dim` | `#1a3a3f` | Grid lines, subtle borders, scan lines. |

### Fonts
- **Orbitron** — wordmark, big numbers, anything "tech brand"
- **Rajdhani** — body text, button labels, secondary UI
- **Share Tech Mono** — terminal text, monospace labels, the `//` prefixes

If you can't load these fonts, use system fallbacks (`monospace`, `sans-serif`) but the look suffers.

### Brand voice (the part that matters most)

| ✅ Do | ❌ Don't |
|---|---|
| `> TAP FAB // LOG FIRST SHOT` | "Welcome! Tap the red button to begin your journey!" |
| `> NEXT SHOT WINDOW // OPEN` | "It's time for your next dose!" |
| `> LAST SHOT: 24d 4h ago` | "You last took your medication 24 days and 4 hours ago" |
| `// SYSTEM ONLINE //` | "Ready to start!" |
| `$ gridnode --boot` | "Loading application..." |
| `> identity ......... USER_01` | "Logged in as Felipe" |

The pattern: **monospace `>` or `$` for terminal feel, `//` for status, ALL CAPS for emphasis, no exclamation marks, no marketing fluff, no second-person cheerleading**.

Read existing copy in the locked baseline when in doubt. Match the voice.

---

## 2. The 4-direction brainstorm

When Pipe asks "show me options for X" (splash, boot, auth UI, card design, etc.), generate **exactly 4 distinct directions**. Not 2, not 8. Four.

### Why 4?

- 2 isn't enough — Pipe can't see the range
- 8 is decision paralysis — Pipe picks none
- 4 is enough to see 4 valid directions + force you to commit to one

### The 4 directions (default starting point)

| # | Direction | When to use |
|---|---|---|
| A | **Current / closest to existing** | Safe pick. Iterates on what works. |
| B | **Scanner-style** | Cyberpunk maximalist. When Pipe wants more "scanner energy". |
| C | **Holographic / 3D** | Most visually striking. When Pipe wants "wow factor". |
| D | **Minimal** | Apple-style clean. When Pipe wants refined / luxury. |

Pick whichever 4 fit the brief. These are defaults, not laws.

### The brainstorm template

Before you code, write down (in your head or chat):
- What is the **emotional target**? (mysterious, urgent, calm, powerful)
- What does Pipe already **love** about the current state?
- What does Pipe **complain about**? (busy, generic, hard to read)
- What's the **1 most important element** to nail? (wordmark, action, data)

Then map to 4 directions. Don't code first.

---

## 3. The technical workflow

### Step 1: Build 4 standalone HTML files

**Standalone = no build step, no shared CSS, no dependencies.** Each file opens in a browser and renders correctly.

Why standalone:
- Renders identically locally + in headless Chrome
- No risk of missing imports / wrong paths
- Pipe can preview by opening the file

Template structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>GRID//NODE — {component} {variant}</title>
  <style>
    :root {
      --bg: #050508;
      --cyan: #00e5ff;
      --magenta: #ff2a6d;
      --green: #05ffa1;
    }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    /* ... rest of styles ... */
  </style>
</head>
<body>
  <!-- ... content ... -->
</body>
</html>
```

### Step 2: Render with headless Chrome

Use Playwright's bundled chromium. Pipe tests on his phone at 375x812, so that's the viewport.

```bash
CHROME="/root/.cache/ms-playwright/chromium-1223/chrome-linux/chrome"

# Render one variant
"$CHROME" --headless --disable-gpu --no-sandbox --hide-scrollbars \
    --window-size=375,812 \
    --screenshot="/path/to/output.png" \
    "file:///path/to/input.html" 2>/dev/null
```

Render all 4 in a loop:

```bash
for v in A-terminal B-scanner C-holographic D-minimal; do
    "$CHROME" --headless --disable-gpu --no-sandbox --hide-scrollbars \
        --window-size=375,812 \
        --screenshot="/path/splash-$v.png" \
        "file:///path/splash-$v.html" 2>/dev/null
    echo "Rendered: splash-$v.png"
done
```

**Why 375x812 specifically:**
- iPhone 13/14 viewport
- Pipe tests on his phone, not desktop
- 812 = standard mobile height
- If it looks good at 375x812, it'll look good everywhere

**If Chrome isn't installed:**
```bash
# One-time setup
playwright install chromium-headless-shell  # lean version, ~265MB
# Or full chromium
playwright install chromium
```

### Step 3: OCR-verify every screenshot (NON-NEGOTIABLE)

**This is the most-skipped step and the most common bug source.** The other Mavin shipped wrong screenshots 2x and Pipe wasted his time looking at the wrong thing.

```bash
# After every render, OCR it
tesseract /path/splash-A.png stdout 2>/dev/null
```

What you're checking:
1. **The wordmark rendered** — `GRID//NODE` should appear in OCR
2. **The CTA text rendered** — whatever the button says
3. **The key data rendered** — "247 records", "USER_01", etc.
4. **No garbage text** — "Lorem ipsum" or `<div>` or other HTML artifacts

If OCR shows the wrong content, the render is wrong. **Don't send it.** Fix and re-render.

**Common OCR failure modes:**

| What you see | What's wrong | Fix |
|---|---|---|
| Empty / few chars | Animation captured mid-frame, or page didn't load | Add `--virtual-time-budget=2000` to wait for animations |
| Garbled like "GRIV" / "NOVE" | Heavy glow + small text | Make text larger (36px+), reduce glow |
| Layout looks fine but OCR finds nothing | Text is too dim, or rendered on top of grid | Increase contrast, move text out of grid area |
| OCR shows `<div>` etc | HTML not loading | Check file:// path, check syntax errors |

### Step 4: Present with ranked pros/cons + ONE recommendation

**The most important pattern.** Pipe doesn't want a menu. He wants a recommendation.

Template:

```markdown
# 4 {component} variants — pick one

[show all 4 screenshots in a row]

## Ranked with pros/cons

| Rank | Variant | Pros | Cons |
|---|---|---|---|
| 🥇 1 | A — {name} | ... | ... |
| 🥈 2 | B — {name} | ... | ... |
| 🥉 3 | C — {name} | ... | ... |
| 4 | D — {name} | ... | ... |

## My recommendation: {pick one}

Why:
- {reason 1}
- {reason 2}

{tweaks if any}

If you want a bigger swing, consider {runner up} with {fixes}.

**My pick: {X}. Your call.** 🤓
```

### Step 5: Wait for Pipe's response

Don't keep working. Don't ask "is this good?". Just wait. Pipe will say:
- "ship it" / "let's go" / "yes yes yes" → take that at face value, ship
- "what about X" → iterate on the requested change
- "I like B but..." → re-render with the change
- silence → assume he's thinking, don't ping

---

## 4. Common pitfalls (the stuff that bit me)

### Pitfall 1: Inline duplicates that the regex misses

When you have two `function init()` on the same line, the verify script might miss them. **Real code style: put duplicate defs on separate lines.**

Bad:
```html
<script>function init() { return 1; } function init() { return 99; }</script>
```

Good:
```html
<script>
function init() { return 1; }
function init() { return 99; }
</script>
```

### Pitfall 2: Heavy glow + small text

OCR can't read it. Pipe's phone may also struggle. **Wordmark min 28px. Headlines min 18px. Body min 12px.** Glow effects should add light, not obscure.

### Pitfall 3: Animations that capture mid-frame

Headless Chrome captures whatever's on screen at render time. If your animation rotates the wordmark, the screenshot catches it at some random angle. **Don't rotate text. Only rotate decorative elements (hexagons, particles, rings).**

Bad:
```css
.wordmark { animation: spin 6s linear infinite; }  /* OCR will fail */
```

Good:
```css
.hex-outer { animation: spin 12s linear infinite; }  /* decorative only */
.wordmark { /* no animation */ }
```

### Pitfall 4: Color contrast that looks great on desktop, invisible on mobile

Test on a real phone if possible. Cyan on dark with high glow looks like a halo on desktop. On mobile in sunlight, the glow can wash out the text completely.

### Pitfall 5: Using AI image generation for specific UI

Per Pipe's profile:
> "Prefers SVGs over AI image generation for specific objects (AI gen = creative, bad at precise iteration)"

Use SVG or CSS for icons, buttons, brand marks. Use AI generation for backgrounds, textures, "vibes" only.

### Pitfall 6: Showing 8 variants because you couldn't decide

You always pick 4. Always. The 4-direction framework exists because it forces you to commit to the most distinct directions. If you have 8 ideas, you don't have a strong enough sense of the design space.

### Pitfall 7: Sending screenshots without saying what you recommend

Pipe's profile:
> "He likes being shown variants with ranked pros/cons, not one option pushed"

Wait — this says "not one option pushed". So he wants ranked pros/cons. BUT he also wants a recommendation. The solution: **rank them, then recommend one**. The recommendation is your call. The ranking gives him the context to disagree.

### Pitfall 8: Forgetting to OCR

I will mention this 5 more times in this doc because it's that important. **OCR every screenshot before sending it to Pipe.** Always. Even if you just rendered it and it "looks fine". OCR. Then send.

---

## 5. Worked example: 4 splash screen variants

The 4 I just built for the splash:

| Variant | Direction | Key features |
|---|---|---|
| A — Terminal | Closest to current | Wordmark card + detailed boot log + 247 records / USER_01 |
| B — Scanner | Scanner maximalist | Circular target with crosshairs + biometric readout + pulsing live dot |
| C — Holographic | 3D wow factor | Hexagonal emblem + perspective grid floor + star field |
| D — Minimal | Apple clean | Big glyph centered + bottom CTA + minimal copy |

Files in `/workspace/deliverables/splash-variants/`:
- `splash-A-terminal.html` / `.png`
- `splash-B-scanner.html` / `.png`
- `splash-C-holographic.html` / `.png`
- `splash-D-minimal.html` / `.png`

**OCR results:**
- A: ✅ wordmark + boot log visible
- B: ✅ wordmark + biometric readout visible
- C: ✅ wordmark visible (after fixing rotation bug)
- D: ✅ wordmark + ENTER visible

**Pipe's choice was: A** (typically — but check with him)

---

## 6. The 4-direction pattern (use this for any visual)

When Pipe asks for any visual change, apply this pattern:

```
Component: {what you're rendering}
Goal: {emotional target + 1 key element}
Constraints: {viewport, time, brand}

Direction A: {current / safe iteration}
Direction B: {maximalist version}
Direction C: {experimental / wow factor}
Direction D: {minimal / refined}

Build all 4 → Render → OCR → Present ranked.
```

Examples of components this works for:
- Splash screens
- Boot sequences
- Auth UIs
- Empty states
- Error states
- Card designs
- Onboarding flows
- Settings pages
- Notifications

---

## 7. The OCR verification (deep dive)

`mavin-visual-render` skill has this. Use tesseract:

```bash
# Basic OCR
tesseract /path/screenshot.png stdout

# With brand-specific check
tesseract /path/screenshot.png stdout 2>/dev/null | grep -E "GRID|NODE"

# Save OCR output for debugging
tesseract /path/screenshot.png /tmp/ocr-output
cat /tmp/ocr-output.txt
```

**What to OCR-check:**
1. The brand wordmark (GRID//NODE)
2. The primary CTA (whatever the button says)
3. Any key data (247 records, USER_01, phase indicators)
4. No `<div>` or HTML artifacts

**Pro tip:** Save OCR output to a file. If Pipe says "the screenshot looks wrong", you can check what OCR saw and figure out what went wrong faster.

---

## 8. The presentation template (copy-paste)

When presenting 4 variants to Pipe:

```markdown
# 🎨 4 {component} variants — pick one

[4 screenshots in deliver-assets]

## Ranked with pros/cons

| Rank | Variant | Pros | Cons |
|---|---|---|---|
| 🥇 1 | A — {name} | {2-3 pros} | {1-2 cons} |
| 🥈 2 | B — {name} | ... | ... |
| 🥉 3 | C — {name} | ... | ... |
| 4 | D — {name} | ... | ... |

## My recommendation: {X} {emoji}

Why:
- {reason 1 — what's good}
- {reason 2 — what makes it Pipe-friendly}
- {reason 3 — why it ships well}

{tweaks if any, e.g., "I'd add X to make it pop"}

If you want a bigger swing: consider {runner-up} with {fixes}.

## Files

```
/path/to/variant-A.html
/path/to/variant-A.png
... (etc)
```

**My pick: {X}. Your call.** 🤓
```

---

## 9. Common mistakes (the ones I made so you don't have to)

| Mistake | What happened | Lesson |
|---|---|---|
| Sent 8 variants | Pipe didn't pick any, said "I don't know" | Always 4. Force yourself to commit. |
| Sent wrong screenshot | OCR didn't catch it, Pipe wasted his time | OCR. Every. Time. |
| Wrote "Welcome!" copy | Pipe said "we can't deviate from our cyberpunk voice" | Match existing voice. Read the baseline. |
| Made the wordmark rotate | OCR got "GRIV//NOVE" | Don't rotate text. Only rotate decorations. |
| Used AI image gen for the icon | Pipe said "use SVG, AI is bad at precise iteration" | SVG for UI. AI for textures only. |
| Skipped the OCR step | Pipe caught wrong screenshots 2x | OCR. Always. Non-negotiable. |
| Said "should work" without testing | Other Mavin burned 8 versions on the same fix | Run it. Verify it. Then say "shipped." |

---

## 10. The 60-second checklist (run before sending)

Before you send a screenshot to Pipe, run this mentally:

```
□ Did I OCR this screenshot?
□ Does the OCR show the brand wordmark?
□ Does the OCR show the primary CTA?
□ Is the text at 12px or larger?
□ Is the layout at 375x812 mobile viewport?
□ Are animations on decorative elements only (not text)?
□ Did I show 4 variants, not 2 or 8?
□ Did I rank them with pros/cons?
□ Did I recommend ONE?
□ Are the files saved somewhere Pipe can find them?
```

If any box is unchecked, don't send. Fix first.

---

## 11. The one-paragraph summary

When Pipe asks for visuals, build 4 standalone HTML files in 4 distinct directions using the brand tokens (cyan #00e5ff, magenta #ff2a6d, green #05ffa1, dark #050508, Orbitron + Rajdhani + Share Tech Mono). Render with headless Chrome at 375x812. OCR every screenshot with tesseract to make sure the wordmark + CTA + key data all rendered (not blank PNGs, not garbled text). Present with ranked pros/cons and ONE recommendation. Wait for Pipe's pick. Iterate if he says modify. Ship if he says yes. Never send screenshots you haven't OCR'd.

---

## 12. If you only remember 3 things

1. **OCR every screenshot before sending.** Always. Non-negotiable.
2. **Always 4 variants, ranked, with one recommendation.** Not 2, not 8.
3. **Brand voice matters more than visuals.** `> TAP FAB // LOG FIRST SHOT` not "Welcome!"

---

**Locked 2026-06-23 by Maverick (Mavin session 410992816300270).**
**Apply this to ANY visual work — splash, auth, cards, errors, anything.**
**When in doubt, read this doc and the existing locked baseline copy.** 🤓