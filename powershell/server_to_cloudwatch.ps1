$aws_path="C:\Program Files\Amazon\AWSCLIV2\aws.exe"
$gabia_folder="C:\Program Files\gabiaConsignManagement\"
$exe_folder="C:\Program Files\gabiaConsignManagement\e\"
$script_folder="C:\Program Files\gabiaConsignManagement\s\"
$log_folder="C:\Program Files\gabiaConsignManagement\log\"

$tmp_file=$log_folder + "result.txt"
$tmp2_file=$log_folder + "result2.txt"
$stream_file=$log_folder + "logstream.json"
$result_file=$log_folder + "action_result.txt"

$unixtime=[int][double]::Parse($(Get-Date -date (Get-Date).ToUniversalTime()-uformat %s)) * 1000

$instance_id=(Invoke-WebRequest -uri "http://169.254.169.254/latest/meta-data/instance-id").Content
$private_ip=(Invoke-WebRequest -uri "http://169.254.169.254/latest/meta-data/local-ipv4").Content
$public_ip=(Invoke-WebRequest -uri "http://169.254.169.254/latest/meta-data/public-ipv4").Content
$region=(Invoke-WebRequest -uri "http://169.254.169.254/latest/meta-data/placement/region").Content
$stream_name="$instance_id (private_ $private_ip  /  public_ $public_ip) - $unixtime"
$stream_group="EC2_ServerInfo"


New-Item "C:\Program Files\gabiaConsignManagement\s" -ItemType Directory -Force
New-Item "C:\Program Files\gabiaConsignManagement\e" -ItemType Directory -Force
New-Item "C:\Program Files\gabiaConsignManagement\log" -ItemType Directory -Force

<#
1. Operation System
#>


Write-output "============= Operation System =============" | out-file -encoding ASCII $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file


