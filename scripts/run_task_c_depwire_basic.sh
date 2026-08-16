#!/bin/bash
set -e

TASK="C"
MODE="depwire_basic"
BRANCH="benchmark-task-c-depwire-basic-$(date +%Y%m%d-%H%M%S)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/task_c_common.sh"

echo "========================================"
echo "BENCHMARK: Task $TASK | Mode: $MODE"
echo "Branch: $BRANCH"
echo "Started: $(date)"
echo "========================================"

prepare_task_c_branch
START_TIME=$(date +%s)
print_task_prompt
echo "=== DEPWIRE BASIC MODE ==="
run_claude_task_c "$MODE"

"$SCRIPT_DIR/measure.sh" "$REPO" "$BASELINE" "$TASK" "$MODE" "$BRANCH" "$START_TIME" "$RESULTS_DIR"
"$SCRIPT_DIR/fill_from_claude_transcript.sh" "$RESULTS_DIR/$BRANCH.json" "$RESULTS_DIR/$BRANCH-transcript.jsonl" "$CLAUDE_EXIT"
finalize_task_c_branch
