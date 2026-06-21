/**
 * boot-speed-snippet.js — measures GRID//NODE boot time on a real device
 *
 * Run this in Chrome DevTools console on a real device (Pipe's phone, etc.)
 * to measure the boot time. The output is the N value for Flex Directive Rule 3.
 *
 * Usage:
 * 1. Open the GRID//NODE app in Chrome on the target device
 * 2. Open DevTools (Chrome menu → More tools → Developer tools, or remote debug)
 * 3. Paste this script into the console
 * 4. Press Enter
 * 5. Reload the page (Cmd+R / Ctrl+R)
 * 6. Wait for the script to log the result
 *
 * Output: a number in milliseconds (boot time from DOMContentLoaded to app screen visible)
 * Run 10 times, take the 90th percentile, add 20% headroom — that's N.
 *
 * IMPORTANT: run this on the REAL TARGET DEVICE (not dev machine, not headless Chromium).
 * The numbers are meaningless on a fast machine.
 */

(function measureBootTime() {
  const startMark = 'gridnode-boot-start';
  const endMark = 'gridnode-boot-end';

  // Mark the start as soon as DOMContentLoaded fires
  document.addEventListener('DOMContentLoaded', function onDOMReady() {
    performance.mark(startMark);
    // Poll for the app screen
    const appEl = document.querySelector('[data-app-screen]') ||
                  document.querySelector('.app-screen') ||
                  document.querySelector('#appScreen') ||
                  document.querySelector('[data-screen="app"]');

    if (appEl) {
      // App screen already in DOM, measure now
      performance.mark(endMark);
      const measure = performance.measure('gridnode-boot', startMark, endMark);
      console.log(`[GRIDNODE-BOOT] ${measure.duration.toFixed(2)}ms (DOMContentLoaded → app screen visible)`);
      return;
    }

    // Otherwise, wait for the app screen to appear
    const observer = new MutationObserver(function(mutations) {
      const appEl = document.querySelector('[data-app-screen]') ||
                    document.querySelector('.app-screen') ||
                    document.querySelector('#appScreen') ||
                    document.querySelector('[data-screen="app"]');
      if (appEl) {
        performance.mark(endMark);
        const measure = performance.measure('gridnode-boot', startMark, endMark);
        console.log(`[GRIDNODE-BOOT] ${measure.duration.toFixed(2)}ms (DOMContentLoaded → app screen visible)`);
        observer.disconnect();
      }
    });

    observer.observe(document.body, { childList: true, subtree: true });

    // Safety timeout: if app screen doesn't appear in 10s, log timeout
    setTimeout(() => {
      observer.disconnect();
      console.warn('[GRIDNODE-BOOT] TIMEOUT: app screen not detected within 10s');
    }, 10000);
  });
})();
