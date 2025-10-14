#!/bin/bash
# PostgreSQL Version-Agnostic Quick Summary

# set -euo pipefail # 이 스크립트는 정보를 수집하는 스크립트이므로 오류 발생 시에도 계속 진행하도록 설정 해제

echo "=== PostgreSQL Universal Quick Summary ==="

# 1. 활성 PostgreSQL 서비스 찾기 및 데이터 경로 추출
# Debian/Ubuntu 계열 (pg_lsclusters 사용)
if command -v pg_lsclusters >/dev/null 2>&1; then
    # 가장 큰 (주요) 클러스터를 찾거나, 단순히 활성 클러스터 중 하나를 선택
    ACTIVE_CLUSTER=$(pg_lsclusters | awk '$5 == "online" {print $1 "/" $2}' | tail -1)
    
    if [ -n "$ACTIVE_CLUSTER" ]; then
        PG_VERSION=$(echo "$ACTIVE_CLUSTER" | cut -d'/' -f1)
        PG_CLUSTER=$(echo "$ACTIVE_CLUSTER" | cut -d'/' -f2)
        
        # pg_lsclusters는 데이터 디렉토리와 포트를 제공
        PG_DATA_DIR=$(pg_lsclusters -h | awk -v v="$PG_VERSION" -v c="$PG_CLUSTER" '$1 == v && $2 == c {print $4}')
        PG_PORT=$(pg_lsclusters -h | awk -v v="$PG_VERSION" -v c="$PG_CLUSTER" '$1 == v && $2 == c {print $3}')

        echo "Status: online (v$PG_VERSION, $PG_CLUSTER)"
    else
        echo "Status: offline (No active clusters found via pg_lsclusters)"
        exit 0
    fi
# RHEL/CentOS/기타 계열 (ps aux 및 환경 변수 사용)
elif command -v psql >/dev/null 2>&1; then
    # psql을 사용하여 포트 및 버전을 직접 질의
    PG_PORT=5432 # 기본 포트 사용 (필요시 수정)
    
    # 활성 psql 연결 확인
    if ss -tan | grep :$PG_PORT | grep ESTAB >/dev/null; then
        
        # psql을 통해 버전과 데이터 디렉토리를 질의
        # PostgreSQL은 기본적으로 'postgres' 계정으로 실행됩니다.
        PG_VERSION_FULL=$(sudo -u postgres psql -p $PG_PORT -t -c 'SELECT version();' 2>/dev/null | grep PostgreSQL | xargs)
        PG_DATA_DIR=$(sudo -u postgres psql -p $PG_PORT -t -c 'SHOW data_directory;' 2>/dev/null | xargs)
        
        if [ -n "$PG_VERSION_FULL" ]; then
            echo "Status: online (Port: $PG_PORT)"
            echo "Version: $PG_VERSION_FULL"
        else
            echo "Status: online, but psql connection failed. Check authentication."
            exit 1
        fi
    else
        echo "Status: offline (No process listening on port $PG_PORT)"
        exit 0
    fi
else
    echo "ERROR: Neither 'pg_lsclusters' nor 'psql' command found. Cannot proceed."
    exit 1
fi

# 2. 공통 정보 출력
if [ -n "$PG_DATA_DIR" ]; then
    echo "Data Dir: $PG_DATA_DIR ($(du -sh "$PG_DATA_DIR" 2>/dev/null | cut -f1))"
fi

if [ -n "$PG_PORT" ]; then
    echo "Connections: $(ss -tan | grep :$PG_PORT | grep ESTAB | wc -l) active"
    echo "Access: External enabled on $(hostname -I | awk '{print $1}'):$PG_PORT"
fi
