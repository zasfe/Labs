#!/usr/bin/env bash
#
# template-provision.sh — Template Ubuntu 안에서 1회 실행
#
# 역할: Claude Code + Codex + 개발도구를 굽고, Windows 연동을 차단한다.
# 실행 위치: Ubuntu-26.04-Sandbox-Template 내부 (root 또는 sudo 가능 사용자)
#
set -euo pipefail

USER_NAME="${1:-john}"

echo "=== [1/6] 기본 패키지 ==="
sudo apt-get update
sudo apt-get install -y \
  git curl ca-certificates tar gzip jq ripgrep \
  build-essential python3

echo "=== [2/6] Node.js (Codex/일부 도구용, nvm) ==="
# native installer는 Node 불필요하나, Codex·범용 작업 위해 LTS 설치
if [ ! -d "$HOME/.nvm" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm alias default 'lts/*'

echo "=== [3/6] Claude Code (native installer) ==="
curl -fsSL https://claude.ai/install.sh | bash
# PATH 보장
grep -q '.local/bin' "$HOME/.bashrc" || \
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"

echo "=== [4/6] Codex CLI (standalone installer) ==="
# npm 트랩 회피: 공식 standalone 사용
curl -fsSL https://developers.openai.com/codex/install.sh | bash 2>/dev/null || {
  echo "  standalone 실패 → npm 폴백"
  npm install -g @openai/codex
}

echo "=== [5/6] gitleaks (secret 방어, 무료 오픈소스) ==="
GITLEAKS_VER="8.21.2"
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) GL_ARCH="x64" ;;
  aarch64) GL_ARCH="arm64" ;;
  *) GL_ARCH="x64" ;;
esac
curl -fsSL "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VER}/gitleaks_${GITLEAKS_VER}_linux_${GL_ARCH}.tar.gz" \
  -o /tmp/gitleaks.tar.gz
tar -xzf /tmp/gitleaks.tar.gz -C /tmp gitleaks
sudo install -m 0755 /tmp/gitleaks /usr/local/bin/gitleaks
gitleaks version

echo "=== [6/6] Windows 연동 차단 (/etc/wsl.conf) ==="
sudo tee /etc/wsl.conf >/dev/null <<EOF
[user]
default=${USER_NAME}

[automount]
enabled=false
mountFsTab=false

[interop]
enabled=false
appendWindowsPath=false

[boot]
systemd=true
EOF

echo ""
echo "=== 검증 ==="
which claude codex gitleaks jq git node 2>/dev/null || true
echo ""
echo "Template 구성 완료."
echo "다음: exit 후 PowerShell에서 'wsl --terminate ${HOSTNAME}'"
echo "이후 이 Template은 직접 사용하지 않고 복사(wtest create)만 한다."
