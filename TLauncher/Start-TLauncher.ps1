param(
    [Parameter(Mandatory)]
    [string]$Version,

    [string]$VersionKey = "login.version",

    [string]$TLauncherPath = "$env:USERPROFILE\Downloads\TLauncher.exe",

    [string]$ConfigPath = "$env:APPDATA\.tlauncher\tlauncher-2.0.properties"
)

$ErrorActionPreference = "Stop"

if (Get-Process -Name "TLauncher", "java", "javaw" -ErrorAction SilentlyContinue) {
    throw "TLauncher 또는 Minecraft가 실행 중입니다. 먼저 종료하십시오."
}

if (-not (Test-Path $ConfigPath)) {
    throw "설정 파일을 찾을 수 없습니다: $ConfigPath"
}

if (-not (Test-Path $TLauncherPath)) {
    throw "TLauncher 실행 파일을 찾을 수 없습니다: $TLauncherPath"
}

# 설치된 버전 확인
$MinecraftDir = "$env:APPDATA\.minecraft"
$VersionDir = Join-Path $MinecraftDir "versions\$Version"

if (-not (Test-Path $VersionDir)) {
    Write-Warning "설치된 버전 디렉터리를 찾지 못했습니다: $VersionDir"
    Write-Warning "TLauncher에서 해당 버전을 먼저 한 번 설치해야 합니다."
}

# 설정 파일 백업
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupPath = "$ConfigPath.$Timestamp.bak"
Copy-Item $ConfigPath $BackupPath -Force

$Lines = Get-Content $ConfigPath -Encoding UTF8
$Pattern = "^\Q$VersionKey\E="

$Found = $false

$UpdatedLines = foreach ($Line in $Lines) {
    if ($Line -match $Pattern) {
        $Found = $true
        "$VersionKey=$Version"
    }
    else {
        $Line
    }
}

if (-not $Found) {
    $UpdatedLines += "$VersionKey=$Version"
}

$UpdatedLines |
    Set-Content $ConfigPath -Encoding UTF8

Write-Host "버전 설정 완료: $VersionKey=$Version"
Write-Host "백업 파일: $BackupPath"

Start-Process -FilePath $TLauncherPath
