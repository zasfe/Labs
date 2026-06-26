# WSL2 Ubuntu Work/Template/Disposable Test 환경 구성 매뉴얼

## 1. 목적

> 실행 위치: 설명 문서

Windows PC에 WSL2만 설치되어 있다는 전제에서 다음 구조를 구성하는 절차임.

| 구분              | 배포판명                    | 역할         | Windows 마운트 | 생명주기       |
| --------------- | ----------------------- | ---------- | ----------- | ---------- |
| Work Ubuntu     | `Ubuntu-26.04-Work`     | 개발/작성/제어   | 허용          | 지속 사용      |
| Template Ubuntu | `Ubuntu-26.04-Template` | 테스트 원본 이미지 | 차단          | 보존         |
| Test Ubuntu     | `Ubuntu-26.04-Test-*`   | 실험/검증      | 차단          | 매 테스트 후 삭제 |

핵심 설계 원칙은 다음과 같음.

* 고정 Isolated Ubuntu 사용 금지
* 테스트마다 Disposable Test Ubuntu를 새로 생성
* 테스트 종료 후 Test Ubuntu 삭제
* Template Ubuntu는 직접 작업하지 않고 원본으로만 보존
* Work Ubuntu는 Windows 연동 허용
* Template/Test Ubuntu는 Windows 마운트 차단
* Template/Test Ubuntu는 Windows 실행파일 연동 차단
* Work Ubuntu에서 `wsl.exe`로 Test Ubuntu 생성/실행/삭제 제어
* Work Ubuntu IP 의존 없음
* SSH 서버 사용 없음
* 파일 전달은 Git bundle 사용
* 실시간 파일 공유가 아닌 명시적 `commit → bundle → 전달 → pull` 방식 사용

