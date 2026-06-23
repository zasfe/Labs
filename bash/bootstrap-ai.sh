#!/usr/bin/env bash

set -euo pipefail

BASE_URL="https://raw.githubusercontent.com/zasfe/Labs/refs/heads/master/prompt"

mkdir -p mydocs/{orders,plans,working,report,feedback,tech,spec,troubleshootings}
mkdir -p mydocs/plans/archives

curl -fsSLO "${BASE_URL}/AGENTS.md"
curl -fsSLO "${BASE_URL}/info-Hyper-Waterfall.md"

echo "프로젝트 초기화 완료"
