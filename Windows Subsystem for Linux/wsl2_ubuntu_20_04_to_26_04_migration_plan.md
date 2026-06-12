# Windows WSL2 Ubuntu 20.04 → Ubuntu 26.04 LTS 전환 계획서

## 0. 문서 목적

- 목적: Windows WSL2에서 현재 사용 중인 `Ubuntu` 배포판을 보존하면서 `Ubuntu-26.04` 신규 배포판으로 개발환경을 전환하기 위한 단계별 계획
- 기준 환경:
  - 현재 WSL 버전: `2.5.9.0`
  - 현재 기본 배포판: `Ubuntu`
  - 현재 WSL 배포판 버전: `2`
  - 현재 Ubuntu 추정 버전: `20.04`
  - 목표 Ubuntu 버전: `26.04 LTS`, `Resolute Raccoon`
- 권장 방식: 기존 Ubuntu 직접 업그레이드가 아니라 `Ubuntu-26.04` 신규 설치 후 개발환경 이전
- 핵심 원칙:
  - 기존 `Ubuntu`는 즉시 삭제하지 않음
  - `wsl --export`로 전체 백업 후 진행
  - Docker와 개발도구는 26.04에서 새로 설치
  - 프로젝트 소스와 런타임 데이터는 복원 후 단계별 검증
  - 1~2주 실사용 후 기존 Ubuntu 제거 여부 결정

