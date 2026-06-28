#!/usr/bin/env bash
set -euo pipefail

# auth-check.sh
#
# 용도: claude-ok-minimal.sh 와 codex-ok-minimal.sh 를 1시간마다 병렬로 실행해
#       두 도구의 OAuth 인증이 만료되지 않았는지 자동으로 점검한다.
#       결과는 ~/.auth-check.log 에 타임스탬프와 함께 누적되며 2000줄 초과 시
#       자동 로테이션된다.
#
# 사전조건:
#   - claude-ok-minimal.sh, codex-ok-minimal.sh 가 같은 디렉터리에 있어야 함
#   - claude auth login / codex login 으로 각각 사전 인증 완료
#
# 사용법:
#   bash auth-check.sh                   # 즉시 실행 (run 과 동일)
#   bash auth-check.sh run               # 즉시 실행 (중복 실행 시 자동 skip)
#   bash auth-check.sh --install-cron    # cron 등록 (멱등 — 중복 등록 안 됨)
#   bash auth-check.sh --remove-cron     # cron 해제
#   bash auth-check.sh --status          # cron 등록 여부 + 최근 로그 10줄
#   bash auth-check.sh --log [N]         # 로그 마지막 N줄 (기본 50)
#
# 멱등성:
#   - 실행 중복: flock 으로 이전 프로세스가 살아있으면 즉시 종료
#   - cron 중복: --install-cron 을 여러 번 실행해도 항목은 1개만 유지

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK_FILE="/tmp/auth-check.lock"
LOG_FILE="$HOME/.auth-check.log"
MAX_LOG_LINES=2000
CRON_SCHEDULE="0 * * * *"   # 매 정시

# ── 로그 헬퍼 ────────────────────────────────────────────────
log() {
  local ts; ts=$(date '+%Y-%m-%d %H:%M:%S')
  printf '[%s] %s\n' "$ts" "$*" | tee -a "$LOG_FILE"
}

rotate_log() {
  local lines; lines=$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)
  if (( lines > MAX_LOG_LINES )); then
    local tmp; tmp=$(mktemp)
    tail -n "$MAX_LOG_LINES" "$LOG_FILE" > "$tmp" && mv "$tmp" "$LOG_FILE"
  fi
}

# ── 개별 체크 ────────────────────────────────────────────────
run_claude() {
  local out exit_code=0
  out=$(bash "$SCRIPT_DIR/claude-ok-minimal.sh" 2>&1) || exit_code=$?
  if (( exit_code == 0 )); then
    local tokens; tokens=$(printf '%s' "$out" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['usage']['input_tokens'])" 2>/dev/null || echo '?')
    log "claude  OK  (input_tokens=${tokens})"
  else
    log "claude  FAIL  exit=${exit_code}"
  fi
  return "$exit_code"
}

run_codex() {
  local out exit_code=0
  out=$(bash "$SCRIPT_DIR/codex-ok-minimal.sh" 2>&1) || exit_code=$?
  if (( exit_code == 0 )); then
    # codex --json 출력에서 usage 추출
    local tokens; tokens=$(printf '%s' "$out" | python3 -c "
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        if d.get('type') == 'turn.completed':
            u = d.get('usage', {})
            print(u.get('input_tokens', u.get('prompt_tokens', '?')))
            break
    except Exception:
        pass
else:
    print('?')
" 2>/dev/null || echo '?')
    log "codex   OK  (input_tokens=${tokens})"
  else
    log "codex   FAIL  exit=${exit_code}"
  fi
  return "$exit_code"
}

# ── 메인 체크 (병렬 실행) ────────────────────────────────────
run_checks() {
  log "--- auth-check start ---"

  local claude_exit=0 codex_exit=0

  run_claude & local claude_pid=$!
  run_codex  & local codex_pid=$!

  wait "$claude_pid" || claude_exit=$?
  wait "$codex_pid"  || codex_exit=$?

  if (( claude_exit == 0 && codex_exit == 0 )); then
    log "--- all OK ---"
  else
    log "--- FAILED (claude=${claude_exit} codex=${codex_exit}) ---"
  fi

  rotate_log
  return $(( claude_exit | codex_exit ))
}

# ── cron 관리 (멱등) ─────────────────────────────────────────
script_path() {
  echo "$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"
}

install_cron() {
  local sp; sp=$(script_path)
  local cron_line="$CRON_SCHEDULE $sp run >> $LOG_FILE 2>&1"
  local tmp; tmp=$(mktemp)
  # 기존 항목 제거 후 재추가 → 중복 방지 (멱등)
  crontab -l 2>/dev/null | grep -vF "$sp" > "$tmp" || true
  echo "$cron_line" >> "$tmp"
  crontab "$tmp"
  rm -f "$tmp"
  echo "Cron installed: $cron_line"
  echo "Log file:       $LOG_FILE"
}

remove_cron() {
  local sp; sp=$(script_path)
  local tmp; tmp=$(mktemp)
  crontab -l 2>/dev/null | grep -vF "$sp" > "$tmp" || true
  crontab "$tmp"
  rm -f "$tmp"
  echo "Cron removed."
}

show_log() {
  tail -n "${1:-50}" "$LOG_FILE" 2>/dev/null || echo "(no log yet)"
}

# ── 진입점 ───────────────────────────────────────────────────
case "${1:-run}" in
  run)
    # flock: 이전 실행이 아직 돌고 있으면 즉시 종료 (중복 실행 방지)
    exec 9>"$LOCK_FILE"
    if ! flock -n 9; then
      echo "Already running (lock: $LOCK_FILE), skipping." >&2
      exit 0
    fi
    run_checks
    ;;
  --install-cron)
    install_cron
    ;;
  --remove-cron)
    remove_cron
    ;;
  --log)
    show_log "${2:-50}"
    ;;
  --status)
    echo "=== Crontab entries ==="
    crontab -l 2>/dev/null | grep -F "$(script_path)" || echo "(not installed)"
    echo ""
    echo "=== Last 10 log lines ==="
    show_log 10
    ;;
  *)
    echo "Usage: $(basename "$0") [run|--install-cron|--remove-cron|--log [N]|--status]"
    exit 1
    ;;
esac
