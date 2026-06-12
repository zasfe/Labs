# Windows WSL2 Ubuntu 20.04 → Ubuntu 24.04 전환 절차서

## 0. 문서 목적

- 목적: Windows WSL2에서 현재 사용 중인 `Ubuntu` 배포판을 보존하면서 `Ubuntu-24.04` 신규 배포판으로 개발환경을 전환하기 위한 단계별 절차
- 기준 환경:
  - 현재 WSL 버전: `2.5.9.0`
  - 현재 기본 배포판: `Ubuntu`
  - 현재 WSL 버전: `2`
  - 현재 Ubuntu 추정 버전: `20.04`
- 권장 방식: 기존 Ubuntu 직접 업그레이드가 아니라 `Ubuntu-24.04` 신규 설치 후 개발환경 이전
- 핵심 원칙:
  - 기존 `Ubuntu`는 즉시 삭제하지 않음
  - `wsl --export`로 전체 백업 후 진행
  - Docker와 개발도구는 24.04에서 새로 설치
  - 프로젝트는 복원 후 검증
  - 1~2주 실사용 후 기존 Ubuntu 제거 여부 결정

>📄출처: [Microsoft, WSL 기본 명령, 2025, https://learn.microsoft.com/ko-kr/windows/wsl/basic-commands], [Ubuntu, Install Ubuntu on WSL 2, 2026, https://documentation.ubuntu.com/wsl/latest/howto/install-ubuntu-wsl2/], [Docker, Install Docker Engine on Ubuntu, 2026, https://docs.docker.com/engine/install/ubuntu/]

---

## 1. 현재 상태 확인

### 1.1 PowerShell에서 실행

```powershell
wsl --version
wsl --status
wsl -l -v
```

### 1.2 현재 확인된 상태

```text
WSL 버전: 2.5.9.0
커널 버전: 6.6.87.2-1
기본 배포: Ubuntu
기본 버전: 2

NAME      STATE           VERSION
* Ubuntu  Running         2
```

### 1.3 판단

- WSL 버전 `2.5.9.0`은 Ubuntu 24.04 WSL 신규 배포 형식 요구 조건인 WSL `2.4.10` 이상 충족
- 현재 배포판 이름은 `Ubuntu`
- 신규 배포판 이름은 `Ubuntu-24.04`로 분리 설치 가능
- 전환 방식은 병행 설치 방식으로 진행

>📄출처: [Ubuntu, Install Ubuntu on WSL 2, 2026, https://documentation.ubuntu.com/wsl/latest/howto/install-ubuntu-wsl2/]

---

## 2. 기존 Ubuntu 정지

### 2.1 PowerShell에서 실행

```powershell
wsl --shutdown
```

### 2.2 상태 확인

```powershell
wsl -l -v
```

### 2.3 기대 결과

```text
NAME      STATE      VERSION
* Ubuntu  Stopped    2
```

### 2.4 판단 기준

- `Ubuntu`가 `Stopped`이면 백업 가능 상태
- `Running`이면 열려 있는 WSL 터미널, Windows Terminal 탭, Docker 관련 프로세스 확인 후 다시 `wsl --shutdown` 실행

>📄출처: [Microsoft, WSL 기본 명령, 2025, https://learn.microsoft.com/ko-kr/windows/wsl/basic-commands]

---

## 3. 기존 Ubuntu 전체 백업

### 3.1 백업 디렉터리 생성

PowerShell에서 실행.

```powershell
mkdir D:\wsl-backup
```

이미 존재한다는 메시지가 나와도 무시 가능.

### 3.2 Ubuntu 배포판 export

```powershell
wsl --export Ubuntu D:\wsl-backup\ubuntu-20.04-backup.tar
```

### 3.3 백업 파일 확인

```powershell
dir D:\wsl-backup
```

### 3.4 기대 결과

```text
ubuntu-20.04-backup.tar
```

### 3.5 주의사항

- 백업 파일 생성 전 기존 Ubuntu 삭제 금지
- 백업 파일은 C 드라이브보다 여유 공간이 충분한 드라이브에 저장 권장
- 백업 파일 크기는 기존 WSL 사용량에 따라 수 GB~수십 GB 가능

>📄출처: [Microsoft, WSL 기본 명령, 2025, https://learn.microsoft.com/ko-kr/windows/wsl/basic-commands]

---

## 4. Ubuntu 24.04 설치 가능 여부 확인

### 4.1 PowerShell에서 실행

```powershell
wsl --list --online
```

### 4.2 확인 대상

목록에 아래 항목이 있는지 확인.

```text
Ubuntu-24.04    Ubuntu 24.04 LTS
```

### 4.3 판단 기준

- `Ubuntu-24.04`가 있으면 5단계 진행
- 목록이 갱신되지 않거나 설치 실패 시 `wsl --update` 후 재시도

```powershell
wsl --update
wsl --shutdown
wsl --list --online
```

>📄출처: [Microsoft, WSL 기본 명령, 2025, https://learn.microsoft.com/ko-kr/windows/wsl/basic-commands], [Ubuntu, Install Ubuntu on WSL 2, 2026, https://documentation.ubuntu.com/wsl/latest/howto/install-ubuntu-wsl2/]

---

## 5. Ubuntu 24.04 신규 설치

### 5.1 PowerShell에서 실행

```powershell
wsl --install -d Ubuntu-24.04
```

또는 일부 환경에서 아래 형식 사용 가능.

```powershell
wsl --install Ubuntu-24.04
```

### 5.2 최초 사용자 생성

설치 후 Ubuntu 24.04 터미널이 열리면 사용자 계정 생성.

```text
Enter new UNIX username: john
New password:
Retype new password:
```

### 5.3 사용자명 권장

- 기존 Ubuntu 사용자명과 동일하게 `john` 사용 권장
- 기존 홈 경로, 스크립트, SSH 설정, 프로젝트 경로 이전 시 충돌 감소

### 5.4 설치 결과 확인

PowerShell에서 실행.

```powershell
wsl -l -v
```

### 5.5 기대 결과

```text
NAME            STATE           VERSION
* Ubuntu         Stopped         2
  Ubuntu-24.04   Stopped         2
```

또는 `Ubuntu-24.04`가 `Running`이어도 정상.

>📄출처: [Ubuntu, Install Ubuntu on WSL 2, 2026, https://documentation.ubuntu.com/wsl/latest/howto/install-ubuntu-wsl2/]

---

## 6. Ubuntu 24.04 버전 확인

### 6.1 Ubuntu 24.04 실행

PowerShell에서 실행.

```powershell
wsl -d Ubuntu-24.04
```

### 6.2 Ubuntu 내부에서 실행

```bash
cat /etc/os-release
```

### 6.3 기대 결과

```text
VERSION_ID="24.04"
VERSION_CODENAME=noble
```

### 6.4 사용자 확인

```bash
whoami
pwd
```

### 6.5 기대 결과 예시

```text
john
/home/john
```

---

## 7. Ubuntu 24.04 기본 패키지 설치

### 7.1 패키지 업데이트

Ubuntu 24.04 내부에서 실행.

```bash
sudo apt update
sudo apt full-upgrade -y
```

### 7.2 기본 개발 도구 설치

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

### 7.3 확인

```bash
git --version
curl --version
ssh -V
```

---

## 8. 기존 Ubuntu 홈 디렉터리 압축

### 8.1 기존 Ubuntu 실행

PowerShell에서 실행.

```powershell
wsl -d Ubuntu
```

### 8.2 기존 Ubuntu 내부에서 백업용 디렉터리 생성

```bash
mkdir -p /mnt/c/wsl-migrate
```

### 8.3 홈 디렉터리 압축

```bash
cd ~

tar \
  --exclude='.cache' \
  --exclude='node_modules' \
  --exclude='.npm/_cacache' \
  --exclude='.local/share/Trash' \
  -czpf /mnt/c/wsl-migrate/home-$USER.tgz .
```

### 8.4 패키지 목록 저장

```bash
apt-mark showmanual > /mnt/c/wsl-migrate/apt-manual.txt
dpkg -l > /mnt/c/wsl-migrate/dpkg-list.txt
```

### 8.5 결과 확인

```bash
ls -lh /mnt/c/wsl-migrate/
```

### 8.6 기대 결과

```text
home-john.tgz
apt-manual.txt
dpkg-list.txt
```

### 8.7 기존 Ubuntu 종료

```bash
exit
```

---

## 9. Ubuntu 24.04에 홈 디렉터리 복원

### 9.1 Ubuntu 24.04 실행

PowerShell에서 실행.

```powershell
wsl -d Ubuntu-24.04
```

### 9.2 이전 파일 확인

```bash
ls -lh /mnt/c/wsl-migrate/
```

### 9.3 홈 디렉터리 복원

```bash
cd ~

tar -xzpf /mnt/c/wsl-migrate/home-*.tgz -C ~
```

### 9.4 SSH 권한 복구

```bash
chmod 700 ~/.ssh 2>/dev/null || true
chmod 600 ~/.ssh/* 2>/dev/null || true
chmod 644 ~/.ssh/*.pub 2>/dev/null || true
```

### 9.5 GitHub SSH 확인

```bash
ssh -T git@github.com
```

### 9.6 정상 메시지 예시

```text
Hi <username>! You've successfully authenticated, but GitHub does not provide shell access.
```

### 9.7 주의사항

- `node_modules`, `.cache` 등은 복원하지 않고 프로젝트별 재설치 권장
- `~/.ssh/config`에 절대경로가 있으면 사용자명과 경로 확인 필요
- `~/.bashrc`, `~/.profile`, `~/.zshrc` 복원 후 24.04에서 없는 명령이 호출될 수 있으므로 쉘 시작 오류 확인 필요

---

## 10. Git 기본 설정 확인

### 10.1 현재 설정 확인

```bash
git config --global user.name
git config --global user.email
```

### 10.2 비어 있을 때 설정

```bash
git config --global user.name "john"
git config --global user.email "사용자이메일"
```

### 10.3 Git 설정 전체 확인

```bash
git config --global --list
```

---

## 11. systemd 활성화

### 11.1 Ubuntu 24.04 내부에서 실행

```bash
sudo tee /etc/wsl.conf >/dev/null <<'EOF'
[boot]
systemd=true
EOF
```

### 11.2 PowerShell에서 WSL 재시작

```powershell
wsl --shutdown
wsl -d Ubuntu-24.04
```

### 11.3 systemd 확인

Ubuntu 24.04 내부에서 실행.

```bash
systemctl status
```

### 11.4 판단 기준

- `running` 또는 systemd 상태 화면이 나오면 정상
- `System has not been booted with systemd` 메시지가 나오면 `/etc/wsl.conf` 확인 후 `wsl --shutdown` 재실행

---

## 12. Docker Engine 설치

## 12.1 충돌 가능 패키지 제거

Ubuntu 24.04 내부에서 실행.

```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove -y "$pkg" 2>/dev/null || true
done
```

Docker 공식 문서는 Docker 공식 패키지 설치 전 배포판 제공 비공식/충돌 가능 Docker 패키지 제거를 안내함.

>📄출처: [Docker, Install Docker Engine on Ubuntu, 2026, https://docs.docker.com/engine/install/ubuntu/]

### 12.2 필수 패키지 설치

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg
```

### 12.3 Docker GPG 키 등록

```bash
sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

### 12.4 Docker apt 저장소 등록

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
```

### 12.5 Docker 패키지 설치

```bash
sudo apt update

sudo apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
```

### 12.6 현재 사용자에게 Docker 권한 부여

```bash
sudo usermod -aG docker "$USER"
```

### 12.7 WSL 재시작

PowerShell에서 실행.

```powershell
wsl --shutdown
wsl -d Ubuntu-24.04
```

### 12.8 Docker 확인

Ubuntu 24.04 내부에서 실행.

```bash
docker version
docker compose version
```

### 12.9 Docker 서비스 확인

```bash
sudo systemctl status docker
```

### 12.10 Docker 서비스가 중지되어 있을 때

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### 12.11 hello-world 테스트

```bash
docker run --rm hello-world
```

Docker 공식 문서는 Ubuntu Noble 24.04 LTS를 Docker Engine 지원 대상에 포함하며, 설치 검증 명령으로 `hello-world` 컨테이너 실행을 안내함.

>📄출처: [Docker, Install Docker Engine on Ubuntu, 2026, https://docs.docker.com/engine/install/ubuntu/]

---

## 13. 기존 개발 프로젝트 확인

### 13.1 작업 디렉터리 확인

```bash
ls -la ~/workground
```

### 13.2 agent-room 프로젝트 확인

```bash
cd ~/workground/zagents-room
ls -la
```

### 13.3 Git 상태 확인

```bash
git status --short
```

### 13.4 의존 런타임 파일 확인

```bash
ls -la .env docker-compose.yml
```

### 13.5 주의사항

- `.env`는 비밀값 포함 가능성이 있으므로 Git 커밋 금지
- `data/`는 컨테이너 런타임 데이터이므로 무분별한 소유권 변경 금지
- `.sisyphus/`는 로컬 agent 세션 상태로 취급
- Docker Compose 기반 프로젝트는 실제 기동 전 `docker compose config --quiet` 검증 우선

---

## 14. Docker Compose 프로젝트 검증

### 14.1 Compose 문법 검증

```bash
docker compose config --quiet
```

### 14.2 browser profile 포함 검증

```bash
docker compose --profile browser config --quiet
```

### 14.3 서비스 기동

```bash
docker compose up -d
```

### 14.4 상태 확인

```bash
docker compose ps
```

### 14.5 로그 확인

```bash
docker compose logs --tail=100
```

### 14.6 기대 상태

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

---

## 15. Ubuntu 24.04를 기본 WSL 배포판으로 변경

### 15.1 PowerShell에서 실행

```powershell
wsl --set-default Ubuntu-24.04
```

### 15.2 확인

```powershell
wsl -l -v
```

### 15.3 기대 결과

```text
NAME            STATE           VERSION
* Ubuntu-24.04   Running         2
  Ubuntu         Stopped         2
```

### 15.4 기본 진입 확인

```powershell
wsl
```

Ubuntu 내부에서 확인.

```bash
cat /etc/os-release
```

기대 결과.

```text
VERSION_ID="24.04"
```

>📄출처: [Microsoft, WSL 기본 명령, 2025, https://learn.microsoft.com/ko-kr/windows/wsl/basic-commands]

---

## 16. 기존 Ubuntu 유지 기간

### 16.1 권장 유지 기간

- 최소 1~2주 유지
- 개발 프로젝트, Docker Compose, Git, SSH, 에디터 연동, 자동화 스크립트 검증 후 제거 판단

### 16.2 기존 Ubuntu 실행 방법

```powershell
wsl -d Ubuntu
```

### 16.3 기존 Ubuntu 삭제 금지 조건

- 24.04에서 Docker가 정상 동작하지 않는 상태
- 24.04에서 프로젝트 빌드 실패 상태
- 24.04에서 SSH/Git 인증 미완료 상태
- 24.04에서 `.env`, 인증 파일, 개발 스크립트 누락 상태
- 20.04 백업 tar 파일 미확인 상태

---

## 17. 기존 Ubuntu 제거

## 17.1 최종 검증 체크리스트

Ubuntu 24.04에서 실행.

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

### 17.2 기존 Ubuntu 제거

PowerShell에서 실행.

```powershell
wsl --unregister Ubuntu
```

### 17.3 주의사항

- `wsl --unregister Ubuntu`는 기존 Ubuntu 배포판의 데이터, 설정, 설치 소프트웨어를 영구 삭제
- 삭제 후 복구는 `D:\wsl-backup\ubuntu-20.04-backup.tar` 백업 파일에 의존
- 삭제 전 백업 파일 존재 여부를 반드시 확인

>📄출처: [Microsoft, WSL 기본 명령, 2025, https://learn.microsoft.com/ko-kr/windows/wsl/basic-commands]

---

## 18. 롤백 절차

## 18.1 Ubuntu 24.04 전환 후 문제가 있을 때 기본 배포판 원복

PowerShell에서 실행.

```powershell
wsl --set-default Ubuntu
wsl
```

### 18.2 백업 파일로 기존 Ubuntu 복구가 필요할 때

기존 `Ubuntu`가 삭제된 경우에만 사용.

```powershell
mkdir D:\wsl\Ubuntu-20.04-Restore
wsl --import Ubuntu-20.04-Restore D:\wsl\Ubuntu-20.04-Restore D:\wsl-backup\ubuntu-20.04-backup.tar --version 2
wsl -d Ubuntu-20.04-Restore
```

### 18.3 복구 후 기본값 지정

```powershell
wsl --set-default Ubuntu-20.04-Restore
```

>📄출처: [Microsoft, WSL 기본 명령, 2025, https://learn.microsoft.com/ko-kr/windows/wsl/basic-commands]

---

## 19. 자주 발생하는 문제와 조치

## 19.1 `wsl --install -d Ubuntu-24.04` 실패

### 증상

```text
Invalid distribution name
```

### 조치

```powershell
wsl --update
wsl --shutdown
wsl --list --online
```

`Ubuntu-24.04` 정확한 이름 확인 후 재시도.

---

## 19.2 Docker 명령이 권한 오류로 실패

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
wsl -d Ubuntu-24.04
```

확인.

```bash
groups
docker run --rm hello-world
```

---

## 19.3 Docker daemon 미기동

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
wsl -d Ubuntu-24.04
```

---

## 19.4 SSH 키 권한 오류

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

## 19.5 기존 프로젝트에서 `node_modules` 누락

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

## 19.6 Compose 프로젝트 포트 충돌

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

이후 Ubuntu 24.04만 실행.

```powershell
wsl -d Ubuntu-24.04
```

---

## 20. 전체 실행 순서 요약

```text
1. wsl --shutdown
2. wsl --export Ubuntu D:\wsl-backup\ubuntu-20.04-backup.tar
3. wsl --list --online
4. wsl --install -d Ubuntu-24.04
5. wsl -d Ubuntu-24.04
6. Ubuntu 24.04 기본 패키지 설치
7. 기존 Ubuntu에서 홈 디렉터리와 패키지 목록 백업
8. Ubuntu 24.04에서 홈 디렉터리 복원
9. SSH/Git 확인
10. systemd 활성화
11. Docker Engine 설치
12. Docker hello-world 검증
13. 기존 프로젝트 검증
14. docker compose config --quiet
15. docker compose up -d
16. wsl --set-default Ubuntu-24.04
17. 1~2주 운영 검증
18. 필요 시 wsl --unregister Ubuntu
```

---

## 21. 최종 체크리스트

| 구분 | 확인 명령 | 완료 |
|---|---|---|
| WSL 백업 | `dir D:\wsl-backup` |  |
| 24.04 설치 | `wsl -l -v` |  |
| Ubuntu 버전 | `cat /etc/os-release` |  |
| Git | `git --version` |  |
| SSH | `ssh -T git@github.com` |  |
| systemd | `systemctl status` |  |
| Docker | `docker version` |  |
| Compose | `docker compose version` |  |
| Docker 테스트 | `docker run --rm hello-world` |  |
| 프로젝트 검증 | `docker compose config --quiet` |  |
| 프로젝트 기동 | `docker compose up -d` |  |
| 기본 배포판 전환 | `wsl --set-default Ubuntu-24.04` |  |
| 기존 Ubuntu 보존 | `wsl -l -v` |  |

---

## 22. 권장 운영 기준

- 기존 Ubuntu 직접 업그레이드보다 신규 Ubuntu 24.04 배포판 병행 설치 방식 우선
- Docker 데이터 디렉터리 직접 복사보다 24.04에서 Docker 재설치 후 컨테이너 재생성 우선
- 프로젝트 소스는 Git 기준 복구 가능 상태 유지
- `.env`, SSH 키, 로컬 인증정보는 별도 확인
- 기존 Ubuntu 삭제는 최소 1~2주 실사용 검증 후 수행
- 문제 발생 시 `wsl --set-default Ubuntu`로 즉시 원복
