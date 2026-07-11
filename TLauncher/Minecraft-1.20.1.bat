@echo off
chcp 65001 > nul
setlocal

set "SCRIPT_DIR=%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass ^
  -File "%SCRIPT_DIR%Start-TLauncher.ps1" ^
  -Version "Fabric 1.21.1" ^
  -TLauncherPath "%APPDATA%\.tlauncher\TLauncher.exe"

if errorlevel 1 (
    echo.
    echo TLauncher 실행 실패
    pause
    exit /b 1
)

endlocal