> 📄출처: [Microsoft, Basic commands for WSL, 2025, https://learn.microsoft.com/en-us/windows/wsl/basic-commands], [Microsoft, Advanced settings configuration in WSL, 2026, https://learn.microsoft.com/en-us/windows/wsl/wsl-config], [Git SCM, git-bundle Documentation, 2025, https://git-scm.com/docs/git-bundle]

---

## 2. 최종 아키텍처

> 실행 위치: 설명 문서

```text
Windows PC
└─ WSL2
   ├─ Ubuntu-26.04-Work
   │  ├─ /home/john/workground/openclaw
   │  │  └─ 실제 개발 작업 사본
   │  ├─ /home/john/bundles
   │  │  └─ Test Ubuntu 전달용 Git bundle
   │  └─ Windows 마운트 허용
   │
   ├─ Ubuntu-26.04-Template
   │  ├─ Docker/Git/기본 패키지 설치 완료 상태
   │  ├─ Windows 마운트 차단
   │  └─ 직접 사용 금지
   │
   └─ Ubuntu-26.04-Test-YYYYMMDD-HHMMSS
      ├─ Template에서 매번 복제 생성
      ├─ /home/john/workground/openclaw
      │  └─ 테스트용 작업 사본
      ├─ /home/john/bundles
      │  └─ Work에서 전달받은 Git bundle
      └─ 테스트 종료 후 삭제
```

---

## 3. 실행 위치 빠른 구분표

> 실행 위치: 설명 문서

이 매뉴얼은 명령 실행 위치가 중요함.
명령을 실행하기 전에 반드시 아래 표를 먼저 확인해야 함.

| 실행 위치                           | 의미                                                 | 대표 명령                                    |
| ------------------------------- | -------------------------------------------------- | ---------------------------------------- |
| Windows PowerShell              | Windows에서 직접 실행                                    | `wsl --list --verbose`                   |
| Work Ubuntu                     | `Ubuntu-26.04-Work` 내부에서 실행                        | `git commit`, `wtest-create`             |
| Template Ubuntu                 | `Ubuntu-26.04-Template` 내부에서 실행                    | 기본 패키지 설치, `/etc/wsl.conf` 설정            |
| Disposable Test Ubuntu          | `Ubuntu-26.04-Test-*` 내부에서 실행                      | Docker Compose 검증, 실험 명령                 |
| Work Ubuntu → Test Ubuntu 원격 실행 | Work Ubuntu에서 `wsl.exe -d Test`로 Test Ubuntu 명령 실행 | `wtest run openclaw 'docker compose ps'` |

---

## 4. 단계별 실행 위치 요약

> 실행 위치: 설명 문서

| 단계                               | 실행 위치                                | 목적                   | 결과                         |
| -------------------------------- | ------------------------------------ | -------------------- | -------------------------- |
| 6. 전제 조건 확인                      | Windows PowerShell                   | WSL 설치 상태 확인         | WSL2 사용 가능 여부 확인           |
| 7. 원본 Ubuntu 설치                  | Windows PowerShell                   | Ubuntu 26.04 최초 설치   | 원본 Ubuntu 생성               |
| 8. 원본 Ubuntu Export              | Windows PowerShell                   | base tar 생성          | `ubuntu-2604-base.tar` 생성  |
| 9. Work Ubuntu 생성                | Windows PowerShell + Work Ubuntu     | 개발용 Ubuntu 구성        | `Ubuntu-26.04-Work` 준비     |
| 10. Work Ubuntu 기본 패키지 설치        | Work Ubuntu                          | Git/도구 설치            | 개발/제어 환경 준비                |
| 11. Template Ubuntu 생성           | Windows PowerShell + Template Ubuntu | 깨끗한 테스트 원본 구성        | `Ubuntu-26.04-Template` 준비 |
| 12. Template VHDX 위치 확인          | Windows PowerShell                   | Template 디스크 이미지 확인  | `ext4.vhdx` 확인             |
| 13. Disposable Test Ubuntu 생성 방식 | 설명 문서                                | 복제/폐기 방식 이해          | 운영 방식 확정                   |
| 14. Work 프로젝트 생성                 | Work Ubuntu                          | 실제 프로젝트 생성           | Git 작업 사본 생성               |
| 15. 자동화 스크립트 작성                  | Work Ubuntu                          | Test 생성/전달/회수/삭제 자동화 | `wtest` 스크립트 생성            |
| 16. alias 등록                     | Work Ubuntu                          | 명령 단축화               | `wtest-*` 명령 사용 가능         |
| 17. 기본 사용 시나리오                   | Work Ubuntu 중심                       | 테스트 생성/실행/회수/삭제      | 실험 루틴 수행                   |
| 18. 전체 실험 흐름 예시                  | Work Ubuntu 중심                       | 브랜치 기반 실험            | 재현 가능한 테스트                 |
| 19. OpenClaw/Hermes 권장 흐름        | 설명 문서                                | 운영형 검증 흐름            | Work/Test 역할 분리            |
| 21. 검증 체크리스트                     | PowerShell/Work/Template/Test        | 구성 검증                | 오작동 조기 확인                  |
| 22. 문제 해결                        | 증상별 실행 위치 다름                         | 오류 조치                | 원인별 복구                     |

---

## 5. 실행 위치 표기 규칙

> 실행 위치: 설명 문서

각 명령 블록 앞에는 다음 형식으로 실행 위치를 명시함.

```text
[실행 위치: Windows PowerShell]
```

```text
[실행 위치: Ubuntu-26.04-Work]
```

```text
[실행 위치: Ubuntu-26.04-Template]
```

```text
[실행 위치: Ubuntu-26.04-Test-*]
```

```text
[실행 위치: Ubuntu-26.04-Work에서 Test Ubuntu로 원격 실행]
```

가장 중요한 판단 기준은 다음과 같음.

```text
WSL 배포판을 만들거나 지우는가?
  → Windows PowerShell 또는 Work Ubuntu의 wsl.exe

코드/문서를 수정하는가?
  → Work Ubuntu

깨끗한 테스트 원본을 준비하는가?
  → Template Ubuntu

Docker/OpenClaw/Hermes를 실제 실행하는가?
  → Disposable Test Ubuntu

테스트 환경을 새로 만들고 지우는가?
  → Work Ubuntu의 wtest 명령

테스트 결과를 가져오는가?
  → Work Ubuntu의 wtest-pull
```

---

## 6. 전제 조건 확인

> 실행 위치: Windows PowerShell

### 6.1 WSL 상태 확인

```powershell
wsl --version
wsl --status
wsl --list --online
```

### 6.2 WSL 기본 버전 2 설정

```powershell
wsl --set-default-version 2
```

### 6.3 Ubuntu 26.04 설치 가능 여부 확인

```powershell
wsl --list --online
```

`Ubuntu-26.04`가 목록에 있으면 그대로 사용함.

`Ubuntu-26.04`가 목록에 없으면 다음 중 하나를 선택함.

| 상황                         | 선택                                   |
| -------------------------- | ------------------------------------ |
| Ubuntu 26.04가 WSL 목록에 있음   | `wsl --install -d Ubuntu-26.04` 사용   |
| Ubuntu 26.04가 WSL 목록에 없음   | Ubuntu 24.04로 먼저 구성 후 26.04 전환 시 재검토 |
| Ubuntu 26.04 rootfs tar 보유 | `wsl --import` 사용                    |

> 📄출처: [Microsoft, Basic commands for WSL, 2025, https://learn.microsoft.com/en-us/windows/wsl/basic-commands]

---

## 7. 원본 Ubuntu 26.04 설치

> 실행 위치: Windows PowerShell

### 7.1 Ubuntu 설치

```powershell
wsl --install -d Ubuntu-26.04
```

### 7.2 최초 Linux 사용자 생성

최초 실행 시 Linux 사용자 계정을 생성함.

예시 사용자명.

```text
john
```

### 7.3 설치 확인

```powershell
wsl --list --verbose
```

예상 출력.

```text
  NAME            STATE           VERSION
* Ubuntu-26.04    Stopped         2
```

---

## 8. 원본 Ubuntu Export

> 실행 위치: Windows PowerShell

### 8.1 원본 배포판 종료

```powershell
wsl --terminate Ubuntu-26.04
```

### 8.2 작업 디렉터리 생성

```powershell
mkdir D:\wsl
mkdir D:\wsl\base
```

### 8.3 base tar 생성

```powershell
wsl --export Ubuntu-26.04 D:\wsl\base\ubuntu-2604-base.tar
```

### 8.4 선택 사항: 원본 배포판 제거

```powershell
wsl --unregister Ubuntu-26.04
```

주의.

```text
wsl --unregister는 해당 배포판과 데이터를 삭제하는 명령임.
base tar 파일 생성 확인 후 실행할 것.
```

> 📄출처: [Microsoft, Basic commands for WSL, 2025, https://learn.microsoft.com/en-us/windows/wsl/basic-commands]

---

## 9. Work Ubuntu 생성

> 실행 위치: Windows PowerShell + Ubuntu-26.04-Work

### 9.1 Work Ubuntu import

> 실행 위치: Windows PowerShell

```powershell
mkdir D:\wsl\Ubuntu-26.04-Work

wsl --import Ubuntu-26.04-Work D:\wsl\Ubuntu-26.04-Work D:\wsl\base\ubuntu-2604-base.tar --version 2
```

### 9.2 Work Ubuntu 접속

> 실행 위치: Windows PowerShell

```powershell
wsl -d Ubuntu-26.04-Work
```

### 9.3 사용자 확인 및 생성

> 실행 위치: Ubuntu-26.04-Work

```bash
id john || adduser john
usermod -aG sudo john
```

### 9.4 Work Ubuntu용 `/etc/wsl.conf` 작성

> 실행 위치: Ubuntu-26.04-Work

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
```

### 9.5 Work Ubuntu 재시작

> 실행 위치: Ubuntu-26.04-Work

```bash
exit
```

> 실행 위치: Windows PowerShell

```powershell
wsl --terminate Ubuntu-26.04-Work
wsl -d Ubuntu-26.04-Work
```

`/etc/wsl.conf`는 배포판별 WSL 설정 파일이며, `automount`, `interop`, `user`, `boot` 등의 배포판 단위 설정에 사용됨.

> 📄출처: [Microsoft, Advanced settings configuration in WSL, 2026, https://learn.microsoft.com/en-us/windows/wsl/wsl-config]

---

## 10. Work Ubuntu 기본 패키지 설치

> 실행 위치: Ubuntu-26.04-Work

### 10.1 기본 패키지 설치

```bash
sudo apt update
sudo apt install -y git ca-certificates curl tar gzip rsync
```

### 10.2 Git 설정

```bash
git config --global user.name "john"
git config --global user.email "john@local"
git config --global init.defaultBranch main
```

### 10.3 작업 디렉터리 생성

```bash
mkdir -p ~/workground
mkdir -p ~/bundles
mkdir -p ~/scripts
```

### 10.4 Work Ubuntu 검증

```bash
whoami
ls /mnt/c
powershell.exe -Command '$PSVersionTable.PSVersion'
wsl.exe --list --verbose
```

기대 결과.

```text
사용자 = john
/mnt/c 접근 가능
powershell.exe 실행 가능
wsl.exe 실행 가능
```

---

## 11. Template Ubuntu 생성

> 실행 위치: Windows PowerShell + Ubuntu-26.04-Template

### 11.1 Template Ubuntu import

> 실행 위치: Windows PowerShell

```powershell
mkdir D:\wsl\Ubuntu-26.04-Template

wsl --import Ubuntu-26.04-Template D:\wsl\Ubuntu-26.04-Template D:\wsl\base\ubuntu-2604-base.tar --version 2
```

### 11.2 Template Ubuntu 접속

> 실행 위치: Windows PowerShell

```powershell
wsl -d Ubuntu-26.04-Template
```

### 11.3 사용자 확인 및 생성

> 실행 위치: Ubuntu-26.04-Template

```bash
id john || adduser john
usermod -aG sudo john
```

### 11.4 Template Ubuntu용 `/etc/wsl.conf` 작성

> 실행 위치: Ubuntu-26.04-Template

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

### 11.5 기본 패키지 설치

> 실행 위치: Ubuntu-26.04-Template

```bash
sudo apt update
sudo apt install -y git ca-certificates curl tar gzip
git config --global user.name "john"
git config --global user.email "john@test.local"
git config --global init.defaultBranch main
mkdir -p ~/workground
mkdir -p ~/bundles
```

### 11.6 Docker를 Template에 포함할 경우

> 실행 위치: Ubuntu-26.04-Template

```bash
sudo apt install -y docker.io docker-compose-v2
sudo usermod -aG docker john
```

### 11.7 Template Ubuntu 종료

> 실행 위치: Ubuntu-26.04-Template

```bash
exit
```

> 실행 위치: Windows PowerShell

```powershell
wsl --terminate Ubuntu-26.04-Template
```

### 11.8 Template 격리 설정 검증

> 실행 위치: Windows PowerShell

```powershell
wsl -d Ubuntu-26.04-Template
```

> 실행 위치: Ubuntu-26.04-Template

```bash
whoami
ls /mnt/c || true
powershell.exe -Command '$PSVersionTable' || true
mount | grep -E 'drvfs|9p' || true
exit
```

기대 결과.

```text
whoami = john
/mnt/c 접근 불가
powershell.exe 실행 불가
Windows 마운트 없음
```

> 실행 위치: Windows PowerShell

```powershell
wsl --terminate Ubuntu-26.04-Template
```

주의.

```text
Template Ubuntu는 이후 직접 작업하지 않음.
Template은 Disposable Test Ubuntu 생성을 위한 원본 이미지로만 사용함.
```

---

## 12. Template VHDX 위치 확인

> 실행 위치: Windows PowerShell

### 12.1 VHDX 위치

기본 경로.

```text
D:\wsl\Ubuntu-26.04-Template\ext4.vhdx
```

### 12.2 파일 확인

```powershell
dir D:\wsl\Ubuntu-26.04-Template
```

예상 출력.

```text
ext4.vhdx
```

주의.

```text
Template Ubuntu가 실행 중인 상태에서 ext4.vhdx를 복사하지 말 것.
항상 wsl --terminate Ubuntu-26.04-Template 또는 wsl --shutdown 후 복사할 것.
```

WSL은 배포판 export/import, unregister, import-in-place 방식의 배포판 관리 명령을 제공함.

> 📄출처: [Microsoft, Basic commands for WSL, 2025, https://learn.microsoft.com/en-us/windows/wsl/basic-commands]

---

## 13. Disposable Test Ubuntu 생성 방식

> 실행 위치: 설명 문서

### 13.1 권장 방식

```text
Template ext4.vhdx 복사
→ wsl --import-in-place로 새 Test Ubuntu 등록
→ 테스트 실행
→ 결과 회수
→ wsl --unregister
→ Test 폴더 삭제
```

### 13.2 장점

| 항목  | 장점                     |
| --- | ---------------------- |
| 속도  | tar import보다 빠름        |
| 재현성 | 항상 같은 Template 상태에서 시작 |
| 격리성 | 테스트마다 새 WSL 배포판 사용     |
| 복구성 | 테스트 실패 시 삭제하면 끝        |
| 운영성 | IP/SSH/Windows 마운트 불필요 |

---

## 14. Work 프로젝트 생성 예시

> 실행 위치: Ubuntu-26.04-Work

### 14.1 프로젝트 생성

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

### 14.2 확인

```bash
git status
git log --oneline --decorate -5
```

---

## 15. Work Ubuntu 자동화 스크립트 작성

> 실행 위치: Ubuntu-26.04-Work

### 15.1 스크립트 생성

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

---

## 16. Work Ubuntu alias 등록

> 실행 위치: Ubuntu-26.04-Work

### 16.1 alias 등록

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

## 17. 기본 사용 시나리오

> 실행 위치: Ubuntu-26.04-Work 중심

### 17.1 Work에서 개발

> 실행 위치: Ubuntu-26.04-Work

```bash
cd ~/workground/openclaw

vi README.md
git status
```

### 17.2 새 Test Ubuntu 생성 및 프로젝트 전달

> 실행 위치: Ubuntu-26.04-Work

```bash
wtest-create
```

내부 동작.

```text
1. Template Ubuntu 종료
2. Template ext4.vhdx 복사
3. 새 Ubuntu-26.04-Test-YYYYMMDD-HHMMSS 등록
4. Work 프로젝트 Git bundle 생성
5. Test Ubuntu로 bundle 전달
6. Test Ubuntu에서 clone
```

### 17.3 Test Ubuntu에서 명령 실행

> 실행 위치: Ubuntu-26.04-Work에서 Test Ubuntu로 원격 실행

```bash
wtest run openclaw 'pwd && git status'
```

Docker Compose 검증.

```bash
wtest run openclaw 'docker compose config --quiet'
wtest run openclaw 'docker compose up -d'
wtest run openclaw 'docker compose ps'
```

### 17.4 Test Ubuntu 직접 진입

> 실행 위치: Ubuntu-26.04-Work

```bash
wtest-enter openclaw
```

결과.

```text
현재 터미널이 Ubuntu-26.04-Test-* 내부 프로젝트 디렉터리로 진입함.
여기서 실행하는 명령은 Disposable Test Ubuntu 내부에서 실행됨.
```

### 17.5 Test 결과를 Work로 회수

> 실행 위치: Ubuntu-26.04-Work

```bash
cd ~/workground/openclaw
wtest-pull
```

### 17.6 Test Ubuntu 삭제

> 실행 위치: Ubuntu-26.04-Work

```bash
wtest-destroy
```

삭제 후 확인.

```bash
wtest-status
wsl.exe --list --verbose
```

---

## 18. 전체 실험 흐름 예시

> 실행 위치: Ubuntu-26.04-Work 중심

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

---

## 19. OpenClaw/Hermes 기준 권장 흐름

> 실행 위치: 설명 문서

```text
1. Work Ubuntu
   - Claude Code / Codex / 문서 작성
   - 코드 수정
   - Git commit
   - wtest-create

2. Disposable Test Ubuntu
   - 매번 Template에서 깨끗하게 생성
   - Windows 마운트 없음
   - Windows 실행파일 연동 없음
   - docker compose config --quiet
   - docker compose up -d
   - docker compose ps
   - OpenClaw/Hermes 동작 검증

3. Work Ubuntu
   - wtest-pull
   - 변경사항 확인
   - wtest-destroy
   - 필요 시 main 병합
```

OpenClaw/Hermes 같은 Compose 운영 저장소에서는 Docker volume, network, bind mount, permission, database, Redis, Mattermost runtime state 오염 가능성이 크므로 Disposable Test Ubuntu 방식이 적합함.

---

## 20. 병렬 테스트 구조

> 실행 위치: 설명 문서

필요 시 Test Ubuntu를 여러 개 만들 수 있음.

```text
Ubuntu-26.04-Work
   │
   ├─ Ubuntu-26.04-Test-20260626-101000
   ├─ Ubuntu-26.04-Test-20260626-102000
   └─ Ubuntu-26.04-Test-20260626-103000
```

주의.

```text
현재 제공 스크립트는 active test 1개 기준임.
병렬 테스트를 운영하려면 state_file을 프로젝트별 또는 테스트명별로 분리해야 함.
초기 운영은 단일 active test 방식 권장.
```

---

## 21. 검증 체크리스트

### 21.1 배포판 확인

> 실행 위치: Windows PowerShell

```powershell
wsl --list --verbose
```

기대.

```text
Ubuntu-26.04-Work        VERSION 2
Ubuntu-26.04-Template    VERSION 2
```

테스트 실행 중 기대.

```text
Ubuntu-26.04-Test-YYYYMMDD-HHMMSS    VERSION 2
```

---

### 21.2 Work Ubuntu 검증

> 실행 위치: Ubuntu-26.04-Work

```bash
whoami
ls /mnt/c
powershell.exe -Command '$PSVersionTable.PSVersion'
wsl.exe --list --verbose
```

기대.

```text
john
/mnt/c 접근 가능
powershell.exe 실행 가능
wsl.exe 실행 가능
```

---

### 21.3 Template Ubuntu 검증

> 실행 위치: Windows PowerShell

```powershell
wsl -d Ubuntu-26.04-Template
```

> 실행 위치: Ubuntu-26.04-Template

```bash
whoami
ls /mnt/c || true
powershell.exe -Command '$PSVersionTable' || true
mount | grep -E 'drvfs|9p' || true
exit
```

기대.

```text
john
/mnt/c 접근 불가
powershell.exe 실행 불가
Windows 마운트 없음
```

---

### 21.4 Test Ubuntu 생성 검증

> 실행 위치: Ubuntu-26.04-Work

```bash
cd ~/workground/openclaw
wtest-create
wtest-status
```

기대.

```text
ACTIVE_TEST_NAME=Ubuntu-26.04-Test-YYYYMMDD-HHMMSS
```

---

### 21.5 Test Ubuntu 격리 검증

> 실행 위치: Ubuntu-26.04-Work에서 Test Ubuntu로 원격 실행

```bash
wtest run openclaw 'ls /mnt/c || true'
wtest run openclaw 'powershell.exe -Command "$PSVersionTable" || true'
wtest run openclaw 'mount | grep -E "drvfs|9p" || true'
```

기대.

```text
/mnt/c 접근 불가
powershell.exe 실행 불가
Windows 마운트 없음
```

---

### 21.6 Git bundle 전달 검증

> 실행 위치: Ubuntu-26.04-Work에서 Test Ubuntu로 원격 실행

```bash
cd ~/workground/openclaw
wtest run openclaw 'git log --oneline --decorate -5'
```

기대.

```text
Work Ubuntu의 최신 commit 확인 가능
```

---

### 21.7 Test 삭제 검증

> 실행 위치: Ubuntu-26.04-Work

```bash
wtest-destroy
wsl.exe --list --verbose
```

기대.

```text
Ubuntu-26.04-Test-* 없음
```

---

## 22. 문제 해결

### 22.1 `wsl.exe: command not found`

> 실행 위치: Ubuntu-26.04-Work + Windows PowerShell

원인.

```text
Work Ubuntu에서 Windows interop이 비활성화된 상태
```

Work Ubuntu의 `/etc/wsl.conf` 확인.

> 실행 위치: Ubuntu-26.04-Work

```bash
cat /etc/wsl.conf
```

필수 설정.

```ini
[interop]
enabled=true
appendWindowsPath=true
```

재시작.

> 실행 위치: Windows PowerShell

```powershell
wsl --terminate Ubuntu-26.04-Work
wsl -d Ubuntu-26.04-Work
```

---

### 22.2 Template/Test에서 `/mnt/c`가 보임

> 실행 위치: Ubuntu-26.04-Template + Ubuntu-26.04-Work

원인.

```text
automount.enabled=false 미적용 또는 배포판 재시작 누락
```

Template Ubuntu `/etc/wsl.conf` 확인.

> 실행 위치: Ubuntu-26.04-Template

```bash
cat /etc/wsl.conf
```

필수 설정.

```ini
[automount]
enabled=false
mountFsTab=false
```

Template 재시작.

> 실행 위치: Windows PowerShell

```powershell
wsl --terminate Ubuntu-26.04-Template
```

이미 생성된 Test Ubuntu는 Template 수정 전 복제본일 수 있으므로 삭제 후 재생성.

> 실행 위치: Ubuntu-26.04-Work

```bash
wtest-destroy
wtest-create
```

---

### 22.3 Template/Test에서 `powershell.exe`가 실행됨

> 실행 위치: Ubuntu-26.04-Template + Ubuntu-26.04-Work

원인.

```text
interop.enabled=false 미적용
```

Template Ubuntu 필수 설정.

```ini
[interop]
enabled=false
appendWindowsPath=false
```

Template 재시작 후 Test 재생성.

> 실행 위치: Windows PowerShell

```powershell
wsl --terminate Ubuntu-26.04-Template
```

> 실행 위치: Ubuntu-26.04-Work

```bash
wtest-destroy
wtest-create
```

---

### 22.4 `wsl --import-in-place` 실패

> 실행 위치: Windows PowerShell + Ubuntu-26.04-Work

가능 원인.

```text
ext4.vhdx 경로 오류
Template 실행 중 복사
기존 Test 이름 중복
VHDX 파일 잠금
```

처리.

> 실행 위치: Windows PowerShell

```powershell
wsl --shutdown
wsl --list --verbose
dir D:\wsl\Ubuntu-26.04-Template\ext4.vhdx
```

기존 Test 제거.

```powershell
wsl --unregister Ubuntu-26.04-Test-YYYYMMDD-HHMMSS
Remove-Item -Recurse -Force D:\wsl\Ubuntu-26.04-Test-YYYYMMDD-HHMMSS
```

> 📄출처: [Microsoft, Basic commands for WSL, 2025, https://learn.microsoft.com/en-us/windows/wsl/basic-commands], [Microsoft, Troubleshooting Windows Subsystem for Linux, 2026, https://learn.microsoft.com/en-us/windows/wsl/troubleshooting]

---

### 22.5 `git pull bundle` 충돌

> 실행 위치: Ubuntu-26.04-Work 또는 Ubuntu-26.04-Test-*

원인.

```text
Work와 Test에서 같은 파일을 서로 다르게 수정한 상태
```

처리.

```bash
git status
git diff
```

충돌 수정 후.

```bash
git add .
git commit -m "resolve disposable test sync conflict"
```

---

### 22.6 `git bundle verify` 실패

> 실행 위치: Ubuntu-26.04-Work 또는 Ubuntu-26.04-Test-*

원인.

```text
bundle 적용 대상 저장소에 필요한 선행 commit이 없음
```

처리.

```bash
git bundle create ~/bundles/openclaw.bundle --all
```

또는 Test를 삭제하고 새로 생성.

```bash
wtest-destroy
wtest-create
```

Git bundle은 활성 서버 없이 Git 객체를 오프라인으로 전달하기 위한 파일이며, `verify`는 bundle 적용 가능성을 확인하는 용도임.

> 📄출처: [Git SCM, git-bundle Documentation, 2025, https://git-scm.com/docs/git-bundle], [Kernel.org, git-bundle Manual Page, 2025, https://www.kernel.org/pub/software/scm/git/docs/git-bundle.html]

---

## 23. 운영 원칙

> 실행 위치: 설명 문서

| 원칙                 | 설명                                       |
| ------------------ | ---------------------------------------- |
| Template 직접 작업 금지  | Template은 깨끗한 원본 이미지 역할                  |
| Test 재사용 금지        | 테스트마다 새 Test Ubuntu 생성                   |
| Test 종료 후 삭제       | 오염 상태를 보존하지 않음                           |
| Work만 지속 사용        | 개발/문서/AI 도구는 Work에서 실행                   |
| Windows 공유폴더 금지    | Test로 `/mnt/c` 공유하지 않음                   |
| IP 의존 금지           | SSH/Bare Repo/IP 기반 접근 사용 안 함            |
| Git bundle 기준 동기화  | 파일 복사가 아닌 commit 단위 전달                   |
| 실험은 브랜치 사용         | `experiment/*` 브랜치 권장                    |
| Docker 실행은 Test 우선 | OpenClaw/Hermes 검증은 Disposable Test에서 수행 |
| 결과 회수 후 삭제         | `wtest-pull` 이후 `wtest-destroy` 수행       |

---

## 24. 헷갈리기 쉬운 명령 기준

> 실행 위치: 설명 문서

| 명령                      | 실행 위치                                        | 이유                                |
| ----------------------- | -------------------------------------------- | --------------------------------- |
| `wsl --install`         | Windows PowerShell                           | WSL 배포판 설치 명령                     |
| `wsl --export`          | Windows PowerShell                           | 배포판 백업/export 명령                  |
| `wsl --import`          | Windows PowerShell                           | 새 배포판 등록 명령                       |
| `wsl --import-in-place` | Windows PowerShell 또는 Work Ubuntu의 `wsl.exe` | VHDX 기반 Test Ubuntu 등록            |
| `wsl --unregister`      | Windows PowerShell 또는 Work Ubuntu의 `wsl.exe` | Test Ubuntu 삭제                    |
| `git add/commit`        | Work Ubuntu 또는 Test Ubuntu                   | 현재 작업 사본 기준 저장                    |
| `git bundle create`     | Work Ubuntu 또는 Test Ubuntu                   | 현재 Git 이력 파일화                     |
| `docker compose up -d`  | Test Ubuntu                                  | 오염 가능성이 있으므로 Disposable Test에서 실행 |
| `wtest-create`          | Work Ubuntu                                  | Template 복제 후 Test 생성             |
| `wtest run ...`         | Work Ubuntu                                  | Work에서 Test 명령 실행                 |
| `wtest-pull`            | Work Ubuntu                                  | Test 결과를 Work로 회수                 |
| `wtest-destroy`         | Work Ubuntu                                  | Test Ubuntu 삭제                    |

---

## 25. 파일명 권장

> 실행 위치: 설명 문서

권장 파일명.

```text
wsl2-ubuntu-work-template-disposable-test-execution-guide.md
```

대안.

```text
wsl2-ubuntu-work-template-disposable-test-git-bundle-manual.md
wsl2-disposable-ubuntu-test-environment-manual.md
wsl2-ubuntu-template-test-git-bundle-workflow.md
wsl2-openclaw-disposable-test-ubuntu-manual.md
```

---

## 26. 최종 요약

> 실행 위치: 설명 문서

```text
기존 방식:
  Work Ubuntu
  고정 Isolated Ubuntu

수정 방식:
  Work Ubuntu
  Template Ubuntu
  Disposable Test Ubuntu

핵심:
  Template은 원본
  Test는 매번 생성
  Test는 매번 삭제
  Work는 지속 사용
  파일 전달은 Git bundle
  제어는 wsl.exe
  SSH/IP/Windows 마운트 의존 없음
  각 단계마다 실행 위치를 명시

효과:
  테스트 오염 누적 방지
  OpenClaw/Hermes Docker 실험 재현성 향상
  실패 복구 단순화
  실행 위치 혼동 감소
  실험 환경 초기화 자동화
```

---

## 27. 참고 출처

> 📄출처: [Microsoft, Basic commands for WSL, 2025, https://learn.microsoft.com/en-us/windows/wsl/basic-commands], [Microsoft, Advanced settings configuration in WSL, 2026, https://learn.microsoft.com/en-us/windows/wsl/wsl-config], [Microsoft, Troubleshooting Windows Subsystem for Linux, 2026, https://learn.microsoft.com/en-us/windows/wsl/troubleshooting], [Git SCM, git-bundle Documentation, 2025, https://git-scm.com/docs/git-bundle], [Kernel.org, git-bundle Manual Page, 2025, https://www.kernel.org/pub/software/scm/git/docs/git-bundle.html]
