# ===============================
# 매주 월요일 04:00 실행 등록
# ===============================

$ScriptPath = "E:\wsl\wsl-maint.ps1"

$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""

$Trigger = New-ScheduledTaskTrigger `
    -Weekly -DaysOfWeek Monday -At 4am

$Principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" -RunLevel Highest

Register-ScheduledTask `
    -TaskName "WSL-Maintenance" `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Description "WSL weekly maintenance (compact + rebuild)" `
    -Force
