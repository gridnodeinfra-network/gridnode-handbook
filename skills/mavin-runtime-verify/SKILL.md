---
name: mavin-runtime-verify
description: >
  Use this skill when Mavin needs to verify a candidate file works at
  RUNTIME, not just at syntax level. Specifically for code with multiple
  function definitions, IIFEs that share scope, or async/deferred logic
  (setTimeout, setInterval, Promises).

  Triggers: "runtime check", "execute the function", "test the call path",
  "verify function definition", "catch ReferenceError", "test setTimeout body",
  "find all definitions", "last definition wins"
---

# Mavin Runtime Verify Pattern

The skill Mavin (session 410992816300270) created after debugging the
other Mavin's report (rc28.x failure modes). The other Mavin caught real
bugs but shipped fixes that didn't actually work in production because
their tests only checked syntax, not runtime behavior.

## When to use this

**Before deploying ANY of these:**
- ✅ Code with multiple `function foo()` definitions (last one wins in JS)
- ✅ Code with IIFEs that share scope (scope leaks across boundaries)
- ✅ Async logic (setTimeout, setInterval, Promises)
- ✅ Functions called from event handlers (timing matters)
- ✅ Code with try/catch around setTimeout bodies

**Never skip this for:**
- 🔴 Any function with the same name appearing 2+ times in the file
- 🔴 Any setTimeout/setInterval that calls complex logic
- 🔴 Any code where "syntactically valid" ≠ "works at runtime"

## The 4 verification patterns

### Pattern 1: Find ALL definitions of a function

```bash
# Find all definitions of function foo
grep -n "function foo\|foo = function\|foo = (.*) =>" file.html | head -20

# Output:
# 1234:function foo() { ... }      <- first definition
# 5678:window.foo = function() { }  <- second definition (THIS ONE WINS)
# 9999:foo = () => { ... }        <- third definition (THIS ONE WINS if it exists)
```

**Rule:** In JavaScript, when multiple definitions exist, the LAST one to be evaluated wins. If you test the first one and the second one runs in production, your test is wrong.

### Pattern 2: Find the LAST definition (the canonical one)

```bash
# Get the LAST definition of function foo
grep -n "function foo\|foo = function\|foo = (.*) =>" file.html | tail -1
```

Or use `tac` (reverse cat):
```bash
grep -n "function foo\|foo = function\|foo = (.*) =>" file.html | tac | head -1
```

### Pattern 3: Runtime test (not just syntax)

For functions that depend on scope:

```python
import re
import subprocess
import sys

def runtime_test(html_path, function_name, test_input):
    """
    Extracts the LAST definition of function_name and runs it
    in a Node.js sandbox to verify runtime behavior.
    """
    with open(html_path) as f:
        html = f.read()
    
    # Find ALL definitions
    pattern = re.compile(
        rf'(?:function {function_name}\s*\([^)]*\)|{function_name}\s*=\s*function[^a-zA-Z]|{function_name}\s*=\s*\([^)]*\)\s*=>)',
        re.MULTILINE
    )
    matches = list(pattern.finditer(html))
    
    if not matches:
        print(f"❌ No definition found for {function_name}")
        return False
    
    if len(matches) > 1:
        print(f"⚠️  Found {len(matches)} definitions of {function_name}")
        print(f"   Testing the LAST one (which is what runs in production)")
    
    # Extract the LAST definition
    last_def = matches[-1].group(0)
    
    # Write a test harness
    test_js = f"""
const {last_def.split('{', 1)[0]}

// Set up minimal DOM if needed
global.document = {{ 
    getElementById: () => null,
    querySelector: () => null,
    addEventListener: () => {{}},
}};

// Run the function
try {{
    const result = {function_name}({test_input});
    console.log("RESULT:", JSON.stringify(result));
}} catch (e) {{
    console.error("ERROR:", e.message);
    process.exit(1);
}}
"""
    
    result = subprocess.run(
        ['node', '-e', test_js],
        capture_output=True, text=True, timeout=10
    )
    
    if result.returncode != 0:
        print(f"❌ {function_name} threw error: {result.stderr}")
        return False
    
    print(f"✅ {function_name} ran successfully")
    print(f"   Output: {result.stdout}")
    return True

# Usage:
runtime_test(
    '/path/to/candidate.html',
    'prepareCSVImport',
    '"shot_date,dose,notes\\n2024-01-01,2.5mg,test"'
)
```

### Pattern 4: Catch scope leaks before deploy

For functions called from setTimeout/Promises that might not have access to scope:

