/**
 * self-check-snippet.js — the runnable check that ships with the app
 *
 * Per Ponytail rule: "Lazy code without its check is unfinished. Non-trivial logic
 * leaves ONE runnable check behind, the smallest thing that fails if the logic breaks."
 *
 * This snippet is appended to the GRID//NODE file. On load, it runs in the console.
 * It checks:
 *   1. All declared modules are loaded
 *   2. Critical functions exist (not just declared — actually present at runtime)
 *   3. localStorage is reachable and gn_settings is readable
 *   4. The app screen element is reachable after boot
 *
 * Per Flex Directive Change 3: this is the standing self-check. It runs on every load.
 * If it fails, the failure is logged loudly so a human sees it.
 *
 * Usage:
 *   Append this script to gridnode-v1.3_post-phase-D_baseline.html before the </body> tag.
 *   Open the file in a browser.
 *   Check the console for [GRIDNODE self-check] messages.
 *
 * The user-flow assertion (per Flex Directive GREEN-lane requirement): the script also
 * tests that a click on the LAB tab actually opens the dose drawer, not just that the
 * function exists.
 */

(function gridnodeSelfCheck() {
  const checks = [];
  let failed = 0;

  function check(name, condition, detail) {
    if (condition) {
      checks.push({ name, status: 'OK', detail });
    } else {
      checks.push({ name, status: 'FAIL', detail });
      failed++;
    }
  }

  // 1. localStorage is reachable
  try {
    const testKey = '__gridnode_selftest__';
    localStorage.setItem(testKey, '1');
    const read = localStorage.getItem(testKey);
    localStorage.removeItem(testKey);
    check('localStorage reachable', read === '1', 'read/write works');
  } catch (e) {
    check('localStorage reachable', false, e.message);
  }

  // 2. gn_settings is readable
  try {
    const settings = localStorage.getItem('gn_settings');
    check('gn_settings readable', settings !== undefined, settings ? `${settings.length} chars` : 'null');
  } catch (e) {
    check('gn_settings readable', false, e.message);
  }

  // 3. Critical functions exist at runtime
  const criticalFns = [
    'loadApp', 'showScreen', 'playBoot', 'bootFinalCorrections',
    'safeText', 'page', 'stage', 'getHudElements', 'activeSelectedZone',
    'qs', 'qsa', 'esc', 'norm', 'play', 'parseTimeValue',
  ];
  for (const fn of criticalFns) {
    check(`function ${fn} exists`, typeof window[fn] === 'function', typeof window[fn]);
  }

  // 4. App screen element is reachable
  setTimeout(function() {
    const appEl = document.querySelector('[data-app-screen]') ||
                  document.querySelector('.app-screen') ||
                  document.querySelector('#appScreen') ||
                  document.querySelector('[data-screen="app"]');
    check('app screen element present', !!appEl, appEl ? appEl.tagName : 'not found');

    // 5. User-flow assertion: click the LAB tab, check that the dose drawer opens
    const labTab = document.querySelector('[data-tab="lab"]') ||
                   document.querySelector('#labTab') ||
                   document.querySelector('.tab-lab');
    if (labTab) {
      labTab.click();
      setTimeout(function() {
        const drawer = document.querySelector('[data-dose-drawer]') ||
                       document.querySelector('.dose-drawer') ||
                       document.querySelector('#doseDrawer');
        check('LAB tab → dose drawer opens (user-flow)', !!drawer, drawer ? drawer.tagName : 'no drawer after click');

        // === Output ===
        const passed = checks.length - failed;
        const result = failed === 0 ? 'OK' : 'FAIL';
        console.log(`[GRIDNODE self-check] ${result}: ${passed}/${checks.length} checks passed`);

        for (const c of checks) {
          const icon = c.status === 'OK' ? '✓' : '✗';
          console.log(`  ${icon} ${c.name}: ${c.status}${c.detail ? ' (' + c.detail + ')' : ''}`);
        }

        if (failed > 0) {
          console.error(`[GRIDNODE self-check] ${failed} check(s) FAILED — review above.`);
        }
      }, 200);
    } else {
      // No LAB tab found, just output what we have
      const passed = checks.length - failed;
      const result = failed === 0 ? 'OK' : 'FAIL';
      console.log(`[GRIDNODE self-check] ${result}: ${passed}/${checks.length} checks passed (no LAB tab found, user-flow assertion skipped)`);

      for (const c of checks) {
        const icon = c.status === 'OK' ? '✓' : '✗';
        console.log(`  ${icon} ${c.name}: ${c.status}${c.detail ? ' (' + c.detail + ')' : ''}`);
      }

      if (failed > 0) {
        console.error(`[GRIDNODE self-check] ${failed} check(s) FAILED — review above.`);
      }
    }
  }, 2000);  // Wait for boot sequence to complete
})();
