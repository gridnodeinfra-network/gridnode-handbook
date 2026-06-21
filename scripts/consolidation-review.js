#!/usr/bin/env node
/**
 * consolidation-review.js — runs the Phase A→D discipline audit
 *
 * Per Flex Directive Rule 4: when the file grows >10% between locked baselines,
 * this script produces a consolidation review report. The report lists findings;
 * it does NOT apply fixes.
 *
 * Audit tags (per Ponytail):
 *   delete: dead code, unused flexibility, speculative feature
 *   stdlib: hand-rolled thing the stdlib ships
 *   native: dependency or code doing what the platform already does
 *   yagni: abstraction with one implementation
 *   shrink: same logic, fewer lines
 *
 * Usage:
 *   node consolidation-review.js <baseline.html>
 *
 * Output: a report to stdout, with findings ranked by potential line savings.
 */

const fs = require('fs');
const path = require('path');

if (process.argv.length < 3) {
  console.error('Usage: node consolidation-review.js <baseline.html>');
  process.exit(1);
}

const baselinePath = process.argv[2];

if (!fs.existsSync(baselinePath)) {
  console.error(`Error: file not found: ${baselinePath}`);
  process.exit(1);
}

const baseline = fs.readFileSync(baselinePath, 'utf8');
const sizeBytes = Buffer.byteLength(baseline, 'utf8');
const lines = baseline.split('\n');

// === Audit checks ===

const findings = [];

// 1. Duplicate function definitions (the Phase A→D core check)
const functionDefs = new Map();
const functionRe = /function\s+(\w+)\s*\(/g;
let m;
while ((m = functionRe.exec(baseline)) !== null) {
  const fnName = m[1];
  if (!functionDefs.has(fnName)) {
    functionDefs.set(fnName, []);
  }
  functionDefs.get(fnName).push(m.index);
}

for (const [name, positions] of functionDefs) {
  if (positions.length > 1) {
    findings.push({
      tag: 'delete',
      severity: positions.length - 1,
      location: `function ${name} (defined ${positions.length} times)`,
      what: `${positions.length} duplicate definitions of ${name}`,
      replacement: 'Hoist to shared scope; keep exactly 1 definition',
      savings: positions.length - 1,
    });
  }
}

// 2. localStorage keys (only gn_settings should be present)
const lsRe = /localStorage\.(getItem|setItem|removeItem)\(['"](\w+)['"]/g;
const lsKeys = new Set();
while ((m = lsRe.exec(baseline)) !== null) {
  lsKeys.add(m[2]);
}
if (lsKeys.size > 1 || (lsKeys.size === 1 && !lsKeys.has('gn_settings'))) {
  findings.push({
    tag: 'yagni',
    severity: 5,
    location: 'localStorage keys',
    what: `Multiple or unexpected localStorage keys: ${Array.from(lsKeys).join(', ')}`,
    replacement: 'Single key: gn_settings. Other keys should be in-memory or namespaced under it.',
    savings: 3,
  });
}

// 3. IIFE-wrapped functions in global scope (potential hoisting candidates)
const iifeCount = (baseline.match(/\(\s*function\s*\(/g) || []).length +
                   (baseline.match(/\(\s*\(\s*\)\s*=>/g) || []).length;
if (iifeCount > 50) {
  findings.push({
    tag: 'shrink',
    severity: 2,
    location: 'IIFE wrappers',
    what: `${iifeCount} IIFE wrappers in the file`,
    replacement: 'Audit which functions actually need IIFE isolation; hoist pure functions to shared scope',
    savings: Math.floor(iifeCount * 0.1),
  });
}

// 4. Comment-heavy regions (potential dead code or stale notes)
const commentLines = lines.filter(l => l.trim().startsWith('//') || l.trim().startsWith('/*') || l.trim().startsWith('*')).length;
const commentRatio = commentLines / lines.length;
if (commentRatio > 0.1) {
  findings.push({
    tag: 'shrink',
    severity: 1,
    location: 'Comments',
    what: `${(commentRatio * 100).toFixed(1)}% of lines are comments (${commentLines} of ${lines.length})`,
    replacement: 'Audit for stale comments; remove or migrate to docs',
    savings: Math.floor(commentLines * 0.2),
  });
}

// 5. Patch-stacked style blocks (38 <style> tags is suspicious)
const styleTagCount = (baseline.match(/<style[^>]*>/g) || []).length;
if (styleTagCount > 5) {
  findings.push({
    tag: 'yagni',
    severity: 3,
    location: '<style> tags',
    what: `${styleTagCount} separate <style> tags`,
    replacement: 'Audit for patch-stacked styles; consolidate where execution order permits',
    savings: styleTagCount - 5,
  });
}

// 6. Script tag count
const scriptTagCount = (baseline.match(/<script[^>]*>/g) || []).length;
if (scriptTagCount > 10) {
  findings.push({
    tag: 'yagni',
    severity: 2,
    location: '<script> tags',
    what: `${scriptTagCount} separate <script> tags`,
    replacement: 'Consider logical fragments; load order is hand-managed',
    savings: scriptTagCount - 10,
  });
}

// === Output report ===

console.log('# GRID//NODE Consolidation Review');
console.log('');
console.log(`Baseline: ${path.basename(baselinePath)}`);
console.log(`Size: ${sizeBytes} bytes (${(sizeBytes / 1024).toFixed(1)} KB)`);
console.log(`Lines: ${lines.length}`);
console.log(`Function definitions: ${functionDefs.size}`);
console.log(`IIFE wrappers: ${iifeCount}`);
console.log(`Style tags: ${styleTagCount}`);
console.log(`Script tags: ${scriptTagCount}`);
console.log('');
console.log(`## Findings (ranked by potential savings)`);
console.log('');

if (findings.length === 0) {
  console.log('Lean already. Ship.');
  process.exit(0);
}

findings.sort((a, b) => b.savings - a.savings);
let totalSavings = 0;
for (const f of findings) {
  totalSavings += f.savings;
  console.log(`${f.tag}: ${f.what} [${f.location}]`);
  console.log(`  Replacement: ${f.replacement}`);
  console.log(`  Potential savings: ~${f.savings} lines`);
  console.log('');
}

console.log(`net: -${totalSavings} lines possible, -${findings.filter(f => f.tag === 'yagni').length} deps possible.`);
console.log('');
console.log('## Boundaries');
console.log('');
console.log('This report lists findings; it does NOT apply fixes. Each finding is its own');
console.log('gated change (GREEN/YELLOW/RED per Flex Directive). The review\'s job is to');
console.log('identify candidates; the fix is a separate decision.');
