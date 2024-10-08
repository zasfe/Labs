#!/usr/bin/env bash

# https://github.com/bahamas10/ysap/blob/main/general/pt004-bash-web-request/http-request

exec 3<>/dev/tcp/ysap.daveeddy.com/80

lines=(
    'GET /ping HTTP/1.1'
    'Host: ysap.daveeddy.com'
    'Connection: close'
    ''
)

printf '%s\r\n' "${lines[@]}" >&3

while read -r data <&3; do
    echo "got server data: $data"
done

exec 3>&-
