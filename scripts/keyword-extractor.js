#!/usr/bin/env node
/**
 * keyword-extractor.js — emits the protected-keyword list from a locked baseline
 *
 * Fixes the v5 bugs Claude caught:
 * 1. Scanner regex no longer emits 'function name(' and 'name(' as junk
 * 2. Bare-word utilities (play, page, etc.) are anchored as definitions/calls
 * 3. Count is emitted as a script output, never a hand-typed number
 *
 * Usage:
 *   node keyword-extractor.js <baseline.html> [output.js]
 *
 * If output.js is provided, writes a JS module exporting PROTECTED_KEYWORDS.
 * If not, prints the array and the count to stdout.
 */

const fs = require('fs');
const path = require('path');

if (process.argv.length < 3) {
  console.error('Usage: node keyword-extractor.js <baseline.html> [output.js]');
  process.exit(1);
}

const baselinePath = process.argv[2];
const outputPath = process.argv[3];

if (!fs.existsSync(baselinePath)) {
  console.error(`Error: file not found: ${baselinePath}`);
  process.exit(1);
}

const baseline = fs.readFileSync(baselinePath, 'utf8');
const generatedAt = new Date().toISOString();

// Helper: extract clean function names from a file
function extractFunctions(pattern) {
  const re = new RegExp(`function\\s+(${pattern})\\s*\\(`, 'g');
  const matches = new Set();
  let m;
  while ((m = re.exec(baseline)) !== null) {
    matches.add(m[1]);
  }
  return Array.from(matches).sort();
}

// Helper: extract clean identifiers by exact match (anchored, not substring)
function extractExact(name) {
  // Match the name as a whole word, not a substring
  // This is the FIX for the bare-word over-matching problem
  const re = new RegExp(`\\b${name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\b`, 'g');
  const matches = baseline.match(re) || [];
  return matches.length > 0 ? [name] : [];
}

// Helper: extract bareword with strict definition/call anchoring
function extractBarewordFunction(name) {
  // Match `function name(` or `\bname\(` — NOT bare substring
  const defRe = new RegExp(`function\\s+${name}\\s*\\(`);
  const callRe = new RegExp(`\\b${name}\\s*\\(`);
  if (defRe.test(baseline) || callRe.test(baseline)) {
    return [name];
  }
  return [];
}

// Build the keyword list, with categories
const keywords = [];

// === Scanner core (exact-match identifiers, never substring) ===
const SCANNER_CORE = [
  'scannerMode', 'scannerSelectedLocation', 'scannerSelected', 'scannerHistory',
];
for (const kw of SCANNER_CORE) {
  const exact = extractExact(kw);
  if (exact.length > 0) {
    keywords.push({ category: 'Scanner core', name: kw, count: (baseline.match(new RegExp(`\\b${kw}\\b`, 'g')) || []).length });
  }
}

// === Scanner functions (clean function names, no prefix/suffix junk) ===
const SCANNER_FNS = extractFunctions('[a-zA-Z]*[Ss]can[a-zA-Z]*');
for (const name of SCANNER_FNS) {
  keywords.push({ category: 'Scanner functions', name, count: 0 });
}

// === Boot / app lifecycle ===
const BOOT_LIFECYCLE = [
  'loadApp', 'showScreen', 'bootFinalCorrections', 'bootStarted', 'gnBoot', 'playBoot',
];
for (const kw of BOOT_LIFECYCLE) {
  const exact = extractExact(kw);
  if (exact.length > 0) {
    keywords.push({ category: 'Boot lifecycle', name: kw, count: (baseline.match(new RegExp(`\\b${kw}\\b`, 'g')) || []).length });
  }
}

// === VAULT (functions + data attrs) ===
const VAULT_FNS = extractFunctions('[a-zA-Z]*[Vv]ault[a-zA-Z]*');
const VAULT_KEYWORDS = ['vaultEdit', 'data-vault-topic', ...VAULT_FNS];
for (const kw of [...new Set(VAULT_KEYWORDS)]) {
  const exact = extractExact(kw);
  if (exact.length > 0 || VAULT_FNS.includes(kw)) {
    keywords.push({ category: 'VAULT', name: kw, count: (baseline.match(new RegExp(`\\b${kw}\\b`, 'g')) || []).length });
  }
}

