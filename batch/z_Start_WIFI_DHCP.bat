@echo off
setlocal

SET WIFI_NAME=WI-FI
SET WIFI_DNS1=8.8.8.8
SET WIFI_DNS2=8.8.4.4
SET WIFI_IP_COMMENT=DHCP

TITLE DHCP Setting

@echo.
@echo [Setting] Start - %WIFI_IP_COMMENT% 
@echo.

@echo [Setting] IPAddress - DHCP
@echo.

netsh interface ipv4 set address "%WIFI_NAME%" source=dhcp
ping 127.0.0.1 >nul 2>nul

@echo [Setting] DNS Server IP - %WIFI_DNS1%, %WIFI_DNS2%
@echo.

netsh interface ipv4 set dnsservers name="%WIFI_NAME%" static "%WIFI_DNS1%" primary >nul 2>nul
ping -n 4 127.0.0.1 >nul 2>nul

netsh interface ipv4 add dnsservers name="%WIFI_NAME%" "%WIFI_DNS2%" index=2 >nul 2>nul
ping -n 2 127.0.0.1 >nul 2>nul

@echo [Setting] End - %WIFI_IP_COMMENT% 
@echo.

@echo [Check] Ethernet Config  - name: %WIFI_NAME%
@echo.

netsh interface ipv4 show config name="%WIFI_NAME%"
@echo.
ping -n 2 127.0.0.1 >nul 2>nul


@echo [Check] Puiblic DNS Resolve
@echo.
nslookup -q=a naver.com %WIFI_DNS1%
@echo.
nslookup -q=a naver.com %WIFI_DNS2%
@echo.

ping  %WIFI_DNS1%
ping  %WIFI_DNS2%

endlocal
