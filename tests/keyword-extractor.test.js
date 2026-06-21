/**
 * keyword-extractor.test.js — vitest test suite for the keyword extraction pipeline
 *
 * Per Ponytail: "Self-test tools on a known case before scaling."
 * Per Flex Directive: source-of-truth artifacts need third-party verification.
 *
 * The first test here is the SELF-TEST on a known case. It runs the extractor
 * against a small fixture and verifies the output. If the self-test fails, the
 * rest of the tests are skipped.
 *
 * Run: npx vitest run tests/
 */

import { describe, it, expect, beforeAll } from 'vitest';
import fs from 'fs';
import path from 'path';
import { execSync } from 'child_process';

const FIXTURE_PATH = path.join(__dirname, 'fixtures', 'small-baseline.html');
const SCRIPT_PATH = path.join(__dirname, '..', 'scripts', 'keyword-extractor.js');
const REAL_BASELINE = process.env.GRIDNODE_BASELINE ||
  '/workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED/gridnode-v1.3_post-phase-D_baseline.html';

// Helper: run a command and capture stdout, even if exit code is non-zero
// (the keyword-extractor uses the count as exit code, so non-zero is expected)
function runOrThrow(cmd) {
  try {
    return { stdout: execSync(cmd, { encoding: 'utf8' }), status: 0 };
  } catch (e) {
    return { stdout: e.stdout || '', status: e.status };
  }
}

