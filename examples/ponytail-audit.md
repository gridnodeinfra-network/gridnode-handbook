# Example: Ponytail audit run

**Purpose:** Show a real Ponytail audit applied to existing code, producing actionable findings.

---

## The setup

Audit target: a 200-line helper module that handles time formatting in the GRID//NODE app.

```js
// (excerpt — the real audit would target the actual file)
function formatDate(d) {
  var result = '';
  if (d) {
    var year = d.getFullYear();
    var month = d.getMonth() + 1;
    var day = d.getDate();
    var monthStr = month < 10 ? '0' + month : '' + month;
    var dayStr = day < 10 ? '0' + day : '' + day;
    result = year + '-' + monthStr + '-' + dayStr;
  }
  return result;
}

function parseDate(str) {
  if (!str) return null;
  var parts = str.split('-');
  if (parts.length !== 3) return null;
  return new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
}

function isToday(d) {
  var now = new Date();
  return d.getFullYear() === now.getFullYear() &&
         d.getMonth() === now.getMonth() &&
         d.getDate() === now.getDate();
}

function addDays(d, n) {
  var result = new Date(d.getTime());
  result.setDate(result.getDate() + n);
  return result;
}

function diffInDays(a, b) {
  var ms = b.getTime() - a.getTime();
  return Math.floor(ms / (1000 * 60 * 60 * 24));
}
```

---

## The 6-rung ladder applied

1. **YAGNI:** is this module needed? Yes, the app uses date formatting everywhere. ✓
2. **Stdlib:** `Intl.DateTimeFormat`, `Date.prototype.toISOString`, etc. could replace most of this. ✓
3. **Native platform:** modern Date APIs handle most of this. ✓
4. **Installed dep:** none used; ponytail says don't add one. ✓
5. **One line:** the format function can be one line. ✓
6. **Minimum:** the implementation below. ✓

## The Ponytail audit (5 tags, ranked)

### `stdlib:`

- **formatDate** is reinventing `Date.prototype.toISOString().split('T')[0]` or `new Date(d).toLocaleDateString('en-CA')` (which gives YYYY-MM-DD).
  - **Replacement:** `new Date(d).toLocaleDateString('en-CA')` (1 line, locale-aware).
  - **Savings:** ~12 lines.

- **parseDate** is reinventing `new Date(str)` (which handles ISO YYYY-MM-DD natively).
  - **Replacement:** `new Date(str)` (1 line, browser handles parsing).
  - **Savings:** ~5 lines. *But:* if you need to handle invalid input, the explicit version gives clearer errors.

- **addDays** is reinventing `new Date(d.getTime() + n * 86400000)`.
  - **Replacement:** inline the math at call sites, OR keep the helper.
  - **Savings:** ~3 lines if you remove the helper.

### `delete:`

- **isToday** is rarely used in the GRID//NODE app (only 1 call site). Inline it.
  - **Replacement:** `(d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth() && d.getDate() === now.getDate())` at the call site.
  - **Savings:** ~4 lines + 1 fewer function in the namespace.

### `yagni:`

- **diffInDays** has 0 call sites in the actual app. Dead code.
  - **Replacement:** nothing.
  - **Savings:** ~3 lines.

### `shrink:`

- The whole module can be reduced from 200 lines to ~50 lines by using stdlib + removing dead code.
  - **Replacement:** see the stdlib/delete findings above.
  - **Savings:** ~150 lines.

### `native:`

- `Intl.DateTimeFormat` is built into every browser since IE11. If you need locale-aware formatting, use it.
  - **Replacement:** `new Intl.DateTimeFormat('en-CA').format(d)` for YYYY-MM-DD.
  - **Savings:** depends on how many formatters exist.

---

## The output (per Ponytail format)

```
L1-22: stdlib: formatDate reinventing Date.toISOString or toLocaleDateString. Use new Date(d).toLocaleDateString('en-CA'). [-12 lines]
L24-29: stdlib: parseDate reinventing new Date(str). Use new Date(str). [-5 lines]
L31-35: delete: isToday has 1 call site. Inline at the call site. [-4 lines]
L37-41: delete: diffInDays has 0 call sites. Dead code. [-3 lines]
L43-47: shrink: addDays can be inline math at call sites, OR keep as helper. [-3 lines if removed]
L1-200: shrink: whole module can be ~50 lines using stdlib + removing dead code. [-150 lines]

net: -177 lines, 0 deps possible.
```

---

## What the audit does NOT do

Per Ponytail's boundaries:
- ❌ Does not apply fixes
- ❌ Does not refactor across modules
- ❌ Does not rename things
- ❌ Does not change behavior

It only lists findings. The fix is a separate gated change.

---

## The discipline reminder

A Ponytail audit is a **report**, not a fix. The report tells you what to cut. The cut is its own gated change with its own standing report.

If the audit says "delete isToday," that's a YELLOW change (single function deletion, reversible). If the audit says "rewrite the whole module using stdlib," that's a RED change (touches multiple call sites, can break callers). Different lanes for different cuts.

---

## The connection to the Flex Directive

Ponytail is the **methodology** (how to think about the code). The Flex Directive is the **policy** (when/how to ship changes). They work together:

- Run a Ponytail audit to find candidates
- Classify each candidate as GREEN/YELLOW/RED per the Flex Directive
- Ship each candidate as its own gated change with its own standing report

This is how the consolidation review works: it runs audit checks across the whole codebase, lists findings, and each finding becomes its own candidate for a future change.

---

## Time estimate

Ponytail audit of a single module: 5-10 minutes. Of a 1MB file: 30-60 minutes. The discipline is in the audit, not the audit's duration. A 5-minute audit that produces 5 actionable findings is more useful than a 60-minute audit that produces a wishlist.