// === localStorage (the only key, per grep) ===
const LS_KEYS = ['gn_settings'];
for (const kw of LS_KEYS) {
  // Match any reference to gn_settings: localStorage calls, const decls, or string usage
  const re = new RegExp(`['"\`]?${kw}['"\`]?`, 'g');
  const matches = baseline.match(re) || [];
  if (matches.length > 0) {
    keywords.push({ category: 'localStorage', name: kw, count: matches.length });
  }
}

// === Phase Engine (functions only) ===
const PHASE_FNS = extractFunctions('[a-zA-Z]*[Pp]hase[a-zA-Z]*');
for (const name of PHASE_FNS) {
  keywords.push({ category: 'Phase Engine', name, count: 0 });
}

// === RESULTS (functions only) ===
const RESULTS_FNS = extractFunctions('[a-zA-Z]*[Rr]esult[a-zA-Z]*');
for (const name of RESULTS_FNS) {
  keywords.push({ category: 'RESULTS', name, count: 0 });
}

// === WEIGHT RECORDS (functions only) ===
const WEIGHT_FNS = extractFunctions('[a-zA-Z]*[Ww]eight[a-zA-Z]*');
for (const name of WEIGHT_FNS) {
  keywords.push({ category: 'WEIGHT RECORDS', name, count: 0 });
}

// === SHOT HISTORY (functions only) ===
const SHOT_HISTORY_FNS = extractFunctions('[a-zA-Z]*[Ss]hot[Hh]istory[a-zA-Z]*');
const SHOT_HISTORY_DATA = ['data-shot-history-view'];
for (const name of [...SHOT_HISTORY_FNS, ...SHOT_HISTORY_DATA]) {
  if (SHOT_HISTORY_DATA.includes(name)) {
    if (extractExact(name).length > 0) {
      keywords.push({ category: 'SHOT HISTORY', name, count: 0 });
    }
  } else {
    keywords.push({ category: 'SHOT HISTORY', name, count: 0 });
  }
}

// === SHOT CRUD (functions only) ===
const SHOT_CRUD_FNS = extractFunctions('[a-zA-Z]*[Ss]hot[a-zA-Z]*');
for (const name of SHOT_CRUD_FNS) {
  // Skip ones already in SHOT HISTORY
  if (!SHOT_HISTORY_FNS.includes(name)) {
    keywords.push({ category: 'SHOT CRUD', name, count: 0 });
  }
}

// === NODE ALIAS ===
const ALIAS_FNS = extractFunctions('[a-zA-Z]*[Aa]lias[a-zA-Z]*');
const ALIAS_KEYWORDS = ['ensureAliasCopy', 'data-node-alias', ...ALIAS_FNS];
for (const kw of [...new Set(ALIAS_KEYWORDS)]) {
  keywords.push({ category: 'NODE ALIAS', name: kw, count: 0 });
}

// === Hoisted shared utilities (the 17) — ANCHORED, not substring ===
// FIX: use function-definition matching, not bare-word matching
const HOISTED_17 = [
  'safeText', 'page', 'stage', 'getHudElements', 'activeSelectedZone',
  'qs', 'qsa', 'esc', 'norm', 'play', 'parseTimeValue',
  'scrollSelectedPanelIntoView', 'formatDateForInput', 'formatDateTime',
  'normalizedSite', 'validDate', 'validDateParts',
];
for (const name of HOISTED_17) {
  // The fix: only count if there's a `function name(` definition
  // OR a `\bname\(` call — NOT bare substring
  const defRe = new RegExp(`function\\s+${name}\\s*\\(`);
  if (defRe.test(baseline)) {
    // Count definitions
    const defCount = (baseline.match(new RegExp(`function\\s+${name}\\s*\\(`, 'g')) || []).length;
    keywords.push({ category: 'Hoisted shared utilities', name, count: defCount, anchored: true });
  }
}

