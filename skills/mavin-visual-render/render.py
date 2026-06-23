#!/usr/bin/env python3
"""
mavin-visual-render — render and capture web pages

Usage:
    python3 render.py https://gridnode.network splash-final
    python3 render.py https://gridnode.network?variant=a design-a
    python3 render.py /path/to/local.html local-test
"""

import sys
import subprocess
from pathlib import Path
from playwright.sync_api import sync_playwright

DEFAULT_VIEWPORTS = [
    (375, 812),    # iPhone standard
    (768, 1024),   # iPad
    (1440, 900),   # Desktop
]

def capture(url, name, viewports=None, output_dir="/workspace/deliverables"):
    """Capture screenshots at multiple viewports."""
    if viewports is None:
        viewports = [(375, 812)]  # just mobile by default
    
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        
        for w, h in viewports:
            context = browser.new_context(
                viewport={'width': w, 'height': h},
                device_scale_factor=2,
            )
            page = context.new_page()
            
            # Cache bust
            cache_bust = f"?_t={int(time.time())}" if '?' not in url else f"&_t={int(time.time())}"
            page.goto(url + cache_bust, wait_until='networkidle')
            
            # Let animations settle
            page.wait_for_timeout(2000)
            
            # Clear localStorage to get fresh state
            try:
                page.evaluate("localStorage.clear()")
                page.reload(wait_until='networkidle')
                page.wait_for_timeout(2000)
            except:
                pass
            
            # Capture
            filename = output_path / f"{name}-{w}x{h}.png"
            page.screenshot(path=str(filename), full_page=True)
            print(f"Captured: {filename}")
            
            context.close()
        
        browser.close()
    
    return str(output_path / f"{name}-375x812.png")


def ocr_verify(image_path, expected_text):
    """OCR an image and check if expected text is present."""
    try:
        result = subprocess.run(
            ['tesseract', image_path, 'stdout'],
            capture_output=True, text=True, timeout=30
        )
        ocr_text = result.stdout.strip()
        
        if expected_text.lower() in ocr_text.lower():
            print(f"✅ '{expected_text}' found")
            return True
        else:
            print(f"❌ '{expected_text}' NOT found")
            print(f"   OCR text: {ocr_text[:200]}")
            return False
    except Exception as e:
        print(f"❌ OCR failed: {e}")
        return False


if __name__ == "__main__":
    import time
    
    if len(sys.argv) < 3:
        print("Usage: python3 render.py <url> <name> [viewport_w] [viewport_h]")
        print("Example: python3 render.py https://gridnode.network splash-final")
        sys.exit(1)
    
    url = sys.argv[1]
    name = sys.argv[2]
    
    viewports = None
    if len(sys.argv) >= 5:
        viewports = [(int(sys.argv[3]), int(sys.argv[4]))]
    
    path = capture(url, name, viewports)
    
    # OCR verify
    if path and Path(path).exists():
        print("\nOCR verification:")
        ocr_verify(path, "GRID//NODE")
