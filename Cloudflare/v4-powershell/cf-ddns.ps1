#requires -Version 5.1
<#
  Cloudflare DDNS Client for Windows (PowerShell)
  - A/AAAA 지원 (IPv4/IPv6)
  - API Token (Bearer) 사용
  - 캐시(last_ip.json) 기반 불필요 호출 최소화
  - 로그 기록
  - Task Scheduler 자동 설치/삭제

  사용 예)
    # 1) 설정 파일 생성(기본 템플릿)
    .\cf-ddns.ps1 -InitConfig

    # 2) 1회 실행
    .\cf-ddns.ps1 -Run

    # 3) 5분 주기 스케줄 설치(관리자 권한 권장)
    .\cf-ddns.ps1 -InstallTask -IntervalMinutes 5

    # 4) 스케줄 삭제
    .\cf-ddns.ps1 -UninstallTask
#>

[CmdletBinding()]
param(
  [switch]$Run,
  [switch]$InitConfig,
  [switch]$InstallTask,
  [switch]$UninstallTask,
  [int]$IntervalMinutes = 5,
  [string]$TaskName = "Cloudflare-DDNS",
  [string]$BaseDir = "$env:ProgramData\cf-ddns"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------- Paths ----------
$ConfigPath = Join-Path $BaseDir "config.json"
$CachePath  = Join-Path $BaseDir "last_ip.json"
$LogPath    = Join-Path $BaseDir "cf-ddns.log"

function Ensure-Dir([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Path $Path | Out-Null
  }
}

function Write-Log([string]$Msg) {
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  $line = "[$ts] $Msg"
  $line | Out-File -FilePath $LogPath -Encoding utf8 -Append
  Write-Host $line
}

function Fail([string]$Msg) {
  Write-Log "ERROR: $Msg"
  throw $Msg
}

function Require-AdminIfInstalling() {
  if ($InstallTask -or $UninstallTask) {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
      ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
      Fail "Task Scheduler 설치/삭제는 관리자 권한 권장. PowerShell을 '관리자 권한'으로 실행하세요."
    }
  }
}