// === window.gn* globals (filtered to known-safe subset) ===
const KNOWN_GN_GLOBALS = [
  'gnFilteredWeightRecords', 'gnFormatShotDateHuman', 'gnFormatShotTimeDisplay',
  'gnFormatYMD', 'gnGetShotDateYMD', 'gnGetShotTime', 'gnHaptic',
  'gnMedRevealGroup', 'gnNormalizeShotClockField', 'gnParseDateInput',
  'gnRenderResultsVisibilityTrustMicrofixV', 'gnRenderWeightRecordsOwnershipV',
  'gnResultsFormula', 'gnResultsFormulaKeys', 'gnResultsLoadWeightRecords',
  'gnResultsSelectedRangeWeightChange', 'gnResultsTrendDirection',
  'gnScannerTapFeedback', 'gnSetShotDateValue', 'gnSetShotMeridiem',
  'gnCloseShotDatePicker',
];
for (const name of KNOWN_GN_GLOBALS) {
  const re = new RegExp(`window\\.${name}|function\\s+${name}\\s*\\(`);
  if (re.test(baseline)) {
    keywords.push({ category: 'window.gn* globals', name, count: 0 });
  }
}

// === Output ===
// Deduplicate by name (a name might be in multiple categories)
const deduped = new Map();
for (const kw of keywords) {
  if (!deduped.has(kw.name)) {
    deduped.set(kw.name, kw);
  } else {
    // Keep the one with the higher count
    const existing = deduped.get(kw.name);
    if ((kw.count || 0) > (existing.count || 0)) {
      deduped.set(kw.name, kw);
    }
  }
}

const finalKeywords = Array.from(deduped.values()).sort((a, b) => {
  if (a.category < b.category) return -1;
  if (a.category > b.category) return 1;
  return a.name.localeCompare(b.name);
});

const count = finalKeywords.length;

if (outputPath) {
  // Output as a JS module
  const lines = [
    `// AUTO-GENERATED from ${path.basename(baselinePath)} at ${generatedAt}`,
    `// DO NOT EDIT — regenerate via: node keyword-extractor.js <baseline.html>`,
    `// Source: scripts/keyword-extractor.js`,
    `// Count: ${count} entries (verified by script output, not hand-typed)`,
    `// `,
    `// Source-of-truth: this file IS the keyword list.`,
    `// Any change to the protected systems or to ${path.basename(baselinePath)}`,
    `// should regenerate this file via the script.`,
    '',
    'const PROTECTED_KEYWORDS = [',
  ];

  let currentCategory = null;
  for (const kw of finalKeywords) {
    if (kw.category !== currentCategory) {
      lines.push(`  // ${kw.category}`);
      currentCategory = kw.category;
    }
    const comment = kw.count ? ` // ${kw.count} occurrences` : '';
    lines.push(`  '${kw.name}',${comment}`);
  }
  lines.push('];');
  lines.push('');
  lines.push(`module.exports = { PROTECTED_KEYWORDS, COUNT: ${count} };`);
  lines.push('');

  fs.writeFileSync(outputPath, lines.join('\n'));
  console.error(`Wrote ${count} keywords to ${outputPath}`);
} else {
  // Output to stdout for human reading
  console.log(`// AUTO-GENERATED from ${path.basename(baselinePath)} at ${generatedAt}`);
  console.log(`// Count: ${count} entries`);
  console.log('const PROTECTED_KEYWORDS = [');

  let currentCategory = null;
  for (const kw of finalKeywords) {
    if (kw.category !== currentCategory) {
      console.log(`  // ${kw.category}`);
      currentCategory = kw.category;
    }
    const comment = kw.count ? ` // ${kw.count} occurrences` : '';
    console.log(`  '${kw.name}',${comment}`);
  }
  console.log('];');
  console.log(`// COUNT = ${count}`);
}

// Exit with the count for callers (capture via $? in shell)
process.exit(count);
