# Protected Systems (Source of Truth)

**The 14 protected systems. Any change to these is RED-class by default.**

Source: `SOURCE_OF_TRUTH.md` from the GRIDNODE_PRIVATE_ARCHIVE repo, with refinements from the Phase A→D consolidation work and the Flex Directive.

---

## The 14 systems

| # | System | Why protected | Verified function/symbol |
|---|---|---|---|
| 1 | SHOTS scanner behavior | The core data-capture surface | `scannerMode`, `setScannerMode`, `getScannerAsset`, `initRegionScanner`, `renderRegionScanner` |
| 2 | Scanner hitboxes | The user-tap input layer | `selectScannerLocation`, `gnScannerTapFeedback`, `data-hitbox` |
| 3 | `scannerMode` logic | The mode state machine | `scannerMode` (34 occurrences), `setScannerMode` |
| 4 | Selected-location source of truth | The location state | `scannerSelectedLocation`, `scannerSelected`, `syncScannerSelectedLocation` |
| 5 | LOG SHOT transfer | The record-creation path | `data-transfer-card`, `data-transfer-btn`, `data-transfer-copy` |
| 6 | SHOT HISTORY | The historical view | `handleShotHistoryAction`, `handleShotHistoryToggle`, `renderShotHistoryControls`, `setShotHistoryView`, `data-shot-history-view` |
| 7 | Archive / restore / purge | The data lifecycle | `cancelArchiveShot`, `cancelPermanentDeleteShot`, `confirmArchiveShot`, `confirmPermanentDeleteShot`, `deleteShot`, `editShot`, `findActiveShotById`, `findShotIndexById`, `getAllShots` |
| 8 | Phase Engine | The cycle calculation | `buildPhaseRing`, `closePhases`, `curPhaseIdx`, `getPhaseSourceInfo`, `getPhases`, `readPhaseEngineProfile`, `readPhaseEngineShots` |
| 9 | RESULTS | The outcome display | `fmtResultValue`, `gnUpdateResultsWeightMetrics`, `renderResultsOutcome`, `gnResultsLoadWeightRecords`, `gnResultsSelectedRangeWeightChange`, `gnResultsTrendDirection`, `gnResultsFormula`, `gnResultsFormulaKeys` |
| 10 | WEIGHT RECORDS edit / remove | The weight data lifecycle | `confirmRemoveWeightRecord`, `getWeightRecords`, `gnFormatWeightLabel`, `loadWeightRecords`, `normalizeWeightRecord`, `openWeightEdit`, `openWeightModal`, `refreshWeightSystems`, `renderWeightRecordsList`, `gnFilteredWeightRecords` |
| 11 | LAB syringe | The dose visualization | `data-syringe`, `data-dose-units`, `data-labseg` |
| 12 | VAULT | The local archive | `vaultEdit`, `saveVault`, `loadVaultSettings`, `getVaultSettings`, `restoreVaultSnapshot`, `applyVaultAutofillSuppression`, `ensureVaultControls`, `hardenVaultInputs`, `readVaultProtocolContext`, `normalizeVaultDate`, `data-vault-topic` |
| 13 | NODE ALIAS | The user identity | `ensureAliasCopy`, `data-node-alias` |
| 14 | localStorage persistence | The single key | `gn_settings` (the only key) |

---

## What "protected" means in the Flex Directive

**RED-class change** — full Phase A→D discipline applies:
1. Trace first, no edits
2. Classify drift true vs cosmetic
3. Founder HQ sign-off (per-change)
4. Staging before live
5. Count forward and backward
6. Full stat-block report + independent verification

**The protected-keyword scan is mandatory:** any change that introduces or modifies an identifier in the table above is RED, regardless of what lane the maker proposed.

---

## How the protected systems list was built

The list started from `SOURCE_OF_TRUTH.md` (Pipe's authoritative list). It was refined through:

1. **Phase A→D consolidation** — clarified the symbols that exist in the locked baseline
2. **Flex Directive v3-v5** — added the 99 verified identifiers
3. **Script failure** (v5) — exposed the gap between hand-typed counts and grep results
4. **The 14 systems + 99 keywords** — system-level abstraction (what) + symbol-level enforcement (how)

The two layers reinforce each other:
- The 14 systems = the *what* (which behaviors are sacred)
- The 99 keywords = the *how* (which identifiers trigger RED if touched)

---

## What does NOT count as a protected system

These are NOT in the list, but might be candidates:

- **Styling and visual chrome** (colors, fonts, animations) — protected at the *brand* level (per `gridnode-pipeline`), but not at the *system* level. A color change is YELLOW at most.
- **Documentation** (this file, the handoff doc) — version-controlled but not RED-protected.
- **The locked baseline itself** — protected by being version-controlled, not by being on this list.
- **The 17 hoisted shared utilities** (`safeText`, `page`, `stage`, `getHudElements`, `activeSelectedZone`, `qs`, `qsa`, `esc`, `norm`, `play`, `parseTimeValue`, `scrollSelectedPanelIntoView`, `formatDateForInput`, `formatDateTime`, `normalizedSite`, `validDate`, `validDateParts`) — these are on the keyword list but are utility functions, not systems. Touching them is YELLOW, not RED, unless the change breaks a protected system's behavior.
- **The manifest and self-check (Ponytail integration)** — these are part of the methodology stack, not protected systems. Changes to them are GREEN/YELLOW depending on scope.

---

## The bare-word utility warning

Per Claude's flag in the v6 response: utilities like `play`, `page`, `stage`, `norm`, `qs`, `esc` are real function names but they also over-match common substrings (e.g., `play` matches every `display:` in CSS, 517 times). A protected-keyword gate that uses these as substring matches will fire constantly on innocent changes.

**The fix:** anchor as whole-word identifiers or match definitions/calls specifically:
- `function play\(` (definition)
- `\bplay\(` (call)
- Never: bare `play` as a substring

The v5 keyword script got this wrong. The v6+ gate must not.

---

## Updates to this list

To add a new protected system:
1. Justify it in the Flex Directive
2. Add the system + reason to this list
3. Add the verified function/symbol to the keyword list
4. Update the gate to recognize the new identifier
5. Bump the handoff doc to v<n+1>

To remove a protected system:
1. Justify why it's no longer protected
2. Remove the system + reason
3. Remove the keyword(s) from the gate
4. Bump the handoff doc

Both changes are YELLOW-class at minimum (RED if they affect a verified keyword).
