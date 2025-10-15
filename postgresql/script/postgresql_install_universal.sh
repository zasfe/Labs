#!/bin/bash
# postgresql_install_universal.sh - PostgreSQL 최신 버전 설치 스크립트 (APT 기반)

# 코드 목적: PostgreSQL 공식 APT 저장소를 추가하고, 사용 가능한 최신 버전을 자동으로 설치하며,
#            기존 시스템의 기본 PostgreSQL 서비스를 비활성화하여 커스텀 설정 준비.
# 필요한 명령 패키지: apt, wget, ca-certificates, curl, gnupg, lsb-release

set -e # 에러 발생시 스크립트 중단

echo "========================================="
echo "PostgreSQL Universal Installation Script"
echo "========================================="

# Root 권한 확인
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# 1. 시스템 업데이트 및 필수 패키지 설치
echo "[1/4] Updating system packages and installing prerequisites..."
apt update && apt upgrade -y
# 설치에 필요한 패키지 목록
REQUIRED_PACKAGES="wget ca-certificates curl gnupg lsb-release"
apt install -y $REQUIRED_PACKAGES

# 2. PostgreSQL 공식 저장소 추가
echo "[2/4] Adding PostgreSQL repository..."
# LSB 릴리스 코드네임 확인
OS_CODENAME=$(lsb_release -cs)
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt '$OS_CODENAME'-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt update

# 3. PostgreSQL 최신 버전 설치 및 버전 확인
echo "[3/4] Installing latest PostgreSQL version..."
# 'postgresql' 메타패키지를 설치하여 최신 버전을 자동으로 가져옴
# 이 스크립트는 APT 기반 시스템(Ubuntu/Debian) 전용입니다.
apt install -y postgresql postgresql-client postgresql-contrib

# 설치된 가장 높은 버전 확인
INSTALLED_VERSIONS=$(dpkg -l | grep -E '^ii.*postgresql-[0-9][\.0-9]' | awk '{print $2}' | grep -oE '[0-9][\.0-9]$' | cut -d'.' -f1 | sort -nr | head -1)
if [ -z "$INSTALLED_VERSIONS" ]; then
    echo "ERROR: PostgreSQL installation failed or version could not be determined."
    exit 1
fi
PG_MAJOR_VERSION=$INSTALLED_VERSIONS
echo "Successfully installed PostgreSQL version: $PG_MAJOR_VERSION"

# 4. 기본 서비스 중지 및 비활성화 (커스텀 데이터 디렉토리/클러스터 설정용)
echo "[4/4] Stopping and disabling default PostgreSQL service..."
# 기본 서비스 이름은 배포판마다 다르지만, 'postgresql' 메타패키지 설치 시 일반적으로 활성화되는 서비스를 찾아 중지
systemctl stop postgresql || true # 실패해도 무시
systemctl disable postgresql || true # 실패해도 무시
systemctl disable "postgresql@${PG_MAJOR_VERSION}-main" 2>/dev/null || true

echo "========================================="
echo "Installation complete. Next, run the data directory change script."
echo "========================================="
