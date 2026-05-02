# ===============================
# WSL Ubuntu 운영형 정리 스크립트
# - 경로: E:\wsl\Ubuntu
# - 기능: 정리 + export/import + compact + 로그
# ===============================

$ErrorActionPreference = "Stop"

# -------- 설정 --------
$DistroName = "Ubuntu"
$BasePath   = "E:\wsl\Ubuntu"
$BackupPath = "E:\wsl\backup"
$LogPath    = "E:\wsl\logs"
$Date       = Get-Date -Format "yyyyMMdd_HHmmss"

$TarFile    = "$BackupPath\$DistroName-$Date.tar"
$LogFile    = "$LogPath\wsl_maint_$Date.log"

# -------- 로그 함수 --------
function Write-Log {
    param([string]$msg)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time $msg" | Tee-Object -FilePath $LogFile -Append
}

# -------- 사전 준비 --------
New-Item -ItemType Directory -Force -Path $BasePath,$BackupPath,$LogPath | Out-Null

Write-Log "=== START ==="

try {

    # 1. WSL 종료
    Write-Log "[1] WSL shutdown"
    wsl --shutdown

    # 2. Windows 임시파일 정리
    Write-Log "[2] Temp cleanup"
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue

    # 3. Docker 정리 (존재시)
    Write-Log "[3] Docker prune"
    wsl -d docker-desktop-data --exec docker system prune -a --volumes -f 2>$null

    # 4. 배포판 존재 확인
    $exists = wsl -l -q | Where-Object { $_ -eq $DistroName }
    if (-not $exists) {
        throw "WSL distro not found: $DistroName"
    }

    # 5. Export
    Write-Log "[4] Export $DistroName -> $TarFile"
    wsl --export $DistroName $TarFile

    # 6. Unregister
    Write-Log "[5] Unregister $DistroName"
    wsl --unregister $DistroName

    # 7. Import (E:\ 경로로)
    Write-Log "[6] Import -> $BasePath"
    wsl --import $DistroName $BasePath $TarFile --version 2

    # 8. Compact (최신 WSL)
    Write-Log "[7] Compact"
    wsl --shutdown
    wsl --manage $DistroName --compact 2>$null

    Write-Log "=== SUCCESS ==="

} catch {
    Write-Log "ERROR: $_"
    exit 1
}
