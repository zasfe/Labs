@echo ==========================================
@echo ## Windows 가상 머신(VM) 인스턴스에서 Persistent Disk 성능(IOPS 및 처리량)을 벤치마킹하는 방법
@echo ==========================================
@echo
@echo - https://cloud.google.com/compute/docs/disks/benchmarking-pd-performance-windows?hl=ko

@echo # 벤치마킹 소프트웨어 구성
$client = New-Object System.Net.WebClient
$client.DownloadFile("https://github.com/Microsoft/diskspd/releases/latest/download/DiskSpd.zip","$env:temp\DiskSpd-download.zip")
Expand-Archive -LiteralPath "$env:temp\DiskSpd-download.zip" C:\DISKSPD
Get-ChildItem C:\DISKSPD
