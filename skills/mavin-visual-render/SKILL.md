---
name: mavin-visual-render
description: >
  Use this when Mavin needs to render a PWA/web page and capture screenshots
  for visual verification, comparison, or iteration with the user. Especially
  useful for:
  - Verifying CSS changes render correctly on mobile
  - Comparing multiple design variants side-by-side
  - Showing the user what a change will look like before deploying
  - Catching visual bugs (text overlap, alignment, color)
  - Generating mockups for review
  Triggers: "render", "screenshot", "show me", "what does this look like",
  "compare variants", "iterate", "design options", "mockup", "preview",
  "see the result", "verify it works visually"
---

# Mavin Visual Render Pattern

The pattern Mavin used for all GRID//NODE visual changes. This is the
canonical way to render, capture, compare, and verify web page changes.

## When to use this

- ✅ Verifying a CSS or HTML change looks right before deploying
- ✅ Comparing multiple design variants to pick the best
- ✅ Capturing screenshots for documentation or sharing
- ✅ Iterating on a design with the user (show → pick → iterate)
- ✅ Generating preview images of the actual product
- ❌ For non-visual changes (logic, data, performance) — use other methods

## The 3 tools you need

These should already be installed by the bootstrap:
- **Playwright** (Python or Node) — headless browser
- **Tesseract** — OCR for text verification
- **ImageMagick** — image comparison and manipulation

## The pattern (Python)

```python
from playwright.sync_api import sync_playwright

def capture_screenshots(url, name, viewports=None):
    """
    Capture screenshots at multiple viewports.
    
    Args:
        url: URL to render (or file:// path to local HTML)
        name: base filename, e.g., "splash-final"
        viewports: list of (width, height) tuples
                  defaults to mobile + desktop
    """
    if viewports is None:
        viewports = [(375, 812), (768, 1024), (1440, 900)]
    
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        
        for w, h in viewports:
            context = browser.new_context(
                viewport={'width': w, 'height': h},
                device_scale_factor=2,  # retina
            )
            page = context.new_page()
            page.goto(url, wait_until='networkidle')
            
            # Wait for any animations to settle
            page.wait_for_timeout(1000)
            
            # Full page screenshot
            filename = f"/workspace/deliverables/{name}-{w}x{h}.png"
            page.screenshot(path=filename, full_page=True)
            print(f"Captured: {filename}")
            
            context.close()
        
        browser.close()

# Usage:
capture_screenshots(
    "https://gridnode.network",
    "current-state",
    viewports=[(375, 812)]  # just mobile
)
```

## The pattern (for design variants)

When showing multiple options to the user:

```python
# 1. Generate 3-4 variants
variants = [
    ("option-a", "https://gridnode.network?variant=a"),
    ("option-b", "https://gridnode.network?variant=b"),
    ("option-c", "https://gridnode.network?variant=c"),
]

# 2. Render each
for name, url in variants:
    capture_screenshots(url, name)

# 3. Show user side-by-side
print("Captured 3 variants:")
print("  - /workspace/deliverables/option-a-375x812.png")
print("  - /workspace/deliverables/option-b-375x812.png")
print("  - /workspace/deliverables/option-c-375x812.png")
print()
print("Which do you prefer?")
```

## The pattern (for verification)

After making a change, verify it actually rendered correctly:

```python
from playwright.sync_api import sync_playwright
import subprocess

def verify_text_rendered(url, expected_text):
    """Take screenshot and OCR to verify text appears."""
    
    # Step 1: Capture
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={'width': 375, 'height': 812},
            device_scale_factor=2,
        )
        page = context.new_page()
        page.goto(url, wait_until='networkidle')
        page.wait_for_timeout(2000)  # let animations finish
        
        screenshot_path = f"/tmp/verify-{int(time.time())}.png"
        page.screenshot(path=screenshot_path, full_page=False)
        
        # Step 2: OCR
        result = subprocess.run(
            ['tesseract', screenshot_path, 'stdout'],
            capture_output=True, text=True
        )
        ocr_text = result.stdout.strip()
        
        # Step 3: Check
        if expected_text in ocr_text:
            print(f"✅ '{expected_text}' found in screenshot")
            return True
        else:
            print(f"❌ '{expected_text}' NOT found")
            print(f"   OCR found: {ocr_text}")
            return False
        
        context.close()
        browser.close()

# Usage:
verify_text_rendered("https://gridnode.network", "LOG YOUR DOSE")
```

## The pattern (for image comparison)

To verify a change didn't break anything visually:

```python
import subprocess

def compare_images(before_path, after_path, threshold=0.95):
    """Use ImageMagick to compute similarity."""
    
    result = subprocess.run([
        'compare',
        '-metric', 'AE',  # absolute error
        '-fuzz', '5%',     # 5% fuzz tolerance
        before_path, after_path,
        '/tmp/diff.png'
    ], capture_output=True, text=True)
    
    # Parse the AE number
    # Lower = more similar (0 = identical)
    ae = int(result.stderr.strip().split()[0])
    
    total_pixels = ...  # compute from image dimensions
    similarity = 1.0 - (ae / total_pixels)
    
    return similarity > threshold
```

