#!/usr/bin/env bash

# 1) bash <(curl -fsSL https://raw.githubusercontent.com/zasfe/Labs/refs/heads/master/bash/bootstrap-ai.sh)
# 2) bash <(wget -qO- https://raw.githubusercontent.com/zasfe/Labs/refs/heads/master/bash/bootstrap-ai.sh)
# 3) curl -fsSLO https://raw.githubusercontent.com/zasfe/Labs/refs/heads/master/bash/bootstrap-ai.sh
#    chmod +x bootstrap-ai.sh
#    ./bootstrap-ai.sh

set -euo pipefail

BASE_URL="https://raw.githubusercontent.com/zasfe/Labs/refs/heads/master/prompt"

mkdir -p mydocs/{orders,plans,working,report,feedback,tech,spec,troubleshootings}
mkdir -p mydocs/plans/archives

curl -fsSLO "${BASE_URL}/AGENTS.md"
curl -fsSLO "${BASE_URL}/info-Hyper-Waterfall.md"

echo "프로젝트 초기화 완료"
