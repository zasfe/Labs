@echo off
REM 변수 지역화
setlocal
ipconfig /flushdns >nul
ipconfig /flushdns >nul

set inn=%1

echo %inn% | findstr . > %temp%\dnstemp.txt
FOR /F "eol= tokens=1 " %%i in (%temp%\dnstemp.txt) do set in=%%i
IF EXIST "%temp%\dnstemp.txt" del "%temp%\dnstemp.txt"

REM %in%가 널이면 변수 지역화를 해제하고 end로 점프
if [%in%]==[] endlocal & goto end



echo ================================================================
changecolor lightgreen /Q
echo 입력한 도메인명 :  %in% 

nslookup -ty=ns %in% > nul 2>&1

changecolor white /Q
echo -----[[ 도메인 네임서버 ]]---------------------------------
nslookup -ty=ns %in% 2>nul  | findstr "="
REM whois %in% 2>nul | findstr /i /C:"Name Server"
nslookup -ty=SOA %in% 2>nul | findstr "TTL"

changecolor white /Q
echo -----[[ 메일 서버 ]]--------------------------------------------
REM nslookup -ty=mx %in% 2>nul | findstr "MX" | findstr /C:"."
nslookup -ty=mx %in% 2>nul | findstr "MX" | findstr /C:"." > %temp%\mx.txt
SORT "%temp%\mx.txt"
FOR /F "eol=; tokens=8 delims=, " %%i in ('SORT %temp%\mx.txt') do nslookup -type=all %%i 2>nul | findstr %%i | findstr /v IPv6
IF EXIST "%temp%\mx.txt" del "%temp%\mx.txt"

changecolor white /Q
echo -----[[ 웹 서버 ]]---------------------------------
REM nslookup -ty=a %in% 2>nul
REM nslookup -ty=a www.%in% 2>nul

for /f "tokens=1,2,3,* delims=: " %%a in ('nslookup -ty^=a %%in%% 2^>nul ^| findstr -n . ^| findstr /R "^[5]:"') do @echo %in% = %%c

for /f "tokens=1,2,3,* delims=: " %%a in ('nslookup -ty^=a www.%%in%% 2^>nul ^| findstr -n . ^| findstr /R "^[5]:"') do @echo www.%in% = %%c

changecolor white /Q
echo -----[[ ping 테스트 ]]----------------------------------------
changecolor white /Q
REM ping -n 1 -w 1000 %in% | findstr /v statistics | findstr /v Approximate | findstr /v /C:"," | findstr /v /C:"통계" | findstr /v /C:"왕복" | findstr .
for /f "tokens=1,* delims=:" %%a in ('ping -w 1000 -n 1 %%in%% ^| findstr -n . ^| findstr /R "^[23]:"') do @echo %%b
changecolor white /Q
echo -----[[ ping 테스트, www있는 경우 ]]--------------------------
changecolor white /Q
REM ping -n 1 -w 1000 www.%in% | findstr /v statistics | findstr /v Approximate | findstr /v /C:"," | findstr /v /C:"통계" | findstr /v /C:"왕복" | findstr .
for /f "tokens=1,* delims=:" %%a in ('ping -w 1000 -n 1 www.%%in%% ^| findstr -n . ^| findstr /R "^[23]:"') do @echo %%b


changecolor white /Q
echo -----[[ HTTP 접속 테스트 ]]-----------------------------------
changecolor lightgreen /Q
echo connection....   http://%in%/
REM tinyget -srv:%in% -uri:/ -h 
changecolor white /Q
REM curl http://%in%/ --insecure --head --location --user-agent "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.14 (KHTML, like Gecko) Chrome/24.0.1292.0 Safari/537.14"  --connect-timeout 5
curl http://%in%/ --insecure --head --user-agent "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.14 (KHTML, like Gecko) Chrome/24.0.1292.0 Safari/537.14"  --connect-timeout 5 --retry 1 --retry-max-time 5

REM --insecure: 
REM --head: header  정보만
REM --location: 리다이렉트 연결까지함


changecolor lightgreen /Q
echo connection....   http://www.%in%/
REM tinyget -srv:www.%in% -uri:/ -h  
changecolor white /Q
REM curl http://www.%in%/ --insecure --head --location --user-agent "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.14 (KHTML, like Gecko) Chrome/24.0.1292.0 Safari/537.14"  --connect-timeout 5
curl http://www.%in%/ --insecure --head --user-agent "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.14 (KHTML, like Gecko) Chrome/24.0.1292.0 Safari/537.14"  --connect-timeout 5 --retry 1 --retry-max-time 5

REM changecolor white /Q
REM echo -----[[ HTTPS 접속 테스트 ]]----------------------------------
REM changecolor lightgreen /Q
REM echo connection....   https://%in%/
REM changecolor white /Q
REM curl https://%in%/ --insecure --head --location --user-agent "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.14 (KHTML, like Gecko) Chrome/24.0.1292.0 Safari/537.14" --connect-timeout 5
REM curl https://%in%/ --insecure --head --user-agent "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.14 (KHTML, like Gecko) Chrome/24.0.1292.0 Safari/537.14" --connect-timeout 5

REM changecolor lightgreen /Q
REM echo connection....   https://www.%in%/
REM changecolor white /Q
REM REM curl https://www.%in%/ --insecure --head --location --user-agent "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.14 (KHTML, like Gecko) Chrome/24.0.1292.0 Safari/537.14"  --connect-timeout 5
REM curl https://www.%in%/ --insecure --head --user-agent "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.14 (KHTML, like Gecko) Chrome/24.0.1292.0 Safari/537.14"  --connect-timeout 5

changecolor white /Q
echo -----[[ 웹 서버 IP 상세정보 ]]---------------------------------
REM nslookup -ty=a %in% 2>nul
REM nslookup -ty=a www.%in% 2>nul

for /f "tokens=1,2,3,* delims=: " %%a in ('nslookup -ty^=a %%in%% 2^>nul ^| findstr -n . ^| findstr /R "^[5]:"') do (
	@echo  - %in% = %%c
	@echo.
	curl http://ipinfo.io/%%c/
)
for /f "tokens=1,2,3,* delims=: " %%a in ('nslookup -ty^=a www.%%in%% 2^>nul ^| findstr -n . ^| findstr /R "^[5]:"') do (
	@echo  - %in% = %%c
	@echo.
	curl http://ipinfo.io/%%c/
)

changecolor white /Q
echo ================================================================

goto end

:end
endlocal