Get-CimInstance -Class Win32_OperatingSystem |
  Select-Object -Property Caption,Version,@{Label='Computername'; E={($_.CSName)}},Manufacturer, CodeSet, MUILanguages, ServicePackMajorVersion, ServicePackMinorVersion, TotalVisibleMemorySize,@{N='TotalVisibleMemorySize_GB'; E={[math]::Round(($_.TotalVisibleMemorySize / 1024/1024), 2)}},
  CurrentTimeZone,  LastBootUpTime,@{Label='RebootInLast30Days';
     Expression={((Get-Date) - $_.lastbootuptime) -ge (New-TimeSpan -Days 30)}}   | Out-String | % {$_.replace('\', '\\')} | %{$_.replace('"','\"')} | %{$_.replace('/','\/')} | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file

<#
2. Users List
#>

Write-output "============= Users List =============" | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file

Get-LocalUser | Select Name, Enabled, Description, SID, LastLogon, PasswordLastSet  | Out-String | % {$_.replace('\', '\\')} | %{$_.replace('"','\"')} | %{$_.replace('/','\/')} | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file

<#
3. Network
#>

Write-output "============= Network Configuration =============" | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file

Get-NetIPConfiguration -All -Detailed  | Out-String | % {$_.replace('\', '\\')} | %{$_.replace('"','\"')} | %{$_.replace('/','\/')} | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file

Write-output "============= Network Connection - Listen =============" | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file

Get-NetTCPConnection | ? {$_.State -eq "Listen"}  | Out-String | % {$_.replace('\', '\\')} | %{$_.replace('"','\"')} | %{$_.replace('/','\/')} | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file

Write-output "============= Network Connection - Established =============" | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file

Get-NetTCPConnection -State Established |Select-Object -Property LocalAddress, LocalPort,RemoteAddress, RemotePort, @{name='PID';expression={(Get-Process -Id $_.OwningProcess). Id}},@{name='ProcessName';expression={(Get-Process -Id $_.OwningProcess). Path}},CreationTime | Format-Table -Wrap -AutoSize | Out-String | % {$_.replace('\', '\\')} | %{$_.replace('"','\"')} | %{$_.replace('/','\/')} | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file



<#
4. Process List
#>

Write-output "============= Process List =============" | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file

Get-Process -IncludeUserName |  Format-List Id, Name, Path, Sessionid, UserName, startTime | Out-String | % {$_.replace('\', '\\')} | %{$_.replace('"','\"')} | %{$_.replace('/','\/')} | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file

Write-output "============= Process List - Tree =============" | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file

Function Show-ProcessTree  {            
[CmdletBinding()]            
Param()            
    Begin {            
        # Identify top level processes            
        # They have either an identified processID that doesn't exist anymore            
        # Or they don't have a Parentprocess ID at all            
        $allprocess  = Get-WmiObject -Class Win32_process            
        $uniquetop  = ($allprocess).ParentProcessID | Sort-Object -Unique            
        $existingtop =  ($uniquetop | ForEach-Object -Process {$allprocess | Where ProcessId -EQ $_}).ProcessID            
        $nonexistent = (Compare-Object -ReferenceObject $uniquetop -DifferenceObject $existingtop).InPutObject            
        $topprocess = ($allprocess | ForEach-Object -Process {            
            if ($_.ProcessID -eq $_.ParentProcessID){            
                $_.ProcessID            
            }            
            if ($_.ParentProcessID -in $nonexistent) {            
                $_.ProcessID            
            }            
        })            
        # Sub functions            
        # Function that indents to a level i            
        function Indent {            
            Param([Int]$i)            
            $Global:Indent = $null            
            For ($x=1; $x -le $i; $x++)            
            {            
                #$Global:Indent += [char]9            
                $Global:Indent += ' '
            }            
        }            
        Function Get-ChildProcessesById {            
        Param($ID)            
            # use $allprocess variable instead of Get-WmiObject -Class Win32_process to speed up            
            $allprocess | Where { $_.ParentProcessID -eq $ID} | ForEach-Object {            
                Indent $i            
                '{0}{1} {2} {3}' -f $Indent,$_.ProcessID,($_.Name -split "\.")[0],$_.CommandLine            
                $i++            
                # Recurse            
                Get-ChildProcessesById -ID $_.ProcessID            
                $i--            
            }            
        } # end of function            
    }            
    Process {            
        $topprocess | ForEach-Object {            
            '{0} {1}' -f $_,(Get-Process -Id $_).ProcessName
            # Avoid processID 0 because parentProcessId = processID            
            if ($_ -ne 0 )            
            {            
                $i = 1            
                Get-ChildProcessesById -ID $_            
            }            
        }            
    }             
    End {}            
}

Show-ProcessTree | Out-String | % {$_.replace('\', '\\')} | %{$_.replace('"',' ')} | %{$_.replace('/','\/')} | %{$_.replace('[char]9' ,'  ')}  | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file



<#
5. Service List
#>

Write-output "============= Service List - running =============" | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file

Get-WmiObject Win32_Service -Filter {State = 'Running'} | Format-Table -AutoSize Name, startname, startmode, State, caption, pathname   | Out-String | % {$_.replace('\', '\\')} | %{$_.replace('"','\"')} | %{$_.replace('/','\/')} | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file



<#
6. Disk
#>

Write-output "============= Disk =============" | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file

function get-diskcapacity {
    [CmdletBinding()]
    param (
    [string[]]$computername = $env:COMPUTERNAME
    )

    PROCESS {
            Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3"  |
            select Caption,
            @{N='Capacity_GB'; E={[math]::Round(($_.Size / 1GB), 2)}},
            @{N='FreeSpace_GB'; E={[math]::Round(($_.FreeSpace / 1GB), 2)}},
            @{N='PercentUsed'; E={[math]::Round(((($_.Size - $_.FreeSpace) / $_.Size) * 100), 2) }},
            @{N='PercentFree'; E={[math]::Round((($_.FreeSpace / $_.Size) * 100), 2) }}

    } # end PROCESS
}

get-diskcapacity  | Out-String | % {$_.replace('\', '\\')} | %{$_.replace('"','\"')} | %{$_.replace('/','\/')} | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file


<#
7. Log
#>

Write-output "============= Log - login logout =============" | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file

function Get-Sessions([STRING]$UserName = "", [STRING]$ComputerName = "$ENV:COMPUTERNAME", [STRING]$After = "", [STRING]$Before = "", [SWITCH]$Detailed)
{
    Begin
    {
        # Array für Anmeldeeinträge initialisieren
        $SCRIPT:AnmeldeListe = @()

        # Eintrag ausgeben
        function PrintEntry([INT]$Index)
        {
            if (![STRING]::IsNullOrEmpty($SCRIPT:AnmeldeListe[$Index].Account))
            {
                if ($Detailed)
                {
                    $SCRIPT:AnmeldeListe[$Index]
                } else {
                    $SCRIPT:AnmeldeListe[$Index] | Select-Object -Property * -ExcludeProperty SessionId, RemoteHost
                }
            }
        }

        # Alle Einträge ausgeben
        function PrintAll
        {
            for ($i; $i -lt $AnmeldeListe.Length; $i++) { PrintEntry -Index $i }
        }

        # Eintrag zu Benutzernamen suchen, Rückgabe Index (wenn gefunden) oder Arraylänge (wenn nicht gefunden)
        function FindEntry([STRING]$Account)
        {
            $Zaehler = 0
            foreach ($Eintrag in $SCRIPT:AnmeldeListe)
            {
                if ($Eintrag.Account -eq $Account) { break; }
                $Zaehler ++;
            }
            return $Zaehler
        }

        # Eintrag um Ereignis ergänzen oder - falls noch nicht da - neuen Eintrag erstellen
        # bei Bedarf wird ein vorhandener Eintrag zum Benutzer oder der aktuelle Eintrag (wenn beendet) ausgegeben
        function AddEntry([STRING]$Account, $SessionId = $NULL, $RemoteHost = $NULL, $LogonTime = $NULL, $ConnectTime = $NULL, $LogoffTime = $NULL, $DisconnectTime = $NULL)
        {
            # gibt es einen Eintrag zum Benutzer
            $Index = FindEntry -Account $Account
            if ($Index -eq ($SCRIPT:AnmeldeListe).Length)
            { # nein, neuen Eintrag erstellen
                $NeuerEintrag = New-Object PSCustomObject
                $NeuerEintrag | Add-Member -MemberType NoteProperty -Name Account -Value $Account
                $NeuerEintrag | Add-Member -MemberType NoteProperty -Name SessionId -Value $SessionId
                $NeuerEintrag | Add-Member -MemberType NoteProperty -Name RemoteHost -Value $RemoteHost
                $NeuerEintrag | Add-Member -MemberType NoteProperty -Name LogonTime -Value $LogonTime
                $NeuerEintrag | Add-Member -MemberType NoteProperty -Name ConnectTime -Value $ConnectTime
                $NeuerEintrag | Add-Member -MemberType NoteProperty -Name LogoffTime -Value $LogoffTime
                $NeuerEintrag | Add-Member -MemberType NoteProperty -Name DisconnectTime -Value $DisconnectTime

                $SCRIPT:AnmeldeListe += $NeuerEintrag
            } else {
                # prüfen, ob ein bestehender Eintrag zum Benutzer vorhanden ist, der beendet, also ausgegeben werden muss
                $Flush = $FALSE
                if ($LogonTime) { $Flush = $TRUE }
                if ($ConnectTime) { $Flush = $TRUE }
                if ($LogoffTime -And $SCRIPT:AnmeldeListe[$Index].LogoffTime) { $Flush = $TRUE }
                if ($DisconnectTime -And $SCRIPT:AnmeldeListe[$Index].DisconnectTime) { $Flush = $TRUE }
                if ($SessionId -ne $SCRIPT:AnmeldeListe[$Index].SessionId) { $Flush = $TRUE }
                if (!$LogoffTime -And $SCRIPT:AnmeldeListe[$Index].RemoteHost -And ($RemoteHost -ne $SCRIPT:AnmeldeListe[$Index].RemoteHost)) { $Flush = $TRUE }

                if ($Flush)
                { # es muss ein bestehender Eintrag zum Benutzer ausgegeben werden
                    PrintEntry -Index $Index
                    # neuer Eintrag überschreibt den bestehenden Datensatz
                    $SCRIPT:AnmeldeListe[$Index].SessionId = $SessionId
                    $SCRIPT:AnmeldeListe[$Index].RemoteHost = $RemoteHost
                    $SCRIPT:AnmeldeListe[$Index].LogonTime = $LogonTime
                    $SCRIPT:AnmeldeListe[$Index].DisconnectTime = $DisconnectTime
                    $SCRIPT:AnmeldeListe[$Index].ConnectTime = $ConnectTime
                    $SCRIPT:AnmeldeListe[$Index].LogoffTime = $LogoffTime
                } else {
                    # bestehender Eintrag wird ergänzt
                    if (!$SCRIPT:AnmeldeListe[$Index].RemoteHost) { $SCRIPT:AnmeldeListe[$Index].RemoteHost = $RemoteHost }
                    if ($DisconnectTime) { $SCRIPT:AnmeldeListe[$Index].DisconnectTime = $DisconnectTime }
                    if ($LogoffTime) { $SCRIPT:AnmeldeListe[$Index].LogoffTime = $LogoffTime }
                }
            }

            if ($SCRIPT:AnmeldeListe[$Index].DisconnectTime -And $SCRIPT:AnmeldeListe[$Index].LogoffTime)
            { # ist der Eintrag beendet? Ja -> Eintrag ausgeben und löschen
                PrintEntry -Index $Index
                $SCRIPT:AnmeldeListe[$Index].Account = ""
            }
        }

        # Parameter interpretieren
        if ([STRING]::IsNullOrEmpty($Before))
        { $BeforeLog = Get-Date } else { $BeforeLog = Get-Date $Before }
        if ([STRING]::IsNullOrEmpty($After))
        { $AfterLog = (Get-Date).AddDays(-31) } else { $AfterLog = Get-Date $After }
    }

    Process
    {
        try
        { # An- und Abmeldeereignisse auslesen. Wegen Beschleunigung alle Filter in Hashtable übergeben
            $EventDataCollector = Get-Winevent -FilterHashTable @{ LogName = "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational"; Id = 21,23,24,25; StartTime = $AfterLog; EndTime = $BeforeLog } -ComputerName $ComputerName -Oldest -EA "SilentlyContinue"
            foreach ($DataCollected in $EventDataCollector)
            { # Ereignisse durchlaufen
                # Nachricht lesen
                $MessageSplit = $DataCollected.Message.Split("`n")
                # Benutzernamen extrahieren
                $UserLogged = ($MessageSplit[2].Split(":"))[1].Trim()
                # Session-ID extrahieren
                $IdLogged = ($MessageSplit[3].Split(":"))[1].Trim().TrimEnd(".")
                if ($DataCollected.Id -ne "23")
                {    # Remotehost extrahieren
                    $SourceLogged = ($MessageSplit[4].Split(":"))[1].Trim().TrimEnd(".")
                } else { # Information nicht vorhanden bei Abmeldenachricht
                    $SourceLogged = $NULL
                }

                if ($UserLogged -match $UserName)
                { # wenn Ereignis zu gesuchter Benutzernamensmaske
                    switch ($DataCollected.Id)
                    { # Anmeldeereignis
                        "21" { AddEntry -Account $UserLogged -SessionId $IdLogged -RemoteHost $SourceLogged -LogonTime $DataCollected.TimeCreated }
                        # Abmeldeereignis
                        "23" { AddEntry -Account $UserLogged -SessionId $IdLogged -RemoteHost $SourceLogged -LogoffTime $DataCollected.TimeCreated }
                        # Trennungsereignis
                        "24" { AddEntry -Account $UserLogged -SessionId $IdLogged -RemoteHost $SourceLogged -DisconnectTime $DataCollected.TimeCreated }
                        # Verbidungsereignis
                        "25" { AddEntry -Account $UserLogged -SessionId $IdLogged -RemoteHost $SourceLogged -ConnectTime $DataCollected.TimeCreated }
                    }
                }
            }
            if ($SCRIPT:AnmeldeListe.Length -eq 0)
            { # kein Eintrag gefunden
                if ([STRING]::IsNullOrEmpty($UserName))
                { # passende Meldung erzeugen
                    Write-Output "No logon events between $AfterLog and $BeforeLog on computer $ComputerName"
                } else {
                    Write-Output "No logon events of users with partial name '$UserName' between $AfterLog and $BeforeLog on computer $ComputerName"
                }
            }
        }
        catch
        { # Fehler beim Ermitteln der Ereignisse
            Write-Error "Error processing event log from computer $ComputerName`: $($_.Exception.Message)"
        }
    }

    End
    { # noch nicht ausgegebene Datensätze ausgeben
        PrintAll
    }
}

Get-Sessions | Format-Table -AutoSize  | Out-String | % {$_.replace('\', '\\')} | %{$_.replace('"','\"')} | %{$_.replace('/','\/')} | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file


Write-output "============= Log - system =============" | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file

Get-EventLog -LogName System -After (Get-Date).AddDays(-31) | 
    Where-Object {$_.EntryType -like 'Error' -or $_.EntryType -like 'Warning'} | 
    Where-Object {$_.Source -notlike 'Schannel' -and $_.Source -notlike 'DCOM'}  | Out-String | % {$_.replace('\', '\\')} | %{$_.replace('"','\"')} | %{$_.replace('/','\/')} | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file

<#
8. App - amazon (ssm)
#>

Write-output "============= App - amazon (ssm) =============" | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file

Get-WMIObject -Class Win32_Process -Filter {Name = 'amazon-ssm-agent.exe' or Name = 'ssm-agent-worker.exe' } | select SessionId, Name, CreationDate, CommandLine | Format-Table -AutoSize | Out-String | % {$_.replace('\', '\\')} | %{$_.replace('"','\"')} | %{$_.replace('/','\/')} | out-file -encoding ASCII -Append $tmp_file
 
<#
9. App - gabia (Zenius, XMS)
#>

Write-output "============= App - gabia (Zenius, XMS) =============" | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file

Get-WMIObject -Class Win32_Process -Filter {Name = 'zagent.exe' or Name = 'gabia_mond.exe'} | select SessionId, Name, CreationDate, CommandLine  | Format-Table -AutoSize | Out-String | % {$_.replace('\', '\\')} | %{$_.replace('"','\"')} | %{$_.replace('/','\/')} | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file


<#
10. App - installed Software
#>

Write-output "============= App - installed Software =============" | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file

Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Format-Table -AutoSize  | Out-String | % {$_.replace('\', '\\')} | %{$_.replace('"','\"')} | %{$_.replace('/','\/')} | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file


<#
10. Windows ScheduledTask
#>

Write-output "============= Windows ScheduledTask - simple =============" | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file


Get-ScheduledTask -TaskPath '\' | Get-ScheduledTaskInfo | Select-Object TaskName, LastRunTime, LastTaskResult, NextRunTime, NumberOfMissedRuns | ft -autosize | Out-String | % {$_.replace('\', '\\')} | %{$_.replace('"','\"')} | %{$_.replace('/','\/')} | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file


Write-output "============= Windows ScheduledTask - detailed =============" | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file


Get-ScheduledTask -TaskName "*" | Select-Object Actions, Author, Date, Description, Documentation, Principal, SecurityDescriptor, Settings, Source, TaskName, TaskPath, Triggers, URI, Version  | Out-String | % {$_.replace('\', '\\')} | %{$_.replace('"','\"')} | %{$_.replace('/','\/')} | out-file -encoding ASCII -Append $tmp_file
Write-output "" | out-file -encoding ASCII -Append $tmp_file









<#
9999. result to json
#>


# (Get-Content $tmp_file) | foreach {$_ +  "\n"} | %{$_ -replace  '"', " "}| %{$_ -replace  ",", " "} | out-file -FilePath $tmp2_file -Force -Encoding ascii
(Get-Content $tmp_file) | foreach {$_ +  "\n"} | out-file -FilePath $tmp2_file -Force -Encoding ascii


$message = (Get-Content $tmp2_file)

echo "[" | out-file -encoding ASCII $stream_file
echo "   {" | out-file -encoding ASCII -Append $stream_file
echo "   ""timestamp"": $unixtime," | out-file -encoding ASCII -Append $stream_file
echo "   ""message"": ""$message""" | out-file -encoding ASCII -Append $stream_file
echo "   }" | out-file -encoding ASCII -Append $stream_file
echo "]" | out-file -encoding ASCII -Append $stream_file


echo "" | out-file -encoding ASCII $result_file

& $aws_path logs create-log-group --region $region --log-group-name "$stream_group" | out-file -encoding ASCII -Append $result_file
& $aws_path logs create-log-stream --region $region --log-group-name "$stream_group"  --log-stream-name "$stream_name"  | out-file -encoding ASCII -Append $result_file
& $aws_path logs put-log-events --region $region --log-group-name "$stream_group" --log-stream-name "$stream_name" --log-events file://$stream_file  | out-file -encoding ASCII -Append $result_file
