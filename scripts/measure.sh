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
# Ground truth files that MUST be changed (relative to packages/payload/)
CORRECT_FILES=(
  # Core change
  "packages/payload/src/errors/APIError.ts"
  # Error subclasses (27)
  "packages/payload/src/errors/AuthenticationError.ts"
  "packages/payload/src/errors/DuplicateCollection.ts"
  "packages/payload/src/errors/DuplicateFieldName.ts"
  "packages/payload/src/errors/DuplicateGlobal.ts"
  "packages/payload/src/errors/ErrorDeletingFile.ts"
  "packages/payload/src/errors/FileRetrievalError.ts"
  "packages/payload/src/errors/FileUploadError.ts"
  "packages/payload/src/errors/Forbidden.ts"
  "packages/payload/src/errors/InvalidConfiguration.ts"
  "packages/payload/src/errors/InvalidFieldJoin.ts"
  "packages/payload/src/errors/InvalidFieldName.ts"
  "packages/payload/src/errors/InvalidFieldRelationship.ts"
  "packages/payload/src/errors/InvalidSchema.ts"
  "packages/payload/src/errors/Locked.ts"
  "packages/payload/src/errors/LockedAuth.ts"
  "packages/payload/src/errors/MissingCollectionLabel.ts"
  "packages/payload/src/errors/MissingEditorProp.ts"
  "packages/payload/src/errors/MissingFieldInputOptions.ts"
  "packages/payload/src/errors/MissingFieldType.ts"
  "packages/payload/src/errors/MissingFile.ts"
  "packages/payload/src/errors/NotFound.ts"
  "packages/payload/src/errors/QueryError.ts"
  "packages/payload/src/errors/ReservedFieldName.ts"
  "packages/payload/src/errors/TimestampsRequired.ts"
  "packages/payload/src/errors/UnauthorizedError.ts"
  "packages/payload/src/errors/UnverifiedEmail.ts"
  "packages/payload/src/errors/ValidationError.ts"
  # Direct callers (52)
  "packages/payload/src/auth/operations/forgotPassword.ts"
  "packages/payload/src/auth/operations/local/forgotPassword.ts"
  "packages/payload/src/auth/operations/local/login.ts"
  "packages/payload/src/auth/operations/local/resetPassword.ts"
  "packages/payload/src/auth/operations/local/unlock.ts"
  "packages/payload/src/auth/operations/local/verifyEmail.ts"
  "packages/payload/src/auth/operations/logout.ts"
  "packages/payload/src/auth/operations/resetPassword.ts"
  "packages/payload/src/auth/operations/unlock.ts"
  "packages/payload/src/auth/operations/verifyEmail.ts"
  "packages/payload/src/collections/endpoints/findDistinct.ts"
  "packages/payload/src/collections/operations/delete.ts"
  "packages/payload/src/collections/operations/findDistinct.ts"
  "packages/payload/src/collections/operations/findVersionByID.ts"
  "packages/payload/src/collections/operations/local/count.ts"
  "packages/payload/src/collections/operations/local/countVersions.ts"
  "packages/payload/src/collections/operations/local/create.ts"
  "packages/payload/src/collections/operations/local/delete.ts"
  "packages/payload/src/collections/operations/local/duplicate.ts"
  "packages/payload/src/collections/operations/local/find.ts"
  "packages/payload/src/collections/operations/local/findByID.ts"
  "packages/payload/src/collections/operations/local/findDistinct.ts"
  "packages/payload/src/collections/operations/local/findVersionByID.ts"
  "packages/payload/src/collections/operations/local/findVersions.ts"
  "packages/payload/src/collections/operations/local/restoreVersion.ts"
  "packages/payload/src/collections/operations/local/update.ts"
  "packages/payload/src/collections/operations/restoreVersion.ts"
  "packages/payload/src/collections/operations/update.ts"
  "packages/payload/src/collections/operations/updateByID.ts"
  "packages/payload/src/config/orderable/index.ts"
  "packages/payload/src/database/getLocalizedPaths.ts"
  "packages/payload/src/fields/config/sanitizeJoinField.ts"
  "packages/payload/src/globals/operations/local/countVersions.ts"
  "packages/payload/src/globals/operations/local/findOne.ts"
  "packages/payload/src/globals/operations/local/findVersionByID.ts"
  "packages/payload/src/globals/operations/local/findVersions.ts"
  "packages/payload/src/globals/operations/local/restoreVersion.ts"
  "packages/payload/src/globals/operations/local/update.ts"
  "packages/payload/src/hierarchy/hooks/ensureSafeCollectionsChange.ts"
  "packages/payload/src/query-presets/preventLockout.ts"
  "packages/payload/src/uploads/endpoints/getFile.ts"
  "packages/payload/src/uploads/endpoints/getFileFromURL.ts"
  "packages/payload/src/uploads/endpoints/uploadInstructions.ts"
  "packages/payload/src/uploads/fetchAPI-multipart/index.ts"
  "packages/payload/src/uploads/fetchAPI-multipart/processMultipart.ts"
  "packages/payload/src/uploads/getExternalFile.ts"
  "packages/payload/src/uploads/getFileFromUploadInstructions.ts"
  "packages/payload/src/uploads/stagedUpload.ts"
  "packages/payload/src/utilities/addDataAndFileToRequest.ts"
  "packages/payload/src/utilities/getRequestEntity.ts"
  "packages/payload/src/utilities/routeError.ts"
  "packages/payload/src/utilities/sanitizeFilename.ts"
  # Test file (has 'new APIError(...)' in assertions)
  "packages/payload/src/utilities/formatErrors.spec.ts"
)

# Check which correct files were updated
CORRECT_UPDATED=()
MISSED_FILES=()
for f in "${CORRECT_FILES[@]}"; do
  if echo "$CHANGED_FILES" | grep -q "^${f}$"; then
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
npx tsc --noEmit > "$TSC_OUTPUT_FILE" 2>&1 || true
TSC_ERRORS=$(grep -c "error TS" "$TSC_OUTPUT_FILE" 2>/dev/null || true)
TSC_ERRORS=${TSC_ERRORS:-0}
echo "  TypeScript errors: $TSC_ERRORS"
cd "$MONOREPO_ROOT"

# --- Run unit tests ---
echo ""
echo "=== Running unit tests... ==="
TEST_OUTPUT_FILE="${RESULTS_DIR}/${BRANCH}-tests.txt"
pnpm test:unit > "$TEST_OUTPUT_FILE" 2>&1 || true
tail -5 "$TEST_OUTPUT_FILE"

# Parse test results
TEST_SUMMARY_LINE=$(grep "Tests " "$TEST_OUTPUT_FILE" | tail -1 || true)
TEST_PASSED=$(echo "$TEST_SUMMARY_LINE" | grep -o '[0-9]* passed' | grep -o '[0-9]*' || echo 0)
TEST_FAILED=$(echo "$TEST_SUMMARY_LINE" | grep -o '[0-9]* failed' | grep -o '[0-9]*' || echo 0)
TEST_SKIPPED=$(echo "$TEST_SUMMARY_LINE" | grep -o '[0-9]* skipped' | grep -o '[0-9]*' || echo 0)

if [ -z "$TEST_SUMMARY_LINE" ]; then
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

# Score: 1 point per correct file, -2 per remaining tsc error, +5 if tests pass
SCORE=$((CORRECTNESS - (TSC_ERRORS * 2)))
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
    "errors": ${TSC_ERRORS},
    "output_file": "${TSC_OUTPUT_FILE}"
  },
  "tests": {
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
