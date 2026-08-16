#!/bin/bash
# Do NOT use set -e — tsc/tests may fail and we need to capture that

# measure.sh — Measurement logic for Task C benchmark
#
# Usage: ./scripts/measure.sh REPO BASELINE TASK MODE BRANCH START_TIME RESULTS_DIR
#
# Arguments:
#   $1 = REPO path (packages/payload dir)
#   $2 = BASELINE branch name
#   $3 = TASK (C)
#   $4 = MODE (no_depwire, depwire_basic, depwire_guided)
#   $5 = BRANCH (current branch name)
#   $6 = START_TIME (unix timestamp)
#   $7 = RESULTS_DIR

REPO="$1"
BASELINE="$2"
TASK="$3"
MODE="$4"
BRANCH="$5"
START_TIME="$6"
RESULTS_DIR="$7"

# Navigate to the monorepo root (two levels up from packages/payload)
MONOREPO_ROOT="$(cd "$REPO/../.." && pwd)"
cd "$MONOREPO_ROOT"

# --- Timing ---
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
DURATION_HUMAN="$((DURATION / 60))m $((DURATION % 60))s"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# --- Files changed (modified + new untracked) ---
MODIFIED_FILES=$(git diff --name-only "$BASELINE" 2>/dev/null || true)
UNTRACKED_FILES=$(git ls-files --others --exclude-standard 2>/dev/null || true)
CHANGED_FILES=$(printf '%s\n%s' "$MODIFIED_FILES" "$UNTRACKED_FILES" | grep -v '^$' | sort -u)
if [ -z "$CHANGED_FILES" ]; then
  CHANGED_COUNT=0
else
  CHANGED_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')
fi
DIFF_STAT=$(git diff --stat "$BASELINE")

# --- Task C: APIError errorCode addition ---
# Hidden monorepo-wide ground truth. This file is never shown to agents.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GROUND_TRUTH_FILE="$SCRIPT_DIR/../tasks/TASK_C_GROUND_TRUTH.txt"
CORRECT_FILES=()
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in \#*) continue ;; esac
  CORRECT_FILES+=("$f")
done < "$GROUND_TRUTH_FILE"

if [ "${#CORRECT_FILES[@]}" -ne 126 ]; then
  echo "ERROR: expected 126 ground-truth files, found ${#CORRECT_FILES[@]}" >&2
  exit 1
fi

# Validate the constructor contract in every required file. A touched file only
# earns credit when every relevant call in that file uses an UPPER_SNAKE_CASE
# string literal and the core constructor/property contract is present.
SOLUTION_VALIDATION_JSON=$(cd "$MONOREPO_ROOT" && node "$SCRIPT_DIR/validate_task_c_solution.mjs" "$MONOREPO_ROOT" "$GROUND_TRUTH_FILE")

# Check which required files were both updated and structurally correct.
CORRECT_UPDATED=()
MISSED_FILES=()
for f in "${CORRECT_FILES[@]}"; do
  IS_STRUCTURALLY_VALID=$(echo "$SOLUTION_VALIDATION_JSON" | jq -r --arg f "$f" '.valid | index($f) != null')
  if echo "$CHANGED_FILES" | grep -q "^${f}$" && [ "$IS_STRUCTURALLY_VALID" = "true" ]; then
    CORRECT_UPDATED+=("$f")
  else
    MISSED_FILES+=("$f")
  fi
done

# Count extra files changed (not in ground truth)
EXTRA_FILES=()
while IFS= read -r changed; do
  [ -z "$changed" ] && continue
  IS_CORRECT="false"
  for correct in "${CORRECT_FILES[@]}"; do
    if [ "$changed" = "$correct" ]; then
      IS_CORRECT="true"
      break
    fi
  done
  if [ "$IS_CORRECT" = "false" ]; then
    EXTRA_FILES+=("$changed")
  fi
done <<< "$CHANGED_FILES"

# --- Run TypeScript compiler ---
echo ""
echo "=== Building translations dependency... ==="
cd "$MONOREPO_ROOT/packages/translations"
pnpm build > /dev/null 2>&1 || true

