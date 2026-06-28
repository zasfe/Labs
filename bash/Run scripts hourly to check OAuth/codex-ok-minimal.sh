#!/usr/bin/env bash
set -euo pipefail

# codex-ok-minimal.sh
#
# 용도: Codex를 비대화형으로 실행해 OAuth 인증이 살아있는지 확인하고,
#       최소 토큰으로 응답을 받는 스크립트. auth-check.sh 에서 호출되거나
#       단독으로 실행할 수 있다.
#
# 사전조건: codex login  (API 키 불필요, OAuth/구독 인증)
#
# 사용법:
#   bash codex-ok-minimal.sh                       # turn.completed JSON 한 줄 출력
#   SHOW_CODEX_PROGRESS=1 bash codex-ok-minimal.sh # stderr 포함 디버그 출력
#
# 출력: --json 스트림 중 type="turn.completed" 인 JSON 한 줄
#   .usage.input_tokens  : 실제 사용 토큰 수
#   .usage.output_tokens : 출력 토큰 수
#
# 토큰 절감 전략:
#   --ephemeral          : 세션 기록 저장 안 함
#   --ignore-user-config : 사용자 설정 파일 무시
#   --ignore-rules       : 프로젝트 rules 파일 무시
#   -m gpt-5.4-mini      : 가장 저렴한 모델
#   model_reasoning_effort=low  : 최소 추론 노력
#   model_verbosity=low         : 출력 간소화
#   web_search=disabled         : 웹 검색 비활성화
#   project_doc_max_bytes=0     : 프로젝트 문서 로드 차단
#   WORKDIR=/tmp         : 프로젝트별 AGENTS.md 자동 탐색 방지
#
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
