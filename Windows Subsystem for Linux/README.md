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
    * x64 머신용 최신 WSL2 Linux 커널 업데이트 패키지[다운로드](https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi)

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

  * 참고 : WSL에서 ML용 GPU 가속 시작[learn.microsoft.com](https://learn.microsoft.com/ko-kr/windows/wsl/tutorials/gpu-compute)

```batch
curl https://get.docker.com | sh
sudo service docker start
```

### 2) 도커 설치 - Docker Desktop (Host PC)

  * Docker Desktop 설치[learn.microsoft.com](https://learn.microsoft.com/ko-kr/windows/wsl/tutorials/wsl-containers#install-docker-desktop)


