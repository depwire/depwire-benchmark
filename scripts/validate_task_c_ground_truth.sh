#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/task_c_common.sh"

actual_file=$(mktemp)
expected_file=$(mktemp)
trap 'rm -f "$actual_file" "$expected_file"' EXIT

{
  git -C "$MONOREPO_ROOT" grep -l -E 'new APIError[[:space:]]*\(' "$BASELINE" -- \
    '*.ts' '*.tsx' '*.js' '*.jsx' '*.mts' '*.cts' || true
  git -C "$MONOREPO_ROOT" grep -l -E 'extends[[:space:]]+APIError' "$BASELINE" -- \
    '*.ts' '*.tsx' '*.js' '*.jsx' '*.mts' '*.cts' || true
  echo "packages/payload/src/errors/APIError.ts"
} | sed "s#^$BASELINE:##" \
  | grep -Ev '^packages/codemod/src/transforms/migrate-aliased-exports/merge\.(input|output)\.ts$' \
  | grep -v '^.github/actions/ai-reviewer/dist/index.js$' \
  | sort -u > "$actual_file"

grep -Ev '^[[:space:]]*(#|$)' "$GROUND_TRUTH" | sort -u > "$expected_file"

if ! diff -u "$expected_file" "$actual_file"; then
  echo "ERROR: hidden Task C ground truth does not match the pinned baseline" >&2
  exit 1
fi

echo "Task C ground truth validated: $(wc -l < "$expected_file" | tr -d ' ') files"