```python
def check_scope_leaks(html_path):
    """
    Finds functions that reference variables defined in other scopes.
    Common leak: IIFE-defined helpers called from outside-IIFE code.
    """
    with open(html_path) as f:
        html = f.read()
    
    # Find all IIFEs
    iife_pattern = re.compile(r'\(function\s*\([^)]*\)\s*\{(.*?)\}\s*\([^)]*\)', re.DOTALL)
    iifes = list(iife_pattern.finditer(html))
    
    print(f"Found {len(iifes)} IIFEs")
    
    # For each IIFE, find functions defined inside
    for i, iife in enumerate(iifes):
        iife_body = iife.group(1)
        defined_funcs = re.findall(r'function\s+(\w+)\s*\(', iife_body)
        for func in defined_funcs:
            # Check if this function is called outside the IIFE
            calls_outside = re.findall(rf'\b{func}\s*\(', html[len(iife.group(0)):])
            if calls_outside:
                print(f"⚠️  Function '{func}' defined in IIFE {i} but called {len(calls_outside)} times outside")
                print(f"   This will throw ReferenceError at runtime")
    
    print("Scope leak check complete")

check_scope_leaks('/path/to/candidate.html')
```

### Pattern 5: setTimeout body extraction

For setTimeout/setInterval/Promise bodies that might fail at runtime:

```python
def check_timeout_bodies(html_path):
    """Find all setTimeout/setInterval/Promise bodies and extract them for runtime testing."""
    with open(html_path) as f:
        html = f.read()
    
    # setTimeout patterns
    patterns = [
        r'setTimeout\s*\(\s*function\s*\([^)]*\)\s*\{(.*?)\}\s*,\s*\d+',
        r'setTimeout\s*\(\s*\(\s*\)\s*=>\s*\{(.*?)\}\s*,\s*\d+',
        r'setInterval\s*\(\s*function\s*\([^)]*\)\s*\{(.*?)\}\s*,',
        r'\.then\s*\(\s*\(\s*\)\s*=>\s*\{(.*?)\}\s*\)',
    ]
    
    bodies = []
    for pattern in patterns:
        bodies.extend(re.findall(pattern, html, re.DOTALL))
    
    print(f"Found {len(bodies)} async bodies")
    print("Each one should be runtime-tested independently")
    
    # Extract them for testing
    for i, body in enumerate(bodies):
        print(f"\n=== Async body {i+1} ===")
        print(body[:200] + ("..." if len(body) > 200 else ""))

check_timeout_bodies('/path/to/candidate.html')
```

## The complete pre-deploy verification

Before shipping any candidate, run this checklist:

```
□ grep for duplicate function definitions
  - If any function appears 2+ times, find the LAST definition
  - Test the LAST one (not the first)
  
□ Runtime test the LAST definition of each changed function
  - Not just syntax check
  - Actually execute with realistic input
  
□ Check scope leaks
  - Functions defined in IIFEs shouldn't be called outside
  - If they are, expect ReferenceError
  
□ Test setTimeout/setInterval/Promise bodies
  - Execute the body, not just check syntax
  - Catch ReferenceErrors like 'pad2 is not defined'
  
□ OCR verify any screenshots sent to user
  - Confirm the screenshot shows what you claim
  - Don't trust test logs alone
```

## Common scenarios

### Scenario 1: "I added a new feature with 2 function edits"

```bash
# Step 1: Find both functions
grep -n "function prepareCSVImport\|prepareCSVImport = function\|prepareCSVImport = (" candidate.html

# If 2+ matches:
echo "⚠️  Multiple definitions found"
echo "    Last one is canonical. Test that one, not the first."

# Step 2: Extract the LAST definition
last_def=$(grep -n "function prepareCSVImport\|prepareCSVImport = function\|prepareCSVImport = (" candidate.html | tail -1)
echo "  Testing: $last_def"
```

### Scenario 2: "My fix worked in isolation but failed in production"

```bash
# Run the candidate in a real browser via Playwright
# Test the actual user flow, not just unit tests

python3 -c "
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_context(viewport={'width': 375, 'height': 812}).new_page()
    page.goto('file:///workspace/gridnode-project/02_QA_CANDIDATES_VISUAL_EXPERIMENTS/candidate.html')
    page.wait_for_load_state('networkidle')
    
    # Click the actual button
    page.click('button:has-text(\"IMPORT\")')
    page.wait_for_timeout(2000)
    
    # Check if the action worked (no errors)
    errors = page.evaluate('window.errors || []')
    if errors:
        print('❌ Errors during flow:', errors)
    else:
        print('✅ No errors')
    
    browser.close()
"
```

### Scenario 3: "I shipped 3 versions of the same fix"

```bash
# STOP. Don't ship a 4th version without testing in real conditions.

# Step 1: Get a screen recording from Pipe
# "Hey Pipe, can you screen-record the issue on your phone? 
#  30 seconds is enough. I need to see what's actually happening."

# Step 2: Look at the recording, not the screenshots

# Step 3: Fix the root cause, not the symptom
```

## The "confidence bug" check

Before declaring any fix "done", ask yourself:

| Question | If "yes" |
|---|---|
| Did I OCR the screenshot? | ❌ Fix it |
| Did I run the function in its actual scope? | ❌ Fix it |
| Did I check for duplicate definitions? | ❌ Fix it |
| Did I test the async body, not just sync? | ❌ Fix it |
| Did Pipe see the actual result on his phone? | ❌ Fix it |
| Have I shipped 3+ versions of this same fix? | 🛑 STOP. Get a screen recording |

