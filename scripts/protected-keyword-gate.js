#!/usr/bin/env node
/**
 * protected-keyword-gate.js — scans a diff for protected keywords
 *
 * Usage:
 *   node protected-keyword-gate.js <baseline.html> <diff.txt>
 *
 * Exits with code 0 if no protected keywords are touched (GREEN/YELLOW-eligible)
 * Exits with code 1 if any protected keywords are touched (forces RED classification)
 *
 * The protected-keyword list is loaded from PROTECTED_KEYWORDS.js
 */

const fs = require('fs');
const path = require('path');

if (process.argv.length < 4) {
  console.error('Usage: node protected-keyword-gate.js <baseline.html> <diff.txt>');
  process.exit(2);
}

const baselinePath = process.argv[2];
const diffPath = process.argv[3];

if (!fs.existsSync(diffPath)) {
  console.error(`Error: diff file not found: ${diffPath}`);
  process.exit(2);
}

// Load the keyword list
const { PROTECTED_KEYWORDS } = require('./PROTECTED_KEYWORDS.js');

const diff = fs.readFileSync(diffPath, 'utf8');

// Parse the diff for added/removed lines
// Simplified: look at any line starting with + or - that's not a header
const changedLines = diff.split('\n').filter(line =>
  (line.startsWith('+') || line.startsWith('-')) &&
  !line.startsWith('+++') &&
  !line.startsWith('---') &&
  !line.startsWith('@@')
);

// Detect touched keywords
const touched = new Set();
for (const line of changedLines) {
  for (const kw of PROTECTED_KEYWORDS) {
    // Match as whole word, not substring (anchored matching)
    const re = new RegExp(`\\b${kw.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\b`);
    if (re.test(line)) {
      touched.add(kw);
    }
  }
}

if (touched.size === 0) {
  console.log('✓ No protected keywords touched — change is GREEN/YELLOW-eligible');
  process.exit(0);
}

console.log(`✗ ${touched.size} protected keyword(s) touched — change MUST be RED-classified:`);
console.log('');
for (const kw of Array.from(touched).sort()) {
  console.log(`  - ${kw}`);
}
console.log('');
console.log('Per Flex Directive: any change touching a protected keyword is RED, regardless of');
console.log('the maker\'s proposed lane. The protected-keyword scan is a required gate.');

process.exit(1);
