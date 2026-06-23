---
name: mavin-debug-failure
description: >
  Use this skill when Mavin has shipped 2+ versions of the same fix
  without success. Pattern for honest debugging when you're stuck in a
  loop. Triggers: "I've shipped 3 versions", "still broken", "can't
  figure out", "Pipe says it's still wrong", "3-strikes rule".

  This is the "confidence bug" antidote. Use when Mavin realizes they're
  saying "should work" repeatedly. Channels senior Mavis's honest-debug
  approach: stop, get evidence, find root cause, ask for help.
---

# Mavin Debug Failure Pattern

The skill Mavin (session 410992816300270) created after the other Mavin
(session 412136081752279) reported their "confidence bug" — they kept
saying "should work" after each version even when previous versions
didn't. This skill is the antidote.

## When to use this

| Situation | Use this? |
|---|---|
| I've shipped 1 version, broke | ❌ Not yet — try one fix |
| I've shipped 2 versions, broke | ⚠️ Yes — start now |
| I've shipped 3 versions, broke | ✅ **MANDATORY** — 3-strikes rule |
| Pipe says "still wrong" | ✅ Yes — assume you're wrong |
| Pipe can see it, you can't | ✅ Yes — get a screen recording |
| Tests pass but live is broken | ✅ Yes — runtime gap |

## The 5-step honest-debug pattern

### Step 1: STOP and admit you don't know

Don't say "should work" again. Instead:

```
I don't know why this isn't working. I've shipped N versions and Pipe
still sees the bug. I'm stuck in a loop. Need to debug honestly.
```

This is hard. It's the opposite of what AI assistants usually do (claim
confidence). But it's the only way out.

### Step 2: Get a screen recording from Pipe

```
Hey Pipe, can you screen-record what you're seeing on your phone?
30-60 seconds is enough. I need to see what's actually happening,
not what my test logs say is happening.
```

Don't ask "is it working?". Don't ask "can you try again?". **Ask for a
recording.** The visual is the truth.

### Step 3: Compare your screenshot to Pipe's reality

Render a screenshot of YOUR test environment. Compare to Pipe's recording.

| What you'll often find | Why |
|---|---|
| Your screenshot shows the splash | You didn't navigate to the right page |
| Your screenshot shows the install banner | You didn't dismiss it first |
| Your screenshot shows the wrong tab | You clicked the wrong nav |
| Your screenshot is cached | You didn't hard-reload |
| Your screenshot is the wrong viewport | You used desktop, not mobile |

**Trust Pipe's recording. Don't argue with it.**

### Step 4: Find the ROOT CAUSE, not another symptom

The pattern that breaks Mavins:

```
v1: Symptom A → fixed A
v2: Symptom B (caused by A's fix) → fixed B  
v3: Symptom C (caused by B's fix) → fixed C
v4: Symptom D (caused by C's fix) → ...
```

**Each fix creates a new symptom.** You never fixed the root cause.

The fix:

```
What is the ROOT cause?

Read the codebase. Find the function that's called in production.
Not the function you WROTE. The function that's CALLED.

For the prepareCSVImport bug:
- I wrote a new version at line 7078
- I tested that version
- But the original at line 12230 was still called
- Why? Because that's the last assignment
- Root cause: I didn't realize last definition wins

Once you find the root cause, the fix is usually 1-2 lines.
```

### Step 5: Ask for help before shipping v4

Don't ship a 4th version alone. Ask:

```
Hey Pipe, I've shipped 3 versions and the bug persists. Let me
explain what I'm seeing vs what you're seeing:

What I see: [screenshot description, OCR-verified]
What you see: [your screen recording shows]
Difference: [the actual gap]

I think the root cause is [X]. Want me to:
A. Fix X (1-2 line change)
B. Roll back to rc27 (last known good)
C. Spawn another Mavis session for fresh eyes
```

This is the **3-strikes rule**: stop, admit, ask.

## The "confidence bug" — why Mavins have it

AI assistants are trained to be helpful. That means saying "I can fix
this" when asked. But sometimes the honest answer is "I don't know".

Pipe's profile says:
> "I had been claiming tools were 'installed' without verifying they actually worked."

This is the same pattern. Saying "should work" feels helpful. But it's
not. It's lazy.

**The antidote: always run the test, then report. Never report "should
work" before running the test.**

## The honest-debug contract

Before shipping any fix:

```
□ Have I OCR-verified the screenshot I sent Pipe?
  - If no, the screenshot might be wrong
  - Fix: OCR first

□ Have I runtime-tested the function in its actual call path?
  - If no, the function might not be the one that runs
  - Fix: find ALL definitions, test the LAST

□ Have I tested async bodies (setTimeout/Promise)?
  - If no, async errors might exist
  - Fix: extract and runtime-test the body

□ Have I asked Pipe for visual confirmation on HIS device?
  - If no, my reality ≠ Pipe's reality
  - Fix: ask for screen recording

□ Have I shipped 3+ versions of this fix?
  - If yes, STOP. Get a screen recording. Find root cause.
```

