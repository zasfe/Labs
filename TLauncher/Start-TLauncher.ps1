param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [string]$TLauncherPath = "$env:USERPROFILE\Downloads\TLauncher.exe",

    [string]$ConfigPath = "$env:APPDATA\.tlauncher\tlauncher-2.0.properties",

    [switch]$Force
)

$ErrorActionPreference = "Stop"
$VersionKey = "login.version.game"

# Windows PowerShell 출력 인코딩
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Utf8WithoutBom {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string[]]$Content
    )

    $Encoding = New-Object System.Text.UTF8Encoding($false)
    $Text = ($Content -join [Environment]::NewLine) + [Environment]::NewLine

    [System.IO.File]::WriteAllText(
        $Path,
        $Text,
        $Encoding
    )
}

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Config file not found: $ConfigPath"
}

if (-not (Test-Path -LiteralPath $TLauncherPath)) {
    throw "TLauncher executable not found: $TLauncherPath"
}

# 다른 Java 프로그램은 무시하고 TLauncher만 검사
$RunningTLauncher = Get-Process -Name "TLauncher" -ErrorAction SilentlyContinue

if ($RunningTLauncher -and -not $Force) {
    throw "TLauncher is already running. Close it first or use -Force."
}

if ($Force -and $RunningTLauncher) {
    $RunningTLauncher | Stop-Process -Force
    Start-Sleep -Seconds 1
}

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupPath = "$ConfigPath.$Timestamp.bak"

Copy-Item `
    -LiteralPath $ConfigPath `
    -Destination $BackupPath `
    -Force

$Lines = [System.IO.File]::ReadAllLines($ConfigPath)
$Found = $false

$UpdatedLines = foreach ($Line in $Lines) {
    if ($Line.StartsWith("$VersionKey=")) {
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

Write-Utf8WithoutBom `
    -Path $ConfigPath `
    -Content $UpdatedLines

$SavedValue = [System.IO.File]::ReadAllLines($ConfigPath) |
    Where-Object {
        $_.StartsWith("$VersionKey=")
    } |
    Select-Object -First 1

if ($SavedValue -ne "$VersionKey=$Version") {
    Copy-Item `
        -LiteralPath $BackupPath `
        -Destination $ConfigPath `
        -Force

    throw "Version setting verification failed. Config restored."
}

Write-Host "TLauncher version configured"
Write-Host "Version : $Version"
Write-Host "Config  : $SavedValue"
Write-Host "Backup  : $BackupPath"

Start-Process `
    -FilePath $TLauncherPath `
    -WorkingDirectory (Split-Path -Parent $TLauncherPath)
