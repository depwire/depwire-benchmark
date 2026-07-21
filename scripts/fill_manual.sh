#!/bin/bash
set -e

# fill_manual.sh — Add manual measurements to a JSON results file
#
# Usage: ./scripts/fill_manual.sh results/<file>.json

JSON_FILE="$1"

if [ -z "$JSON_FILE" ] || [ ! -f "$JSON_FILE" ]; then
  echo "Usage: ./scripts/fill_manual.sh <results-json-file>"
  exit 1
fi

echo "Updating manual fields in: $JSON_FILE"
echo ""

CURRENT_AGENT=$(jq -r '.manual.agent // ""' "$JSON_FILE")
CURRENT_MODE=$(jq -r '.mode' "$JSON_FILE")

read -rp "Agent used (claude-code/cline/codex) [$CURRENT_AGENT]: " AGENT
AGENT="${AGENT:-$CURRENT_AGENT}"

read -rp "Quality score (1-10): " QUALITY
read -rp "Total cost USD (e.g. 12.50): " COST
read -rp "Total tool calls: " TOOL_CALLS

if [ "$CURRENT_MODE" = "no_depwire" ]; then
  DW_CALLS=0
  echo "Depwire tool calls: 0 (no_depwire mode)"
else
  read -rp "Depwire tool calls: " DW_CALLS
fi

read -rp "Notes: " NOTES

TMPFILE=$(mktemp)
jq \
  --arg agent "$AGENT" \
  --argjson quality "${QUALITY:-null}" \
  --argjson cost "${COST:-null}" \
  --argjson tool_calls "${TOOL_CALLS:-null}" \
  --argjson dw_calls "${DW_CALLS:-null}" \
  --arg notes "$NOTES" \
  '.manual = {
    "agent": $agent,
    "quality": $quality,
    "cost_usd": $cost,
    "tool_calls_total": $tool_calls,
    "depwire_tool_calls": $dw_calls,
    "notes": $notes
  }' "$JSON_FILE" > "$TMPFILE" && mv "$TMPFILE" "$JSON_FILE"

echo ""
echo "Updated: $JSON_FILE"
jq '.manual' "$JSON_FILE"