## Why the other Mavin's bugs were structural

The bugs were:
1. **pad2 ReferenceError** — scope leak across IIFEs
2. **prepareCSVImport wrong version** — last definition wins
3. **setTimeout-triggered error** — async scope not tested

**All three are the same pattern: "test the easy thing, ship the hard thing."**

The fix: **always test what actually runs in production**, not what runs in isolation.

## Files to add to the bootstrap

This skill is reactive (catches bugs after they're made). The fix is:

1. Add runtime test to `mavin-build-candidate`
2. Add OCR check to `mavin-visual-render`  
3. Add scope-leak detector to `mavin-build-candidate`

The other Mavin's report is a wakeup call. We need to make these checks mandatory, not optional.

## The full pre-deploy verification checklist

```bash
#!/bin/bash
# verify-candidate.sh — comprehensive pre-deploy checks

CANDIDATE="${1:?Usage: bash verify-candidate.sh <candidate.html>}"

if [ ! -f "$CANDIDATE" ]; then
    echo "❌ Candidate not found: $CANDIDATE"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════════"
echo "  GRID//NODE CANDIDATE VERIFICATION"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# 1. Find duplicate function definitions
echo "1/5 Checking for duplicate function definitions..."
duplicates=$(grep -E "function [a-zA-Z_]+\s*\(|window\.[a-zA-Z_]+\s*=\s*function" "$CANDIDATE" | \
    sed 's/.*function \([a-zA-Z_]*\).*/\1/; s/.*window\.\([a-zA-Z_]*\).*=.*/\1/' | \
    sort | uniq -c | sort -rn | awk '$1 > 1 {print}')
if [ -n "$duplicates" ]; then
    echo "  ⚠️  Functions with multiple definitions:"
    echo "$duplicates" | head -10
    echo "  Action: Test the LAST definition, not the first"
else
    echo "  ✅ No duplicate function definitions"
fi
echo ""

# 2. Find setTimeout/setInterval/Promise bodies
echo "2/5 Counting async bodies..."
timeouts=$(grep -c "setTimeout\|setInterval" "$CANDIDATE")
promises=$(grep -c "\.then\|\.catch\|\.finally" "$CANDIDATE")
echo "  setTimeout/setInterval: $timeouts"
echo "  Promises: $promises"
echo "  Action: Runtime-test the async bodies, not just syntax-check"
echo ""

# 3. Check for IIFEs (potential scope leaks)
echo "3/5 Counting IIFEs (potential scope boundaries)..."
iifes=$(grep -c "(function()" "$CANDIDATE")
echo "  IIFEs: $iifes"
echo "  Action: Verify functions defined in IIFEs aren't called outside"
echo ""

# 4. SHA delta check
echo "4/5 Checking size delta..."
baseline_size=970160  # or actual baseline size
candidate_size=$(wc -c < "$CANDIDATE")
delta=$((candidate_size - baseline_size))
echo "  Baseline: $baseline_size bytes"
echo "  Candidate: $candidate_size bytes"
echo "  Delta: $delta bytes"
if [ $delta -gt 10000 ]; then
    echo "  ⚠️  Large delta — review for unintended changes"
fi
echo ""

# 5. Run a real browser test (if Playwright available)
echo "5/5 Browser test..."
if command -v python3 &> /dev/null && python3 -c "import playwright" 2>/dev/null; then
    python3 -c "
from playwright.sync_api import sync_playwright
import sys
try:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_context(viewport={'width': 375, 'height': 812}).new_page()
        page.goto('file://$CANDIDATE', wait_until='networkidle')
        page.wait_for_timeout(2000)
        
        errors = page.evaluate('window.errors || []')
        if errors:
            print('  ❌ Errors during load:', errors)
        else:
            print('  ✅ No errors during load')
        browser.close()
except Exception as e:
    print(f'  ⚠️  Browser test skipped: {e}')
" 2>&1 | head -5
else
    echo "  ⚠️  Playwright not available, skipping browser test"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  REVIEW BEFORE DEPLOY"
echo "═══════════════════════════════════════════════════════════════"
```

## The 3-strikes rule (from the other Mavin's confession)

If you've shipped 3+ versions of the same fix without success:

```bash
echo "⚠️  3-strikes rule triggered"
echo ""
echo "You've shipped 3+ versions of the same fix."
echo "Don't ship a 4th."
echo ""
echo "Action items:"
echo "1. STOP"
echo "2. Get a screen recording from Pipe (or any real device)"
echo "3. Look at the recording, not your test logs"
echo "4. Find the ROOT CAUSE, not another symptom fix"
echo "5. Ask Pipe: 'show me exactly what you see on your phone'"
```

## Summary for the next Mavin

**The other Mavin's bugs were all the same pattern:**
- Test the wrong thing
- Trust the wrong signal
- Ship before verifying

**The fix:**
- Always runtime-test the LAST definition
- Always OCR-verify screenshots
- Always test async bodies, not just sync
- Stop after 3 versions of the same fix

---

**The next Mavin reads this and knows the structural failures to avoid.**