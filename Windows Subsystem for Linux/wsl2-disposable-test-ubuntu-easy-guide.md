# WSL2 Ubuntu 테스트 환경 구성 매뉴얼 (쉬운 버전)

> Work / Template / Disposable Test 구조를 처음부터 끝까지 따라 만드는 안내서.
> IT 지식이 많지 않아도 따라올 수 있게 다시 정리했다.

---

## 📍 실행 위치 표기 약속

이 매뉴얼은 **명령을 어디서 치느냐**가 가장 중요하다.
각 코드 블록 앞에 아래 배지로 위치를 표시한다.

| 배지 | 실행 위치 | 무엇을 하는 곳 |
|------|-----------|----------------|
| 🪟 **PowerShell** | Windows PowerShell | 배포판 설치·삭제 |
| 🛠️ **Work** | Ubuntu-26.04-Work | 코드 작성·Git·제어 |
| 📦 **Template** | Ubuntu-26.04-Template | 깨끗한 원본 (복사 전용) |
| 🧪 **Test** | Ubuntu-26.04-Test-* | 실험 (매번 생성·삭제) |
| 🛠️→🧪 | Work에서 Test로 원격 실행 | `wtest run ...` |

---

# 0. 퀵스타트 — 일단 한번 돌려보기

> **목표:** 세부 설명은 건너뛰고, 복사·붙여넣기로 환경을 만들어 첫 실험까지 가본다.
> **소요 시간:** 약 40분 (대부분 다운로드·설치 대기)
> **전제:** Windows에 WSL2가 설치돼 있고, `D:` 드라이브를 쓸 수 있다.

막히면 본문의 해당 섹션(괄호 안 번호)이나 **5장 문제 해결**을 본다.

## 한눈에 보는 전체 흐름

```
[1회만] 환경 구축                    [매번 반복] 실험
─────────────────                   ─────────────────
A. Ubuntu 설치·백업                  ┌─▶ wtest-create   (Test 생성)
B. Work Ubuntu 생성                  │   wtest run ...   (실험 실행)
C. Template Ubuntu 생성              │   wtest-pull      (결과 회수)
D. 자동화 스크립트 설치              └── wtest-destroy   (Test 삭제)
```

처음 A~D는 한 번만 한다. 그 다음부터는 오른쪽 4줄만 반복하면 된다.

## A. Ubuntu 설치 + 백업본 만들기

🪟 **PowerShell** · 상세 → 본문 1장

```powershell
wsl --install -d Ubuntu-26.04
wsl --terminate Ubuntu-26.04
mkdir D:\wsl\base
wsl --export Ubuntu-26.04 D:\wsl\base\ubuntu-2604-base.tar
```

✅ `D:\wsl\base\ubuntu-2604-base.tar` 생성 확인.

## B. Work Ubuntu 만들기

🪟 **PowerShell** → 🛠️ **Work** · 상세 → 본문 2.1

```powershell
mkdir D:\wsl\Ubuntu-26.04-Work
wsl --import Ubuntu-26.04-Work D:\wsl\Ubuntu-26.04-Work D:\wsl\base\ubuntu-2604-base.tar --version 2
wsl -d Ubuntu-26.04-Work
```

```bash
id john || adduser john
usermod -aG sudo john
cat >/etc/wsl.conf <<'EOF'
[user]
default=john
[automount]
enabled=true
root=/mnt/
[interop]
enabled=true
appendWindowsPath=true
[boot]
systemd=true
EOF
exit
```

```powershell
wsl --terminate Ubuntu-26.04-Work
wsl -d Ubuntu-26.04-Work
```

```bash
sudo apt update && sudo apt install -y git ca-certificates curl tar gzip rsync
git config --global user.name "john"
git config --global user.email "john@local"
mkdir -p ~/workground ~/bundles ~/scripts
```

✅ `ls /mnt/c` 보이고 `wsl.exe --list` 실행됨.

## C. Template Ubuntu 만들기

🪟 **PowerShell** → 📦 **Template** · 상세 → 본문 2.3

```powershell
mkdir D:\wsl\Ubuntu-26.04-Template
wsl --import Ubuntu-26.04-Template D:\wsl\Ubuntu-26.04-Template D:\wsl\base\ubuntu-2604-base.tar --version 2
wsl -d Ubuntu-26.04-Template
```

```bash
id john || adduser john
usermod -aG sudo john
cat >/etc/wsl.conf <<'EOF'
[user]
default=john
[automount]
enabled=false
mountFsTab=false
[interop]
enabled=false
appendWindowsPath=false
[boot]
systemd=true
EOF
sudo apt update && sudo apt install -y git ca-certificates curl tar gzip docker.io docker-compose-v2
sudo usermod -aG docker john
git config --global user.name "john"
git config --global user.email "john@test.local"
mkdir -p ~/workground ~/bundles
exit
```

