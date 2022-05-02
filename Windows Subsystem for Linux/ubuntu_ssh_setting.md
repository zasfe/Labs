# Windows Subsystem for Linux 에서 Ubuntu로 SSH 서버 자동 구동시키기


## 1. WSL 설치(리부팅 필요) (Host PC)

`dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart`


## 2. Microsoft Store에서 Ubuntu App 설치 (Host PC)

```batch
REM wsl 업데이트
wsl --update

REM 설치 가능한 이미지 목록 보기
REM wsl --list --online

REM Ubuntu 이미지 설치
wsl --install -d Ubuntu
```


## 3. Ubuntu에서 SSH 서버 재설치 (WSL Ubuntu)

```bash
sudo apt-get update; 
sudo apt-get upgrade; 
sudo apt-get purge openssh-server; 
sudo apt-get install openssh-server;
```

## 4. SSH config 수정 (WSL Ubuntu)

```
cp -pa /etc/ssh/sshd_config /etc/ssh/sshd_config_bak
echo <<EOF > /etc/ssh/sshd_config
Port 22
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile      .ssh/authorized_keys .ssh/authorized_keys2
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
UseDNS no
AcceptEnv LANG LC_*
Subsystem       sftp    /usr/lib/openssh/sftp-server
EOF
```

## 5. SSH 서버 시작 스크립트 작성 (Host PC)

```bat
@echo off

REM 기본 사용자를 root로 변경
ubuntu config --default-user root

REM sshd: no hostkeys available -- exiting. 에러 방지
"C:\Windows\System32\bash.exe" -c "ssh-keygen -A"

REM ssh 서비스 재시작
"C:\Windows\System32\bash.exe" -c "sudo bash service ssh restart"

REM 기본 사용자를 root로 변경
ubuntu config --default-user root
```

## 6. 부팅할 때 자동으로 실행하도록 윈도우 스케줄 등록 (Host PC)





## 참고

* [nstall Linux on Windows with WSL](https://docs.microsoft.com/en-us/windows/wsl/install)