echo "=== Running TypeScript check... ==="
TSC_OUTPUT_FILE="${RESULTS_DIR}/${BRANCH}-tsc.txt"
mkdir -p "$RESULTS_DIR"
cd "$MONOREPO_ROOT/packages/payload"
npx tsc --noEmit > "$TSC_OUTPUT_FILE" 2>&1
TSC_EXIT=$?
TSC_ERRORS=$(grep -c "error TS" "$TSC_OUTPUT_FILE" 2>/dev/null || true)
TSC_ERRORS=${TSC_ERRORS:-0}
echo "  TypeScript errors: $TSC_ERRORS"
cd "$MONOREPO_ROOT"

# --- Run unit tests ---
echo ""
echo "=== Running unit tests... ==="
TEST_OUTPUT_FILE="${RESULTS_DIR}/${BRANCH}-tests.txt"
pnpm test:unit > "$TEST_OUTPUT_FILE" 2>&1
TEST_EXIT=$?
tail -5 "$TEST_OUTPUT_FILE"

# Parse test results
TEST_SUMMARY_LINE=$(grep "Tests " "$TEST_OUTPUT_FILE" | tail -1 || true)
TEST_PASSED=$(echo "$TEST_SUMMARY_LINE" | grep -o '[0-9]* passed' | grep -o '[0-9]*' || echo 0)
TEST_FAILED=$(echo "$TEST_SUMMARY_LINE" | grep -o '[0-9]* failed' | grep -o '[0-9]*' || echo 0)
TEST_SKIPPED=$(echo "$TEST_SUMMARY_LINE" | grep -o '[0-9]* skipped' | grep -o '[0-9]*' || echo 0)

if [ "$TEST_EXIT" -ne 0 ]; then
  TEST_RESULT="FAIL"
  TEST_FAILED="-1"
elif [ -z "$TEST_SUMMARY_LINE" ]; then
  if grep -q "error TS" "$TEST_OUTPUT_FILE" 2>/dev/null; then
    TEST_RESULT="FAIL"
    TEST_FAILED="-1"
  elif grep -q "ERR!" "$TEST_OUTPUT_FILE" 2>/dev/null; then
    TEST_RESULT="FAIL"
    TEST_FAILED="-1"
  else
    TEST_RESULT="PASS"
  fi
elif [ "$TEST_FAILED" -gt 0 ] 2>/dev/null; then
  TEST_RESULT="FAIL"
else
  TEST_RESULT="PASS"
fi

