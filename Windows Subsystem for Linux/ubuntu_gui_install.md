# Ubuntu 서버에서 GUI를 설치하는 방법

> 설치는 아래 문서를 참고하세요
> https://github.com/zasfe/Labs/blob/master/Windows%20Subsystem%20for%20Linux/ubuntu_ssh_setting.md

## 1. 데스크탑 환경 설치

```bash
sudo apt install tasksel
```

## 2. 그놈 데스크탑 설치

```bash
sudo tasksel install ubuntu-desktop
```

## 3. 디스플레이 관리자 설치 및 설정

```bash
sudo apt install lightdm
```

## 4. 디스플레이 관리자 실행

```bash
sudo service lightdm start
```

## 5. 디스플레이 관리자 중지

```bash
sudo service lightdm stop
```



