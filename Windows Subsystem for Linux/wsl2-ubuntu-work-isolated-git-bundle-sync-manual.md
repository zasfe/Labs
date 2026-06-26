````markdown
# WSL2 Ubuntu Work/Isolated 이중 환경 구성 매뉴얼

## 1. 목적

Windows PC에 WSL2만 설치되어 있다는 전제에서 Ubuntu 26.04 기반 배포판 2개를 구성하는 절차임.

구성 목표는 다음과 같음.

| 구분 | 배포판명 | 역할 | Windows 마운트 | 사용 목적 |
|---|---|---|---|---|
| Work Ubuntu | `Ubuntu-26.04-Work` | 개발/작성/동기화 제어 | 허용 | Claude Code, Codex, 문서 작업, Git 관리 |
| Isolated Ubuntu | `Ubuntu-26.04-Isolated` | 실험/검증 | 차단 | Docker, OpenClaw, Hermes, 위험 실험 |

핵심 설계 원칙은 다음과 같음.

- Work Ubuntu와 Isolated Ubuntu는 같은 파일시스템을 공유하지 않음
- Isolated Ubuntu는 Windows 드라이브 자동 마운트를 차단함
- Isolated Ubuntu는 Windows 실행파일 연동을 차단함
- Work Ubuntu에서 `wsl.exe -d Ubuntu-26.04-Isolated`로 Isolated Ubuntu 명령을 호출함
- Work Ubuntu IP에 의존하지 않음
- SSH 서버를 사용하지 않음
- 파일 전달은 Git bundle을 사용함
- 실시간 동기화가 아니라 명시적 `commit → bundle → transfer → pull` 방식으로 동기화함

