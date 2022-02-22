# discourse

> QA 포럼형 사이트

- 솔루션 정보
   * 홈페이지: https://www.discourse.org/
   * 업체명: Civilized Discourse Construction Kit, Inc.
   * git: [https://github.com/discourse/discourse](https://github.com/discourse/discourse)
   * 사용 예시: [https://discourse.joplinapp.org/latest](https://discourse.joplinapp.org/latest)
- 요금제 (https://www.discourse.org/pricing)
   * discourse 모든 기능은 기본 제공, 저장 공간과 메일 발송 개수 등으로 구별됨
   * STANDARD, $100/월, 스토리지 20GB, 메일 발송 10만
   * BUSINESS, $300/월, 스토리지 100GB, 메일 발송 30만
   * ENTERPRISE, Contact us, 스토리지 200GB 이상, 메일 발송 1.5M 이상
- Open Source 에디션 라이선스
   * GNU General Public License Version 2.0 (or later) (복제, 배포, 수정의 권한 허용, 라이선스 고지 필요)
   * URL: [https://github.com/discourse/discourse/blob/main/LICENSE.txt](https://github.com/discourse/discourse/blob/main/LICENSE.txt)
   * GNU2 라이선스 한글 설명: https://www.olis.or.kr/license/Detailselect.do?lId=1004
- 테스트 구축(Open Source 에디션)
   * 구성 환경
      * 가상 서버: AWS EC2 t2.micro(루트볼륨:30GB, 월 9.70 USD, 서울 리전)
      * 이미지: Amazon Linux 2
      * 설치 버전: discourse, 2.9.0.beta2, Docker Version
      * 메일링 시스템: [Mailjet](https://www.mailjet.com/pricing) (mail send service)을 사용
   * 설치(Docker based): [https://github.com/discourse/discourse/blob/main/docs/INSTALL-cloud.md](https://github.com/discourse/discourse/blob/main/docs/INSTALL-cloud.md)


## 설치

* 사전 준비
   * 메모리가 최소 2GB 이상이 필요합니다.
   * Docker가 설치되어 있어야 합니다.
   * 무료 인증서 적용을 위해서 도메인을 외부에서 접속할 수 있어야 합니다. (무료 인증서 적용을 위해)

> 여기에서는 discourse.zasfe.com을 사용하였습니다.  

### git 설치

```bash
sudo yum install git
```

### Install Discourse (official Dopcker setup guide)

```bash
sudo -s
git clone https://github.com/discourse/discourse_docker.git /var/discourse
cd /var/discourse
```

### Edit Discourse Configuration

> Mailjet 에서 메일 발송 세팅을 먼저 하셔야 합니다.  

```bash
### Setting Up Email
#### Mailjet — 6k emails/month (200 max/day)
#### SMTP Server: in-v3.mailjet.com
#### Port: 25 or 587
#### Username: [자동 발급된 사용자 이름]
#### Password: [자동 발급된 사용자 암호]


cd /var/discourse
./discourse-setup

Hostname for your Discourse? [discourse.example.com]: discourse.zasfe.com
Email address for admin account(s)? [me@example.com,you@example.com]: [Mailjet 관리 계정 메일주소]
SMTP server address? [smtp.example.com]: [Mailjet 제공하는 SMTP Server]
SMTP port? [587]: 587
SMTP user name? [user@example.com]: [Mailjet 자동 발급된 사용자 이름]
SMTP password? [pa$$word]: [ Mailjet자동 발급된 사용자 암호]
Let's Encrypt account email? (ENTER to skip) [me@example.com]: [인증서 발급용 메일주소]
Optional Maxmind License key () [xxxxxxxxxxxxxxxx]:

```



## 플러그인 

### 설치 방법
    
> 플러그인 설치는 Github 또는 Bitbuchet 를 복사하는 방식으로 진행을 함
    
1. 컨테이너 `app.yml` 파일을 수정합니다.
```bash
cd /var/discourse
nano containers/app.yml
```

2. 플러그인 레포지토리 URL을 추가합니다. 

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/discourse/docker_manager.git
          - git clone https://github.com/discourse/discourse-spoiler-alert.git
```

3. 컨테이너 사이트를 다시 만듭니다. 

```bash
cd /var/discourse
./launcher rebuild app
```

### 삭제하는 방법

`app.yml` 파일에서 삭제하려는 플러그인 레포지토리를 지우고 다시 만듭니다. 

1. `app.yml` 파일에서 `git clone https://github.com/...` 부분을 삭제합니다.
2. 컨테이너 사이트를 다시 만듭니다.

```bash
cd /var/discourse
./launcher rebuild app
```


## 팁

### 사이트 사설 인증서 적용 방법

> 사용할 도메인이 무료 인증서 설치 환경이 구성되어 있지 않은 경우(웹서버 외부 접속X, 도메인 CNAME 설정X) 인증서 파일이 0MB로  표시됩니다

1. 설치 환경 정보

> **Docker 마운트 정보**
> - 서버: "/var/discourse/shared/standalone" => 도커내 경로: "/shared"
> - 서버: "/var/discourse/shared/standalone/log/var-log" => 도커내 경로: "/var/log"

2. 사설 인증서 적용 방법(예시 도메인: discourse.zasfe.com)

```bash
# 도커 컨테이너 BASH 접속
sudo docker exec -it app bash

# (in-docker) SSL 인증서 폴더 이동
cd /shared/ssl

# (in-docker) 자체 인증서용 키 파일 생성 (패스워드: 1234 입력)
openssl genrsa -des3 -out discourse.zasfe.com_password.key 2048

# (in-docker) 자체 인증서용 CSR 파일 생성 (패스워드: 1234 입력)
openssl req -new -key discourse.zasfe.com_password.key -out discourse.zasfe.com.csr

# (in-docker) 웹서버에서 인증서 추가 실행시 입력하는 패스워드 삭제 (패스워드: 1234 입력)
openssl rsa -in discourse.zasfe.com_password.key -out discourse.zasfe.com_nopass.key

# (in-docker) 추가되는 인증서 파일 이름 변경
cp -pa discourse.zasfe.com_nopass.key discourse.zasfe.com.key

# (in-docker) 자체 인증서용 CRT 파일 생성(인증기간 365일 설정)
openssl x509 -req -days 365 -in discourse.zasfe.com.csr -signkey discourse.zasfe.com.key  -out discourse.zasfe.com.crt

# (in-docker) 도커 컨테이너 접속 종료
exit
```

### Docker에서 인증서 설정 동작 방식

> letsencrypt용 nginx 구동 → 설정 도메인으로 인증서 발급 API호출 → letsencrypt용 nginx 중지

```bash
## /etc/runit/1.d/letsencrypt - letsencrypt setting

#!/bin/bash
/usr/sbin/nginx -c /etc/nginx/letsencrypt.conf

issue_cert() {
  LE_WORKING_DIR="${LETSENCRYPT_DIR}" /shared/letsencrypt/acme.sh --issue $2 -d discourse.zasfe.com --keylength $1 -w /var/www/discourse/public
}

cert_exists() {
  [[ "$(cd /shared/letsencrypt/discourse.zasfe.com$1 && openssl verify -CAfile <(openssl x509 -in ca.cer) fullchain.cer | grep "OK")" ]]
}

########################################################
# RSA cert
########################################################
issue_cert "4096"

if ! cert_exists ""; then
  # Try to issue the cert again if something goes wrong
  issue_cert "4096" "--force"
fi

LE_WORKING_DIR="${LETSENCRYPT_DIR}" /shared/letsencrypt/acme.sh \
  --installcert \
  -d discourse.zasfe.com \
  --fullchainpath /shared/ssl/discourse.zasfe.com.cer \
  --keypath /shared/ssl/discourse.zasfe.com.key \
  --reloadcmd "sv reload nginx"

########################################################
# ECDSA cert
########################################################
issue_cert "ec-256"

if ! cert_exists "_ecc"; then
  # Try to issue the cert again if something goes wrong
  issue_cert "ec-256" "--force"
fi

LE_WORKING_DIR="${LETSENCRYPT_DIR}" /shared/letsencrypt/acme.sh \
  --installcert --ecc \
  -d discourse.zasfe.com \
  --fullchainpath /shared/ssl/discourse.zasfe.com_ecc.cer \
  --keypath /shared/ssl/discourse.zasfe.com_ecc.key \
  --reloadcmd "sv reload nginx"

if cert_exists "" || cert_exists "_ecc"; then
  grep -q 'force_https' "/var/www/discourse/config/discourse.conf" || echo "force_https = 'true'" >> "/var/www/discourse/config/discourse.conf"
fi

/usr/sbin/nginx -c /etc/nginx/letsencrypt.conf -s stop
```


## 참고 링크
* https://github.com/discourse/discourse/blob/main/docs/INSTALL-email.md
* https://meta.discourse.org/t/setting-up-https-support-with-lets-encrypt/40709
* [https://meta.discourse.org/t/setting-up-https-support-with-lets-encrypt/40709](https://meta.discourse.org/t/setting-up-https-support-with-lets-encrypt/40709)
* [https://github.com/acmesh-official/acme.sh](https://github.com/acmesh-official/acme.sh)

