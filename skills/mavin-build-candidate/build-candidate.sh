#!/bin/bash
# build-candidate.sh — creates a candidate HTML from baseline
# Usage: bash build-candidate.sh "dash_empty_cta"

set -e

NAME="${1:?Usage: bash build-candidate.sh <name>}"
DATE=$(date +%Y-%m-%d)
BASELINE="/workspace/gridnode-project/01_SOURCE_TRUTH_LOCKED/gridnode-v1.3_post-phase-D_baseline.html"
CANDIDATES_DIR="/workspace/gridnode-project/02_QA_CANDIDATES_VISUAL_EXPERIMENTS"
BACKUP="/workspace/gridnode-project/gridnode-GOOD-${DATE}_pre-${NAME//_/-}.html"
CANDIDATE="${CANDIDATES_DIR}/gridnode-v1.3_${NAME}_microfix_v1.html"

echo "═══════════════════════════════════════════════════════════════"
echo "  GRID//NODE CANDIDATE BUILDER"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Step 1: Check baseline exists
if [ ! -f "$BASELINE" ]; then
    echo "❌ Baseline not found: $BASELINE"
    exit 1
fi

# Step 2: Check candidate doesn't already exist
if [ -f "$CANDIDATE" ]; then
    echo "⚠️  Candidate already exists: $CANDIDATE"
    echo "    Use a different name or version (e.g., ${NAME}_v2)"
    exit 1
fi

# Step 3: Create backup
echo "Step 1/5: Creating backup..."
mkdir -p "$(dirname "$BACKUP")"
cp "$BASELINE" "$BACKUP"
echo "  Backup: $BACKUP"
echo ""

# Step 4: Capture baseline SHA
echo "Step 2/5: Capturing baseline SHA..."
BASELINE_SHA=$(sha256sum "$BASELINE" | cut -d' ' -f1)
BASELINE_SIZE=$(wc -c < "$BASELINE")
echo "  Baseline SHA: $BASELINE_SHA"
echo "  Baseline size: $BASELINE_SIZE bytes"
echo ""

# Step 5: Copy to candidate
echo "Step 3/5: Creating candidate..."
mkdir -p "$CANDIDATES_DIR"
cp "$BASELINE" "$CANDIDATE"
echo "  Candidate: $CANDIDATE"
echo ""

# Step 6: Report status
echo "Step 4/5: Ready for edits..."
echo ""
echo "  Candidate SHA: $(sha256sum "$CANDIDATE" | cut -d' ' -f1)"
echo "  Candidate size: $(wc -c < "$CANDIDATE") bytes"
echo ""

# Step 7: Next steps
echo "Step 5/5: Next steps..."
echo ""
echo "1. Edit $CANDIDATE using the Edit tool (precise text replacement)"
echo "2. After each edit, verify the change applied (check line numbers)"
echo "3. When done, capture final SHA:"
echo "     sha256sum $CANDIDATE"
echo "4. Report to Pipe:"
echo "     Candidate SHA: ..."
echo "     Size delta: ..."
echo "5. Pipe reviews, then deploy:"
echo "     ./deploy-gridnode.sh \"${NAME}\" $CANDIDATE"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  CANDIDATE READY FOR EDITS"
echo "═══════════════════════════════════════════════════════════════"