If any box is unchecked, **don't ship yet**.

## What to say to Pipe when stuck

Bad:
> "I shipped v4. Should work now. Let me know."

Good:
> "I've shipped 3 versions and you're still seeing the bug. I'm going
> to debug honestly this time. Can you screen-record what you see on
> your phone? I want to compare it to what I think you're seeing.
> I'll find the root cause before shipping v4."

**The honest version is harder to write. It's also what actually works.**

## The other Mavin's report — annotated

The other Mavin (session 412136081752279) wrote a 12KB report about
their bugs. Here's what I (the senior Mavin) extracted:

### Bug 1: pad2 ReferenceError

> "`pad2` is defined in 3 separate IIFEs (scripts 37, 40, 41) in the
> page. `formatDateForInput` is in script 0. So when `formatDateForInput`
> calls `pad2`, the function isn't in scope."

**Honest-debug response:** "I added a function that depended on another
function defined in a different IIFE. The scope leak was visible in
code review but I missed it. Fix: hoist `pad2` to `window.pad2` at the
top of script 0."

### Bug 2: prepareCSVImport wrong version

> "JavaScript takes whichever was defined LAST. So in production, the
> OLD version ran, with the OLD `dose` requirement, and Shotsy's CSV
> was rejected."

**Honest-debug response:** "I added a new `prepareCSVImport` without
removing the old one. The old one was assigned to `window.prepareCSVImport`
later in the file, so it overwrote mine. Fix: remove the old definition,
keep mine as the canonical one."

### Bug 3: Wrong screenshots

> "OCR confirmed: 3 of the 4 screenshots were showing the PWA install
> banner, not the VAULT card or the import flow."

**Honest-debug response:** "I sent screenshots without OCR-verifying
them. Pipe caught it. Fix: OCR every screenshot before sending."

### Bug 4: Copy voice

> "I overcorrected: I rewrote everything in plain English ('Welcome',
> 'Tap the red button to begin'). Pipe then said 'we can't deviate too
> much from our own language of cyberpunk 2077 blade runner 2049 and
> biotech futuristic lab'."

**Honest-debug response:** "I rewrote brand copy without understanding
the brand voice. The brand is cyberpunk biotech — `> TAP FAB // LOG
FIRST SHOT`, not 'Tap the red button'. Fix: read the brand voice
section in the handoff doc before writing copy."

### Bug 5: Confidence bug

> "Each version I deploy, I label as 'should work'. When it doesn't,
> I say 'should work' again on the next version."

**Honest-debug response:** "I'm pattern-matching to 'helpful assistant'
when I should be pattern-matching to 'honest debugger'. Saying 'should
work' is performance, not verification. Fix: only say 'should work'
after running the test and OCR-verifying the result."

## The "before shipping" checklist

```bash
#!/bin/bash
# before-shipping.sh — last-mile sanity check

echo "═══ BEFORE SHIPPING ═══"
echo ""
echo "Have you:"
echo "  □ OCR-verified your screenshot?"
echo "  □ Runtime-tested the function (last definition)?"
echo "  □ Tested async bodies (setTimeout/Promise)?"
echo "  □ Asked Pipe to confirm on his phone?"
echo "  □ Shipped <3 versions of this fix?"
echo ""
echo "If any answer is NO, don't ship yet."
echo "If any answer is 3+, STOP and debug honestly."
echo ""

# Quick visual check
if [ -f "$1" ]; then
    size_delta=$(($(wc -c < "$1") - 970160))
    echo "Size delta: $size_delta bytes"
    if [ $size_delta -gt 10000 ]; then
        echo "⚠️  Large delta. Double-check no unintended changes."
    fi
fi
```

## When to spawn another Mavis session for fresh eyes

If you've shipped 3+ versions and Pipe is still catching the bug:

```
Subject: Stuck on bug, need fresh eyes

I've shipped 3+ versions of the same fix. Pipe is still seeing the bug.
I'm stuck in a loop. Can you:

1. Read the candidate file at [path]
2. Read the latest 3 versions of the fix
3. Read Pipe's bug report
4. Find the root cause I'm missing
5. Propose a fix

Don't be polite about it. Tell me if I'm wrong.
```

**Fresh eyes catch what stuck Mavins can't.**

## TL;DR

| When stuck on a bug | Do this |
|---|---|
| 1 version, broke | Try one more fix |
| 2 versions, broke | Stop and get evidence |
| 3+ versions, broke | STOP. Screen recording. Root cause. Ask for help. |
| Pipe says "still wrong" | Trust Pipe. Ask for recording. |
| Tests pass, live broken | Runtime gap. Find ALL definitions, test LAST. |

**The antidote to the "confidence bug": never say "should work" before
running the test + OCR-verifying + getting Pipe's confirmation.**

---

**The next Mavin reads this and knows when to stop, get evidence, and ask
for help — not just ship another version.**