>📄출처: [Microsoft, WSL 기본 명령, 2025, https://learn.microsoft.com/en-us/windows/wsl/basic-commands], [Ubuntu, Install Ubuntu on WSL 2, 2026, https://documentation.ubuntu.com/wsl/latest/howto/install-ubuntu-wsl2/], [Ubuntu, Ubuntu 26.04 LTS release notes, 2026, https://documentation.ubuntu.com/release-notes/26.04/], [Docker, Install Docker Engine on Ubuntu, 2026, https://docs.docker.com/engine/install/ubuntu/]

---

## 1. 전환 방식 결정

### 1.1 선택 방식

```text
기존 Ubuntu 직접 업그레이드 X
Ubuntu-26.04 신규 WSL 배포판 병행 설치 O
```

### 1.2 직접 업그레이드 비권장 사유

- 현재 배포판이 Ubuntu 20.04인 경우 26.04로 바로 업그레이드하는 경로가 아니라 중간 LTS를 거쳐야 하는 구조
- Ubuntu 공식 문서 기준 26.04로 진행하려면 오래된 LTS는 먼저 Ubuntu 24.04 LTS 또는 25.10으로 올린 뒤 진행 필요
- 개발환경, Docker, 인증파일, 로컬 런타임 데이터가 섞인 WSL 환경은 직접 업그레이드 중 장애 발생 시 복구 난이도 증가
- WSL은 여러 배포판 병행 실행이 가능하므로 신규 배포판 방식이 더 안전함

>📄출처: [Ubuntu, Ubuntu 26.04 LTS release notes, 2026, https://documentation.ubuntu.com/release-notes/26.04/], [Microsoft, Install WSL, 2025, https://learn.microsoft.com/en-us/windows/wsl/install]

### 1.3 최종 목표 구조

```text
전환 전:
Windows
└─ WSL2
   └─ Ubuntu              # 기존 20.04 개발환경, 기본 배포판

전환 중:
Windows
└─ WSL2
   ├─ Ubuntu              # 기존 20.04 보존
   └─ Ubuntu-26.04        # 신규 26.04 개발환경 검증

전환 후:
Windows
└─ WSL2
   ├─ Ubuntu-26.04        # 기본 배포판
   └─ Ubuntu              # 1~2주 보존 후 제거 후보
```

---

## 2. 현재 상태 확인

### 2.1 PowerShell에서 실행

```powershell
wsl --version
wsl --status
wsl -l -v
```

### 2.2 현재 확인된 상태

```text
WSL 버전: 2.5.9.0
커널 버전: 6.6.87.2-1
기본 배포: Ubuntu
기본 버전: 2

NAME      STATE           VERSION
* Ubuntu  Running         2
```

### 2.3 판단

- WSL 버전 `2.5.9.0`은 Ubuntu 24.04 이상 WSL 신규 배포 형식 요구 조건인 WSL `2.4.10` 이상 충족
- 현재 배포판 이름은 `Ubuntu`
- 신규 배포판 이름은 `Ubuntu-26.04`로 분리 설치 가능
- 기존 배포판은 백업 전 삭제 금지

Ubuntu 공식 WSL 문서는 Ubuntu 24.04 LTS 및 이후 버전이 WSL의 새 tar 기반 배포 형식으로 다운로드되며, 이 형식에는 WSL `2.4.10` 이상이 필요하다고 설명함.

>📄출처: [Ubuntu, Install Ubuntu on WSL 2, 2026, https://documentation.ubuntu.com/wsl/latest/howto/install-ubuntu-wsl2/]

---

## 3. 기존 Ubuntu 정지

### 3.1 PowerShell에서 실행

```powershell
wsl --shutdown
```

### 3.2 상태 확인

```powershell
wsl -l -v
```

### 3.3 기대 결과

```text
NAME      STATE      VERSION
* Ubuntu  Stopped    2
```

### 3.4 판단 기준

- `Ubuntu`가 `Stopped`이면 백업 가능 상태
- `Running`이면 열려 있는 WSL 터미널, Windows Terminal 탭, Docker 관련 프로세스 확인 후 다시 `wsl --shutdown` 실행

>📄출처: [Microsoft, WSL 기본 명령, 2025, https://learn.microsoft.com/en-us/windows/wsl/basic-commands]

---

## 4. 기존 Ubuntu 전체 백업

### 4.1 백업 디렉터리 생성

PowerShell에서 실행.

```powershell
mkdir D:\wsl-backup
```

이미 존재한다는 메시지가 나와도 무시 가능.

### 4.2 Ubuntu 배포판 export

```powershell
wsl --export Ubuntu D:\wsl-backup\ubuntu-20.04-before-26.04-migration.tar
```

### 4.3 백업 파일 확인

```powershell
dir D:\wsl-backup
```

### 4.4 기대 결과

```text
ubuntu-20.04-before-26.04-migration.tar
```

### 4.5 주의사항

- 백업 파일 생성 전 기존 Ubuntu 삭제 금지
- 백업 파일은 C 드라이브보다 여유 공간이 충분한 드라이브에 저장 권장
- 백업 파일 크기는 기존 WSL 사용량에 따라 수 GB~수십 GB 가능
- 백업 파일은 26.04 검증 완료 후에도 일정 기간 보존

WSL 배포판의 백업과 복원은 `wsl --export`, `wsl --import` 명령으로 수행 가능.

>📄출처: [Microsoft, WSL 기본 명령, 2025, https://learn.microsoft.com/en-us/windows/wsl/basic-commands]

---

## 5. Ubuntu 26.04 설치 가능 여부 확인

### 5.1 PowerShell에서 온라인 목록 확인

```powershell
wsl --list --online
```

### 5.2 확인 대상

목록에 아래 항목이 있는지 확인.

```text
Ubuntu-26.04    Ubuntu 26.04 LTS
```

### 5.3 판단 기준

- `Ubuntu-26.04`가 있으면 6단계의 일반 설치 방식 진행
- `Ubuntu-26.04`가 없으면 7단계의 `.wsl` 이미지 기반 설치 방식 진행
- 목록 갱신이 안 되면 WSL 업데이트 후 재시도

```powershell
wsl --update
wsl --shutdown
wsl --list --online
```

Microsoft 문서는 `wsl --list --online`으로 설치 가능한 배포판 목록을 확인하고 `wsl --install -d <DistroName>`으로 특정 배포판을 설치하는 방식을 안내함.

>📄출처: [Microsoft, Install WSL, 2025, https://learn.microsoft.com/en-us/windows/wsl/install]

---

## 6. Ubuntu 26.04 일반 설치 방식

### 6.1 PowerShell에서 실행

```powershell
wsl --install -d Ubuntu-26.04
```

또는 일부 환경에서 아래 형식 사용 가능.

```powershell
wsl --install Ubuntu-26.04
```

### 6.2 최초 사용자 생성

설치 후 Ubuntu 26.04 터미널이 열리면 사용자 계정 생성.

```text
Enter new UNIX username: john
New password:
Retype new password:
```

### 6.3 사용자명 권장

- 기존 Ubuntu 사용자명과 동일하게 `john` 사용 권장
- 기존 홈 경로, 스크립트, SSH 설정, 프로젝트 경로 이전 시 충돌 감소

### 6.4 설치 결과 확인

PowerShell에서 실행.

```powershell
wsl -l -v
```

### 6.5 기대 결과

```text
NAME            STATE           VERSION
* Ubuntu         Stopped         2
  Ubuntu-26.04   Running         2
```

또는 `Ubuntu-26.04`가 `Stopped`이어도 정상.

>📄출처: [Microsoft, Install WSL, 2025, https://learn.microsoft.com/en-us/windows/wsl/install]

---

## 7. Ubuntu 26.04 `.wsl` 이미지 설치 방식

## 7.1 사용 조건

- `wsl --list --online` 목록에 `Ubuntu-26.04`가 없는 경우
- Microsoft Store 사용이 어렵거나 네트워크 정책상 직접 파일 설치가 필요한 경우
- 내부망/오프라인 배포 방식으로 Ubuntu 26.04 WSL 이미지를 관리하려는 경우

Ubuntu 공식 WSL 문서는 WSL 이미지를 Ubuntu archive에서 직접 다운로드할 수 있으며, `.wsl` 파일은 더블클릭 또는 `wsl --install --from-file <image>.wsl`로 설치 가능하다고 안내함.

>📄출처: [Ubuntu, Install Ubuntu on WSL 2, 2026, https://documentation.ubuntu.com/wsl/latest/howto/install-ubuntu-wsl2/]

### 7.2 다운로드 위치

브라우저에서 아래 Ubuntu WSL 다운로드 페이지 또는 release archive 확인.

```text
https://ubuntu.com/download/wsl
https://releases.ubuntu.com/26.04/
https://releases.ubuntu.com/resolute/
```

Ubuntu 다운로드 페이지는 Ubuntu 26.04 LTS를 WSL용 최신 LTS 버전으로 제공하며, Intel/AMD 64-bit 및 ARM 64-bit WSL 이미지를 제공함.

>📄출처: [Ubuntu, Get Ubuntu on WSL, 2026, https://ubuntu.com/download/wsl], [Ubuntu, Ubuntu 26.04 LTS release archive, 2026, https://releases.ubuntu.com/26.04/]

### 7.3 파일명 예시

실제 파일명은 다운로드 시점에 따라 다를 수 있음.

```text
ubuntu-26.04-wsl-amd64.wsl
ubuntu-26.04-wsl-arm64.wsl
```

### 7.4 PowerShell에서 설치

다운로드 디렉터리로 이동 후 실행.

```powershell
cd $env:USERPROFILE\Downloads
wsl --install --from-file .\ubuntu-26.04-wsl-amd64.wsl --name Ubuntu-26.04
```

### 7.5 설치 결과 확인

```powershell
wsl -l -v
```

### 7.6 기대 결과

```text
NAME            STATE           VERSION
* Ubuntu         Stopped         2
  Ubuntu-26.04   Stopped         2
```

---

## 8. Ubuntu 26.04 버전 확인

### 8.1 Ubuntu 26.04 실행

PowerShell에서 실행.

```powershell
wsl -d Ubuntu-26.04
```

### 8.2 Ubuntu 내부에서 실행

```bash
cat /etc/os-release
```

### 8.3 기대 결과

```text
VERSION_ID="26.04"
VERSION_CODENAME=resolute
```

### 8.4 사용자 확인

```bash
whoami
pwd
```

### 8.5 기대 결과 예시

```text
john
/home/john
```

Ubuntu 26.04 LTS의 코드네임은 `Resolute Raccoon`이며, 5년 보안 업데이트와 중요 버그 수정 대상인 LTS 릴리스.

>📄출처: [Ubuntu, Ubuntu 26.04 LTS release notes, 2026, https://documentation.ubuntu.com/release-notes/26.04/]

---

## 9. Ubuntu 26.04 기본 패키지 설치

### 9.1 패키지 업데이트

Ubuntu 26.04 내부에서 실행.

```bash
sudo apt update
sudo apt full-upgrade -y
```

### 9.2 기본 개발 도구 설치

```bash
sudo apt install -y \
  build-essential \
  curl wget git unzip zip jq \
  ca-certificates gnupg lsb-release \
  software-properties-common \
  openssh-client \
  rsync \
  vim nano htop tree
```

### 9.3 확인

```bash
git --version
curl --version
ssh -V
```

### 9.4 개발도구 호환성 주의

- Ubuntu 26.04는 Ubuntu 24.04보다 기본 컴파일러, 런타임, 라이브러리 버전이 높음
- 26.04에서 빌드한 네이티브 바이너리를 Ubuntu 20.04/22.04/24.04 서버에 배포할 경우 glibc 호환성 문제 가능성 있음
- 운영 서버 대상 바이너리는 컨테이너, cross, musl, zig, CI 빌드 이미지 등으로 타깃 런타임을 분리하는 방식 권장

>📄출처: [Ubuntu, Ubuntu 26.04 LTS summary for LTS users, 2026, https://documentation.ubuntu.com/release-notes/26.04/summary-for-lts-users/]

---

## 10. 기존 Ubuntu 홈 디렉터리 압축

### 10.1 기존 Ubuntu 실행

PowerShell에서 실행.

```powershell
wsl -d Ubuntu
```

### 10.2 기존 Ubuntu 내부에서 백업용 디렉터리 생성

```bash
mkdir -p /mnt/c/wsl-migrate
```

### 10.3 홈 디렉터리 압축

```bash
cd ~

tar \
  --exclude='.cache' \
  --exclude='node_modules' \
  --exclude='.npm/_cacache' \
  --exclude='.local/share/Trash' \
  -czpf /mnt/c/wsl-migrate/home-$USER-before-26.04.tgz .
```

### 10.4 패키지 목록 저장

```bash
apt-mark showmanual > /mnt/c/wsl-migrate/apt-manual-before-26.04.txt
dpkg -l > /mnt/c/wsl-migrate/dpkg-list-before-26.04.txt
```

### 10.5 주요 설정 별도 확인

```bash
ls -la ~/.ssh ~/.gitconfig ~/.config 2>/dev/null || true
ls -la ~/workground 2>/dev/null || true
```

### 10.6 결과 확인

```bash
ls -lh /mnt/c/wsl-migrate/
```

### 10.7 기대 결과

```text
home-john-before-26.04.tgz
apt-manual-before-26.04.txt
dpkg-list-before-26.04.txt
```

### 10.8 기존 Ubuntu 종료

```bash
exit
```

---

## 11. Ubuntu 26.04에 홈 디렉터리 복원

### 11.1 Ubuntu 26.04 실행

PowerShell에서 실행.

```powershell
wsl -d Ubuntu-26.04
```

### 11.2 이전 파일 확인

```bash
ls -lh /mnt/c/wsl-migrate/
```

### 11.3 홈 디렉터리 복원

```bash
cd ~

tar -xzpf /mnt/c/wsl-migrate/home-*-before-26.04.tgz -C ~
```

### 11.4 SSH 권한 복구

```bash
chmod 700 ~/.ssh 2>/dev/null || true
chmod 600 ~/.ssh/* 2>/dev/null || true
chmod 644 ~/.ssh/*.pub 2>/dev/null || true
```

### 11.5 GitHub SSH 확인

```bash
ssh -T git@github.com
```

### 11.6 정상 메시지 예시

```text
Hi <username>! You've successfully authenticated, but GitHub does not provide shell access.
```

### 11.7 주의사항

- `node_modules`, `.cache` 등은 복원하지 않고 프로젝트별 재설치 권장
- `~/.ssh/config`에 절대경로가 있으면 사용자명과 경로 확인 필요
- `~/.bashrc`, `~/.profile`, `~/.zshrc` 복원 후 26.04에서 없는 명령이 호출될 수 있으므로 쉘 시작 오류 확인 필요
- `pyenv`, `nvm`, `rustup`, `goenv`, `uv`, `pnpm` 등은 셸 설정 복원 후 개별 버전 검증 필요

---

## 12. Git 기본 설정 확인

### 12.1 현재 설정 확인

```bash
git config --global user.name
git config --global user.email
```

### 12.2 비어 있을 때 설정

```bash
git config --global user.name "john"
git config --global user.email "사용자이메일"
```

### 12.3 Git 설정 전체 확인

```bash
git config --global --list
```

---

## 13. systemd 활성화

### 13.1 Ubuntu 26.04 내부에서 실행

```bash
sudo tee /etc/wsl.conf >/dev/null <<'EOF'
[boot]
systemd=true
EOF
```

### 13.2 PowerShell에서 WSL 재시작

```powershell
wsl --shutdown
wsl -d Ubuntu-26.04
```

### 13.3 systemd 확인

Ubuntu 26.04 내부에서 실행.

```bash
systemctl status
```

### 13.4 판단 기준

- `running` 또는 systemd 상태 화면이 나오면 정상
- `System has not been booted with systemd` 메시지가 나오면 `/etc/wsl.conf` 확인 후 `wsl --shutdown` 재실행

---

## 14. Docker Engine 설치

## 14.1 충돌 가능 패키지 제거

Ubuntu 26.04 내부에서 실행.

```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove -y "$pkg" 2>/dev/null || true
done
```

Docker 공식 문서는 Docker 공식 패키지 설치 전 배포판 제공 비공식/충돌 가능 Docker 패키지 제거를 안내함.

>📄출처: [Docker, Install Docker Engine on Ubuntu, 2026, https://docs.docker.com/engine/install/ubuntu/]

### 14.2 필수 패키지 설치

```bash
sudo apt update
sudo apt install -y ca-certificates curl
```

### 14.3 Docker GPG 키 등록

```bash
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

### 14.4 Docker apt 저장소 등록

Docker 공식 문서의 `docker.sources` 방식 사용.

```bash
sudo tee /etc/apt/sources.list.d/docker.sources <<'EOF'
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: resolute
Components: stable
Architectures: amd64
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```

자동 아키텍처/코드네임 감지가 필요하면 아래 방식 사용.

```bash
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```

### 14.5 Docker 패키지 설치

```bash
sudo apt update

sudo apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
```

### 14.6 현재 사용자에게 Docker 권한 부여

```bash
sudo usermod -aG docker "$USER"
```

### 14.7 WSL 재시작

PowerShell에서 실행.

```powershell
wsl --shutdown
wsl -d Ubuntu-26.04
```

### 14.8 Docker 확인

Ubuntu 26.04 내부에서 실행.

```bash
docker version
docker compose version
```

### 14.9 Docker 서비스 확인

```bash
sudo systemctl status docker
```

### 14.10 Docker 서비스가 중지되어 있을 때

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### 14.11 hello-world 테스트

```bash
docker run --rm hello-world
```

Docker 공식 문서는 Ubuntu Resolute 26.04 LTS를 Docker Engine 지원 대상에 포함하며, 설치 검증 명령으로 `hello-world` 컨테이너 실행을 안내함.

>📄출처: [Docker, Install Docker Engine on Ubuntu, 2026, https://docs.docker.com/engine/install/ubuntu/]

---

## 15. 런타임별 개발환경 검증

### 15.1 Python 확인

```bash
python3 --version
pip3 --version 2>/dev/null || true
uv --version 2>/dev/null || true
```

### 15.2 Node.js 확인

```bash
node --version 2>/dev/null || true
npm --version 2>/dev/null || true
pnpm --version 2>/dev/null || true
```

### 15.3 Rust 확인

```bash
rustc --version 2>/dev/null || true
cargo --version 2>/dev/null || true
```

### 15.4 Go 확인

```bash
go version 2>/dev/null || true
```

### 15.5 Java 확인

```bash
java -version 2>/dev/null || true
javac -version 2>/dev/null || true
```

### 15.6 Java 버전 고정이 필요할 때

운영 또는 프로젝트 기준이 Java 21이면 26.04 기본값에 의존하지 않고 명시 설치.

```bash
sudo apt install -y openjdk-21-jdk
sudo update-alternatives --config java
sudo update-alternatives --config javac
```

---

## 16. 기존 개발 프로젝트 확인

### 16.1 작업 디렉터리 확인

```bash
ls -la ~/workground
```

### 16.2 agent-room 프로젝트 확인

```bash
cd ~/workground/zagents-room
ls -la
```

### 16.3 Git 상태 확인

```bash
git status --short
```

### 16.4 의존 런타임 파일 확인

```bash
ls -la .env docker-compose.yml
```

### 16.5 주의사항

- `.env`는 비밀값 포함 가능성이 있으므로 Git 커밋 금지
- `data/`는 컨테이너 런타임 데이터이므로 무분별한 소유권 변경 금지
- `.sisyphus/`는 로컬 agent 세션 상태로 취급
- Docker Compose 기반 프로젝트는 실제 기동 전 `docker compose config --quiet` 검증 우선
- 기존 WSL 20.04에서 실행 중인 컨테이너와 26.04에서 실행할 컨테이너의 포트 충돌 방지 필요

---

## 17. Docker Compose 프로젝트 검증

### 17.1 Compose 문법 검증

```bash
docker compose config --quiet
```

### 17.2 browser profile 포함 검증

```bash
docker compose --profile browser config --quiet
```

### 17.3 서비스 기동

```bash
docker compose up -d
```

### 17.4 상태 확인

```bash
docker compose ps
```

### 17.5 로그 확인

```bash
docker compose logs --tail=100
```

### 17.6 기대 상태

```text
openclaw                 Up / healthy
hermes-agent             Up
mariadb                  Up
mattermost               Up / healthy
redis                    Up
runtime-bridge           Up
openclaw-permissions     Exited 0
mattermost-permissions   Exited 0
```

### 17.7 실패 시 우선 확인

```bash
docker compose logs --tail=200 openclaw

docker compose logs --tail=200 mattermost

docker compose logs --tail=200 runtime-bridge
```

---

## 18. Ubuntu 26.04를 기본 WSL 배포판으로 변경

### 18.1 PowerShell에서 실행

```powershell
wsl --set-default Ubuntu-26.04
```

### 18.2 확인

```powershell
wsl -l -v
```

### 18.3 기대 결과

```text
NAME            STATE           VERSION
* Ubuntu-26.04   Running         2
  Ubuntu         Stopped         2
```

### 18.4 기본 진입 확인

```powershell
wsl
```

Ubuntu 내부에서 확인.

```bash
cat /etc/os-release
```

기대 결과.

```text
VERSION_ID="26.04"
VERSION_CODENAME=resolute
```

>📄출처: [Microsoft, WSL 기본 명령, 2025, https://learn.microsoft.com/en-us/windows/wsl/basic-commands]

---

## 19. 기존 Ubuntu 유지 기간

### 19.1 권장 유지 기간

- 최소 1~2주 유지
- 개발 프로젝트, Docker Compose, Git, SSH, 에디터 연동, 자동화 스크립트 검증 후 제거 판단

### 19.2 기존 Ubuntu 실행 방법

```powershell
wsl -d Ubuntu
```

### 19.3 기존 Ubuntu 삭제 금지 조건

- 26.04에서 Docker가 정상 동작하지 않는 상태
- 26.04에서 프로젝트 빌드 실패 상태
- 26.04에서 SSH/Git 인증 미완료 상태
- 26.04에서 `.env`, 인증 파일, 개발 스크립트 누락 상태
- 20.04 백업 tar 파일 미확인 상태
- 26.04에서 VS Code Remote WSL, Windows Terminal profile, Git credential helper 검증 미완료 상태

---

## 20. 기존 Ubuntu 제거

## 20.1 최종 검증 체크리스트

Ubuntu 26.04에서 실행.

```bash
git --version
ssh -T git@github.com
docker version
docker compose version
```

프로젝트 디렉터리에서 실행.

```bash
cd ~/workground/zagents-room

docker compose config --quiet
docker compose --profile browser config --quiet
docker compose up -d
docker compose ps
```

### 20.2 기존 Ubuntu 제거

PowerShell에서 실행.

```powershell
wsl --unregister Ubuntu
```

### 20.3 주의사항

- `wsl --unregister Ubuntu`는 기존 Ubuntu 배포판의 데이터, 설정, 설치 소프트웨어를 영구 삭제
- 삭제 후 복구는 `D:\wsl-backup\ubuntu-20.04-before-26.04-migration.tar` 백업 파일에 의존
- 삭제 전 백업 파일 존재 여부를 반드시 확인

>📄출처: [Microsoft, WSL 기본 명령, 2025, https://learn.microsoft.com/en-us/windows/wsl/basic-commands]

---

## 21. 롤백 절차

## 21.1 Ubuntu 26.04 전환 후 문제가 있을 때 기본 배포판 원복

PowerShell에서 실행.

```powershell
wsl --set-default Ubuntu
wsl
```

### 21.2 백업 파일로 기존 Ubuntu 복구가 필요할 때

기존 `Ubuntu`가 삭제된 경우에만 사용.

```powershell
mkdir D:\wsl\Ubuntu-20.04-Restore
wsl --import Ubuntu-20.04-Restore D:\wsl\Ubuntu-20.04-Restore D:\wsl-backup\ubuntu-20.04-before-26.04-migration.tar --version 2
wsl -d Ubuntu-20.04-Restore
```

### 21.3 복구 후 기본값 지정

```powershell
wsl --set-default Ubuntu-20.04-Restore
```

>📄출처: [Microsoft, WSL 기본 명령, 2025, https://learn.microsoft.com/en-us/windows/wsl/basic-commands]

---

## 22. 자주 발생하는 문제와 조치

## 22.1 `wsl --install -d Ubuntu-26.04` 실패

### 증상

```text
Invalid distribution name
```

### 조치 1: 온라인 목록 재확인

```powershell
wsl --update
wsl --shutdown
wsl --list --online
```

`Ubuntu-26.04` 정확한 이름 확인 후 재시도.

### 조치 2: `.wsl` 이미지 설치 방식 사용

```powershell
cd $env:USERPROFILE\Downloads
wsl --install --from-file .\ubuntu-26.04-wsl-amd64.wsl --name Ubuntu-26.04
```

---

## 22.2 Docker 명령이 권한 오류로 실패

### 증상

```text
permission denied while trying to connect to the Docker daemon socket
```

### 조치

```bash
sudo usermod -aG docker "$USER"
```

PowerShell에서 실행.

```powershell
wsl --shutdown
wsl -d Ubuntu-26.04
```

확인.

```bash
groups
docker run --rm hello-world
```

---

## 22.3 Docker daemon 미기동

### 증상

```text
Cannot connect to the Docker daemon
```

### 조치

```bash
sudo systemctl status docker
sudo systemctl start docker
sudo systemctl enable docker
```

systemd 오류가 있으면 `/etc/wsl.conf` 확인.

```bash
cat /etc/wsl.conf
```

기대 내용.

```ini
[boot]
systemd=true
```

PowerShell에서 재시작.

```powershell
wsl --shutdown
wsl -d Ubuntu-26.04
```

---

## 22.4 SSH 키 권한 오류

### 증상

```text
Bad permissions
Permission denied (publickey)
```

### 조치

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/*.pub
ssh -T git@github.com
```

---

## 22.5 기존 프로젝트에서 `node_modules` 누락

### 원인

- 홈 이전 시 `node_modules` 제외 권장으로 인한 정상 상태

### 조치

프로젝트별 의존성 재설치.

```bash
npm install
```

또는 pnpm 사용 시.

```bash
pnpm install
```

---

## 22.6 Python 패키지 빌드 실패

### 가능 원인

- Ubuntu 26.04의 Python, GCC, OpenSSL, glibc 버전 변화
- 오래된 Python 패키지의 wheel 미지원
- C 확장 패키지의 빌드 의존성 누락

### 조치

```bash
sudo apt install -y build-essential python3-dev pkg-config
```

프로젝트별 가상환경 재생성.

```bash
rm -rf .venv
python3 -m venv .venv
source .venv/bin/activate
pip install -U pip setuptools wheel
pip install -r requirements.txt
```

---

## 22.7 Rust/Go 바이너리 구버전 서버 실행 실패

### 가능 원인

- Ubuntu 26.04에서 빌드한 바이너리가 구버전 glibc에 의존
- 배포 대상 서버가 Ubuntu 20.04/22.04/Rocky 8 계열인 경우 실행 실패 가능

### 조치 방향

```text
1. 배포 대상 OS와 동일한 컨테이너 이미지에서 빌드
2. Rust는 musl target 또는 cross/zig 검토
3. Go는 CGO_ENABLED=0 또는 대상 glibc 기준 빌드 검토
4. CI 빌드 이미지를 Ubuntu 22.04/24.04로 고정 검토
```

---

## 22.8 Compose 프로젝트 포트 충돌

### 확인

```bash
ss -lntp
```

또는 Windows PowerShell.

```powershell
netstat -ano | findstr LISTENING
```

### 조치

- 기존 Ubuntu에서 실행 중인 Docker/WSL 프로세스 정리
- PowerShell에서 전체 WSL 종료

```powershell
wsl --shutdown
```

이후 Ubuntu 26.04만 실행.

```powershell
wsl -d Ubuntu-26.04
```

---

## 23. 전체 실행 순서 요약

```text
1. wsl --shutdown
2. wsl --export Ubuntu D:\wsl-backup\ubuntu-20.04-before-26.04-migration.tar
3. wsl --list --online
4. Ubuntu-26.04 목록 존재 시 wsl --install -d Ubuntu-26.04
5. 목록 미존재 시 Ubuntu 26.04 .wsl 이미지 다운로드 후 wsl --install --from-file 사용
6. wsl -d Ubuntu-26.04
7. Ubuntu 26.04 기본 패키지 설치
8. 기존 Ubuntu에서 홈 디렉터리와 패키지 목록 백업
9. Ubuntu 26.04에서 홈 디렉터리 복원
10. SSH/Git 확인
11. systemd 활성화
12. Docker Engine 설치
13. Docker hello-world 검증
14. 런타임별 개발환경 검증
15. 기존 프로젝트 검증
16. docker compose config --quiet
17. docker compose up -d
18. wsl --set-default Ubuntu-26.04
19. 1~2주 운영 검증
20. 필요 시 wsl --unregister Ubuntu
```

---

## 24. 최종 체크리스트

| 구분 | 확인 명령 | 완료 |
|---|---|---|
| WSL 백업 | `dir D:\wsl-backup` |  |
| 26.04 설치 | `wsl -l -v` |  |
| Ubuntu 버전 | `cat /etc/os-release` |  |
| Git | `git --version` |  |
| SSH | `ssh -T git@github.com` |  |
| systemd | `systemctl status` |  |
| Docker | `docker version` |  |
| Compose | `docker compose version` |  |
| Docker 테스트 | `docker run --rm hello-world` |  |
| Python | `python3 --version` |  |
| Node.js | `node --version` |  |
| Rust | `rustc --version` |  |
| Go | `go version` |  |
| Java | `java -version` |  |
| 프로젝트 검증 | `docker compose config --quiet` |  |
| 프로젝트 기동 | `docker compose up -d` |  |
| 기본 배포판 전환 | `wsl --set-default Ubuntu-26.04` |  |
| 기존 Ubuntu 보존 | `wsl -l -v` |  |

---

## 25. 권장 운영 기준

- 기존 Ubuntu 직접 업그레이드보다 신규 Ubuntu 26.04 배포판 병행 설치 방식 우선
- Docker 데이터 디렉터리 직접 복사보다 26.04에서 Docker 재설치 후 컨테이너 재생성 우선
- 프로젝트 소스는 Git 기준 복구 가능 상태 유지
- `.env`, SSH 키, 로컬 인증정보는 별도 확인
- 기존 Ubuntu 삭제는 최소 1~2주 실사용 검증 후 수행
- 문제 발생 시 `wsl --set-default Ubuntu`로 즉시 원복
- 운영 서버가 Ubuntu 20.04/22.04/24.04 계열이면 배포 바이너리는 26.04 직접 빌드 결과물을 그대로 사용하지 말고 대상 런타임 기준으로 별도 빌드
- Docker Compose 서비스의 bind mount 소유권과 런타임 데이터는 서비스별 UID/GID 기준 유지

---

## 26. 24.04 계획서 대비 변경점

| 항목 | 24.04 계획서 | 26.04 계획서 |
|---|---|---|
| 목표 배포판 | `Ubuntu-24.04` | `Ubuntu-26.04` |
| 코드네임 | `noble` | `resolute` |
| 설치 방식 | `wsl --install -d Ubuntu-24.04` 중심 | `wsl --install -d Ubuntu-26.04` + `.wsl` 이미지 설치 대안 포함 |
| WSL 이미지 조건 | WSL 2.4.10 이상 | WSL 2.4.10 이상 동일 |
| Docker 지원 | Ubuntu Noble 24.04 LTS 지원 | Ubuntu Resolute 26.04 LTS 지원 |
| 개발도구 리스크 | 상대적으로 낮음 | 최신 런타임으로 인한 호환성 검증 필요 |
| 바이너리 배포 주의 | 보통 | glibc/런타임 호환성 더 주의 |
| 권장 검증 | Docker, Git, SSH, Compose | Docker, Git, SSH, Compose + Python/Node/Rust/Go/Java |

>📄출처: [Ubuntu, Ubuntu 26.04 LTS release notes, 2026, https://documentation.ubuntu.com/release-notes/26.04/], [Docker, Install Docker Engine on Ubuntu, 2026, https://docs.docker.com/engine/install/ubuntu/]