```powershell
wsl --terminate Ubuntu-26.04-Template
```

✅ `D:\wsl\Ubuntu-26.04-Template\ext4.vhdx` 파일 존재 확인.

> ⚠️ Template은 여기서 끝. 이후 직접 접속하지 않고 복사해서만 쓴다.

## D. 자동화 스크립트 설치

🛠️ **Work** · 상세 → 본문 3장

본문 3.2의 전체 스크립트를 `~/scripts/wsl2-disposable-test.sh` 로 저장한 뒤:

```bash
chmod +x ~/scripts/wsl2-disposable-test.sh
cat >>~/.bashrc <<'EOF'
alias wtest='~/scripts/wsl2-disposable-test.sh'
alias wtest-create='~/scripts/wsl2-disposable-test.sh create'
alias wtest-pull='~/scripts/wsl2-disposable-test.sh pull'
alias wtest-enter='~/scripts/wsl2-disposable-test.sh enter'
alias wtest-destroy='~/scripts/wsl2-disposable-test.sh destroy'
alias wtest-status='~/scripts/wsl2-disposable-test.sh status'
EOF
source ~/.bashrc
```

✅ `wtest-status` → "No active Test Ubuntu" 출력.

## 🎉 첫 실험

🛠️ **Work**

```bash
mkdir -p ~/workground/openclaw && cd ~/workground/openclaw
git init && echo "# 테스트" > README.md
git add . && git commit -m "first"

wtest-create                                   # ① Test 생성
wtest run openclaw 'pwd && git log --oneline'  # ② Test 안에서 확인
wtest-pull                                     # ③ 결과 회수
wtest-destroy                                  # ④ Test 삭제
```

여기까지 됐다면 환경 구축 완료. 이제 본문에서 자세한 사용법을 익히면 된다.

---

# 1. 시작 전 읽기 — 핵심 개념

> 이 섹션만 먼저 읽으면 전체 매뉴얼의 70%가 이해된다.

## 한 줄 요약

> **작업은 Work에서, 실험은 Test에서, Test는 쓰고 버린다.**

## 세 가지 Ubuntu — 도장 비유

```
┌──────────────────────────────────────────────────────┐
│                   내 Windows PC                      │
│                                                      │
│  ┌─────────────┐   ┌─────────────┐                  │
│  │  Template   │   │    Work     │                  │
│  │  (원판/도장) │   │  (작업대)   │                  │
│  │             │   │             │                  │
│  │ 깨끗한 상태  │   │ 코드 수정   │                  │
│  │ 건드리지 않음│   │ 문서 작성   │                  │
│  │ 복사 전용   │   │ Git commit  │                  │
│  └──────┬──────┘   └─────────────┘                  │
│         │ 복사 (도장 찍기)                            │
│         ▼                                            │
│  ┌─────────────┐                                     │
│  │    Test     │                                     │
│  │  (실험대)   │                                     │
│  │ 도커 실행   │                                     │
│  │ 검증/실험   │                                     │
│  │ 끝나면 삭제 │ ◀── 테스트마다 새로 만들고 버린다   │
│  └─────────────┘                                     │
└──────────────────────────────────────────────────────┘
```

| 역할 | 비유 | 실제 이름 | 하는 일 |
|------|------|-----------|---------|
| 원판 | 도장 원판 | `Ubuntu-26.04-Template` | 복사만 당함, 손대지 않음 |
| 작업대 | 내 책상 | `Ubuntu-26.04-Work` | 코드 작성, Git 관리 |
| 실험대 | 일회용 접시 | `Ubuntu-26.04-Test-날짜시간` | 실험 후 버림 |

## 왜 이렇게 하나요?

```
[기존 방식]                          [이 매뉴얼 방식]
고정 Ubuntu에서 계속 실험            Test를 매번 새로 만들고 버림
   │                                    │
   ▼                                    ▼
실험 흔적 누적 → 오염 😱             항상 깨끗한 상태에서 시작 ✨
"어제는 됐는데 왜 안 되지?"          실패해도 삭제하면 끝
```

실험이 끝나면 Test 환경을 통째로 버린다. 오염될 걱정이 없다.

## "지금 어디서 실행하나요?" 판단법

```
WSL 배포판을 만들거나 지운다  → 🪟 PowerShell 또는 🛠️ Work의 wsl.exe
코드·문서를 수정한다          → 🛠️ Work
Docker/OpenClaw를 실행한다    → 🧪 Test
Test 환경을 만들고 지운다     → 🛠️ Work의 wtest 명령
```

## 파일은 어떻게 주고받나요? — Git bundle

SSH도 공유 폴더도 없다. **Git bundle** 파일 하나로 코드를 주고받는다.

```
🛠️ Work                              🧪 Test
   │  1. git commit                     │
   │  2. git bundle create ──────────▶  │  3. git clone
   │                   파일 하나        │  4. 실험 실행
   │  6. git pull     ◀──────────────── │  5. git bundle create
   │  7. wtest-destroy                  │  ← 삭제
```