## Where to save screenshots

| Use case | Save to | Naming |
|---|---|---|
| Visual verification (one-off) | `/tmp/` | Any name |
| Documentation/sharing | `/workspace/deliverables/` | `feature-state.png` |
| Time-based (animations) | `/workspace/screenshots/` | `feature-time-{t}.png` |
| Variant comparison | `/workspace/deliverables/` | `feature-variant-{a,b,c}.png` |

## File naming convention

Always use this pattern so the next Mavin (and you) can find them:

```
{what-it-shows}-{state-or-variant}-{optional-modifier}.png

Examples:
- splash-final.png           # the final version of the splash
- splash-variant-a.png       # variant A of the splash
- boot-after-fix-5s.png     # boot screen 5 seconds after the fix
- auth-final-v2-wide.png     # auth screen v2, wide viewport
- cf-clean-home.png         # "clean" Cloudflare cache, home page
```

## Common viewport sizes

For GRID//NODE (Android-focused):

| Device | Width | Height | Use |
|---|---|---|---|
| iPhone SE (small) | 375 | 667 | Smallest target |
| iPhone 13 | 390 | 844 | Standard mobile |
| iPhone Pro Max | 428 | 926 | Large mobile |
| iPad | 768 | 1024 | Tablet |
| Desktop | 1440 | 900 | Web fallback |

For Pipe specifically (Android), test at:
- 360 × 800 (most common Android phone)
- 412 × 915 (Pixel-style)
- 768 × 1024 (if tablet)

## Common gotchas

1. **Animations not finished** — always `wait_for_timeout` for at least 1-2 seconds
2. **Service worker interference** — load with cache-busting query param `?v=2`
3. **PWA install banner** — might show on first load, use `localStorage.clear()` first
4. **Mobile viewport vs screen** — set `device_scale_factor=2` for retina
5. **localStorage state** — clear between captures to avoid cached state

## Full example: render and compare 3 design variants

```python
from playwright.sync_api import sync_playwright
import subprocess

variants = {
    "a": "https://gridnode.network?variant=a&cache=bust1",
    "b": "https://gridnode.network?variant=b&cache=bust2",
    "c": "https://gridnode.network?variant=c&cache=bust3",
}

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    context = browser.new_context(
        viewport={'width': 375, 'height': 812},
        device_scale_factor=2,
    )
    page = context.new_page()
    
    for name, url in variants.items():
        page.goto(url, wait_until='networkidle')
        page.wait_for_timeout(1500)  # animations
        
        # Clear localStorage to avoid cached state
        page.evaluate("localStorage.clear()")
        page.reload(wait_until='networkidle')
        page.wait_for_timeout(1500)
        
        # Capture
        path = f"/workspace/deliverables/design-{name}.png"
        page.screenshot(path=path, full_page=True)
        print(f"Captured: {path}")
    
    browser.close()

# Then OCR-verify text in each
for name in variants:
    path = f"/workspace/deliverables/design-{name}.png"
    result = subprocess.run(
        ['tesseract', path, 'stdout'],
        capture_output=True, text=True
    )
    print(f"\n{name}: {result.stdout.strip()[:100]}")

# Then send to user with file attachments
print("\nAll variants captured:")
print("- /workspace/deliverables/design-a.png")
print("- /workspace/deliverables/design-b.png")
print("- /workspace/deliverables/design-c.png")
```

## What you should tell the user

After rendering variants:

```
Rendered 3 design variants at 375x812 (mobile):
- /workspace/deliverables/design-a.png
- /workspace/deliverables/design-b.png
- /workspace/deliverables/design-c.png

OCR confirmed:
- a: "GRID//NODE / LOG YOUR DOSE / SEE WHAT WORKS / GET STARTED"
- b: "GRID//NODE / TRACK YOUR DOSE / SEE YOUR LEVELS / START NOW"
- c: "GRID//NODE / NEVER GUESS AGAIN / TAP TO LOG / BEGIN"

Which do you prefer? (a, b, c, or "show me more")
```

## Why this pattern works

1. **Real browser, real rendering** — not mocked HTML
2. **Multiple viewports** — covers Pipe's actual device
3. **OCR verification** — catches bugs before Pipe sees them
4. **Side-by-side comparison** — easy decision-making
5. **File attachments** — Pipe can share with anyone
6. **Cache busting** — shows the current state, not stale cache

## The setup (one-time)

Make sure these are installed (already in install-tools.sh):

```bash
# Python
pip install playwright pillow pytesseract
playwright install chromium

# System
apt-get install tesseract-ocr imagemagick
```

## When NOT to use this

- For pure data/logic changes (no visual)
- For backend API work (no rendering)
- For performance testing (use proper perf tools)
- For accessibility testing (use axe-core)

For those, use other tools. This skill is for visual rendering only.

---

**The next Mavin reads this skill file and knows exactly how to render, capture, OCR-verify, and present design variants to the user.**