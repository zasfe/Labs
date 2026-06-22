#!/usr/bin/env bash
#
# Claude Code PreToolUse hook: block dangerous bash commands.
# Reads JSON from stdin, extracts the command, checks against deny patterns.
#

CMD=$(jq -r '.tool_input.command // empty')

if [ -z "$CMD" ]; then
  exit 0
fi

DENY_PATTERNS=(
  'rm\s+-rf\s+/'
  'rm\s+-rf\s+\.'
  'rm\s+-fr\s+/'
  'rm\s+-fr\s+\.'
  '\bDROP\s+TABLE\b'
  '\bDROP\s+DATABASE\b'
  '\bTRUNCATE\s+TABLE\b'
  'git\s+push\s+.*--force'
  'git\s+push\s+-f\b'
  'git\s+reset\s+--hard'
  'git\s+clean\s+-fd'
  'git\s+checkout\s+\.\s*$'
  '>\s*/dev/sd'
  '\bmkfs\b'
  '\bdd\s+if='
  ':(){.*};'
)

for pattern in "${DENY_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qEi "$pattern"; then
    MATCHED=$(echo "$CMD" | grep -oEi "$pattern" | head -1)
    cat <<EOF
{"decision":"block","reason":"Blocked dangerous command pattern: $MATCHED"}
EOF
    exit 0
  fi
done
