#!/bin/bash
set -e

REPO="/Users/atefataya/Developer/depwire-benchmark-v2/repo/packages/payload"
TASK="C"
MODE="no_depwire"
RESULTS_DIR="/Users/atefataya/Developer/depwire-benchmark-v2/results"
BRANCH="benchmark-task-c-no-depwire-$(date +%Y%m%d-%H%M%S)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MONOREPO_ROOT="/Users/atefataya/Developer/depwire-benchmark-v2/repo"

echo "========================================"
echo "BENCHMARK: Task $TASK | Mode: $MODE"
echo "Branch: $BRANCH"
echo "Started: $(date)"
echo "========================================"

cd "$MONOREPO_ROOT"
git stash -u 2>/dev/null || true
git checkout benchmark-baseline
git checkout -b "$BRANCH"

# Build required dependency
echo "Building translations package..."
cd "$MONOREPO_ROOT/packages/translations" && pnpm build > /dev/null 2>&1
cd "$MONOREPO_ROOT"

START_TIME=$(date +%s)

echo ""
echo "=== TASK PROMPT (paste this to agent) ==="
echo ""
cat /Users/atefataya/Developer/depwire-benchmark-v2/tasks/TASK_C.md
echo ""
echo "=== NO DEPWIRE MODE — agent has no MCP tools ==="
echo "=== Working directory: $REPO ==="
echo "=== Press ENTER when agent has completed the task ==="
read -r

"$SCRIPT_DIR/measure.sh" "$REPO" "benchmark-baseline" "$TASK" "$MODE" "$BRANCH" "$START_TIME" "$RESULTS_DIR"
