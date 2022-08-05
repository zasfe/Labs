@echo off
REM 변수 지역화
setlocal
ipconfig /flushdns >NULL
ipconfig /flushdns >NULL

set inn=%1

echo %inn% | findstr . > %temp%\dnstemp.txt
FOR /F "eol= tokens=1 " %%i in (%temp%\dnstemp.txt) do set in=%%i
IF EXIST "%temp%\dnstemp.txt" del "%temp%\dnstemp.txt"

REM %in%가 널이면 변수 지역화를 해제하고 end로 점프
if [%in%]==[] endlocal & goto end



echo ================================================================
changecolor lightgreen /Q
echo 입력한 도메인명 :  %in% 

changecolor white /Q
echo -----[[ 도메인 네임서버 주소 ]]---------------------------------
REM nslookup -ty=ns %in% 2>NULL | findstr "="
whois %in% 2>NULL | findstr /i /C:"Name Server"

changecolor white /Q
echo -----[[ 네임서버 갱신주기 ]]------------------------------------
nslookup -ty=SOA %in% 2>NULL | findstr "TTL"

changecolor white /Q
echo -----[[ 메일 서버 ]]--------------------------------------------
REM nslookup -ty=mx %in% 2>NULL | findstr "MX" | findstr /C:"."
nslookup -ty=mx %in% 2>NULL | findstr "MX" | findstr /C:"." > %temp%\mx.txt
SORT "%temp%\mx.txt"
FOR /F "eol=; tokens=8 delims=, " %%i in ('SORT %temp%\mx.txt') do nslookup -type=all %%i 2>NULL | findstr %%i | findstr /v IPv6
IF EXIST "%temp%\mx.txt" del "%temp%\mx.txt"


changecolor white /Q
echo -----[[ ping 테스트 ]]----------------------------------------
changecolor white /Q
REM ping -n 1 %in% | findstr /v statistics | findstr /v Approximate | findstr /v /C:"," | findstr /v /C:"통계" | findstr /v /C:"왕복" | findstr .
for /f "tokens=1,* delims=:" %%a in ('ping -n 1 %%in%% ^| findstr -n . ^| findstr /R "^[23]:"') do @echo %%b
changecolor white /Q
echo -----[[ ping 테스트, www있는 경우 ]]--------------------------
changecolor white /Q
REM ping -n 1 www.%in% | findstr /v statistics | findstr /v Approximate | findstr /v /C:"," | findstr /v /C:"통계" | findstr /v /C:"왕복" | findstr .
for /f "tokens=1,* delims=:" %%a in ('ping -n 1 %%in%% ^| findstr -n . ^| findstr /R "^[23]:"') do @echo %%b


changecolor white /Q
echo -----[[ HTTP 접속 테스트 ]]-----------------------------------
changecolor lightgreen /Q
echo connection....   http://%in%/
REM tinyget -srv:%in% -uri:/ -h 
changecolor white /Q
REM curl http://%in%/ --insecure --head --location --user-agent "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.14 (KHTML, like Gecko) Chrome/24.0.1292.0 Safari/537.14"  --connect-timeout 5
curl http://%in%/ --insecure --head --user-agent "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.14 (KHTML, like Gecko) Chrome/24.0.1292.0 Safari/537.14"  --connect-timeout 5

REM --insecure: 
REM --head: header  정보만
REM --location: 리다이렉트 연결까지함


changecolor lightgreen /Q
echo connection....   http://www.%in%/
REM tinyget -srv:www.%in% -uri:/ -h  
changecolor white /Q
REM curl http://www.%in%/ --insecure --head --location --user-agent "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.14 (KHTML, like Gecko) Chrome/24.0.1292.0 Safari/537.14"  --connect-timeout 5
curl http://www.%in%/ --insecure --head --user-agent "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.14 (KHTML, like Gecko) Chrome/24.0.1292.0 Safari/537.14"  --connect-timeout 5

changecolor white /Q
echo -----[[ HTTPS 접속 테스트 ]]----------------------------------
changecolor lightgreen /Q
echo connection....   https://%in%/
changecolor white /Q
REM curl https://%in%/ --insecure --head --location --user-agent "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.14 (KHTML, like Gecko) Chrome/24.0.1292.0 Safari/537.14" --connect-timeout 5
curl https://%in%/ --insecure --head --user-agent "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.14 (KHTML, like Gecko) Chrome/24.0.1292.0 Safari/537.14" --connect-timeout 5

changecolor lightgreen /Q
echo connection....   https://www.%in%/
changecolor white /Q
REM curl https://www.%in%/ --insecure --head --location --user-agent "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.14 (KHTML, like Gecko) Chrome/24.0.1292.0 Safari/537.14"  --connect-timeout 5
curl https://www.%in%/ --insecure --head --user-agent "Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.14 (KHTML, like Gecko) Chrome/24.0.1292.0 Safari/537.14"  --connect-timeout 5

changecolor white /Q
echo ================================================================

goto end

:end
endlocal
