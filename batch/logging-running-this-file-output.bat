@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem === Log folder/file settings ===
set "LOGDIR=%~dp0logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

rem === Get date/time in a stable way ===
rem %date% and %time% can vary, so normalize to digits only
for /f "tokens=1-4 delims=/.- " %%a in ("%date%") do (
    set "p1=%%a"
    set "p2=%%b"
    set "p3=%%c"
)
rem Detect which is year
if "!p1!" gtr "31" (set YYYY=!p1!&set MM=!p2!&set DD=!p3!) ^
else if "!p3!" gtr "31" (set YYYY=!p3!&set MM=!p1!&set DD=!p2!) ^
else (set YYYY=!p3!&set MM=!p2!&set DD=!p1!)

rem Zero padding for MM and DD
if 1!MM! LSS 110 set MM=0!MM!
if 1!DD! LSS 110 set DD=0!DD!

for /f "tokens=1-4 delims=:.," %%a in ("%time%") do (
    set "HH=%%a"
    set "MN=%%b"
    set "SS=%%c"
)
if 1!HH! LSS 110 set HH=0!HH!
if 1!MN! LSS 110 set MN=0!MN!
if 1!SS! LSS 110 set SS=0!SS!

set "TS=%YYYY%%MM%%DD%_%HH%%MN%%SS%"
set "LOGFILE=%LOGDIR%\run_%TS%.log"

rem === First run: call itself with /child and redirect all output ===
if /I not "%~1"=="/child" (
  echo [INFO] Log file: "%LOGFILE%"
  call "%~f0" /child %* >> "%LOGFILE%" 2>&1
  set "RET=%ERRORLEVEL%"
  echo [INFO] Exit code: %RET%
  exit /b %RET%
)

rem === Actual work section (all output goes to log) ===

chcp 65001 >nul
echo ==========================================================
echo [START] %DATE% %TIME%
echo [WORKDIR] %CD%
echo [SCRIPT ] %~f0
echo ==========================================================

rem Example commands
echo [STEP] System info
ver
whoami
ipconfig /all

echo [STEP] List current folder
dir /a

echo [STEP] Delete non-existing file (to check error output)
del /q "%TEMP%\__not_exists__.tmp"

echo ----------------------------------------------------------
echo [END] %DATE% %TIME%
echo ----------------------------------------------------------

endlocal
