<#
schtasks /Create ^
 /SC MINUTE /MO 5 ^
 /TN "MultiPingLogger" ^
 /TR "powershell.exe -ExecutionPolicy Bypass -File \"C:\Scripts\MultiPing.ps1\"" ^
 /RU "SYSTEM"

schtasks /Query /TN "MultiPingLogger"
schtasks /Delete /TN "MultiPingLogger" /F
#>
$IpListPath = "C:\config\iplist.txt"
$LogDir     = "C:\config\logs"
$today      = Get-Date -Format "yyyyMMdd"

if (-not (Test-Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory | Out-Null
}

$IPs = Get-Content -Path $IpListPath

foreach ($ip in $IPs) {
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # 파일명에 쓸 수 없는 문자 치환 + 날짜 포함
    $safeName = ($ip -replace "[:\\\/\*\?\""<>\|]", "_")
    $logFile  = Join-Path $LogDir ("{0}_{1}.log" -f $safeName, $today)

    if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
        "$time | $ip | OK"   | Out-File -FilePath $logFile -Append -Encoding UTF8
    }
    else {
        "$time | $ip | FAIL" | Out-File -FilePath $logFile -Append -Encoding UTF8
    }
}
