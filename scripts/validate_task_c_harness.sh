#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/task_c_common.sh"
validate_task_c_harness

echo "Task C harness validated"
echo "Prompt: $TASK_PROMPT"
echo "Prompt SHA-256: $(shasum -a 256 "$TASK_PROMPT" | awk '{print $1}')"
echo "Ground truth: 126 monorepo source files"
echo "Working directory: $REPO"
echo "Depwire version: $DEPWIRE_VERSION"
