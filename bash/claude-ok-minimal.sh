#!/usr/bin/env bash
set -euo pipefail

# Run Claude non-interactively with minimum token usage.
# Requires: claude auth login (OAuth/subscription — no API key needed)
#
# Token-saving strategies used:
#   --system-prompt       : replaces the huge default system prompt
#   --tools ""            : disables all built-in tools (no tool defs in prompt)
#   --model haiku         : cheapest/fastest model
#   --effort low          : minimal reasoning effort
#   --strict-mcp-config   : ignore all user MCP servers
#   --mcp-config '{}'     : empty MCP config → zero MCP servers loaded
#   WORKDIR=/tmp          : no project CLAUDE.md auto-discovery
#
# Note: --bare would be even leaner but breaks OAuth/keychain auth.

PROMPT='Reply with exactly: ok'
WORKDIR=/tmp

run_claude() {
  cd "$WORKDIR" && claude \
    --print \
    --model claude-haiku-4-5-20251001 \
    --tools "" \
    --system-prompt "You are a minimal assistant. Reply with exactly what the user asks. Nothing else." \
    --effort low \
    --output-format json \
    --strict-mcp-config \
    --mcp-config '{"mcpServers":{}}' \
    -- "$PROMPT"
}

# Set SHOW_PROGRESS=1 to debug failures (shows stderr).
if [[ "${SHOW_PROGRESS:-0}" == "1" ]]; then
  run_claude
else
  run_claude 2>/dev/null
fi