> Git bundle = 코드 우체통. 인터넷도 서버도 IP도 필요 없다.

## 자주 쓰는 명령

```
wtest-create   ← Test Ubuntu 새로 만들기 (Template 복사)
wtest run      ← Test Ubuntu 안에서 명령 실행
wtest-pull     ← Test 결과를 Work로 가져오기
wtest-destroy  ← Test Ubuntu 삭제
wtest-status   ← 현재 Test Ubuntu 이름 확인
```

> 📄출처: [Microsoft, Basic commands for WSL, 2025, https://learn.microsoft.com/en-us/windows/wsl/basic-commands], [Microsoft, Advanced settings configuration in WSL, 2026, https://learn.microsoft.com/en-us/windows/wsl/wsl-config], [Git SCM, git-bundle Documentation, 2025, https://git-scm.com/docs/git-bundle]

---

# 2. 사전 준비

🪟 **PowerShell** · 소요 10~20분

## 2.1 WSL 상태 확인

```powershell
wsl --version
wsl --status
wsl --set-default-version 2
wsl --list --online
```

`Ubuntu-26.04`가 목록에 있으면 그대로 사용한다. 없으면 Ubuntu 24.04로 먼저 구성하거나 rootfs tar를 직접 import 한다.

## 2.2 Ubuntu 26.04 설치

```powershell
wsl --install -d Ubuntu-26.04
```

최초 실행 시 Linux 사용자 계정을 만든다 (예: `john`).

```powershell
wsl --list --verbose
```

## 2.3 base 백업본 만들기

```powershell
wsl --terminate Ubuntu-26.04
mkdir D:\wsl
mkdir D:\wsl\base
wsl --export Ubuntu-26.04 D:\wsl\base\ubuntu-2604-base.tar
```

선택: 원본 제거 (백업본 확인 후)

```powershell
wsl --unregister Ubuntu-26.04
```

> ⚠️ `wsl --unregister`는 배포판과 데이터를 삭제한다. base tar 생성을 반드시 확인하고 실행한다.

> 이 단계가 끝나면 모든 Ubuntu 환경은 이 tar 파일에서 복사된다.

> 📄출처: [Microsoft, Basic commands for WSL, 2025, https://learn.microsoft.com/en-us/windows/wsl/basic-commands]

---

# 3. 환경 구축

소요 20~30분

## 3.1 Work Ubuntu 만들기

🪟 **PowerShell** — import 및 접속

```powershell
mkdir D:\wsl\Ubuntu-26.04-Work
wsl --import Ubuntu-26.04-Work D:\wsl\Ubuntu-26.04-Work D:\wsl\base\ubuntu-2604-base.tar --version 2
wsl -d Ubuntu-26.04-Work
```

🛠️ **Work** — 사용자 생성

```bash
id john || adduser john
usermod -aG sudo john
```

🛠️ **Work** — `/etc/wsl.conf` 작성 (Windows 연동 허용)

```bash
cat >/etc/wsl.conf <<'EOF'
[user]
default=john

[automount]
enabled=true
root=/mnt/
options=metadata,umask=22,fmask=11
mountFsTab=true

[interop]
enabled=true
appendWindowsPath=true

[boot]
systemd=true
EOF
exit
```

🪟 **PowerShell** — 재시작

```powershell
wsl --terminate Ubuntu-26.04-Work
wsl -d Ubuntu-26.04-Work
```

🛠️ **Work** — 기본 패키지 설치

```bash
sudo apt update
sudo apt install -y git ca-certificates curl tar gzip rsync
git config --global user.name "john"
git config --global user.email "john@local"
git config --global init.defaultBranch main
mkdir -p ~/workground ~/bundles ~/scripts
```

🛠️ **Work** — 검증

```bash
whoami                 # → john
ls /mnt/c              # → C드라이브 내용 보임
powershell.exe -Command '$PSVersionTable.PSVersion'   # → 실행됨
wsl.exe --list --verbose                              # → 실행됨
```

> 📄출처: [Microsoft, Advanced settings configuration in WSL, 2026, https://learn.microsoft.com/en-us/windows/wsl/wsl-config]

## 3.2 Template Ubuntu 만들기

🪟 **PowerShell** — import 및 접속

```powershell
mkdir D:\wsl\Ubuntu-26.04-Template
wsl --import Ubuntu-26.04-Template D:\wsl\Ubuntu-26.04-Template D:\wsl\base\ubuntu-2604-base.tar --version 2
wsl -d Ubuntu-26.04-Template
```

📦 **Template** — 사용자 생성

```bash
id john || adduser john
usermod -aG sudo john
```

📦 **Template** — `/etc/wsl.conf` 작성 (Windows 연동 **차단**)

```bash
cat >/etc/wsl.conf <<'EOF'
[user]
default=john

[automount]
enabled=false
mountFsTab=false

[interop]
enabled=false
appendWindowsPath=false

[boot]
systemd=true
EOF
```

📦 **Template** — 기본 패키지 + Docker 설치

```bash
sudo apt update
sudo apt install -y git ca-certificates curl tar gzip
git config --global user.name "john"
git config --global user.email "john@test.local"
git config --global init.defaultBranch main
mkdir -p ~/workground ~/bundles

# Docker 포함할 경우
sudo apt install -y docker.io docker-compose-v2
sudo usermod -aG docker john
exit
```

🪟 **PowerShell** — 종료

```powershell
wsl --terminate Ubuntu-26.04-Template
```

📦 **Template** — 격리 검증 (재접속 후)

```bash
whoami                                          # → john
ls /mnt/c || true                               # → 접근 불가
powershell.exe -Command '$PSVersionTable' || true  # → 실행 불가
mount | grep -E 'drvfs|9p' || true              # → Windows 마운트 없음
exit
```

> ⚠️ Template은 이후 직접 작업하지 않는다. Disposable Test 생성을 위한 원본 이미지로만 쓴다.

## 3.3 Template VHDX 위치 확인

🪟 **PowerShell**

```powershell
dir D:\wsl\Ubuntu-26.04-Template
```

기본 경로: `D:\wsl\Ubuntu-26.04-Template\ext4.vhdx`

> ⚠️ Template이 실행 중일 때 ext4.vhdx를 복사하지 않는다. 항상 `wsl --terminate` 또는 `wsl --shutdown` 후 복사한다.

### Disposable Test 생성 방식 (참고)

```
Template ext4.vhdx 복사
→ wsl --import-in-place로 새 Test Ubuntu 등록
→ 테스트 실행 → 결과 회수
→ wsl --unregister → Test 폴더 삭제
```

장점: tar import보다 빠름 / 항상 같은 상태에서 시작 / 테스트마다 새 배포판 / 실패 시 삭제로 끝 / IP·SSH·마운트 불필요.

> 📄출처: [Microsoft, Basic commands for WSL, 2025, https://learn.microsoft.com/en-us/windows/wsl/basic-commands]

---

# 4. 도구 설치

🛠️ **Work** · 소요 10분

## 4.1 프로젝트 생성

```bash
mkdir -p ~/workground/openclaw
cd ~/workground/openclaw
git init
cat >README.md <<'EOF'
# OpenClaw Lab
WSL2 Work/Template/Disposable Test 동기화 테스트 프로젝트.
EOF
git add .
git commit -m "initial commit"
```

## 4.2 자동화 스크립트 작성

🛠️ **Work** — 아래 전체를 그대로 실행한다.

```bash
cat >~/scripts/wsl2-disposable-test.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_NAME="Ubuntu-26.04-Template"
TEST_PREFIX="Ubuntu-26.04-Test"
WINDOWS_WSL_ROOT="D:\\wsl"
LINUX_WSL_ROOT="/mnt/d/wsl"
USER_NAME="john"

usage() {
  cat <<USAGE
Usage:
  $(basename "$0") create [project_dir]
  $(basename "$0") push [project_dir]
  $(basename "$0") enter [project_name]
  $(basename "$0") run [project_name] '<command>'
  $(basename "$0") pull [project_dir]
  $(basename "$0") destroy
  $(basename "$0") status

Commands:
  create   Create fresh disposable Test Ubuntu from Template VHDX and push project bundle
  push     Send current project to active Test Ubuntu
  enter    Enter active Test Ubuntu project directory
  run      Run command in active Test Ubuntu project directory
  pull     Pull result bundle from active Test Ubuntu to Work Ubuntu
  destroy  Unregister active Test Ubuntu and remove its directory
  status   Show active Test Ubuntu name
USAGE
}

state_dir="$HOME/.wsl2-disposable-test"
state_file="$state_dir/active-test.env"

mkdir -p "$state_dir"

load_state() {
  if [ -f "$state_file" ]; then
    source "$state_file"
  fi
}

save_state() {
  mkdir -p "$state_dir"
  cat >"$state_file" <<STATE
ACTIVE_TEST_NAME="$ACTIVE_TEST_NAME"
ACTIVE_TEST_WIN_DIR="$ACTIVE_TEST_WIN_DIR"
ACTIVE_TEST_LINUX_DIR="$ACTIVE_TEST_LINUX_DIR"
STATE
}

require_active() {
  load_state
  if [ -z "${ACTIVE_TEST_NAME:-}" ]; then
    echo "ERROR: active Test Ubuntu not found. Run create first." >&2
    exit 1
  fi
}

project_name_from_dir() {
  basename "$1"
}

commit_if_dirty() {
  if ! git diff --quiet || ! git diff --cached --quiet; then
    git add .
    git commit -m "$1"
  fi
}

create_test() {
  local project_dir="${1:-$PWD}"
  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"

  ACTIVE_TEST_NAME="${TEST_PREFIX}-${timestamp}"
  ACTIVE_TEST_WIN_DIR="${WINDOWS_WSL_ROOT}\\${ACTIVE_TEST_NAME}"
  ACTIVE_TEST_LINUX_DIR="${LINUX_WSL_ROOT}/${ACTIVE_TEST_NAME}"

  echo "[1/5] Stop template"
  wsl.exe --terminate "$TEMPLATE_NAME" 2>/dev/null || true

  echo "[2/5] Copy template VHDX"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "
    \$ErrorActionPreference = 'Stop'
    \$src = '${WINDOWS_WSL_ROOT}\\${TEMPLATE_NAME}\\ext4.vhdx'
    \$dstDir = '${ACTIVE_TEST_WIN_DIR}'
    \$dst = Join-Path \$dstDir 'ext4.vhdx'
    if (Test-Path \$dstDir) { Remove-Item -Recurse -Force \$dstDir }
    New-Item -ItemType Directory -Force -Path \$dstDir | Out-Null
    Copy-Item -LiteralPath \$src -Destination \$dst -Force
  " >/dev/null

  echo "[3/5] Register Test Ubuntu"
  wsl.exe --import-in-place "$ACTIVE_TEST_NAME" "${ACTIVE_TEST_WIN_DIR}\\ext4.vhdx"

  save_state

  echo "[4/5] Push project bundle"
  push_project "$project_dir"

  echo "[5/5] Ready: $ACTIVE_TEST_NAME"
}

push_project() {
  require_active

  local project_dir="${1:-$PWD}"
  local project_name
  project_name="$(project_name_from_dir "$project_dir")"

  local work_bundle="$HOME/bundles/${project_name}.bundle"
  local test_bundle="/home/${USER_NAME}/bundles/${project_name}.bundle"
  local test_project="/home/${USER_NAME}/workground/${project_name}"

  cd "$project_dir"

  if [ ! -d .git ]; then
    echo "ERROR: not a git repository: $project_dir" >&2
    exit 1
  fi

  mkdir -p "$HOME/bundles"

  commit_if_dirty "sync to disposable test"

  git bundle create "$work_bundle" HEAD
  git bundle verify "$work_bundle"

  wsl.exe -d "$ACTIVE_TEST_NAME" -- mkdir -p "/home/${USER_NAME}/bundles" "/home/${USER_NAME}/workground"

  cat "$work_bundle" \
    | wsl.exe -d "$ACTIVE_TEST_NAME" -- tee "$test_bundle" >/dev/null

  wsl.exe -d "$ACTIVE_TEST_NAME" -- bash -lc "
    set -e
    if [ ! -d '$test_project/.git' ]; then
      cd /home/${USER_NAME}/workground
      rm -rf '$project_name'
      git clone '$test_bundle' '$project_name'
    else
      cd '$test_project'
      git pull '$test_bundle' HEAD
    fi
    cd '$test_project'
    git status
  "
}

enter_test() {
  require_active
  local project_name="${1:-$(basename "$PWD")}"
  wsl.exe -d "$ACTIVE_TEST_NAME" --cd "/home/${USER_NAME}/workground/${project_name}"
}

run_test() {
  require_active
  local project_name="${1:-$(basename "$PWD")}"
  shift || true

  if [ "$#" -eq 0 ]; then
    echo "ERROR: command is required." >&2
    exit 1
  fi

  wsl.exe -d "$ACTIVE_TEST_NAME" -- bash -lc "cd /home/${USER_NAME}/workground/${project_name} && $*"
}

pull_result() {
  require_active

  local project_dir="${1:-$PWD}"
  local project_name
  project_name="$(project_name_from_dir "$project_dir")"

  local test_project="/home/${USER_NAME}/workground/${project_name}"
  local test_bundle="/home/${USER_NAME}/bundles/${project_name}-result.bundle"
  local work_bundle="$HOME/bundles/${project_name}-result.bundle"

  mkdir -p "$HOME/bundles"

  wsl.exe -d "$ACTIVE_TEST_NAME" -- bash -lc "
    set -e
    cd '$test_project'

    if ! git diff --quiet || ! git diff --cached --quiet; then
      git add .
      git commit -m 'sync from disposable test'
    fi

    mkdir -p /home/${USER_NAME}/bundles
    git bundle create '$test_bundle' HEAD
    git bundle verify '$test_bundle'
  "

  wsl.exe -d "$ACTIVE_TEST_NAME" -- cat "$test_bundle" > "$work_bundle"

  cd "$project_dir"
  git pull "$work_bundle" HEAD
  git status
}

destroy_test() {
  require_active

  echo "[1/3] Terminate $ACTIVE_TEST_NAME"
  wsl.exe --terminate "$ACTIVE_TEST_NAME" 2>/dev/null || true

  echo "[2/3] Unregister $ACTIVE_TEST_NAME"
  wsl.exe --unregister "$ACTIVE_TEST_NAME"

  echo "[3/3] Remove directory $ACTIVE_TEST_WIN_DIR"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "
    \$ErrorActionPreference = 'Stop'
    \$dir = '${ACTIVE_TEST_WIN_DIR}'
    if (Test-Path \$dir) { Remove-Item -Recurse -Force \$dir }
  " >/dev/null

  rm -f "$state_file"

  echo "Destroyed: $ACTIVE_TEST_NAME"
}

status_test() {
  load_state
  if [ -z "${ACTIVE_TEST_NAME:-}" ]; then
    echo "No active Test Ubuntu"
    exit 0
  fi

  echo "ACTIVE_TEST_NAME=$ACTIVE_TEST_NAME"
  echo "ACTIVE_TEST_WIN_DIR=$ACTIVE_TEST_WIN_DIR"
  wsl.exe --list --verbose | grep -F "$ACTIVE_TEST_NAME" || true
}

cmd="${1:-}"
shift || true

case "$cmd" in
  create)  create_test "${1:-$PWD}" ;;
  push)    push_project "${1:-$PWD}" ;;
  enter)   enter_test "${1:-$(basename "$PWD")}" ;;
  run)     run_test "$@" ;;
  pull)    pull_result "${1:-$PWD}" ;;
  destroy) destroy_test ;;
  status)  status_test ;;
  *)       usage; exit 1 ;;
esac
EOF

chmod +x ~/scripts/wsl2-disposable-test.sh
```

## 4.3 단축 명령(alias) 등록

🛠️ **Work**

```bash
cat >>~/.bashrc <<'EOF'

# WSL2 Disposable Test Ubuntu workflow
alias wtest='~/scripts/wsl2-disposable-test.sh'
alias wtest-create='~/scripts/wsl2-disposable-test.sh create'
alias wtest-push='~/scripts/wsl2-disposable-test.sh push'
alias wtest-enter='~/scripts/wsl2-disposable-test.sh enter'
alias wtest-pull='~/scripts/wsl2-disposable-test.sh pull'
alias wtest-destroy='~/scripts/wsl2-disposable-test.sh destroy'
alias wtest-status='~/scripts/wsl2-disposable-test.sh status'
EOF

source ~/.bashrc
```

---

# 5. 사용법

🛠️ **Work** 중심

## 5.1 기본 사용 흐름

```bash
# ① 새 Test Ubuntu 생성 + 프로젝트 전달
wtest-create

# ② Test 안에서 명령 실행
wtest run openclaw 'pwd && git status'
wtest run openclaw 'docker compose config --quiet'
wtest run openclaw 'docker compose up -d'
wtest run openclaw 'docker compose ps'

# ③ Test 직접 진입
wtest-enter openclaw

# ④ 결과를 Work로 회수
cd ~/workground/openclaw
wtest-pull

# ⑤ Test 삭제
wtest-destroy
wtest-status
```

`wtest-create` 내부 동작: Template 종료 → ext4.vhdx 복사 → 새 Test 등록 → Git bundle 생성 → Test로 전달 → clone.

## 5.2 한 사이클 전체 예시

```bash
cd ~/workground/openclaw

git checkout -b experiment/docker-compose-test
vi docker-compose.yml
git add .
git commit -m "prepare docker compose experiment"

wtest-create
wtest run openclaw 'docker compose config --quiet'
wtest run openclaw 'docker compose up -d'
wtest run openclaw 'docker compose ps'

wtest-pull
wtest-destroy

git log --oneline --decorate -5
```

## 5.3 OpenClaw / Hermes 권장 흐름

```
[🛠️ Work]
  Claude Code / Codex / 문서 작성 → 코드 수정 → git commit → wtest-create

[🧪 Test] (매번 Template에서 깨끗하게 생성)
  Windows 마운트·실행파일 연동 없음
  docker compose config --quiet
  docker compose up -d
  docker compose ps
  OpenClaw/Hermes 동작 검증

[🛠️ Work]
  wtest-pull → 변경 확인 → wtest-destroy → 필요 시 main 병합
```

OpenClaw/Hermes 같은 Compose 운영 저장소는 Docker volume·network·bind mount·DB·Redis·Mattermost 상태 오염 가능성이 크므로 Disposable Test 방식이 적합하다.

## 5.4 심화: 병렬 테스트

필요 시 Test를 여러 개 만들 수 있다.

```
Ubuntu-26.04-Work
   ├─ Ubuntu-26.04-Test-20260626-101000
   ├─ Ubuntu-26.04-Test-20260626-102000
   └─ Ubuntu-26.04-Test-20260626-103000
```

> ⚠️ 현재 스크립트는 active Test 1개 기준이다. 병렬 운영하려면 `state_file`을 테스트명별로 분리해야 한다. 초기엔 단일 active test 방식을 권장한다.

---

# 6. 문제 해결 & 검증

## 6.1 설치 완료 검증 체크리스트

| 확인 항목 | 기대 결과 | 실행 위치 |
|-----------|-----------|-----------|
| `wsl --list --verbose` | Work, Template 둘 다 VERSION 2 | 🪟 PowerShell |
| `whoami` | john | 🛠️ Work |
| `ls /mnt/c` | C드라이브 내용 보임 | 🛠️ Work |
| `powershell.exe` 실행 | 실행됨 | 🛠️ Work |
| `ls /mnt/c` | 오류 (접근 불가) | 📦 Template |
| `powershell.exe` 실행 | 오류 (실행 불가) | 📦 Template |
| `mount \| grep drvfs` | 결과 없음 | 📦 Template |
| `wtest-create` 후 `wtest-status` | Test 이름 출력 | 🛠️ Work |
| `wtest run openclaw 'ls /mnt/c'` | 접근 불가 | 🛠️→🧪 |
| `wtest run openclaw 'git log --oneline'` | Work 최신 commit 보임 | 🛠️→🧪 |
| `wtest-destroy` 후 `wsl --list` | Test-* 없음 | 🛠️ Work |

## 6.2 자주 발생하는 오류

| 증상 | 원인 | 해결 |
|------|------|------|
| `wsl.exe: command not found` | Work의 interop 비활성화 | `/etc/wsl.conf` → `[interop] enabled=true` 후 재시작 |
| Template/Test에서 `/mnt/c` 보임 | automount 미적용 | `/etc/wsl.conf` → `[automount] enabled=false` 후 재시작, Test 재생성 |
| Template/Test에서 `powershell.exe` 실행됨 | interop 미적용 | `/etc/wsl.conf` → `[interop] enabled=false` 후 재시작, Test 재생성 |
| `wsl --import-in-place` 실패 | VHDX 잠금·경로 오류·이름 중복 | `wsl --shutdown` 후 재시도, 기존 Test 제거 |
| `git pull bundle` 충돌 | Work/Test 양쪽 수정 충돌 | `git status` → 충돌 수정 → `git add . && git commit` |
| `git bundle verify` 실패 | 선행 commit 없음 | `git bundle create ... --all` 또는 `wtest-destroy && wtest-create` |

### `import-in-place` 실패 시 정리

🪟 **PowerShell**

```powershell
wsl --shutdown
wsl --list --verbose
dir D:\wsl\Ubuntu-26.04-Template\ext4.vhdx
wsl --unregister Ubuntu-26.04-Test-YYYYMMDD-HHMMSS
Remove-Item -Recurse -Force D:\wsl\Ubuntu-26.04-Test-YYYYMMDD-HHMMSS
```

> 📄출처: [Microsoft, Troubleshooting Windows Subsystem for Linux, 2026, https://learn.microsoft.com/en-us/windows/wsl/troubleshooting], [Git SCM, git-bundle Documentation, 2025, https://git-scm.com/docs/git-bundle]

---

# 부록 A. 운영 원칙

| 원칙 | 설명 |
|------|------|
| Template 직접 작업 금지 | 깨끗한 원본 이미지 역할, 항상 복사해서 사용 |
| Test 재사용 금지 | 테스트마다 새 Test Ubuntu 생성 |
| Test 종료 후 삭제 | 오염 상태를 보존하지 않음 |
| Work만 지속 사용 | 개발·문서·AI 도구는 Work에서 실행 |
| Windows 공유폴더 금지 | Test로 `/mnt/c` 공유하지 않음 |
| IP 의존 금지 | SSH·Bare Repo·IP 기반 접근 안 함 |
| Git bundle 기준 동기화 | 파일 복사가 아닌 commit 단위 전달 |
| 실험은 브랜치 사용 | `experiment/*` 브랜치 권장 |
| Docker 실행은 Test 우선 | OpenClaw/Hermes 검증은 Disposable Test에서 |
| 결과 회수 후 삭제 | `wtest-pull` 이후 `wtest-destroy` |

---

# 부록 B. 헷갈리기 쉬운 명령 실행 위치

| 명령 | 실행 위치 | 이유 |
|------|-----------|------|
| `wsl --install / --export / --import` | 🪟 PowerShell | 배포판 설치·백업·등록 |
| `wsl --import-in-place / --unregister` | 🪟 PowerShell 또는 🛠️ Work의 wsl.exe | VHDX 등록·삭제 |
| `git add / commit / bundle create` | 🛠️ Work 또는 🧪 Test | 현재 작업 사본 기준 |
| `docker compose up -d` | 🧪 Test | 오염 가능성 → Disposable에서 실행 |
| `wtest-create / run / pull / destroy` | 🛠️ Work | Work에서 Test 제어 |

---

# 부록 C. 참고 출처

> 📄출처: [Microsoft, Basic commands for WSL, 2025, https://learn.microsoft.com/en-us/windows/wsl/basic-commands], [Microsoft, Advanced settings configuration in WSL, 2026, https://learn.microsoft.com/en-us/windows/wsl/wsl-config], [Microsoft, Troubleshooting Windows Subsystem for Linux, 2026, https://learn.microsoft.com/en-us/windows/wsl/troubleshooting], [Git SCM, git-bundle Documentation, 2025, https://git-scm.com/docs/git-bundle], [Kernel.org, git-bundle Manual Page, 2025, https://www.kernel.org/pub/software/scm/git/docs/git-bundle.html]

---

# 부록 D. 용어 사전

> 읽다가 모르는 단어가 나오면 여기서 찾는다.

## 가장 먼저 알아야 할 5개

| 용어 | 한 줄 설명 | 비유 |
|------|-----------|------|
| **WSL2** | Windows 안에서 진짜 리눅스를 돌리는 기능 | Windows 안의 작은 리눅스 PC |
| **배포판 (distro)** | 리눅스의 한 종류·한 대. Ubuntu가 그중 하나 | 리눅스 PC 한 대 |
| **Work/Template/Test** | 이 매뉴얼의 세 가지 Ubuntu 환경 | 작업대 / 도장 원판 / 일회용 접시 |
| **Disposable (일회용)** | 쓰고 바로 버리는 방식 | 일회용 종이컵 |
| **Git bundle** | 코드를 파일 하나로 묶어 전달하는 방법 | 코드 우체통 |

## WSL 관련

| 용어 | 한 줄 설명 |
|------|-----------|
| **VHDX** | 배포판 디스크 전체가 담긴 파일. 복사하면 환경이 통째로 복제됨 |
| **rootfs / tar** | 리눅스 초기 상태 압축 파일. 새 배포판 원본 |
| **wsl.conf** | 배포판별 설정 파일(`/etc/wsl.conf`). Windows 연동 등 결정 |
| **automount** | 리눅스에서 Windows 드라이브(C:) 자동 표시 여부 |
| **interop** | 리눅스에서 Windows 프로그램 실행 가능 여부 |
| **systemd** | 리눅스 서비스(Docker 등) 백그라운드 관리자 |
| **격리 (isolation)** | Test가 Windows와 완전히 분리된 상태 |

### WSL 명령어

| 명령 | 한 줄 설명 |
|------|-----------|
| `wsl --install` | 새 Ubuntu 설치 |
| `wsl --export` | 배포판을 tar로 백업 |
| `wsl --import` | tar로 새 배포판 등록 |
| `wsl --import-in-place` | VHDX를 그대로 새 배포판으로 등록 (복사보다 빠름) |
| `wsl --unregister` | 배포판 완전 삭제 (데이터도 사라짐 ⚠️) |
| `wsl --terminate` | 배포판 하나만 잠깐 끄기 |
| `wsl --shutdown` | 모든 WSL 한꺼번에 끄기 |

## Git 관련

| 용어 | 한 줄 설명 | 비유 |
|------|-----------|------|
| **commit** | 변경한 코드를 저장 시점으로 기록 | 게임 세이브 포인트 |
| **branch** | 본체를 안 건드리고 따로 실험하는 갈래 | 평행세계 |
| **clone** | 저장소를 통째로 복제 | 통째로 복사 |
| **pull** | 변경분을 가져와 합침 | 최신화 |
| **HEAD** | 지금 작업 중인 최신 위치 | 현재 위치 표시 |
| **bundle** | 커밋 이력 전체를 파일 하나로 | 코드 택배 상자 |
| **bundle verify** | 그 상자가 정상인지 검사 | 택배 검수 |

## Docker 관련

| 용어 | 한 줄 설명 | 비유 |
|------|-----------|------|
| **Docker** | 프로그램을 격리된 상자에서 실행하는 도구 | 도시락 통 |
| **Docker Compose** | 여러 Docker 상자를 묶어 실행 | 도시락 세트 |
| **컨테이너** | 실제로 돌아가는 Docker 상자 | 돌아가는 도시락 |
| **volume** | 컨테이너 데이터 저장 공간 | 반찬칸 |
| **bind mount** | 외부 폴더를 컨테이너에 연결 | 외부 반찬 끼워넣기 |
| **오염** | 실험 흔적이 쌓여 깨끗하지 않게 된 것 | 설거지 안 한 그릇 |

## wtest 명령

| 명령 | 한 줄 설명 |
|------|-----------|
| `wtest-create` | Template 복사해 Test 생성 + 코드 전달 |
| `wtest run` | Test 안에서 명령 실행 (Work에서 원격) |
| `wtest-enter` | Test 내부로 직접 진입 |
| `wtest-pull` | Test 결과를 Work로 회수 |
| `wtest-destroy` | Test 삭제 |
| `wtest-status` | 현재 활성 Test 이름 확인 |