>📄출처: [Microsoft, Basic commands for WSL, 2025, https://learn.microsoft.com/en-us/windows/wsl/basic-commands], [Microsoft, Advanced settings configuration in WSL, 2026, https://learn.microsoft.com/ko-kr/windows/wsl/wsl-config], [Git SCM, git-bundle Documentation, 2025, https://git-scm.com/docs/git-bundle]

---

## 2. 최종 아키텍처

```text
Windows PC
└─ WSL2
   ├─ Ubuntu-26.04-Work
   │  ├─ /home/john/workground/openclaw
   │  │  └─ 실제 개발 작업 사본
   │  ├─ /home/john/bundles
   │  │  └─ Isolated 전달용 Git bundle
   │  └─ Windows 마운트 허용
   │
   └─ Ubuntu-26.04-Isolated
      ├─ /home/john/workground/openclaw
      │  └─ 실험/검증 작업 사본
      ├─ /home/john/bundles
      │  └─ Work에서 전달받은 Git bundle
      └─ Windows 마운트 차단
````

---

## 3. 통신/데이터 흐름

### 3.1 Work → Isolated

```text
Ubuntu-26.04-Work
  git add
  git commit
  git bundle create
       │
       │ wsl.exe pipe
       ▼
Ubuntu-26.04-Isolated
  bundle 파일 저장
  git pull bundle
  docker compose test
```

### 3.2 Isolated → Work

```text
Ubuntu-26.04-Isolated
  git add
  git commit
  git bundle create
       │
       │ wsl.exe stdout pipe
       ▼
Ubuntu-26.04-Work
  bundle 파일 저장
  git pull bundle
```

Git bundle은 네트워크 서버 없이 Git 객체와 참조를 하나의 파일로 묶어 오프라인 전달하는 방식임.

> 📄출처: [Git SCM, git-bundle Documentation, 2025, [https://git-scm.com/docs/git-bundle](https://git-scm.com/docs/git-bundle)], [Kernel.org, git-bundle Manual Page, 2025, [https://www.kernel.org/pub/software/scm/git/docs/git-bundle.html](https://www.kernel.org/pub/software/scm/git/docs/git-bundle.html)]

---

## 4. 전제 조건

### 4.1 Windows PowerShell에서 확인

```powershell
wsl --version
wsl --status
wsl --list --online
```

### 4.2 WSL 기본 버전 2 설정

```powershell
wsl --set-default-version 2
```

### 4.3 설치 가능한 Ubuntu 배포판명 확인

```powershell
wsl --list --online
```

출력 목록에서 `Ubuntu-26.04`가 있으면 그대로 사용함.

예상 예시:

```text
Ubuntu
Ubuntu-24.04
Ubuntu-26.04
Debian
```

`Ubuntu-26.04`가 목록에 없으면 다음 중 하나를 선택함.

| 상황                                       | 선택                                   |
| ---------------------------------------- | ------------------------------------ |
| Ubuntu 26.04가 Microsoft Store/WSL 목록에 있음 | `wsl --install -d Ubuntu-26.04` 사용   |
| Ubuntu 26.04가 목록에 없음                     | Ubuntu 24.04로 먼저 구성 후 26.04 전환 시 재검토 |
| 별도 rootfs tar 보유                         | `wsl --import` 사용                    |

WSL은 `wsl --list --online`으로 설치 가능한 배포판을 확인하고, `wsl --install -d <Distro>`로 특정 배포판을 설치할 수 있음.

> 📄출처: [Microsoft, How to install Linux on Windows with WSL, 2025, [https://learn.microsoft.com/en-us/windows/wsl/install](https://learn.microsoft.com/en-us/windows/wsl/install)], [Microsoft, Basic commands for WSL, 2025, [https://learn.microsoft.com/en-us/windows/wsl/basic-commands](https://learn.microsoft.com/en-us/windows/wsl/basic-commands)]

---

## 5. Ubuntu 26.04 원본 배포판 설치

PowerShell 관리자 또는 일반 PowerShell에서 실행함.

```powershell
wsl --install -d Ubuntu-26.04
```

설치 후 최초 실행하여 Linux 사용자 계정을 생성함.

예시 계정:

```text
john
```

설치 확인:

```powershell
wsl --list --verbose
```

예상:

```text
  NAME            STATE           VERSION
* Ubuntu-26.04    Stopped         2
```

---

## 6. 원본 Ubuntu 26.04 종료 및 Export

```powershell
wsl --terminate Ubuntu-26.04
mkdir D:\wsl
wsl --export Ubuntu-26.04 D:\wsl\ubuntu-2604-base.tar
```

WSL은 `wsl --export`로 배포판을 tar 파일로 내보내고, `wsl --import`로 새 배포판을 만들 수 있음.

> 📄출처: [Microsoft, Basic commands for WSL, 2025, [https://learn.microsoft.com/en-us/windows/wsl/basic-commands](https://learn.microsoft.com/en-us/windows/wsl/basic-commands)]

---

## 7. Work/Isolated 배포판 Import

```powershell
mkdir D:\wsl\Ubuntu-26.04-Work
mkdir D:\wsl\Ubuntu-26.04-Isolated

wsl --import Ubuntu-26.04-Work D:\wsl\Ubuntu-26.04-Work D:\wsl\ubuntu-2604-base.tar --version 2
wsl --import Ubuntu-26.04-Isolated D:\wsl\Ubuntu-26.04-Isolated D:\wsl\ubuntu-2604-base.tar --version 2
```

확인:

```powershell
wsl --list --verbose
```

예상:

```text
  NAME                     STATE           VERSION
  Ubuntu-26.04             Stopped         2
  Ubuntu-26.04-Work        Stopped         2
  Ubuntu-26.04-Isolated    Stopped         2
```

선택 사항으로 원본 배포판 제거:

```powershell
wsl --unregister Ubuntu-26.04
```

주의:

```text
wsl --unregister는 해당 배포판 데이터를 삭제함.
base tar 파일을 보관한 뒤 실행할 것.
```

---

## 8. 기본 사용자 설정

`wsl --import`로 만든 배포판은 기본 사용자가 root로 잡힐 수 있음.

각 배포판에서 `/etc/wsl.conf`에 기본 사용자를 지정함.

### 8.1 Work Ubuntu 접속

```powershell
wsl -d Ubuntu-26.04-Work
```

Work Ubuntu 내부:

```bash
id john || adduser john
usermod -aG sudo john
```

`/etc/wsl.conf` 작성:

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

종료:

```bash
exit
```

PowerShell:

```powershell
wsl --terminate Ubuntu-26.04-Work
```

### 8.2 Isolated Ubuntu 접속

```powershell
wsl -d Ubuntu-26.04-Isolated
```

Isolated Ubuntu 내부:

```bash
id john || adduser john
usermod -aG sudo john
```

`/etc/wsl.conf` 작성:

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

종료:

```bash
exit
```

PowerShell:

```powershell
wsl --terminate Ubuntu-26.04-Isolated
```

`/etc/wsl.conf`는 배포판별 WSL 설정 파일이며, `automount`, `interop`, `user`, `boot` 같은 섹션을 지원함. `automount.enabled=false`는 Windows 드라이브 자동 마운트를 비활성화하는 설정임.

> 📄출처: [Microsoft, Advanced settings configuration in WSL, 2026, [https://learn.microsoft.com/ko-kr/windows/wsl/wsl-config](https://learn.microsoft.com/ko-kr/windows/wsl/wsl-config)]

---

## 9. Isolated 격리 상태 검증

PowerShell:

```powershell
wsl -d Ubuntu-26.04-Isolated
```

Isolated Ubuntu 내부:

```bash
whoami
ls -al /mnt
mount | grep -E 'drvfs|9p' || true
echo "$PATH" | tr ':' '\n' | grep -Ei 'windows|system32|program files' || true
powershell.exe -Command '$PSVersionTable' || true
```

기대 결과:

```text
whoami = john
/mnt/c 없음
drvfs/Windows 마운트 없음
Windows 경로 없음
powershell.exe 실행 불가
```

주의:

```text
interop.enabled=false 상태에서는 Isolated Ubuntu 내부에서 wsl.exe, powershell.exe, cmd.exe 같은 Windows 실행파일 호출이 차단됨.
따라서 Isolated 제어 명령은 Work Ubuntu 또는 Windows PowerShell에서 실행해야 함.
```

---

## 10. Work Ubuntu 기본 패키지 설치

PowerShell:

```powershell
wsl -d Ubuntu-26.04-Work
```

Work Ubuntu 내부:

```bash
sudo apt update
sudo apt install -y git ca-certificates curl tar gzip
```

Git 사용자 설정:

```bash
git config --global user.name "john"
git config --global user.email "john@local"
git config --global init.defaultBranch main
```

작업 디렉터리 생성:

```bash
mkdir -p ~/workground
mkdir -p ~/bundles
```

---

## 11. Isolated Ubuntu 기본 패키지 설치

PowerShell 또는 Work Ubuntu에서 실행 가능함.

PowerShell:

```powershell
wsl -d Ubuntu-26.04-Isolated
```

Isolated Ubuntu 내부:

```bash
sudo apt update
sudo apt install -y git ca-certificates curl tar gzip
git config --global user.name "john"
git config --global user.email "john@isolated.local"
git config --global init.defaultBranch main
mkdir -p ~/workground
mkdir -p ~/bundles
exit
```

---

## 12. Work Ubuntu에서 Isolated Ubuntu 호출 확인

Work Ubuntu 내부:

```bash
wsl.exe -d Ubuntu-26.04-Isolated -- bash -lc 'whoami && hostname && pwd'
```

기대 결과:

```text
john
<isolated hostname>
/home/john
```

WSL 문서는 Linux 배포판 내부에서 WSL 명령을 호출할 때 `wsl` 대신 `wsl.exe`를 사용한다고 설명함.

> 📄출처: [Microsoft, Basic commands for WSL, 2025, [https://learn.microsoft.com/en-us/windows/wsl/basic-commands](https://learn.microsoft.com/en-us/windows/wsl/basic-commands)]

---

## 13. 샘플 프로젝트 생성

Work Ubuntu 내부:

```bash
mkdir -p ~/workground/openclaw
cd ~/workground/openclaw

git init
cat >README.md <<'EOF'
# OpenClaw Lab

WSL2 Work/Isolated 동기화 테스트 프로젝트.
EOF

git add .
git commit -m "initial commit"
```

확인:

```bash
git status
git log --oneline --decorate -5
```

---

## 14. Work → Isolated 최초 전달

### 14.1 Work에서 bundle 생성

Work Ubuntu 내부:

```bash
cd ~/workground/openclaw
mkdir -p ~/bundles

git bundle create ~/bundles/openclaw.bundle main
git bundle verify ~/bundles/openclaw.bundle
```

### 14.2 Isolated로 bundle 복사

Work Ubuntu 내부:

```bash
wsl.exe -d Ubuntu-26.04-Isolated -- mkdir -p /home/john/bundles

cat ~/bundles/openclaw.bundle \
  | wsl.exe -d Ubuntu-26.04-Isolated -- tee /home/john/bundles/openclaw.bundle >/dev/null
```

### 14.3 Isolated에서 clone

Work Ubuntu 내부에서 Isolated 명령 실행:

```bash
wsl.exe -d Ubuntu-26.04-Isolated -- bash -lc '
set -e
mkdir -p /home/john/workground
cd /home/john/workground
rm -rf openclaw
git clone /home/john/bundles/openclaw.bundle openclaw
cd openclaw
git status
'
```

확인:

```bash
wsl.exe -d Ubuntu-26.04-Isolated -- bash -lc '
cd /home/john/workground/openclaw
ls -al
git log --oneline --decorate -5
'
```

---

## 15. Work → Isolated 반복 동기화 함수

Work Ubuntu의 `~/.bashrc`에 함수 추가:

```bash
cat >>~/.bashrc <<'EOF'

# Send current Git project from Work Ubuntu to Isolated Ubuntu using git bundle.
iso-push() {
  set -e

  local project_dir="${1:-$PWD}"
  local project_name
  project_name="$(basename "$project_dir")"

  local work_bundle="$HOME/bundles/${project_name}.bundle"
  local isolated_bundle="/home/john/bundles/${project_name}.bundle"
  local isolated_project="/home/john/workground/${project_name}"

  cd "$project_dir"

  if [ ! -d .git ]; then
    echo "ERROR: not a git repository: $project_dir" >&2
    return 1
  fi

  mkdir -p "$HOME/bundles"

  if ! git diff --quiet || ! git diff --cached --quiet; then
    git add .
    git commit -m "sync to isolated"
  fi

  git bundle create "$work_bundle" HEAD
  git bundle verify "$work_bundle"

  wsl.exe -d Ubuntu-26.04-Isolated -- mkdir -p /home/john/bundles /home/john/workground

  cat "$work_bundle" \
    | wsl.exe -d Ubuntu-26.04-Isolated -- tee "$isolated_bundle" >/dev/null

  wsl.exe -d Ubuntu-26.04-Isolated -- bash -lc "
    set -e

    if [ ! -d '$isolated_project/.git' ]; then
      cd /home/john/workground
      git clone '$isolated_bundle' '$project_name'
    else
      cd '$isolated_project'
      git pull '$isolated_bundle' HEAD
    fi

    cd '$isolated_project'
    git status
  "
}

# Enter same project path in Isolated Ubuntu.
iso-enter() {
  local project_name
  project_name="$(basename "${1:-$PWD}")"

  wsl.exe -d Ubuntu-26.04-Isolated --cd "/home/john/workground/$project_name"
}

# Run command in Isolated Ubuntu project directory.
iso-run() {
  local project_name
  project_name="$(basename "$PWD")"

  if [ "$#" -eq 0 ]; then
    wsl.exe -d Ubuntu-26.04-Isolated --cd "/home/john/workground/$project_name"
  else
    wsl.exe -d Ubuntu-26.04-Isolated -- bash -lc "cd /home/john/workground/$project_name && $*"
  fi
}
EOF
```

적용:

```bash
source ~/.bashrc
```

사용:

```bash
cd ~/workground/openclaw
iso-push
iso-run 'pwd && git status'
iso-enter
```

---

## 16. Isolated → Work 결과 회수 함수

Work Ubuntu의 `~/.bashrc`에 함수 추가:

```bash
cat >>~/.bashrc <<'EOF'

# Pull result from Isolated Ubuntu to Work Ubuntu using git bundle.
iso-pull() {
  set -e

  local project_dir="${1:-$PWD}"
  local project_name
  project_name="$(basename "$project_dir")"

  local isolated_project="/home/john/workground/${project_name}"
  local isolated_bundle="/home/john/bundles/${project_name}-result.bundle"
  local work_bundle="$HOME/bundles/${project_name}-result.bundle"

  mkdir -p "$HOME/bundles"

  wsl.exe -d Ubuntu-26.04-Isolated -- bash -lc "
    set -e

    cd '$isolated_project'

    if ! git diff --quiet || ! git diff --cached --quiet; then
      git add .
      git commit -m 'sync from isolated'
    fi

    mkdir -p /home/john/bundles
    git bundle create '$isolated_bundle' HEAD
    git bundle verify '$isolated_bundle'
  "

  wsl.exe -d Ubuntu-26.04-Isolated -- cat "$isolated_bundle" > "$work_bundle"

  cd "$project_dir"

  git pull "$work_bundle" HEAD
  git status
}
EOF
```

적용:

```bash
source ~/.bashrc
```

사용:

```bash
cd ~/workground/openclaw
iso-pull
```

---

## 17. 전체 사용 시나리오

### 17.1 Work에서 개발

```bash
cd ~/workground/openclaw

vi README.md
git status
```

### 17.2 Isolated로 전달

```bash
iso-push
```

### 17.3 Isolated에서 실험 실행

```bash
iso-run 'git status'
iso-run 'ls -al'
```

Docker Compose 프로젝트라면:

```bash
iso-run 'docker compose config --quiet'
iso-run 'docker compose up -d'
iso-run 'docker compose ps'
```

### 17.4 Isolated 직접 진입

```bash
iso-enter
```

### 17.5 Isolated 결과를 Work로 회수

```bash
cd ~/workground/openclaw
iso-pull
```

---

## 18. OpenClaw/Hermes 프로젝트 권장 흐름

```text
1. Work Ubuntu
   - 코드 작성
   - 문서 작성
   - Claude Code / Codex 사용
   - git commit
   - iso-push

2. Isolated Ubuntu
   - Windows 마운트 없는 상태에서 검증
   - docker compose config --quiet
   - docker compose up -d
   - docker compose ps
   - 로그 확인
   - 필요한 수정
   - git commit

3. Work Ubuntu
   - iso-pull
   - 변경사항 리뷰
   - 최종 commit 정리
```

OpenClaw/Hermes 같은 Compose 운영 저장소에서는 bind mount, 포트, secret, container ownership, runtime data 경계를 명확히 분리해야 하므로 Work/Isolated 분리 구조가 적합함.

---

## 19. 브랜치 기반 실험 권장

Work Ubuntu:

```bash
cd ~/workground/openclaw
git checkout -b experiment/openclaw-runtime-test
git add .
git commit -m "start isolated experiment"
iso-push
```

Isolated에서 실험:

```bash
iso-run 'git branch --show-current'
iso-run 'docker compose config --quiet'
```

실험 결과 회수:

```bash
iso-pull
```

main에 병합:

```bash
git checkout main
git merge experiment/openclaw-runtime-test
```

---

## 20. 검증 체크리스트

### 20.1 배포판 확인

```powershell
wsl --list --verbose
```

기대:

```text
Ubuntu-26.04-Work        VERSION 2
Ubuntu-26.04-Isolated    VERSION 2
```

### 20.2 Work Windows 마운트 확인

Work Ubuntu:

```bash
ls /mnt/c
powershell.exe -Command '$PSVersionTable.PSVersion'
```

기대:

```text
/mnt/c 접근 가능
powershell.exe 실행 가능
```

### 20.3 Isolated Windows 마운트 차단 확인

Isolated Ubuntu:

```bash
ls /mnt/c
powershell.exe -Command '$PSVersionTable.PSVersion'
```

기대:

```text
/mnt/c 접근 불가
powershell.exe 실행 불가
```

### 20.4 Work에서 Isolated 호출 확인

Work Ubuntu:

```bash
wsl.exe -d Ubuntu-26.04-Isolated -- bash -lc 'whoami && pwd'
```

기대:

```text
john
/home/john
```

### 20.5 Git bundle 전달 확인

Work Ubuntu:

```bash
cd ~/workground/openclaw
iso-push
iso-run 'git log --oneline --decorate -3'
```

### 20.6 결과 회수 확인

Work Ubuntu:

```bash
cd ~/workground/openclaw
iso-pull
git log --oneline --decorate -5
```

---

## 21. 문제 해결

### 21.1 `wsl.exe: command not found`

원인:

```text
Work Ubuntu에서 interop이 꺼져 있거나 Windows PATH 연동이 비활성화된 상태
```

확인:

```bash
cat /etc/wsl.conf
```

Work Ubuntu는 다음이어야 함.

```ini
[interop]
enabled=true
appendWindowsPath=true
```

적용:

```powershell
wsl --terminate Ubuntu-26.04-Work
wsl -d Ubuntu-26.04-Work
```

---

### 21.2 Isolated에서 `powershell.exe`가 실행됨

원인:

```text
Isolated Ubuntu의 interop 차단 설정이 적용되지 않았거나 재시작되지 않은 상태
```

확인:

```bash
cat /etc/wsl.conf
```

Isolated Ubuntu는 다음이어야 함.

```ini
[interop]
enabled=false
appendWindowsPath=false
```

적용:

```powershell
wsl --terminate Ubuntu-26.04-Isolated
wsl -d Ubuntu-26.04-Isolated
```

---

### 21.3 Isolated에서 `/mnt/c`가 보임

원인:

```text
automount.enabled=false 미적용 또는 배포판 미종료 상태
```

Isolated Ubuntu:

```bash
cat /etc/wsl.conf
```

필수 설정:

```ini
[automount]
enabled=false
mountFsTab=false
```

적용:

```powershell
wsl --terminate Ubuntu-26.04-Isolated
wsl -d Ubuntu-26.04-Isolated
```

---

### 21.4 `git pull bundle` 충돌

원인:

```text
Work와 Isolated에서 같은 파일을 서로 다르게 수정한 상태
```

처리:

```bash
git status
git diff
```

충돌 파일 수정 후:

```bash
git add .
git commit -m "resolve isolated sync conflict"
```

---

### 21.5 `git bundle verify` 실패

원인:

```text
증분 bundle을 만들었는데 대상 저장소에 선행 commit이 없음
```

해결:

```bash
git bundle create ~/bundles/openclaw.bundle --all
```

또는 단순 운영에서는 항상 `HEAD` 전체 기준 bundle 사용:

```bash
git bundle create ~/bundles/openclaw.bundle HEAD
```

---

## 22. 운영 원칙

| 원칙                     | 설명                                   |
| ---------------------- | ------------------------------------ |
| 실시간 공유 금지              | `/mnt/c` 공유로 Isolated에 파일을 넘기지 않음    |
| IP 의존 금지               | WSL2 NAT IP 변경 문제를 피함                |
| SSH 서버 금지              | Work Ubuntu IP 변경, sshd 관리 부담 제거     |
| Git 기준 동기화             | 파일 복사가 아니라 commit 단위 전달              |
| Isolated 오염 허용         | 실험 환경은 망가져도 Work에 영향 없음              |
| Work 중심 제어             | 모든 push/pull/enter/run 제어는 Work에서 수행 |
| 실험은 브랜치 사용             | `experiment/*` 브랜치 권장                |
| Docker 실행은 Isolated 우선 | OpenClaw/Hermes 검증은 Isolated에서 수행    |

---

## 23. 최종 요약

```text
Windows PC
  └─ WSL2만 설치

구성:
  Ubuntu-26.04-Work
    - Windows 마운트 허용
    - wsl.exe 사용 가능
    - 개발/제어 담당

  Ubuntu-26.04-Isolated
    - Windows 마운트 차단
    - Windows 실행파일 연동 차단
    - 실험/검증 담당

동기화:
  Work → git bundle → wsl.exe pipe → Isolated
  Isolated → git bundle → wsl.exe pipe → Work

장점:
  - Work Ubuntu IP 변경 문제 없음
  - SSH 서버 불필요
  - Windows 공유폴더 불필요
  - Isolated 격리성 유지
  - Git 이력 기반으로 변경 추적 가능
  - OpenClaw/Hermes 실험 환경에 적합
```

---

## 24. 참고 출처

> 📄출처: [Microsoft, Basic commands for WSL, 2025, [https://learn.microsoft.com/en-us/windows/wsl/basic-commands](https://learn.microsoft.com/en-us/windows/wsl/basic-commands)], [Microsoft, How to install Linux on Windows with WSL, 2025, [https://learn.microsoft.com/en-us/windows/wsl/install](https://learn.microsoft.com/en-us/windows/wsl/install)], [Microsoft, Advanced settings configuration in WSL, 2026, [https://learn.microsoft.com/ko-kr/windows/wsl/wsl-config](https://learn.microsoft.com/ko-kr/windows/wsl/wsl-config)], [Microsoft, Accessing network applications with WSL, 2025, [https://learn.microsoft.com/en-us/windows/wsl/networking](https://learn.microsoft.com/en-us/windows/wsl/networking)], [Git SCM, git-bundle Documentation, 2025, [https://git-scm.com/docs/git-bundle](https://git-scm.com/docs/git-bundle)], [Kernel.org, git-bundle Manual Page, 2025, [https://www.kernel.org/pub/software/scm/git/docs/git-bundle.html](https://www.kernel.org/pub/software/scm/git/docs/git-bundle.html)]

```
```