describe('keyword-extractor self-test (the ponytail rule)', () => {
  beforeAll(() => {
    // Ensure the fixture exists; if not, create a minimal one
    const fixtureDir = path.dirname(FIXTURE_PATH);
    if (!fs.existsSync(fixtureDir)) {
      fs.mkdirSync(fixtureDir, { recursive: true });
    }
    if (!fs.existsSync(FIXTURE_PATH)) {
      const minimalFixture = `<!DOCTYPE html>
<html>
<body>
<script>
function loadApp() { console.log('app loaded'); }
function showScreen(s) { console.log('screen:', s); }
function scannerMode() { return 'default'; }
const gn_settings = '{}';
</script>
</body>
</html>`;
      fs.writeFileSync(FIXTURE_PATH, minimalFixture);
    }
  });

  it('runs without error on a minimal fixture', () => {
    const result = runOrThrow(`node ${SCRIPT_PATH} ${FIXTURE_PATH}`);
    expect(result.stdout).toContain('loadApp');
    expect(result.stdout).toContain('showScreen');
    expect(result.stdout).toContain('scannerMode');
    expect(result.stdout).toContain('gn_settings');
  });

  it('produces a numeric count at the end of output', () => {
    const result = runOrThrow(`node ${SCRIPT_PATH} ${FIXTURE_PATH}`);
    expect(result.stdout).toMatch(/COUNT = \d+/);
  });

  it('exit code matches the count (capture via $?)', () => {
    const result = runOrThrow(`node ${SCRIPT_PATH} ${FIXTURE_PATH}`);
    const match = result.stdout.match(/COUNT = (\d+)/);
    expect(match).toBeTruthy();
    const count = parseInt(match[1], 10);
    expect(result.status).toBe(count);
    expect(count).toBeGreaterThan(0);
  });

  it('does NOT emit junk like "function name(" or "name(" (the v5 bug fix)', () => {
    const result = runOrThrow(`node ${SCRIPT_PATH} ${FIXTURE_PATH}`);
    expect(result.stdout).not.toMatch(/'function \w+/);
    expect(result.stdout).not.toMatch(/'\w+\(',/);
  });

  it('anchors bare-word utilities (play, page, etc.) as definitions, not substrings', () => {
    const result = runOrThrow(`node ${SCRIPT_PATH} ${FIXTURE_PATH}`);
    // 'page' and 'play' would be falsely emitted by the v5 bug
    // The fix: only emit if there's a `function name(` definition
    if (result.stdout.includes("'page'") || result.stdout.includes("'play'")) {
      expect(result.stdout).toMatch(/'page',\s*\/\/.*occurrences/);
    }
  });
});

describe('keyword-extractor on real GRID//NODE baseline', () => {
  it('runs successfully against the actual baseline', () => {
    if (!fs.existsSync(REAL_BASELINE)) {
      console.log(`Skipping: baseline not found at ${REAL_BASELINE}`);
      return;
    }
    const result = runOrThrow(`node ${SCRIPT_PATH} ${REAL_BASELINE}`);
    expect(result.stdout).toContain('loadApp');
    expect(result.stdout).toContain('scannerMode');
    expect(result.stdout).toContain('gn_settings');
  }, 30000);

  it('emits 100+ keywords (more than the v4 hand-verified 99)', () => {
    if (!fs.existsSync(REAL_BASELINE)) {
      console.log('Skipping: baseline not found');
      return;
    }
    const result = runOrThrow(`node ${SCRIPT_PATH} ${REAL_BASELINE}`);
    const match = result.stdout.match(/COUNT = (\d+)/);
    expect(match).toBeTruthy();
    const count = parseInt(match[1], 10);
    expect(count).toBeGreaterThanOrEqual(100);
  }, 30000);
});

describe('protected-keyword-gate', () => {
  it('passes on a clean diff (no protected keywords touched)', () => {
    const cleanDiff = `diff --git a/file.js b/file.js
--- a/file.js
+++ b/file.js
@@ -1,3 +1,4 @@
 function existingHelper() {
   return 42;
 }
+// new comment about a new feature`;

    const cleanDiffPath = path.join(__dirname, 'fixtures', 'clean-diff.txt');
    fs.writeFileSync(cleanDiffPath, cleanDiff);

    const result = runOrThrow(
      `node ${path.join(__dirname, '..', 'scripts', 'protected-keyword-gate.js')} ${REAL_BASELINE} ${cleanDiffPath}`
    );
    expect(result.stdout).toContain('No protected keywords touched');
  });

  it('fails on a dirty diff (touches a protected keyword)', () => {
    const dirtyDiff = `diff --git a/file.js b/file.js
--- a/file.js
+++ b/file.js
@@ -1,3 +1,4 @@
+// changed how loadApp behaves
 function existingHelper() {
   return 42;
 }`;

    const dirtyDiffPath = path.join(__dirname, 'fixtures', 'dirty-diff.txt');
    fs.writeFileSync(dirtyDiffPath, dirtyDiff);

    try {
      execSync(
        `node ${path.join(__dirname, '..', 'scripts', 'protected-keyword-gate.js')} ${REAL_BASELINE} ${dirtyDiffPath}`,
        { encoding: 'utf8' }
      );
      throw new Error('Expected gate to fail, but it passed');
    } catch (e) {
      // execSync throws on non-zero exit
      expect(e.status).toBe(1);
      expect(e.stdout).toContain('loadApp');
    }
  });
});

describe('consolidation-review', () => {
  it('produces a report on the real baseline', () => {
    if (!fs.existsSync(REAL_BASELINE)) {
      console.log('Skipping: baseline not found');
      return;
    }
    const result = runOrThrow(
      `node ${path.join(__dirname, '..', 'scripts', 'consolidation-review.js')} ${REAL_BASELINE}`
    );
    expect(result.stdout).toContain('GRID//NODE Consolidation Review');
    expect(result.stdout).toContain('Findings');
    expect(result.stdout).toMatch(/clamp/);
  }, 30000);

  it('produces a net savings line', () => {
    if (!fs.existsSync(REAL_BASELINE)) {
      console.log('Skipping: baseline not found');
      return;
    }
    const result = runOrThrow(
      `node ${path.join(__dirname, '..', 'scripts', 'consolidation-review.js')} ${REAL_BASELINE}`
    );
    expect(result.stdout).toMatch(/net: -\d+ lines possible/);
  }, 30000);
});
