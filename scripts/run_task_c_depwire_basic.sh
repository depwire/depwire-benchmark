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
confirm_agent_working_directory

START_TIME=$(date +%s)

print_task_prompt

echo ""
echo "=== DEPWIRE BASIC MODE ==="
echo "MCP config for Claude Desktop/Cline/Codex:"
echo '{
  "mcpServers": {
    "depwire": {
      "command": "npx",
      "args": ["-y", "depwire-cli@'"$DEPWIRE_VERSION"'", "mcp", "."],
      "cwd": "'"$REPO"'"
    }
  }
}'
echo ""
echo "=== SYSTEM PROMPT TO INJECT ==="
echo "Add the Depwire AGENTS.md as agent context:"
echo "---"
cat "$REPO/.depwire/AGENTS.md"
echo "---"
echo ""
echo "Then give the task prompt."
echo ""
echo "=== Press ENTER when agent has completed the task ==="
read -r

"$SCRIPT_DIR/measure.sh" "$REPO" "$BASELINE" "$TASK" "$MODE" "$BRANCH" "$START_TIME" "$RESULTS_DIR"
