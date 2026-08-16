#!/bin/bash
set -e

RESULT_FILE="$1"
TRANSCRIPT_FILE="$2"
CLI_EXIT="${3:-0}"

if [ ! -f "$RESULT_FILE" ] || [ ! -f "$TRANSCRIPT_FILE" ]; then
  echo "usage: fill_from_claude_transcript.sh RESULT_JSON TRANSCRIPT_JSONL [CLI_EXIT]" >&2
  exit 1
fi

RESULT_EVENT=$(jq -sc '[.[] | select(.type == "result")][-1] // {}' "$TRANSCRIPT_FILE")
COST=$(echo "$RESULT_EVENT" | jq '.total_cost_usd // null')
TURNS=$(echo "$RESULT_EVENT" | jq '.num_turns // null')
MODEL=$(jq -sr '[.[] | select(.type == "assistant") | .message.model // empty][0] // "unknown"' "$TRANSCRIPT_FILE")
TOOL_CALLS=$(jq -s '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use")] | length' "$TRANSCRIPT_FILE")
DEPWIRE_CALLS=$(jq -s '[.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use" and (.name | startswith("mcp__depwire__")))] | length' "$TRANSCRIPT_FILE")

tmp_file=$(mktemp)
jq \
  --arg agent "Claude Code $MODEL" \
  --argjson cost "$COST" \
  --argjson total_calls "$TOOL_CALLS" \
  --argjson depwire_calls "$DEPWIRE_CALLS" \
  --argjson turns "$TURNS" \
  --argjson cli_exit "$CLI_EXIT" \
  '.manual.agent = $agent |
   .manual.cost_usd = $cost |
   .manual.tool_calls_total = $total_calls |
   .manual.depwire_tool_calls = $depwire_calls |
   .manual.notes = ("Automated Claude CLI run; num_turns=" + ($turns | tostring) + "; cli_exit=" + ($cli_exit | tostring))' \
  "$RESULT_FILE" > "$tmp_file"
mv "$tmp_file" "$RESULT_FILE"
