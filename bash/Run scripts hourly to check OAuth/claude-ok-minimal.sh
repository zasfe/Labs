#!/usr/bin/env bash
set -euo pipefail

# claude-ok-minimal.sh
#
# 용도: Claude를 비대화형으로 실행해 OAuth 인증이 살아있는지 확인하고,
#       최소 토큰으로 응답을 받는 스크립트. auth-check.sh 에서 호출되거나
#       단독으로 실행할 수 있다.
#
# 사전조건: claude auth login  (API 키 불필요, OAuth/구독 인증)
#
# 사용법:
#   bash claude-ok-minimal.sh            # JSON 출력 (usage 포함)
#   SHOW_PROGRESS=1 bash claude-ok-minimal.sh  # stderr 포함 디버그 출력
#
# 출력: --output-format json 의 단일 JSON 객체
#   .result           : 모델 응답 텍스트 ("ok")
#   .usage.input_tokens  : 실제 사용 토큰 수
#   .total_cost_usd   : 요청 비용
#
# 토큰 절감 전략 (기본값 대비 ~42x 절감):
#   --system-prompt  : 기본 시스템 프롬프트(~6000 토큰)를 짧은 문장으로 교체
#   --tools ""       : 모든 내장 툴 비활성화 (툴 정의 ~9600 토큰 제거)
#   --model haiku    : 가장 저렴한 모델
#   --effort low     : 최소 추론 노력
#   --strict-mcp-config + --mcp-config '{}' : MCP 서버 로드 차단
#   WORKDIR=/tmp     : CLAUDE.md 자동 탐색 방지
#
# 주의: --bare 는 더 가볍지만 OAuth/keychain 인증을 깨뜨리므로 사용 안 함.

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
