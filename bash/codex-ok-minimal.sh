#!/usr/bin/env bash
set -euo pipefail

# Run Codex non-interactively while keeping the visible JSON output small.
# This assumes you already authenticated with `codex login`; it does not use an API key.

# Keep the prompt explicit. A plain "ok" can make Codex inspect files or prepare
# for a task, which increases output and token usage.
PROMPT='Do not inspect files. Do not run commands. Reply with exactly: ok'

# Use /tmp to avoid loading project-specific AGENTS.md files from a repository.
WORKDIR=/tmp

run_codex() {
  codex exec \
    --ephemeral \
    --ignore-user-config \
    --ignore-rules \
    --skip-git-repo-check \
    -C "$WORKDIR" \
    -m gpt-5.4-mini \
    -c model_reasoning_effort='"low"' \
    -c model_reasoning_summary='"none"' \
    -c model_verbosity='"low"' \
    -c web_search='"disabled"' \
    -c project_doc_max_bytes=0 \
    --json \
    "$PROMPT" </dev/null
}

# By default, hide Codex progress messages on stderr and print only the final
# token usage event. Set SHOW_CODEX_PROGRESS=1 when debugging failed runs.
if [[ "${SHOW_CODEX_PROGRESS:-0}" == "1" ]]; then
  run_codex | grep '"turn.completed"'
else
  run_codex 2>/dev/null | grep '"turn.completed"'
fi
