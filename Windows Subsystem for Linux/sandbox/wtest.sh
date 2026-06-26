#!/usr/bin/env bash
#
# wtest — Claude Code / Codex 권한 격리 샌드박스 자동화
#
# 설계: Template 복제 → 프로젝트별 일회용 Test Ubuntu
#   · SSH: agent forwarding (개인키 Test 밖)
#   · Claude: CLAUDE_CODE_OAUTH_TOKEN 환경변수 주입
#   · Codex: CODEX_ACCESS_TOKEN 환경변수 주입 (refresh 토큰 제외)
#   · Secret: gitleaks pre-commit 훅
#   · Git: SSH remote 직접
#
set -euo pipefail

# ─────────────────────────────────────────────────────────
# 설정
# ─────────────────────────────────────────────────────────
TEMPLATE_NAME="Ubuntu-26.04-Sandbox-Template"
TEST_PREFIX="Ubuntu-26.04-Sandbox"
WINDOWS_WSL_ROOT="D:\\wsl"
USER_NAME="john"
SKILLS_REPO="git@github.com:zasfe/claude-skills.git"   # 별도 스킬 repo (SSH)

state_dir="$HOME/.wtest"
mkdir -p "$state_dir"

# ─────────────────────────────────────────────────────────
# 공통 유틸
# ─────────────────────────────────────────────────────────
usage() {
  cat <<USAGE
wtest — Claude Code / Codex 격리 샌드박스

Usage:
  wtest create <project>           프로젝트 전용 Test 생성 + clone + 인증 주입
  wtest claude  <project> [args]   Test 안에서 Claude Code 실행
  wtest codex   <project> [args]   Test 안에서 Codex 실행
  wtest enter   <project>          Test 내부 셸 진입
  wtest run     <project> '<cmd>'  Test 안에서 임의 명령 실행
  wtest destroy <project>          Test 삭제 (코드는 GitHub에 안전)
  wtest list                       활성 Test 목록
  wtest doctor                     인증·도구 상태 점검

프로젝트별로 독립 Test가 생성됨. 코드 영속성은 GitHub가 담당.
USAGE
}

test_name_for() { echo "${TEST_PREFIX}-$1"; }
state_file_for() { echo "$state_dir/$1.env"; }

require_host_auth() {
  # 호스트에 인증 자격이 준비됐는지 확인
  local missing=0

  if ! ssh-add -l >/dev/null 2>&1; then
    echo "WARN: ssh-agent에 키 없음. 'ssh-add ~/.ssh/id_ed25519' 먼저 실행." >&2
    missing=1
  fi

  if [ ! -f "$HOME/.wtest-tokens/claude_oauth" ]; then
    echo "WARN: Claude 토큰 없음. 'wtest setup-claude' 실행." >&2
    missing=1
  fi

  if [ ! -f "$HOME/.codex/auth.json" ]; then
    echo "WARN: Codex auth 없음. 호스트에서 'codex login' 실행." >&2
    missing=1
  fi

  return $missing
}

# 호스트 ~/.codex/auth.json 에서 access_token만 추출 (refresh 토큰 제외)
codex_access_token() {
  if [ -f "$HOME/.codex/auth.json" ]; then
    jq -r '.tokens.access_token // empty' "$HOME/.codex/auth.json" 2>/dev/null || true
  fi
}

claude_oauth_token() {
  cat "$HOME/.wtest-tokens/claude_oauth" 2>/dev/null || true
}

# ─────────────────────────────────────────────────────────
# setup-claude : 호스트에서 1회. setup-token 발급 후 저장
# ─────────────────────────────────────────────────────────
setup_claude() {
  mkdir -p "$HOME/.wtest-tokens"
  chmod 700 "$HOME/.wtest-tokens"
  echo "호스트에서 Claude Code OAuth 토큰(1년)을 발급합니다."
  echo "브라우저 인증 후 출력되는 토큰을 복사하세요."
  echo ""
  echo "  claude setup-token"
  echo ""
  read -rsp "발급된 토큰을 붙여넣으세요: " token
  echo ""
  printf '%s' "$token" > "$HOME/.wtest-tokens/claude_oauth"
  chmod 600 "$HOME/.wtest-tokens/claude_oauth"
  echo "저장 완료: ~/.wtest-tokens/claude_oauth"
}

