#!/bin/bash

# summary.sh — Print a markdown summary table from all JSON results
#
# Usage: ./scripts/summary.sh

RESULTS_DIR="/Users/atefataya/Developer/depwire-benchmark-v2/results"

if ! ls "$RESULTS_DIR"/*.json 1>/dev/null 2>&1; then
  echo "No results found in $RESULTS_DIR/"
  exit 0
fi

echo "# Benchmark v2 Results — Task C (Payload CMS APIError)"
echo ""
echo "| Mode | Agent | Duration | Correct | Missed | Extra | TSC Errors | Tests | Score | Depwire Calls | Tokens | Cost | Quality |"
echo "|------|-------|----------|---------|--------|-------|------------|-------|-------|---------------|--------|------|---------|"

for f in "$RESULTS_DIR"/*.json; do
  MODE=$(jq -r '.mode' "$f")
  AGENT=$(jq -r '.manual.agent // ""' "$f")
  DURATION=$(jq -r '.duration_human' "$f")
  CORRECTNESS=$(jq -r '.score.correctness' "$f")
  CORRECTNESS_MAX=$(jq -r '.score.correctness_max' "$f")
  MISSED_COUNT=$(jq -r '.files.missed_count' "$f")
  EXTRA_COUNT=$(jq -r '.files.extra_count' "$f")
  TSC_ERRORS=$(jq -r '.tsc.errors' "$f")
  TEST_RESULT=$(jq -r '.tests.result' "$f")
  SCORE=$(jq -r '.score.points' "$f")
  MAX_SCORE=$(jq -r '.score.max_points' "$f")
  PCT=$(jq -r '.score.percentage' "$f")
  DEPWIRE=$(jq -r '.manual.depwire_tool_calls // 0' "$f")
  QUALITY=$(jq -r '.manual.quality // ""' "$f")
  TOKENS=$(jq -r '.tokens.total_tokens // ""' "$f")
  COST=$(jq -r '.tokens.cost_usd // .manual.cost_usd // ""' "$f")

  TOKENS_STR=""
  if [ "$TOKENS" != "" ] && [ "$TOKENS" != "null" ]; then
    TOKENS_STR=$(printf "%'d" "$TOKENS" 2>/dev/null || echo "$TOKENS")
  fi
  COST_STR=""
  if [ "$COST" != "" ] && [ "$COST" != "null" ]; then
    COST_STR="\$${COST}"
  fi

  echo "| $MODE | $AGENT | $DURATION | ${CORRECTNESS}/${CORRECTNESS_MAX} | $MISSED_COUNT | $EXTRA_COUNT | $TSC_ERRORS | $TEST_RESULT | ${SCORE}/${MAX_SCORE} (${PCT}%) | $DEPWIRE | $TOKENS_STR | $COST_STR | $QUALITY |"
done

echo ""
echo "Generated from $(ls "$RESULTS_DIR"/*.json | wc -l | tr -d ' ') result files in $RESULTS_DIR/"
