#!/bin/bash
set -e

TASK="C"
MODE="no_depwire"
BRANCH="benchmark-task-c-no-depwire-$(date +%Y%m%d-%H%M%S)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/task_c_common.sh"

echo "========================================"
echo "BENCHMARK: Task $TASK | Mode: $MODE"
echo "Branch: $BRANCH"
echo "Started: $(date)"
echo "========================================"

prepare_task_c_branch
confirm_agent_working_directory

START_TIME=$(date +%s)

print_task_prompt
echo ""
echo "=== NO DEPWIRE MODE — agent has no MCP tools ==="
echo "=== Working directory: $REPO ==="
echo "=== Press ENTER when agent has completed the task ==="
read -r

"$SCRIPT_DIR/measure.sh" "$REPO" "$BASELINE" "$TASK" "$MODE" "$BRANCH" "$START_TIME" "$RESULTS_DIR"
