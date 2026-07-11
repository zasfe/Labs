@echo off
setlocal

set "SCRIPT_DIR=%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File "%SCRIPT_DIR%Start-TLauncher.ps1" ^
  -Version "Forge 1.20.1"

endlocal