# ─────────────────────────────────────────────────────────
# create : Test 생성 + clone + 인증 주입
# ─────────────────────────────────────────────────────────
create_test() {
  local project="${1:?project 인자 필요}"
  local test_name; test_name="$(test_name_for "$project")"
  local win_dir="${WINDOWS_WSL_ROOT}\\${test_name}"
  local repo_url="git@github.com:${GITHUB_USER:-zasfe}/${project}.git"

  require_host_auth || { echo "ERROR: 호스트 인증 미비. 위 WARN 해결 후 재시도." >&2; exit 1; }

  echo "[1/6] Template VHDX 복제"
  wsl.exe --terminate "$TEMPLATE_NAME" 2>/dev/null || true
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "
    \$ErrorActionPreference='Stop'
    \$src='${WINDOWS_WSL_ROOT}\\${TEMPLATE_NAME}\\ext4.vhdx'
    \$dst='${win_dir}'
    if (Test-Path \$dst) { Remove-Item -Recurse -Force \$dst }
    New-Item -ItemType Directory -Force -Path \$dst | Out-Null
    Copy-Item -LiteralPath \$src -Destination (Join-Path \$dst 'ext4.vhdx') -Force
  " >/dev/null

  echo "[2/6] Test 등록"
  wsl.exe --import-in-place "$test_name" "${win_dir}\\ext4.vhdx"

  # state 저장 (프로젝트별)
  cat > "$(state_file_for "$project")" <<STATE
TEST_NAME="$test_name"
WIN_DIR="$win_dir"
PROJECT="$project"
REPO_URL="$repo_url"
STATE

  echo "[3/6] SSH agent forwarding 확인"
  # SSH_AUTH_SOCK을 Test로 전달 (실측 항목 — 안 되면 폴백 안내)
  if ! wsl.exe -d "$test_name" -- bash -lc 'SSH_AUTH_SOCK='"$SSH_AUTH_SOCK"' ssh-add -l' >/dev/null 2>&1; then
    echo "WARN: agent forwarding이 이 환경에서 동작하지 않음." >&2
    echo "      폴백: 임시 deploy key 방식으로 전환 필요 (wtest doctor 참고)." >&2
  fi

  echo "[4/6] 코드 + 스킬 clone"
  local ctok; ctok="$(claude_oauth_token)"
  local xtok; xtok="$(codex_access_token)"
  wsl.exe -d "$test_name" -- bash -lc "
    set -e
    export SSH_AUTH_SOCK='$SSH_AUTH_SOCK'
    mkdir -p ~/workground ~/.claude
    cd ~/workground
    [ -d '$project/.git' ] || git clone '$repo_url' '$project'
    # 스킬 repo clone → ~/.claude/skills 심볼릭 링크
    [ -d ~/.claude/skills-repo/.git ] || git clone '$SKILLS_REPO' ~/.claude/skills-repo
    ln -sfn ~/.claude/skills-repo/skills ~/.claude/skills
  "

  echo "[5/6] 인증 토큰 주입 (~/.bashrc, 환경변수만 — 파일 아님)"
  wsl.exe -d "$test_name" -- bash -lc "
    set -e
    # 기존 주입 블록 제거 후 재작성
    sed -i '/# >>> wtest auth >>>/,/# <<< wtest auth <<</d' ~/.bashrc 2>/dev/null || true
    cat >> ~/.bashrc <<'AUTH'
# >>> wtest auth >>>
export CLAUDE_CODE_OAUTH_TOKEN='$ctok'
export CODEX_ACCESS_TOKEN='$xtok'
export SSH_AUTH_SOCK='$SSH_AUTH_SOCK'
# Codex는 stdin 주입 방식: 최초 1회 로그인
if [ ! -f ~/.codex/auth.json ] && [ -n \"\$CODEX_ACCESS_TOKEN\" ]; then
  printenv CODEX_ACCESS_TOKEN | codex login --with-access-token >/dev/null 2>&1 || true
fi
# <<< wtest auth <<<
AUTH
  "

  echo "[6/6] gitleaks pre-commit 훅 설치"
  wsl.exe -d "$test_name" -- bash -lc "
    set -e
    cd ~/workground/$project
    mkdir -p .git/hooks
    cat > .git/hooks/pre-commit <<'HOOK'
#!/usr/bin/env bash
# secret 커밋 차단 (gitleaks)
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks protect --staged --redact --config ~/.claude/skills-repo/gitleaks.toml 2>/dev/null \
    || gitleaks protect --staged --redact
  if [ \$? -ne 0 ]; then
    echo 'BLOCKED: secret 감지됨. 커밋 차단.' >&2
    exit 1
  fi
fi
HOOK
    chmod +x .git/hooks/pre-commit
  "

  echo "Ready: $test_name (project=$project)"
  echo "  wtest claude $project   # Claude Code 실행"
  echo "  wtest codex  $project   # Codex 실행"
}

# ─────────────────────────────────────────────────────────
# 실행 계열
# ─────────────────────────────────────────────────────────
load_project() {
  local project="${1:?project 인자 필요}"
  local sf; sf="$(state_file_for "$project")"
  [ -f "$sf" ] || { echo "ERROR: '$project' Test 없음. 'wtest create $project' 먼저." >&2; exit 1; }
  # shellcheck disable=SC1090
  source "$sf"
}

run_claude() {
  local project="${1:?}"; shift || true
  load_project "$project"
  wsl.exe -d "$TEST_NAME" --cd "/home/${USER_NAME}/workground/${project}" -- \
    bash -lc "claude --dangerously-skip-permissions $*"
}

run_codex() {
  local project="${1:?}"; shift || true
  load_project "$project"
  wsl.exe -d "$TEST_NAME" --cd "/home/${USER_NAME}/workground/${project}" -- \
    bash -lc "codex --dangerously-bypass-approvals-and-sandbox $*"
}

enter_test() {
  local project="${1:?}"
  load_project "$project"
  wsl.exe -d "$TEST_NAME" --cd "/home/${USER_NAME}/workground/${project}"
}

run_cmd() {
  local project="${1:?}"; shift || true
  load_project "$project"
  [ "$#" -gt 0 ] || { echo "ERROR: 명령 필요." >&2; exit 1; }
  wsl.exe -d "$TEST_NAME" --cd "/home/${USER_NAME}/workground/${project}" -- bash -lc "$*"
}

# ─────────────────────────────────────────────────────────
# destroy
# ─────────────────────────────────────────────────────────
destroy_test() {
  local project="${1:?}"
  load_project "$project"
  echo "[1/3] Terminate $TEST_NAME"
  wsl.exe --terminate "$TEST_NAME" 2>/dev/null || true
  echo "[2/3] Unregister $TEST_NAME"
  wsl.exe --unregister "$TEST_NAME"
  echo "[3/3] 디렉토리 + state 삭제"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "
    \$d='${WIN_DIR}'; if (Test-Path \$d) { Remove-Item -Recurse -Force \$d }
  " >/dev/null
  rm -f "$(state_file_for "$project")"
  echo "Destroyed: $TEST_NAME (코드는 GitHub에 안전)"
}

# ─────────────────────────────────────────────────────────
# list / doctor
# ─────────────────────────────────────────────────────────
list_tests() {
  echo "활성 Test:"
  for sf in "$state_dir"/*.env; do
    [ -f "$sf" ] || continue
    # shellcheck disable=SC1090
    ( source "$sf"; echo "  $PROJECT → $TEST_NAME" )
  done
  wsl.exe --list --verbose 2>/dev/null | grep -F "$TEST_PREFIX" || true
}

doctor() {
  echo "=== wtest doctor ==="
  echo -n "ssh-agent 키: "; ssh-add -l >/dev/null 2>&1 && echo "OK" || echo "없음 (ssh-add 필요)"
  echo -n "Claude 토큰: "; [ -f "$HOME/.wtest-tokens/claude_oauth" ] && echo "OK" || echo "없음 (wtest setup-claude)"
  echo -n "Codex auth: "; [ -f "$HOME/.codex/auth.json" ] && echo "OK" || echo "없음 (codex login)"
  echo -n "Codex access_token 추출: "; [ -n "$(codex_access_token)" ] && echo "OK" || echo "실패 (auth.json 확인)"
  echo -n "jq 설치: "; command -v jq >/dev/null && echo "OK" || echo "없음 (apt install jq)"
  echo ""
  echo "agent forwarding 폴백: 실패 시 프로젝트별 임시 deploy key 사용"
  echo "  (GitHub repo → Settings → Deploy keys, 작업 종료 시 삭제)"
}

# ─────────────────────────────────────────────────────────
# 디스패치
# ─────────────────────────────────────────────────────────
cmd="${1:-}"; shift || true
case "$cmd" in
  create)        create_test "$@" ;;
  claude)        run_claude "$@" ;;
  codex)         run_codex "$@" ;;
  enter)         enter_test "$@" ;;
  run)           run_cmd "$@" ;;
  destroy)       destroy_test "$@" ;;
  list)          list_tests ;;
  doctor)        doctor ;;
  setup-claude)  setup_claude ;;
  *)             usage; exit 1 ;;
esac
