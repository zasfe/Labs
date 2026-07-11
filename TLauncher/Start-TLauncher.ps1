param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [string]$TLauncherPath = "$env:APPDATA\.minecraft\TLauncher.exe",

    [string]$ConfigPath = "$env:APPDATA\.tlauncher\tlauncher-2.0.properties",

    [switch]$Force
)

$ErrorActionPreference = "Stop"

$VersionKey = "login.version.game"

function Write-Utf8WithoutBom {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string[]]$Content
    )

    $Utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    $Text = ($Content -join [Environment]::NewLine) + [Environment]::NewLine

    [System.IO.File]::WriteAllText(
        $Path,
        $Text,
        $Utf8WithoutBom
    )
}

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "TLauncher 설정 파일을 찾을 수 없습니다: $ConfigPath"
}

if (-not (Test-Path -LiteralPath $TLauncherPath)) {
    throw "TLauncher 실행 파일을 찾을 수 없습니다: $TLauncherPath"
}

$RunningProcesses = Get-Process |
    Where-Object {
        $_.ProcessName -in @(
            "TLauncher",
            "java",
            "javaw"
        )
    }

if ($RunningProcesses -and -not $Force) {
    $Names = $RunningProcesses.ProcessName |
        Sort-Object -Unique

    throw "실행 중인 프로세스가 있습니다: $($Names -join ', '). 먼저 종료하거나 -Force를 사용하십시오."
}

if ($Force) {
    Get-Process -Name "TLauncher" -ErrorAction SilentlyContinue |
        Stop-Process -Force
}

$MinecraftDirectoryLine = Get-Content -LiteralPath $ConfigPath |
    Where-Object {
        $_ -match "^minecraft\.gamedir="
    } |
    Select-Object -First 1

if ($MinecraftDirectoryLine) {
    $MinecraftDirectory = $MinecraftDirectoryLine `
        -replace "^minecraft\.gamedir=", "" `
        -replace "\\:", ":" `
        -replace "\\\\", "\"
}
else {
    $MinecraftDirectory = "$env:APPDATA\.minecraft"
}

$VersionDirectory = Join-Path `
    $MinecraftDirectory `
    "versions\$Version"

if (-not (Test-Path -LiteralPath $VersionDirectory)) {
    Write-Warning "버전 디렉터리를 찾지 못했습니다: $VersionDirectory"
    Write-Warning "TLauncher에서 해당 버전을 먼저 설치해야 할 수 있습니다."
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

$SavedValue = Get-Content -LiteralPath $ConfigPath |
    Where-Object {
        $_.StartsWith("$VersionKey=")
    } |
    Select-Object -First 1

if ($SavedValue -ne "$VersionKey=$Version") {
    Copy-Item `
        -LiteralPath $BackupPath `
        -Destination $ConfigPath `
        -Force

    throw "버전 설정 검증에 실패했습니다. 설정 파일을 복원했습니다."
}

Write-Host "TLauncher 버전 설정 완료"
Write-Host "  버전: $Version"
Write-Host "  설정: $SavedValue"
Write-Host "  백업: $BackupPath"

Start-Process `
    -FilePath $TLauncherPath `
    -WorkingDirectory (Split-Path -Parent $TLauncherPath)
