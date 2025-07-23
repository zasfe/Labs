#!/bin/bash

OTP_SECRET_PATH="$HOME/.google_authenticator"
USER=$(whoami)
HOST=$(hostname)

# 명령어 확인
if ! command -v google-authenticator &>/dev/null || ! command -v qrencode &>/dev/null; then
    echo "[ERROR] 'google-authenticator'와 'qrencode'가 모두 설치되어 있어야 합니다."
    exit 1
fi

# OTP 키가 없으면 생성
if [ ! -f "$OTP_SECRET_PATH" ]; then
    echo "[INFO] Google OTP 키가 없어 새로 생성합니다."

    # OTP 키 생성
    google-authenticator -t -d -f -r 3 -R 30 -W > /dev/null

    # 비밀키 추출
    SECRET=$(grep '^[A-Z2-7]\{16\}$' "$OTP_SECRET_PATH")
    if [ -z "$SECRET" ]; then
        echo "[ERROR] 비밀키 추출 실패"
        exit 1
    fi

    # OTP URL 생성
    URL="otpauth://totp/${USER}@${HOST}?secret=${SECRET}&issuer=${HOST}"

    # QR코드 표시
    echo "[INFO] Google OTP QR 코드:"
    qrencode -t ANSIUTF8 "$URL"

    echo "[INFO] 수동 등록용 비밀키: $SECRET"
else
    echo "[INFO] 이미 Google OTP 키가 존재합니다."
fi
