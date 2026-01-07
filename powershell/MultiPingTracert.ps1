<#
schtasks /Create ^
 /SC MINUTE /MO 5 ^
 /TN "MultiPingTracertLogger" ^
 /TR "powershell.exe -ExecutionPolicy Bypass -File \"C:\Scripts\MultiPingTracert.ps1\"" ^
 /RU "SYSTEM"

schtasks /Query /TN "MultiPingTracertLogger"
schtasks /Delete /TN "MultiPingTracertLogger" /F
#>

$IpListPath = "C:\Scripts\iplist.txt"
$LogDir     = "C:\Logs\NetCheck_PerHost_PS"

# 로그 디렉터리 없으면 생성
if (-not (Test-Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory | Out-Null
}

$IPs = Get-Content -Path $IpListPath

foreach ($ip in $IPs) {
    $today = Get-Date -Format "yyyyMMdd"
    
    # 대상별 안전한 파일명 생성 (특수문자 치환)
    $safeHostName = ($ip -replace "[:\\\/\*\?\""<>\|]", "_")
    $LogPath = Join-Path $LogDir ("{0}_{1}.log" -f $safeHostName, $today)

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # 1) ICMP 체크 (ping)
    $pingOk = Test-Connection -ComputerName $ip -Count 2 -Quiet 2>$null

    if ($pingOk) {
        "$time | $ip | PING=OK" | Out-File -FilePath $LogPath -Append -Encoding UTF8
    }
    else {
        "$time | $ip | PING=FAIL" | Out-File -FilePath $LogPath -Append -Encoding UTF8
    }

    # 2) tracert 결과 추가
    "==== $time | $ip | TRACERT START ====" | Out-File -FilePath $LogPath -Append -Encoding UTF8
    
    tracert -d -h 15 $ip 2>&1 | Out-File -FilePath $LogPath -Append -Encoding UTF8
    
    "==== $time | $ip | TRACERT END ====`r`n" | Out-File -FilePath $LogPath -Append -Encoding UTF8
}
