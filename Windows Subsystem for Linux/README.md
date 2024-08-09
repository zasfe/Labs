# Windows Subsystem for Linux 사용하기

  * 이전 버전 WSL의 수동 설치 단계 [(learn.Microsoft.com)](https://learn.microsoft.com/ko-kr/windows/wsl/install-manual)

## 1.사전 준비
### 1) WSL 설치(리부팅 필요) (Host PC)

```batch
REM Microsoft-Windows-Subsystem-Linux 기능을 활성화
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

REM VirtualMachinePlatform 기능을 활성화
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

### 2) WSL2 업데이트 (Host PC)

```batch
REM wsl2 업데이트
wsl --update
```
  * wsl2 수동 업데이트
    * x64 머신용 최신 WSL2 Linux 커널 업데이트 패키지 [(다운로드)](https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi)

```batch
REM wsl 기본 버전 변경
wsl --set-default-version 2
```


## 2. WSL OS 구성
### 1) Microsoft Store에서 Ubuntu App 설치 (Host PC)

```batch
REM 설치 가능한 이미지 목록 보기
REM wsl --list --online

REM Ubuntu 이미지 설치
wsl --install -d Ubuntu
```

## 3. WSL 사용 
### 1) 도커 설치 - Docker Desktop 없이 (WSL OS에서 실행)

  * 참고 : WSL에서 ML용 GPU 가속 시작 [(learn.microsoft.com)](https://learn.microsoft.com/ko-kr/windows/wsl/tutorials/gpu-compute)

```batch
curl https://get.docker.com | sh
sudo service docker start
```

### 2) 도커 설치 - Docker Desktop (Host PC)

  * Docker Desktop 설치 [(learn.microsoft.com)](https://learn.microsoft.com/ko-kr/windows/wsl/tutorials/wsl-containers#install-docker-desktop)


## 4. WSL 기타

### 1) /etc/resolv.conf 이슈: host ip 로 설정된 nameserver 도메인 질의 실패함

#### 방법1: (추천) 부팅할때 host pc의 nameserver 설정을 가져와서 /etc/resolv.conf을 재생성.

  * 참고
    * https://gist.github.com/ThePlenkov/6ecf2a43e2b3898e8cd4986d277b5ecf

```configure
# vi /etc/wsl.conf
[network]
hostname = ubuntu
generateHosts = false
generateResolvConf = false

[boot]
## enable systemd
systemd=true
command=/usr/local/bin/boot.sh

## disable systemd
# systemd=false
```

```bash
#!/bin/bash
# 
# /usr/local/bin/boot.sh
# 

# Remove existing "nameserver" lines from /etc/resolv.conf
sed -i '/nameserver/d' /etc/resolv.conf

# Run the PowerShell command to generate "nameserver" lines and append to /etc/resolv.conf
# we use full path here to support boot command with root user
/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Command '(Get-DnsClientServerAddress -AddressFamily IPv4).ServerAddresses | ForEach-Object { "nameserver $_" }' | tr -d '\r'| tee -a /etc/resolv.conf > /dev/null
```

#### 방법2: WSL 2.2.1 이상인 경우 DNS Tunneling 설정 추가

* https://devblogs.microsoft.com/commandline/windows-subsystem-for-linux-september-2023-update/#dns-tunneling

WSL이 인터넷에 연결할 수 없는 한 가지 요인은 Windows 호스트에 대한 DNS 호출이 차단된다는 것입니다. 이는 WSL VM에서 Windows 호스트로 보낸 DNS에 대한 네트워킹 패킷이 기존 네트워킹 구성에 의해 차단되었기 때문입니다. DNS 터널링은 대신 가상화 기능을 사용하여 Windows와 직접 통신하여 이를 수정합니다. 이를 통해 네트워킹 패킷을 보내지 않고도 DNS 이름 요청을 확인할 수 있으므로 VPN, 특정 방화벽 설정 또는 기타 네트워킹 구성이 있어도 더 나은 인터넷 연결을 얻을 수 있습니다. 이 기능은 네트워크 호환성을 개선하여 WSL 내부에서 네트워크 연결이 없는 경우가 줄어들 것입니다.

이 기능은 현재 Windows Insider Canary 및 Release Preview Channel에서만 사용할 수 있으며, 최신 Windows 11, 버전 22H2 업데이트는 여기에서 확인할 수 있습니다. 지금 Windows Insider Program에 가입 하고 기기를 Release Preview Channel에 가입하도록 선택하면 액세스할 수 있습니다 .

```
# C:\Users\<yourusername>\.wslconfig
dnsTunneling=True
# default value: false
```


