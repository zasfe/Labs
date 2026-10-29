# Docker Compose 통합 구성
**기준 환경**: Linux + Docker Compose v2, 공개 도메인, 외부 TCP 80/443 접근 가능

호스트에 Certbot을 설치하지 않고, Docker Compose에서 인증서 발급·갱신과 whoami HTTPS 서비스를 모두 관리합니다.

- Certbot: 최초 인증서 발급 및 자동 갱신
- whoami: HTTPS 직접 제공, 리버스 프록시 없음
- 인증서: Docker Volume에 영구 저장
- 갱신: 12시간마다 확인하고, 인증서가 변경되면 whoami를 재시작

최초 발급과 갱신에는 HTTP-01 인증을 사용합니다. 이를 위해 Certbot이 TCP 80을 사용하고, whoami는 TCP 443을 사용합니다.

**1. docker-compose.yml**
```YAML
services:
  certbot:
    image: certbot/certbot:latest
    container_name: certbot
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - letsencrypt:/etc/letsencrypt
    environment:
      DOMAIN: whoami.example.com
      EMAIL: admin@example.com
    entrypoint: /bin/sh
    command:
      - -c
      - |
        set -eu
        while :; do
          if [ ! -s "/etc/letsencrypt/live/$${DOMAIN}/fullchain.pem" ]; then
            certbot certonly --standalone \
              --non-interactive \
              --agree-tos \
              --email "$${EMAIL}" \
              -d "$${DOMAIN}"
          else
            certbot renew --standalone --quiet
          fi
          sleep 12h
        done

  whoami:
    image: traefik/whoami:latest
    container_name: whoami
    restart: unless-stopped
    depends_on:
      - certbot
    ports:
      - "443:443"
    volumes:
      - letsencrypt:/etc/letsencrypt:ro
    entrypoint: /bin/sh
    command:
      - -c
      - |
        set -eu
        CERT=/etc/letsencrypt/live/whoami.example.com/fullchain.pem
        KEY=/etc/letsencrypt/live/whoami.example.com/privkey.pem

        while [ ! -s "$$CERT" ] || [ ! -s "$$KEY" ]; do
          echo "Waiting for Let's Encrypt certificate..."
          sleep 5
        done

        while :; do
          /whoami --port=443 --cert="$$CERT" --key="$$KEY" &
          PID=$$!

          OLD=$$(sha256sum "$$CERT" "$$KEY")

          while kill -0 "$$PID" 2>/dev/null; do
            sleep 60
            NEW=$$(sha256sum "$$CERT" "$$KEY")
            if [ "$$OLD" != "$$NEW" ]; then
              echo "Certificate changed, restarting whoami..."
              kill "$$PID"
              wait "$$PID" || true
              break
            fi
          done
        done

volumes:
  letsencrypt:
```
**2. 실행**
도메인과 이메일을 실제 값으로 변경한 다음 실행합니다.

```bash
docker compose up -d
docker compose logs -f certbot whoami
```

**3. HTTPS 확인**
```bash
curl -Iv https://whoami.example.com
```

**4. 구성 특징**

| 항목 | 설정 |
|--|--|
| HTTP 인증 | Certbot TCP 80 |
| HTTPS 서비스 | whoami TCP 443 |
| 인증서 발급 | Let's Encrypt |
| 인증서 갱신 확인 | 12시간 간격 |
| 갱신 인증서 반영 | 변경 감지 후 프로세스 재시작 |
| 인증서 보관 | Docker Named Volume |


**주의**: 이 구성은 Docker 이미지에 /bin/sh와 /whoami 실행 파일이 존재한다는 전제입니다. 또한 최초 인증서 발급이 실패하면 Certbot 컨테이너가 종료되므로, DNS와 방화벽을 확인한 후 docker compose restart certbot으로 다시 시도해야 합니다. whoami 이미지의 실행 파일 경로도 배포 전에 확인하는 것이 좋습니다.

별도 프록시	불필요