# --- Build JSON arrays ---
if [ ${#CORRECT_UPDATED[@]} -eq 0 ]; then
  CORRECT_UPDATED_JSON="[]"
else
  CORRECT_UPDATED_JSON=$(printf '%s\n' "${CORRECT_UPDATED[@]}" | jq -R . | jq -s .)
fi
if [ ${#MISSED_FILES[@]} -eq 0 ]; then
  MISSED_FILES_JSON="[]"
else
  MISSED_FILES_JSON=$(printf '%s\n' "${MISSED_FILES[@]}" | jq -R . | jq -s .)
fi
if [ ${#EXTRA_FILES[@]} -eq 0 ]; then
  EXTRA_FILES_JSON="[]"
else
  EXTRA_FILES_JSON=$(printf '%s\n' "${EXTRA_FILES[@]}" | jq -R . | jq -s .)
fi
if [ -z "$CHANGED_FILES" ]; then
  CHANGED_FILES_JSON="[]"
else
  CHANGED_FILES_JSON=$(echo "$CHANGED_FILES" | jq -R . | jq -s . 2>/dev/null || echo '[]')
fi

CORRECTNESS="${#CORRECT_UPDATED[@]}"
CORRECTNESS_MAX="${#CORRECT_FILES[@]}"
MISSED_COUNT="${#MISSED_FILES[@]}"
EXTRA_COUNT="${#EXTRA_FILES[@]}"

# Score: 1 point per structurally correct required file, -1 per unrelated file,
# -2 per remaining tsc error, +5 if tests pass.
SCORE=$((CORRECTNESS - EXTRA_COUNT - (TSC_ERRORS * 2)))
if [ "$TEST_RESULT" = "PASS" ]; then
  SCORE=$((SCORE + 5))
fi
MAX_SCORE=$((CORRECTNESS_MAX + 5))
if [ $SCORE -lt 0 ]; then
  SCORE=0
fi
PERCENTAGE=$((SCORE * 100 / MAX_SCORE))

# --- Build final JSON ---
cat > "${RESULTS_DIR}/${BRANCH}.json" << JSONEOF
{
  "task": "${TASK}",
  "mode": "${MODE}",
  "branch": "${BRANCH}",
  "timestamp": "${TIMESTAMP}",
  "duration_seconds": ${DURATION},
  "duration_human": "${DURATION_HUMAN}",
  "files": {
    "changed": ${CHANGED_FILES_JSON},
    "changed_count": ${CHANGED_COUNT},
    "ground_truth_total": ${CORRECTNESS_MAX},
    "correct_updated": ${CORRECT_UPDATED_JSON},
    "correct_count": ${CORRECTNESS},
    "missed": ${MISSED_FILES_JSON},
    "missed_count": ${MISSED_COUNT},
    "extra_changed": ${EXTRA_FILES_JSON},
    "extra_count": ${EXTRA_COUNT}
  },
  "diff_stat": $(echo "$DIFF_STAT" | jq -Rs .),
  "tsc": {
    "exit_code": ${TSC_EXIT},
    "errors": ${TSC_ERRORS},
    "output_file": "${TSC_OUTPUT_FILE}"
  },
  "tests": {
    "exit_code": ${TEST_EXIT},
    "result": "${TEST_RESULT}",
    "passed": ${TEST_PASSED},
    "failed": ${TEST_FAILED},
    "skipped": ${TEST_SKIPPED},
    "output_file": "${TEST_OUTPUT_FILE}"
  },
  "score": {
    "points": ${SCORE},
    "max_points": ${MAX_SCORE},
    "percentage": ${PERCENTAGE},
    "correctness": ${CORRECTNESS},
    "correctness_max": ${CORRECTNESS_MAX},
    "tests_pass": $([ "$TEST_RESULT" = "PASS" ] && echo "true" || echo "false")
  },
  "manual": {
    "agent": "",
    "quality": null,
    "cost_usd": null,
    "tool_calls_total": null,
    "depwire_tool_calls": null,
    "notes": ""
  }
}
JSONEOF

# --- Print summary ---
echo ""
echo "========================================"
echo "RESULTS: Task $TASK | Mode: $MODE"
echo "========================================"
echo "Duration:    ${DURATION_HUMAN} (${DURATION}s)"
echo "Branch:      $BRANCH"
echo ""
echo "Files changed: $CHANGED_COUNT"
echo "Ground truth:  $CORRECTNESS_MAX"
echo "Correct:       $CORRECTNESS/$CORRECTNESS_MAX"
echo "Missed:        $MISSED_COUNT"
echo "Extra:         $EXTRA_COUNT"
echo ""
echo "TypeScript errors: $TSC_ERRORS"
echo "Tests: $TEST_RESULT"
echo ""
echo "Score: ${SCORE}/${MAX_SCORE} (${PERCENTAGE}%)"
echo ""
if [ ${#MISSED_FILES[@]} -gt 0 ]; then
  echo "Missed files:"
  for f in "${MISSED_FILES[@]}"; do echo "  ✗ $f"; done
  echo ""
fi
echo "TSC output: $TSC_OUTPUT_FILE"
echo "Test output: $TEST_OUTPUT_FILE"
echo "JSON results: ${RESULTS_DIR}/${BRANCH}.json"
echo "========================================"
echo ""
echo "Run ./scripts/fill_manual.sh ${RESULTS_DIR}/${BRANCH}.json to add agent/cost/quality data"