function Read-JsonFile([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  Get-Content -LiteralPath $Path -Raw -Encoding utf8 | ConvertFrom-Json
}

function Write-JsonFile([string]$Path, $Obj) {
  ($Obj | ConvertTo-Json -Depth 10) | Out-File -LiteralPath $Path -Encoding utf8 -Force
}

function Init-ConfigTemplate() {
  Ensure-Dir $BaseDir
  if (Test-Path -LiteralPath $ConfigPath) {
    Write-Log "config.json 이미 존재: $ConfigPath"
    return
  }

  $tpl = @{
    apiToken = "CLOUDFLARE_API_TOKEN"
    zoneName = "example.com"
    # records: 여러 레코드 지원
    records = @(
      @{
        name    = "home.example.com"
        type    = "A"        # A 또는 AAAA
        proxied = $false
        ttl     = 1          # 1=Auto
      },
      @{
        name    = "home6.example.com"
        type    = "AAAA"
        proxied = $false
        ttl     = 1
      }
    )
    # IP 조회 URL (원하면 교체 가능)
    ipProviders = @{
      v4 = "https://api.ipify.org"
      v6 = "https://api64.ipify.org"
    }
  }

  Write-JsonFile -Path $ConfigPath -Obj $tpl
  Write-Log "config.json 템플릿 생성 완료: $ConfigPath"
  Write-Log "apiToken/zoneName/records 값을 수정하세요."
}

function Invoke-CfApi([string]$Method, [string]$Url, [hashtable]$Headers, $BodyObj = $null) {
  $params = @{
    Method  = $Method
    Uri     = $Url
    Headers = $Headers
  }
  if ($null -ne $BodyObj) {
    $params["ContentType"] = "application/json"
    $params["Body"] = ($BodyObj | ConvertTo-Json -Depth 10)
  }

  # TLS 1.2 강제(구버전 환경 대비)
  try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

  $resp = Invoke-RestMethod @params
  if ($resp -and $resp.success -eq $false) {
    $errs = ($resp.errors | ConvertTo-Json -Depth 10)
    Fail "Cloudflare API 실패: $errs"
  }
  return $resp
}

function Get-ExternalIP([string]$Url) {
  try {
    $ip = (Invoke-RestMethod -Method Get -Uri $Url).ToString().Trim()
    if (-not $ip) { throw "empty" }
    return $ip
  } catch {
    Fail "외부 IP 조회 실패: $Url / $_"
  }
}

function Get-ZoneId([string]$ZoneName, [hashtable]$Headers) {
  $u = "https://api.cloudflare.com/client/v4/zones?name=$([uri]::EscapeDataString($ZoneName))"
  $z = Invoke-CfApi -Method "GET" -Url $u -Headers $Headers
  if (-not $z.result -or $z.result.Count -lt 1) { Fail "Zone 미발견: $ZoneName" }
  return $z.result[0].id
}

function Get-DnsRecord([string]$ZoneId, [string]$Type, [string]$Name, [hashtable]$Headers) {
  $u = "https://api.cloudflare.com/client/v4/zones/$ZoneId/dns_records?type=$Type&name=$([uri]::EscapeDataString($Name))"
  $r = Invoke-CfApi -Method "GET" -Url $u -Headers $Headers
  if (-not $r.result -or $r.result.Count -lt 1) { return $null }
  return $r.result[0]
}

function Update-DnsRecord([string]$ZoneId, [string]$RecordId, [hashtable]$Headers, [hashtable]$Payload) {
  $u = "https://api.cloudflare.com/client/v4/zones/$ZoneId/dns_records/$RecordId"
  # Cloudflare DNS 레코드 업데이트는 PATCH 기반(문서 기준)
  $resp = Invoke-CfApi -Method "PATCH" -Url $u -Headers $Headers -BodyObj $Payload
  return $resp
}

function Ensure-CacheAndDecide([string]$Key, [string]$NewIp) {
  $cache = Read-JsonFile $CachePath
  if (-not $cache) { $cache = @{ } }
  if (-not $cache.ContainsKey($Key)) { return @{ cache=$cache; changed=$true } }
  $old = $cache[$Key]
  return @{ cache=$cache; changed=($old -ne $NewIp) }
}

function Save-Cache($CacheObj) {
  Write-JsonFile -Path $CachePath -Obj $CacheObj
}

function Run-Client() {
  Ensure-Dir $BaseDir
  if (-not (Test-Path -LiteralPath $ConfigPath)) { Fail "config.json 없음: $ConfigPath (먼저 -InitConfig 실행)" }

  $cfg = Read-JsonFile $ConfigPath
  if (-not $cfg.apiToken -or $cfg.apiToken -eq "CLOUDFLARE_API_TOKEN") { Fail "config.json apiToken 설정 필요" }
  if (-not $cfg.zoneName) { Fail "config.json zoneName 설정 필요" }
  if (-not $cfg.records -or $cfg.records.Count -lt 1) { Fail "config.json records 설정 필요" }

  $headers = @{
    "Authorization" = "Bearer $($cfg.apiToken)"
    "Content-Type"  = "application/json"
  }

  $zoneId = Get-ZoneId -ZoneName $cfg.zoneName -Headers $headers
  Write-Log "ZoneID: $zoneId (zoneName=$($cfg.zoneName))"

  # 외부 IP 조회 (필요한 타입만)
  $needV4 = $false
  $needV6 = $false
  foreach ($rec in $cfg.records) {
    if ($rec.type -eq "A")    { $needV4 = $true }
    if ($rec.type -eq "AAAA") { $needV6 = $true }
  }

  $ipV4 = $null
  $ipV6 = $null
  if ($needV4) { $ipV4 = Get-ExternalIP -Url $cfg.ipProviders.v4; Write-Log "External IPv4: $ipV4" }
  if ($needV6) { $ipV6 = Get-ExternalIP -Url $cfg.ipProviders.v6; Write-Log "External IPv6: $ipV6" }

  foreach ($rec in $cfg.records) {
    $name = $rec.name
    $type = $rec.type
    if (-not $name -or -not $type) { Write-Log "SKIP: records 항목 누락"; continue }

    $newIp = if ($type -eq "A") { $ipV4 } else { $ipV6 }
    if (-not $newIp) { Write-Log "SKIP: $name ($type) - 외부 IP 미확인"; continue }

    $cacheKey = "$type|$name"
    $dec = Ensure-CacheAndDecide -Key $cacheKey -NewIp $newIp
    $cache = $dec.cache

    # 캐시상 변화 없으면, API 호출 최소화를 위해 우선 스킵(원하면 여기서 주기적 검증 로직 추가 가능)
    if (-not $dec.changed) {
      Write-Log "NOCHANGE(cache): $name $type = $newIp"
      continue
    }

    $dns = Get-DnsRecord -ZoneId $zoneId -Type $type -Name $name -Headers $headers
    if (-not $dns) {
      Write-Log "MISS: DNS 레코드 없음: $name ($type) - 대시보드에서 먼저 생성 권장"
      continue
    }

    $current = $dns.content
    $rid = $dns.id

    if ($current -eq $newIp) {
      Write-Log "NOCHANGE(api): $name $type = $newIp"
      $cache[$cacheKey] = $newIp
      Save-Cache $cache
      continue
    }

    $payload = @{
      type    = $type
      name    = $name
      content = $newIp
      ttl     = [int]($rec.ttl)
      proxied = [bool]($rec.proxied)
    }

    Write-Log "UPDATE: $name $type $current -> $newIp (recordId=$rid)"
    $u = Update-DnsRecord -ZoneId $zoneId -RecordId $rid -Headers $headers -Payload $payload
    Write-Log "UPDATED: success=$($u.success)"

    $cache[$cacheKey] = $newIp
    Save-Cache $cache
  }
}

function Install-Task([string]$ScriptPath, [string]$Name, [int]$Minutes) {
  Import-Module ScheduledTasks -ErrorAction Stop

  $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" -Run"
  $start  = (Get-Date).AddMinutes(1)
  $trigger = New-ScheduledTaskTrigger -Daily -At $start.TimeOfDay
  # 하루 동안 $Minutes 간격 반복(매일 갱신)
  $trigger.RepetitionInterval = (New-TimeSpan -Minutes $Minutes)
  $trigger.RepetitionDuration = (New-TimeSpan -Days 1)

  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  $settings  = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

  $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings
  Register-ScheduledTask -TaskName $Name -InputObject $task -Force | Out-Null

  Write-Log "Task 설치 완료: $Name (매 $Minutes 분)"
}

function Uninstall-Task([string]$Name) {
  Import-Module ScheduledTasks -ErrorAction Stop
  if (Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $Name -Confirm:$false
    Write-Log "Task 삭제 완료: $Name"
  } else {
    Write-Log "Task 없음: $Name"
  }
}

# ---------- Main ----------
Ensure-Dir $BaseDir
Require-AdminIfInstalling

if ($InitConfig) { Init-ConfigTemplate; exit 0 }
if ($InstallTask) { Install-Task -ScriptPath $PSCommandPath -Name $TaskName -Minutes $IntervalMinutes; exit 0 }
if ($UninstallTask) { Uninstall-Task -Name $TaskName; exit 0 }
if ($Run) { Run-Client; exit 0 }

Write-Host "옵션 필요: -InitConfig | -Run | -InstallTask | -UninstallTask"
exit 2
