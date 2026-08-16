#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MONOREPO_ROOT="$BENCHMARK_ROOT/repo"
REPO="$MONOREPO_ROOT/packages/payload"
RESULTS_DIR="$BENCHMARK_ROOT/results"
TASK_PROMPT="$BENCHMARK_ROOT/tasks/TASK_C_PROMPT.md"
GROUND_TRUTH="$BENCHMARK_ROOT/tasks/TASK_C_GROUND_TRUTH.txt"
GUIDED_WORKFLOW="$BENCHMARK_ROOT/tasks/DEPWIRE_GUIDED_WORKFLOW.md"
BASELINE="benchmark-baseline"
DEPWIRE_VERSION="1.14.2"

validate_task_c_harness() {
  local runner

  test -f "$TASK_PROMPT" || {
    echo "ERROR: missing shared task prompt: $TASK_PROMPT" >&2
    return 1
  }
  test -f "$GROUND_TRUTH" || {
    echo "ERROR: missing hidden ground truth: $GROUND_TRUTH" >&2
    return 1
  }
  test -f "$GUIDED_WORKFLOW" || {
    echo "ERROR: missing guided workflow: $GUIDED_WORKFLOW" >&2
    return 1
  }
  if grep -qi 'Ground Truth' "$TASK_PROMPT"; then
    echo "ERROR: agent-visible prompt contains ground-truth material" >&2
    return 1
  fi
  if grep -Eqi 'Ground Truth|Files That MUST|81 files|80 files total|27 error subclasses|52 direct callers|AUTHENTICATION_ERROR' "$GUIDED_WORKFLOW"; then
    echo "ERROR: guided workflow contains answer-key material" >&2
    return 1
  fi

  for runner in "$SCRIPT_DIR"/run_task_c_*.sh; do
    if ! grep -Fq 'source "$SCRIPT_DIR/task_c_common.sh"' "$runner"; then
      echo "ERROR: mixed-arm guard: $runner does not use task_c_common.sh" >&2
      return 1
    fi
    if grep -Eq 'TASK_C\.md|TASK_C_PROMPT\.md' "$runner"; then
      echo "ERROR: mixed-arm guard: $runner hard-codes a task file" >&2
      return 1
    fi
  done

  local expected_count
  expected_count=$(grep -Ev '^[[:space:]]*(#|$)' "$GROUND_TRUTH" | wc -l | tr -d ' ')
  if [ "$expected_count" -ne 126 ]; then
    echo "ERROR: expected 126 hidden ground-truth files, found $expected_count" >&2
    return 1
  fi

  "$SCRIPT_DIR/validate_task_c_ground_truth.sh" > /dev/null
}

prepare_task_c_branch() {
  validate_task_c_harness
  cd "$MONOREPO_ROOT"
  git stash -u 2>/dev/null || true
  git checkout "$BASELINE"
  git checkout -b "$BRANCH"

  echo "Building translations package..."
  cd "$MONOREPO_ROOT/packages/translations"
  pnpm build > /dev/null 2>&1

  cd "$REPO"
  if [ "$(pwd -P)" != "$(cd "$REPO" && pwd -P)" ]; then
    echo "ERROR: failed to enter enforced agent working directory: $REPO" >&2
    return 1
  fi
}

print_task_prompt() {
  echo ""
  echo "=== TASK PROMPT (paste this exact file to the agent) ==="
  echo "Prompt SHA-256: $(shasum -a 256 "$TASK_PROMPT" | awk '{print $1}')"
  echo "Agent working directory: $(pwd -P)"
  echo ""
  cat "$TASK_PROMPT"
}

confirm_agent_working_directory() {
  local confirmed_path
  echo ""
  echo "Launch the agent from: $REPO"
  echo "In the agent terminal, run: pwd -P"
  echo "Paste that exact output here to start timing:"
  read -r confirmed_path
  if [ "$confirmed_path" != "$(cd "$REPO" && pwd -P)" ]; then
    echo "ERROR: agent working directory mismatch; session not started" >&2
    return 1
  fi
}
