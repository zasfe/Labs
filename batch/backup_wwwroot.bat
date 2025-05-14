@echo off
setlocal

REM wwwroot 백업 - C:\backup\backup_wwwroot.bat

REM 작업 스케줄 생성: SCHTASKS /Create /SC DAILY /MO 1 /TN gabia_Backup_wwwroot /ST 01:00 /TR "C:\backup\backup_wwwroot.bat" /RU ""
REM 작업 스케줄 실행: SCHTASKS /run /TN "gabia_Backup_wwwroot"


REM 현재 날짜를 YYYY-MM-DD 형식으로 설정합니다.
set currentDate=%DATE:~0,4%-%DATE:~5,2%-%DATE:~8,2%

REM 백업 대상 경로와 로그 저장 경로를 설정합니다.
set sourcePath=C:\inetpub\wwwroot\
set destinationPath=C:\backup\wwwroot\%currentDate%\
set logPath=C:\backup\logs\

REM 폴더가 존재하지 않으면 생성합니다.
if not exist C:\backup mkdir C:\backup
if not exist C:\backup\logs mkdir C:\backup\logs
if not exist C:\backup\wwwroot mkdir C:\backup\wwwroot

REM 오늘자 백업 경로
if not exist "%destinationPath%" mkdir "%destinationPath%"

REM robocopy를 사용하여 파일 복사 및 로그 저장
robocopy %sourcePath%  %destinationPath% /MIR /LOG+:"%logPath%\backup_%currentDate%.log" /NP /R:10 /W:10 /TEE

REM 오래된 백업(10일 이전) 삭제
forfiles /p "C:\backup\wwwroot" /d -10 /c "cmd /c if @isdir==TRUE rd /s /q @path"

endlocal
