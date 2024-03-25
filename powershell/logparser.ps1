# Logparser

# http://www.leeholmes.com/blog/2008/07/30/workaround-the-os-handles-position-is-not-what-filestream-expected/
$bindingFlags = [Reflection.BindingFlags] "Instance,NonPublic,GetField"
$objectRef = $host.GetType().GetField("externalHostRef", $bindingFlags).GetValue($host)

$bindingFlags = [Reflection.BindingFlags] "Instance,NonPublic,GetProperty"
$consoleHost = $objectRef.GetType().GetProperty("Value", $bindingFlags).GetValue($objectRef, @())

[void] $consoleHost.GetType().GetProperty("IsStandardOutputRedirected", $bindingFlags).GetValue($consoleHost, @())
$bindingFlags = [Reflection.BindingFlags] "Instance,NonPublic,GetField"
$field = $consoleHost.GetType().GetField("standardOutputWriter", $bindingFlags)
$field.SetValue($consoleHost, [Console]::Out)
$field2 = $consoleHost.GetType().GetField("standardErrorWriter", $bindingFlags)
$field2.SetValue($consoleHost, [Console]::Out)

###############
# Security Log
###############

# Find Event id
Write-Host "[5038] Code integrity determined that the image hash of a file is not valid"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '5038'"

# Show what eventids in event log sorted by count
Write-Host "Eventids in event log sorted by count"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT COUNT(*) AS CNT, EventID FROM 'Security.evtx' GROUP BY EventID ORDER BY CNT DESC"


# Eventid 1102
# Eventlog was cleared
Write-Host "[1102] Eventlog was cleared"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 1, '|') as Username, EXTRACT_TOKEN(Strings, 2, '|') AS Workstation FROM 'Security.evtx' WHERE EventID = '1102'"


# Eventid 4624
# successful logon
Write-Host "[4624] successful logon"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 5, '|') as Username, EXTRACT_TOKEN(Strings, 6, '|') as Domain, EXTRACT_TOKEN(Strings, 8, '|') as LogonType,EXTRACT_TOKEN(strings, 9, '|') AS AuthPackage, EXTRACT_TOKEN(Strings, 11, '|') AS Workstation, EXTRACT_TOKEN(Strings, 17, '|') AS ProcessName, EXTRACT_TOKEN(Strings, 18, '|') AS SourceIP INTO '[4624] successful logon.csv' FROM 'Security.evtx' WHERE EventID = 4624 AND Username NOT IN ('SYSTEM'; 'ANONYMOUS LOGON'; 'LOCAL SERVICE'; 'NETWORK SERVICE') AND Domain NOT IN ('NT AUTHORITY')"

# Find specific user
Write-Host "[4624] administrator"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 5, '|') as Username, EXTRACT_TOKEN(Strings, 6, '|') as Domain, EXTRACT_TOKEN(Strings, 8, '|') as LogonType,EXTRACT_TOKEN(strings, 9, '|') AS AuthPackage, EXTRACT_TOKEN(Strings, 11, '|') AS Workstation, EXTRACT_TOKEN(Strings, 17, '|') AS ProcessName, EXTRACT_TOKEN(Strings, 18, '|') AS SourceIP FROM 'Security.evtx' WHERE EventID = 4624 AND Username NOT IN ('SYSTEM'; 'ANONYMOUS LOGON'; 'LOCAL SERVICE'; 'NETWORK SERVICE') AND Domain NOT IN ('NT AUTHORITY') AND Username = 'Administrator'"

# Find RDP logons
Write-Host "[4624] RDP logons"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 5, '|') as Username, EXTRACT_TOKEN(Strings, 6, '|') as Domain, EXTRACT_TOKEN(Strings, 8, '|') as LogonType,EXTRACT_TOKEN(strings, 9, '|') AS AuthPackage, EXTRACT_TOKEN(Strings, 11, '|') AS Workstation, EXTRACT_TOKEN(Strings, 17, '|') AS ProcessName, EXTRACT_TOKEN(Strings, 18, '|') AS SourceIP FROM 'Security.evtx' WHERE EventID = 4624 AND Username NOT IN ('SYSTEM'; 'ANONYMOUS LOGON'; 'LOCAL SERVICE'; 'NETWORK SERVICE') AND Domain NOT IN ('NT AUTHORITY') AND LogonType = '10'"

# Find console logons
Write-Host "[4624] console logons"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 5, '|') as Username, EXTRACT_TOKEN(Strings, 6, '|') as Domain, EXTRACT_TOKEN(Strings, 8, '|') as LogonType,EXTRACT_TOKEN(strings, 9, '|') AS AuthPackage, EXTRACT_TOKEN(Strings, 11, '|') AS Workstation, EXTRACT_TOKEN(Strings, 17, '|') AS ProcessName, EXTRACT_TOKEN(Strings, 18, '|') AS SourceIP INTO '[4624] console logons.csv' FROM 'Security.evtx' WHERE EventID = 4624 AND Username NOT IN ('SYSTEM'; 'ANONYMOUS LOGON'; 'LOCAL SERVICE'; 'NETWORK SERVICE') AND Domain NOT IN ('NT AUTHORITY') AND LogonType = '2'"

# Find specific IP
Write-Host "[4624] specific IP"
#& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 5, '|') as Username, EXTRACT_TOKEN(Strings, 6, '|') as Domain, EXTRACT_TOKEN(Strings, 8, '|') as LogonType,EXTRACT_TOKEN(strings, 9, '|') AS AuthPackage, EXTRACT_TOKEN(Strings, 11, '|') AS Workstation, EXTRACT_TOKEN(Strings, 17, '|') AS ProcessName, EXTRACT_TOKEN(Strings, 18, '|') AS SourceIP FROM 'Security.evtx' WHERE EventID = 4624 AND Username NOT IN ('SYSTEM'; 'ANONYMOUS LOGON'; 'LOCAL SERVICE'; 'NETWORK SERVICE') AND Domain NOT IN ('NT AUTHORITY') AND SourceIP = '10.1.47.151'"


# look at NTLM based logons
# possible pass-the-hash
Write-Host "[4624] NTLM based logons possible pass-the-hash"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 5, '|') as Username, EXTRACT_TOKEN(Strings, 6, '|') as Domain, EXTRACT_TOKEN(Strings, 8, '|') as LogonType, EXTRACT_TOKEN(strings, 10, '|') AS AuthPackage, EXTRACT_TOKEN(Strings, 11, '|') AS Workstation, EXTRACT_TOKEN(Strings, 17, '|') AS ProcessName, EXTRACT_TOKEN(Strings, 18, '|') AS SourceIP FROM 'Security.evtx' WHERE EventID = 4624 AND Username NOT IN ('SYSTEM'; 'ANONYMOUS LOGON'; 'LOCAL SERVICE'; 'NETWORK SERVICE') AND Domain NOT IN ('NT AUTHORITY') AND AuthPackage LIKE '%NtLmSsp%' AND Username NOT LIKE '%$'"

# group by NTLM users
Write-Host "[4624] group by NTLM users"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -q:ON -rtp:-1 -stats:OFF -i:EVT "SELECT COUNT(*) AS CNT, EXTRACT_TOKEN(Strings, 5, '|') as Username, EXTRACT_TOKEN(Strings, 6, '|') as Domain, EXTRACT_TOKEN(Strings, 8, '|') as LogonType, EXTRACT_TOKEN(strings, 9, '|') AS AuthPackage, EXTRACT_TOKEN(Strings, 11, '|') AS Workstation, EXTRACT_TOKEN(Strings, 17, '|') AS ProcessName, EXTRACT_TOKEN(Strings, 18, '|') AS SourceIP FROM 'Security.evtx' WHERE EventID = 4624 AND Username NOT IN ('SYSTEM'; 'ANONYMOUS LOGON'; 'LOCAL SERVICE'; 'NETWORK SERVICE') AND Domain NOT IN ('NT AUTHORITY') AND AuthPackage LIKE '%NtLmSsp%' AND Username NOT LIKE '%$' GROUP BY Username, Domain, LogonType, AuthPackage, Workstation, ProcessName, SourceIP ORDER BY CNT DESC"


# group by users
Write-Host "[4624] group by users"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT EXTRACT_TOKEN(Strings, 5, '|') as Username, COUNT(*) AS CNT FROM 'Security.evtx' WHERE EventID = 4624 AND Username NOT IN ('SYSTEM'; 'ANONYMOUS LOGON'; 'LOCAL SERVICE'; 'NETWORK SERVICE') AND Username NOT LIKE '%$' GROUP BY Username ORDER BY CNT DESC"

# group by domain
Write-Host "[4624] group by domain"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT EXTRACT_TOKEN(Strings, 6, '|') as Domain, COUNT(*) AS CNT FROM 'Security.evtx' WHERE EventID = 4624 GROUP BY Domain ORDER BY CNT DESC"

# group by authpackage
Write-Host "[4624] group by authpackage"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT EXTRACT_TOKEN(Strings, 9, '|') as AuthPackage, COUNT(*) AS CNT FROM 'Security.evtx' WHERE EventID = 4624 GROUP BY AuthPackage ORDER BY CNT DESC"

# group by LogonType
Write-Host "[4624] group by LogonType"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT EXTRACT_TOKEN(Strings, 8, '|') as LogonType, COUNT(*) AS CNT FROM 'Security.evtx' WHERE EventID = 4624 GROUP BY LogonType ORDER BY CNT DESC"

# group by workstation name
Write-Host "[4624] group by workstation name"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT EXTRACT_TOKEN(Strings, 11, '|') as Workstation, COUNT(*) AS CNT FROM 'Security.evtx' WHERE EventID = 4624 GROUP BY Workstation ORDER BY CNT DESC"

# group by process name
Write-Host "[4624] group by process name"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT EXTRACT_TOKEN(Strings, 17, '|') as ProcName, COUNT(*) AS CNT FROM 'Security.evtx' WHERE EventID = 4624 GROUP BY ProcName ORDER BY CNT DESC"

# Event id 4625
# unsuccessful logon
Write-Host "[4625] unsuccessful logon"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 5, '|') as Username, EXTRACT_TOKEN(Strings, 6, '|') as Domain, EXTRACT_TOKEN(Strings, 10, '|') as LogonType,EXTRACT_TOKEN(strings, 11, '|') AS AuthPackage, EXTRACT_TOKEN(Strings, 13, '|') AS Workstation, EXTRACT_TOKEN(Strings, 19, '|') AS SourceIP FROM 'Security.evtx' WHERE EventID = 4625 AND Username NOT IN ('SYSTEM'; 'ANONYMOUS LOGON'; 'LOCAL SERVICE'; 'NETWORK SERVICE') AND Domain NOT IN ('NT AUTHORITY')"

# Find specific User
Write-Host "[4625] administrator"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 5, '|') as Username, EXTRACT_TOKEN(Strings, 6, '|') as Domain, EXTRACT_TOKEN(Strings, 10, '|') as LogonType,EXTRACT_TOKEN(strings, 11, '|') AS AuthPackage, EXTRACT_TOKEN(Strings, 13, '|') AS Workstation, EXTRACT_TOKEN(Strings, 19, '|') AS SourceIP FROM 'Security.evtx' WHERE EventID = 4625 AND Username NOT IN ('SYSTEM'; 'ANONYMOUS LOGON'; 'LOCAL SERVICE'; 'NETWORK SERVICE') AND Domain NOT IN ('NT AUTHORITY') AND Username = 'Administrator'"


# Find specific IP
#& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 5, '|') as Username, EXTRACT_TOKEN(Strings, 6, '|') as Domain, EXTRACT_TOKEN(Strings, 10, '|') as LogonType,EXTRACT_TOKEN(strings, 11, '|') AS AuthPackage, EXTRACT_TOKEN(Strings, 13, '|') AS Workstation, EXTRACT_TOKEN(Strings, 19, '|') AS SourceIP FROM 'Security.evtx' WHERE EventID = 4625 AND Username NOT IN ('SYSTEM'; 'ANONYMOUS LOGON'; 'LOCAL SERVICE'; 'NETWORK SERVICE') AND Domain NOT IN ('NT AUTHORITY') AND SourceIP = '10.1.47.151'"

# check ntlm based attempts
Write-Host "[4625] ntlm based attempts"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 5, '|') as Username, EXTRACT_TOKEN(Strings, 6, '|') as Domain, EXTRACT_TOKEN(Strings, 10, '|') as LogonType, EXTRACT_TOKEN(strings, 11, '|') AS AuthPackage, EXTRACT_TOKEN(Strings, 13, '|') AS Workstation, EXTRACT_TOKEN(Strings, 19, '|') AS SourceIP FROM 'Security.evtx' WHERE EventID = 4625 AND Username NOT IN ('SYSTEM'; 'ANONYMOUS LOGON'; 'LOCAL SERVICE'; 'NETWORK SERVICE') AND Domain NOT IN ('NT AUTHORITY') AND AuthPackage LIKE '%NtLmSsp%' AND Username NOT LIKE '%$'"

# group by ntlm users
Write-Host "[4625] group by ntlm users"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT COUNT(*) AS CNT, EXTRACT_TOKEN(Strings, 5, '|') as Username, EXTRACT_TOKEN(Strings, 6, '|') as Domain, EXTRACT_TOKEN(Strings, 10, '|') as LogonType,EXTRACT_TOKEN(strings, 11, '|') AS AuthPackage, EXTRACT_TOKEN(Strings, 13, '|') AS Workstation, EXTRACT_TOKEN(Strings, 19, '|') AS SourceIP FROM 'Security.evtx' WHERE EventID = 4625 AND Username NOT IN ('SYSTEM'; 'ANONYMOUS LOGON'; 'LOCAL SERVICE'; 'NETWORK SERVICE') AND Domain NOT IN ('NT AUTHORITY') AND AuthPackage LIKE '%NtLmSsp%' AND Username NOT LIKE '%$' GROUP BY Username, Domain, LogonType, AuthPackage, Workstation, SourceIP ORDER BY CNT DESC"

# group by Username
Write-Host "[4625] group by Username"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT COUNT(*) AS CNT, EXTRACT_TOKEN(Strings, 5, '|') as Username FROM 'Security.evtx' WHERE EventID = 4625 AND Username NOT IN ('SYSTEM'; 'ANONYMOUS LOGON'; 'LOCAL SERVICE'; 'NETWORK SERVICE') AND Username NOT LIKE '%$' GROUP BY Username ORDER BY CNT DESC"


# event id 4634
# user logoff
Write-Host "[4634] user logoff"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 1, '|') AS Username, EXTRACT_TOKEN(Strings, 2, '|') AS Domain FROM 'Security.evtx' WHERE EventID = 4634 AND Domain NOT IN ('NT AUTHORITY')"


# Event id 4648
# explicit creds was used
Write-Host "[4648] explicit creds was used"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT timegenerated as date, extract_token(strings, 1, '|') as accountname, extract_token(strings, 2, '|') as domain, extract_token(strings, 5, '|') as usedaccount, extract_token(strings, 6, '|') as useddomain, extract_token(strings, 8, '|') as targetserver, extract_token(strings, 9, '|') as extradata, extract_token(strings, 11, '|') as procname, extract_token(strings, 12, '|') as sourceip INTO '[4648] explicit creds was used.csv' from 'Security.evtx' WHERE EventID = 4648"

# Search by accountname
Write-Host "[4648] administrator"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT timegenerated as date, extract_token(strings, 1, '|') as accountname, extract_token(strings, 2, '|') as domain, extract_token(strings, 5, '|') as usedaccount, extract_token(strings, 6, '|') as useddomain, extract_token(strings, 8, '|') as targetserver, extract_token(strings, 9, '|') as extradata, extract_token(strings, 11, '|') as procname, extract_token(strings, 12, '|') as sourceip from 'Security.evtx' WHERE EventID = 4648 AND accountname = 'Administrator'"

# Search by usedaccount
Write-Host "[4648] usedaccount"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT timegenerated as date, extract_token(strings, 1, '|') as accountname, extract_token(strings, 2, '|') as domain, extract_token(strings, 5, '|') as usedaccount, extract_token(strings, 6, '|') as useddomain, extract_token(strings, 8, '|') as targetserver, extract_token(strings, 9, '|') as extradata, extract_token(strings, 11, '|') as procname, extract_token(strings, 12, '|') as sourceip from 'Security.evtx' WHERE EventID = 4648 AND usedaccount = 'Administrator'"

# group by accountname
Write-Host "[4648] group by accountname"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT COUNT(*) as CNT, extract_token(strings, 1, '|') as accountname from 'Security.evtx' WHERE EventID = 4648 GROUP BY accountname ORDER BY CNT DESC"

# group by used account
Write-Host "[4648] group by used account"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT COUNT(*) as CNT, extract_token(strings, 5, '|') as usedaccount from 'Security.evtx' WHERE EventID = 4648 GROUP BY usedaccount ORDER BY CNT DESC"

# event id 4657
# A registry value was modified
Write-Host "[4657] A registry value was modified"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '4657'"


# event id 4663
# An attempt was made to access an object
Write-Host "[4663] An attempt was made to access an object"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '4663'"


# Event id 4672
# Admin logon
Write-Host "[4672] Admin logon"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 1, '|') AS Username, EXTRACT_TOKEN(Strings, 2, '|') AS Domain FROM 'Security.evtx' WHERE EventID = 4672 AND Domain NOT IN ('NT AUTHORITY')"

# Find specific user
Write-Host "[4672] administrator"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 1, '|') AS Username, EXTRACT_TOKEN(Strings, 2, '|') AS Domain FROM 'Security.evtx' WHERE EventID = 4672 AND Domain NOT IN ('NT AUTHORITY') AND Username = 'Administrator'"

# group by username
Write-Host "[4672] group by username"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select EXTRACT_TOKEN(Strings, 1, '|') AS Username, COUNT(*) AS CNT FROM 'Security.evtx' WHERE EventID = 4672 AND Username NOT IN ('SYSTEM'; 'ANONYMOUS LOGON'; 'LOCAL SERVICE'; 'NETWORK SERVICE') AND Username NOT LIKE '%$' GROUP BY Username ORDER BY CNT DESC"

# group by domain
Write-Host "[4672] group by domain"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select EXTRACT_TOKEN(Strings, 2, '|') AS Domain, COUNT(*) AS CNT FROM 'Security.evtx' WHERE EventID = 4672 AND Domain NOT IN ('NT AUTHORITY') GROUP BY Domain ORDER BY CNT DESC"

# event id 4688
# new process was created
Write-Host "[4688] new process was created"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 1, '|') AS Username, EXTRACT_TOKEN(Strings, 2, '|') AS Domain, EXTRACT_TOKEN(Strings, 5, '|') AS Process FROM 'Security.evtx' WHERE EventID = 4688"

# Search by user
Write-Host "[4688] administrator"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 1, '|') AS Username, EXTRACT_TOKEN(Strings, 2, '|') AS Domain, EXTRACT_TOKEN(Strings, 5, '|') AS Process FROM 'Security.evtx' WHERE EventID = 4688 AND Username = 'Administrator'"

# Search by process name
Write-Host "[4688] process: rundll32"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 1, '|') AS Username, EXTRACT_TOKEN(Strings, 2, '|') AS Domain, EXTRACT_TOKEN(Strings, 5, '|') AS Process FROM 'Security.evtx' WHERE EventID = 4688 AND Process LIKE '%rundll32.exe%'"

# group by username
Write-Host "[4688] group by username"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT COUNT(*) AS CNT, EXTRACT_TOKEN(Strings, 1, '|') AS Username FROM 'Security.evtx' WHERE EventID = 4688 GROUP BY Username ORDER BY CNT DESC"

# group by process name
Write-Host "[4688] group by process name"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT COUNT(*) AS CNT, EXTRACT_TOKEN(Strings, 5, '|') AS Process FROM 'Security.evtx' WHERE EventID = 4688 GROUP BY Process ORDER BY CNT DESC"


# event id 4704
# A user right was assigned
Write-Host "[4704] A user right was assigned"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '4704'"

# event id 4705
# A user right was removed
Write-Host "[4705] A user right was removed"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '4705'"

# event id 4706
# A new trust was created to a domain
Write-Host "[4706] A new trust was created to a domain"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '4706'"

# event id 4720
# A user account was created
Write-Host "[4720] A user account was created"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(Strings, 0, '|') AS createduser, extract_token(strings, 1, '|') AS createddomain, extract_token(strings, 4, '|') as whocreated, extract_token(strings, 5, '|') AS whodomain FROM 'Security.evtx' WHERE EventID = '4720'"


# Event id 4722
# user account was enabled
Write-Host "[4722] user account was enabled"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(strings, 0, '|') as user, extract_token(strings, 1, '|') as domain, extract_token(strings, 4, '|') as whichaccount, extract_token(strings, 5, '|') as whichdomain FROM 'Security.evtx' WHERE EventID = 4722"

# event id 4723
# attempt to change password for the account - user changed his own password
Write-Host "[4723] attempt to change password for the account - user changed his own password"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(strings, 0, '|') as user, extract_token(strings, 1, '|') as domain, extract_token(strings, 4, '|') as whichaccount, extract_token(strings, 5, '|') as whichdomain FROM 'Security.evtx' WHERE EventID = 4723"

# event id 4724
# attempt to reset user
Write-Host "[4724] attempt to reset user"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(strings, 0, '|') as user, extract_token(strings, 1, '|') as domain, extract_token(strings, 4, '|') as whichaccount, extract_token(strings, 5, '|') as whichdomain FROM 'Security.evtx' WHERE EventID = 4724"


# event id 4725
# user account was disabled
Write-Host "[4725] user account was disabled"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(strings, 0, '|') as user, extract_token(strings, 1, '|') as domain, extract_token(strings, 4, '|') as whichaccount, extract_token(strings, 5, '|') as whichdomain FROM 'Security.evtx' WHERE EventID = 4725"

# event id 4726
# A user account was deleted
Write-Host "[4726] A user account was deleted"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(Strings, 0, '|') AS deleteduser, extract_token(strings, 1, '|') AS deleteddomain, extract_token(strings, 4, '|') as whodeleted, extract_token(strings, 5, '|') AS whodomain FROM 'Security.evtx' WHERE EventID = '4726'"

# event id 4727
# A security-enabled global group was created
Write-Host "[4727] A security-enabled global group was created"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT *  FROM 'Security.evtx' WHERE EventID = '4727'"

# event id 4728
# A member was added to a security-enabled global group
Write-Host "[4728] A member was added to a security-enabled global group"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(Strings, 0, '|') as addeduser, extract_token(strings, 2, '|') as togroup, extract_token(strings, 3, '|') as groupdomain, extract_token(strings, 6, '|') as whoadded, extract_token(strings, 7, '|') as whodomain FROM 'Security.evtx' WHERE EventID = '4728'"

# event id 4729
# A member was removed from a security-enabled global group
Write-Host "[4729] A member was removed from a security-enabled global group"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(Strings, 0, '|') as removeduser, extract_token(strings, 2, '|') as fromgroup, extract_token(strings, 3, '|') as groupdomain, extract_token(strings, 6, '|') as whoremoved, extract_token(strings, 7, '|') as whodomain FROM 'Security.evtx' WHERE EventID = '4729'"

# event id 4730
# A security-enabled global group was deleted
Write-Host "[4730] A security-enabled global group was deleted"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '4730'"

# event id 4731
# A security-enabled local group was created
Write-Host "[4731] A security-enabled local group was created"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(strings, 0, '|') as createdgroup, extract_token(strings, 1, '|') as domain, extract_token(strings, 4, '|') as whichaccount, extract_token(strings, 5, '|') as whichdomain FROM 'Security.evtx' WHERE EventID = 4731"

# event id 4732
# A member was added to a security-enabled local group
Write-Host "[4732] A member was added to a security-enabled local group"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(Strings, 0, '|') as addeduser, extract_token(strings, 2, '|') as togroup, extract_token(strings, 3, '|') as groupdomain, extract_token(strings, 6, '|') as whoadded, extract_token(strings, 7, '|') as whodomain FROM 'Security.evtx' WHERE EventID = '4732'"

# event id 4733
# A member was removed from a security-enabled local group
Write-Host "[4733] A member was removed from a security-enabled local group"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(Strings, 0, '|') as removeduser, extract_token(strings, 2, '|') as fromgroup, extract_token(strings, 3, '|') as groupdomain, extract_token(strings, 6, '|') as whoremoved, extract_token(strings, 7, '|') as whodomain FROM 'Security.evtx' WHERE EventID = '4733'"

# event id 4734
#  A security-enabled local group was deleted
Write-Host "[4734] A security-enabled local group was deleted"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 2, '|') AS whichgroup, EXTRACT_TOKEN(Strings, 3, '|') AS domaingroup, EXTRACT_TOKEN(Strings, 6, '|') AS who, EXTRACT_TOKEN(Strings, 7, '|') AS workstation FROM 'Security.evtx' WHERE EventID = 4734"

# event id 4738
# user account was changed
Write-Host "[4738] user account was changed"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(strings, 1, '|') as user, extract_token(strings, 2, '|') as domain, extract_token(strings, 5, '|') as whichaccount, extract_token(strings, 6, '|') as whichdomain FROM 'Security.evtx' WHERE EventID = 4738"

# event id 4740
# A user account was locked out
Write-Host "[4740] A user account was locked out"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(strings, 0, '|') as user, extract_token(strings, 1, '|') as workstation, extract_token(strings, 4, '|') as wholocked, extract_token(strings, 5, '|') as whodomain FROM 'Security.evtx' WHERE EventID = '4740'"

# event id 4742
# computer account was changed
Write-Host "[4742] computer account was changed"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(strings, 5, '|') as user, extract_token(strings, 6, '|') as domain, extract_token(strings, 1, '|') as whichaccount, extract_token(strings, 2, '|') as whichdomain FROM 'Security.evtx' WHERE EventID = 4742"

# event id 4754
# A security-enabled universal group was created
Write-Host "[4754] A security-enabled universal group was created"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(strings, 0, '|') as createdgroup, extract_token(strings, 1, '|') as domain, extract_token(strings, 4, '|') as whichaccount, extract_token(strings, 5, '|') as whichdomain FROM 'Security.evtx' WHERE EventID = 4754"

# event id 4756
# A member was added to a security-enabled universal group
Write-Host "[4756] A member was added to a security-enabled universal group"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(Strings, 0, '|') as addeduser, extract_token(strings, 2, '|') as togroup, extract_token(strings, 3, '|') as groupdomain, extract_token(strings, 6, '|') as whoadded, extract_token(strings, 7, '|') as whodomain FROM 'Security.evtx' WHERE EventID = '4756'"

# event id 4757
# A member was removed from a security-enabled universal group
Write-Host "[4757] A member was removed from a security-enabled universal group"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(Strings, 0, '|') as removeduser, extract_token(strings, 2, '|') as fromgroup, extract_token(strings, 3, '|') as groupdomain, extract_token(strings, 6, '|') as whoremoved, extract_token(strings, 7, '|') as whodomain FROM 'Security.evtx' WHERE EventID = '4757'"

# event id 4758
# A security-enabled universal group was deleted
Write-Host "[4758] A security-enabled universal group was deleted"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 2, '|') AS whichgroup, EXTRACT_TOKEN(Strings, 3, '|') AS domaingroup, EXTRACT_TOKEN(Strings, 6, '|') AS who, EXTRACT_TOKEN(Strings, 7, '|') AS workstation FROM 'Security.evtx' WHERE EventID = 4758"

# event id 4767
# A user account was unlocked
Write-Host "[4767] A user account was unlocked"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '4767'"


# event id 4768
# Kerberos TGT was requested
Write-Host "[4768] Kerberos TGT was requested"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(strings, 0, '|') as user, extract_token(strings, 1, '|') as domain, extract_token(strings, 7, '|') as cipher, extract_token(strings, 9, '|') as sourceip FROM 'Security.evtx' WHERE EventID = 4768"

# group by user
Write-Host "[4768] Group by user"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT extract_token(strings, 0, '|') as user, COUNT(*) AS CNT FROM 'Security.evtx' WHERE EventID = 4768 AND user NOT LIKE '%$' GROUP BY user ORDER BY CNT DESC"

# group by domain
Write-Host "[4768] group by domain"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT extract_token(strings, 1, '|') as domain, COUNT(*) AS CNT FROM 'Security.evtx' WHERE EventID = 4768 GROUP BY domain ORDER BY CNT DESC"

# group by cipher
Write-Host "[4768] group by cipher"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT extract_token(strings, 7, '|') as cipher, COUNT(*) AS CNT FROM 'Security.evtx' WHERE EventID = 4768 GROUP BY cipher ORDER BY CNT DESC"

# event id 4769
# Kerberos Service ticket was requested
Write-Host "[4769] Kerberos Service ticket was requested"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(strings, 0, '|') as user, extract_token(strings, 1, '|') as domain, extract_token(strings, 2, '|') as service, extract_token(strings, 5, '|') as cipher, extract_token(strings, 6, '|') as sourceip FROM 'Security.evtx' WHERE EventID = 4769"

# group by user
Write-Host "[4769] group by user"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT extract_token(strings, 0, '|') as user, COUNT(*) AS CNT FROM 'Security.evtx' WHERE EventID = 4769 AND user NOT LIKE '%$' GROUP BY user ORDER BY CNT DESC"

# group by domain
Write-Host "[4769] group by domain"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT extract_token(strings, 1, '|') as domain, COUNT(*) AS CNT FROM 'Security.evtx' WHERE EventID = 4769 GROUP BY domain ORDER BY CNT DESC"

# group by service
Write-Host "[4769] group by service"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT extract_token(strings, 2, '|') as service, COUNT(*) AS CNT FROM 'Security.evtx' WHERE EventID = 4769 GROUP BY service ORDER BY CNT DESC"

Write-Host "[4769] group by cipher"
# group by cipher
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT extract_token(strings, 5, '|') as cipher, COUNT(*) AS CNT FROM 'Security.evtx' WHERE EventID = 4769 GROUP BY cipher ORDER BY CNT DESC"

#####
# event id 4771
# kerberos pre-atuhentication failed
Write-Host "[4771] kerberos pre-atuhentication failed"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(strings, 0 , '|') as user, extract_token(strings, 6 , '|') as sourceip FROM 'Security.evtx' WHERE EventID = 4771 AND user NOT LIKE '%$'"

# group by user
Write-Host "[4771] group by user"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT extract_token(strings, 0, '|') as user, COUNT(user) AS CNT FROM 'Security.evtx' WHERE EventID = 4771 AND user NOT LIKE '%$' GROUP BY user ORDER BY CNT DESC"


#####
# event id 4776
# domain/computer attemped to validate user credentials
Write-Host "[4776] domain/computer attemped to validate user credentials"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 1, '|') AS Username, EXTRACT_TOKEN(Strings, 2, '|') AS Domain FROM 'Security.evtx' WHERE EventID = 4776 AND Domain NOT IN ('NT AUTHORITY') AND Username NOT LIKE '%$'"
# Search by username
Write-Host "[4771] administrator"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 1, '|') AS Username, EXTRACT_TOKEN(Strings, 2, '|') AS Domain FROM 'Security.evtx' WHERE EventID = 4776 AND Domain NOT IN ('NT AUTHORITY') AND Username NOT LIKE '%$' AND Username = 'Administrator'"

# group by username
Write-Host "[4771] group by username"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select EXTRACT_TOKEN(Strings, 1, '|') AS Username, COUNT(*) AS CNT FROM 'Security.evtx' WHERE EventID = 4776 AND Username NOT LIKE '%$' GROUP BY Username ORDER BY CNT DESC"

# group by domain
Write-Host "[4771] group by domain"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select EXTRACT_TOKEN(Strings, 2, '|') AS Domain, COUNT(*) AS CNT FROM 'Security.evtx' WHERE EventID = 4776 GROUP BY Domain ORDER BY CNT DESC"

#####
# event id 4778
# RDP session reconnected
Write-Host "[4778] RDP session reconnected"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date,EXTRACT_TOKEN(Strings, 0, '|') AS Username, EXTRACT_TOKEN(Strings, 1, '|') AS Domain, EXTRACT_TOKEN(Strings, 4, '|') AS Workstation, EXTRACT_TOKEN(Strings, 5, '|') AS SourceIP  FROM 'Security.evtx' WHERE EventID = 4778"

#####
# event id 4779
# RDP session disconnected
Write-Host "[4779] RDP session disconnected"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date,EXTRACT_TOKEN(Strings, 0, '|') AS Username, EXTRACT_TOKEN(Strings, 1, '|') AS Domain, EXTRACT_TOKEN(Strings, 4, '|') AS Workstation, EXTRACT_TOKEN(Strings, 5, '|') AS SourceIP  FROM 'Security.evtx' WHERE EventID = 4779"

#####
# event id 4781
# User account was renamed
Write-Host "[4781] User account was renamed"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 0, '|') AS newname, EXTRACT_TOKEN(Strings, 1, '|') AS oldname, EXTRACT_TOKEN(Strings, 2, '|') AS accdomain, EXTRACT_TOKEN(Strings, 5, '|') AS Username, EXTRACT_TOKEN(Strings, 6, '|') AS Domain FROM 'Security.evtx' WHERE EventID = 4781"

#####
# event id 4825
# RDP Access denied
Write-Host "[4825] RDP Access denied"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, EXTRACT_TOKEN(Strings, 0, '|') AS Username, EXTRACT_TOKEN(Strings, 1, '|') AS Domain, EXTRACT_TOKEN(Strings, 3, '|') AS SourceIP FROM 'Security.evtx' WHERE EventID = 4825"


# event id 4946
# new exception was added to firewall
Write-Host "[4946] new exception was added to firewall"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select TimeGenerated AS Date, extract_token(strings, 2, '|') as rulename FROM 'Security.evtx' WHERE EventID = 4946"

# group by rule name
Write-Host "[4946] group by rule name"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select Count(*) as CNT, extract_token(strings, 2, '|') as rulename FROM 'Security.evtx' WHERE EventID = 4946 GROUP BY rulename ORDER BY CNT DESC"

# event id 4948
# rule was deleted from firewall
Write-Host "[4948] rule was deleted from firewall"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select TimeGenerated AS Date, extract_token(strings, 2, '|') as rulename FROM 'Security.evtx' WHERE EventID = 4948"

# group by rule name
Write-Host "[4948] group by rule name"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select Count(*) as CNT, extract_token(strings, 2, '|') as rulename FROM 'Security.evtx' WHERE EventID = 4948 GROUP BY rulename ORDER BY CNT DESC"

# event id 5038
# Code integrity determined that the image hash of a file is not valid
Write-Host "[5038] Code integrity determined that the image hash of a file is not valid"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '5038'"

# event id 5136
# A directory service object was modified
Write-Host "[5136] A directory service object was modified"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT TimeGenerated AS Date, extract_token(strings, 3, '|') AS Username, extract_token(strings, 4, '|') AS Domain, extract_token(strings, 8, '|') AS objectdn, extract_token(strings, 10, '|') AS objectclass, extract_token(strings, 11, '|') AS objectattrib, extract_token(strings, 13, '|') AS attribvalue FROM 'Security.evtx' WHERE EventID = '5136'"

# group by username
Write-Host "[5136] group by username"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT COUNT(*) AS CNT, extract_token(strings, 3, '|') AS Username FROM 'Security.evtx' WHERE EventID = '5136' GROUP BY Username ORDER BY CNT DESC"

# group by domain
Write-Host "[5136] group by domain"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT COUNT(*) AS CNT, extract_token(strings, 4, '|') AS Domain FROM 'Security.evtx' WHERE EventID = '5136' GROUP BY Domain ORDER BY CNT DESC"

# group by objectdn
Write-Host "[5136] group by objectDN"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT COUNT(*) AS CNT, extract_token(strings, 8, '|') AS objectdn FROM 'Security.evtx' WHERE EventID = '5136' GROUP BY objectdn ORDER BY CNT DESC"

# group by objectclass
Write-Host "[5136] group by objectclass"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT COUNT(*) AS CNT, extract_token(strings, 10, '|') AS objectclass FROM 'Security.evtx' WHERE EventID = '5136' GROUP BY objectclass ORDER BY CNT DESC"

# group by objectattrib
Write-Host "[5136] group by object attrib"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT COUNT(*) AS CNT, extract_token(strings, 11, '|') AS objectattrib FROM 'Security.evtx' WHERE EventID = '5136' GROUP BY objectattrib ORDER BY CNT DESC"

# group by attribvalue
Write-Host "[5136] group by attrib value"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT COUNT(*) AS CNT, extract_token(strings, 13, '|') AS attribvalue FROM 'Security.evtx' WHERE EventID = '5136' GROUP BY attribvalue ORDER BY CNT DESC"


# event id 5137
# A directory service object was created
Write-Host "[5137] A directory service object was created"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '5137'"

# event id 5138
# A directory service object was undeleted
Write-Host "[5138] A directory service object was undeleted"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '5138'"

# event id 5139
# A directory service object was moved
Write-Host "[5139] A directory service object was moved"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '5139'"

# event id 5141
# A directory service object was deleted
Write-Host "[5141] A directory object was deleted"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '5141'"

# event id 5140
# A network share object was accessed
Write-Host "[5140] A network share object was accessed"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '5140'"

# event id 5142
# A network share object was added
Write-Host "[5142] A network shared object was added"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '5142'"

# event id 5143
# A network share object was modified
Write-Host "[5143] A network share object was modified"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '5143'"

# event id 5144
# A network share object was deleted
Write-Host "[5144] A network object was deleted"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '5144'"

# event id 5145
# A network share object was checked to see whether client can be granted desired access
Write-Host "[5145] A network share object was checked to where client can be granted desired access"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '5145'"

# event id 5154
# The Windows Filtering Platform has permitted an application or service to listen on a port for incoming connections
Write-Host "[5154] Windows Filtering Platform has permitted an application or service to listen on a port for incoming connections"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -stats:OFF -i:EVT "SELECT * INTO '[5154] Windows Filtering Platform has permitted an application or service to listen on a port for incoming connections.csv' FROM 'Security.evtx' WHERE EventID = '5154'"

# event id 5155
# The Windows Filtering Platform has blocked an application or service from listening on a port for incoming connections
Write-Host "[5155] Windows Filtering Platform has blocked an application or service from listening on a port for incoming connections"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '5155'"

# event id 5156
# The Windows Filtering Platform has allowed a connection
Write-Host "[5156] Windows Filtering Platform has allowed a connection"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -stats:OFF -i:EVT "SELECT * INTO '[5156] Windows Filtering Platform has allowed a connection.csv' FROM 'Security.evtx' WHERE EventID = '5156'"

# event id 5157
# The Windows Filtering Platform has blocked a connection
Write-Host "[5157] Windows Filtering Platform has blocked a connection"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -stats:OFF -i:EVT "SELECT * INTO '[5157] Windows Filtering Platform has blocked a connection[5157] Windows Filtering Platform has blocked a connection.csv' FROM 'Security.evtx' WHERE EventID = '5157'"

# event id 5158
# The Windows Filtering Platform has permitted a bind to a local port
Write-Host "[5158] Windows Filtering Platform has permitted a bind to a local port"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -stats:OFF -i:EVT "SELECT * INTO '[5158] Windows Filtering Platform has permitted a bind to a local port.csv' FROM 'Security.evtx' WHERE EventID = '5158'"

# event id 5159
# The Windows Filtering Platform has blocked a bind to a local port
Write-Host "[5159] Windows Filtering Platform has blocked a bind to a local port"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "SELECT * FROM 'Security.evtx' WHERE EventID = '5159'"

#############
# System Log.evtx
#############
# EventID 7045
# New Service was installed in system
Write-Host "[7045] New Service was installed in system"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -stats:OFF -i:EVT "Select TimeGenerated AS Date, extract_token(strings, 0, '|') AS ServiceName, extract_token(strings, 1, '|') AS ServicePath, extract_token(strings, 4, '|') AS ServiceUser INTO '[7045] New Service was installed in system.csv' FROM System.evtx WHERE EventID = 7045"


# EventID 7036
# Service actions
Write-Host "[7036] Service actions"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -stats:OFF -i:EVT "Select TimeGenerated AS Date, extract_token(strings, 0, '|') as servicename INTO '[7036] Service actions.csv' FROM System.evtx WHERE EventID = 7036"

# group by service name
Write-Host "[7036] group by service name"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select COUNT(*) as CNT, extract_token(strings, 0, '|') as servicename FROM System.evtx WHERE EventID = 7036 GROUP BY servicename ORDER BY CNT DESC"

#####################
# Task Scheduler Log.evtx
#####################
# EventID 100
# Task was run
Write-Host "[100] Task was run"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select TimeGenerated AS Date, extract_token(strings,0, '|') as taskname, extract_token(strings, 1, '|') as username INTO '[100] Task was run.csv' FROM 'Microsoft-Windows-TaskScheduler%4Operational.evtx' WHERE EventID = 100"

# group by taskname
Write-Host "[100] group by task"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select extract_token(strings, 0, '|') as taskname, count(*) as cnt FROM 'Microsoft-Windows-TaskScheduler%4Operational.evtx' WHERE EventID = 100 GROUP BY taskname ORDER BY CNT DESC"

# eventid 200
# action was executed
Write-Host "[200] task was executed"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select TimeGenerated AS Date, extract_token(strings,0, '|') as taskname, extract_token(strings, 1, '|') as taskaction INTO '[200] task was executed.csv' FROM 'Microsoft-Windows-TaskScheduler%4Operational.evtx' WHERE EventID = 200"

# group by action
Write-Host "[200] group by action"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select extract_token(strings, 1, '|') as taskaction, count(*) as cnt FROM 'Microsoft-Windows-TaskScheduler%4Operational.evtx' WHERE EventID = 200 GROUP BY taskaction ORDER BY CNT DESC"

# eventid 140
# user updated a task
Write-Host "[140] User updated a task"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select TimeGenerated as Date, extract_token(strings, 0, '|') as taskname, extract_token(strings, 1, '|') as user INTO '[140] User updated a task.csv' FROM 'Microsoft-Windows-TaskScheduler%4Operational.evtx' WHERE EventID = 140"

# group by user
Write-Host "[140] group by user"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select extract_token(strings, 1, '|') as user, count(*) as cnt FROM 'Microsoft-Windows-TaskScheduler%4Operational.evtx' WHERE EventID = 140 GROUP BY user ORDER BY CNT DESC"

# group by taskname
Write-Host "[140] group by taskname"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select extract_token(strings, 0, '|') as taskname, count(*) as cnt FROM 'Microsoft-Windows-TaskScheduler%4Operational.evtx' WHERE EventID = 140 GROUP BY taskname ORDER BY CNT DESC"

# event id 141
# user deleted a task
Write-Host "[141] user deleted a task"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select TimeGenerated as Date, extract_token(strings, 0, '|') as taskname, extract_token(strings, 1, '|') as user FROM 'Microsoft-Windows-TaskScheduler%4Operational.evtx' WHERE EventID = 141"

# group by user
Write-Host "[141] group by user"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select extract_token(strings, 1, '|') as user, count(*) as cnt FROM 'Microsoft-Windows-TaskScheduler%4Operational.evtx' WHERE EventID = 141 GROUP BY user ORDER BY CNT DESC"

# group by taskname
Write-Host "[141] group by taskname"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select extract_token(strings, 0, '|') as taskname, count(*) as cnt FROM 'Microsoft-Windows-TaskScheduler%4Operational.evtx' WHERE EventID = 141 GROUP BY taskname ORDER BY CNT DESC"

#######################
# Windows Firewall Log
#######################
# EventID 2004
# New exception rule was added
Write-Host "[2004] New exceotion rule was added"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select TimeGenerated AS Date, extract_token(strings, 1, '|') as rulename, extract_token(strings, 3, '|') as apppath, extract_token(strings, 22, '|') as changedapp INTO '[2004] New exceotion rule was added.csv' from 'Microsoft-Windows-Windows Firewall With Advanced Security%4Firewall.evtx' WHERE EventID = 2004"

# group by apppath
Write-Host "[2004] group by app path"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select COUNT(*) as CNT, extract_token(strings, 3, '|') as apppath from 'Microsoft-Windows-Windows Firewall With Advanced Security%4Firewall.evtx' WHERE EventID = 2004 GROUP BY apppath ORDER BY CNT DESC"

# event id 2005
# rule was changed
Write-Host "[2005] rule was changed"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select TimeGenerated AS Date, extract_token(Strings, 1, '|') as rulename, extract_token(Strings, 3, '|') AS apppath, extract_token(Strings, 4, '|') AS servicename, extract_token(strings, 7, '|') AS localport, extract_token(strings, 22, '|') as modifyingapp INTO '[2005] rule was changed.csv' from 'Microsoft-Windows-Windows Firewall With Advanced Security%4Firewall.evtx' WHERE EventID = 2005"

# group by apppath
Write-Host "[2005] group by app path"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select COUNT(*) as CNT, extract_token(strings, 3, '|') as apppath from 'Microsoft-Windows-Windows Firewall With Advanced Security%4Firewall.evtx' WHERE EventID = 2005 GROUP BY apppath ORDER BY CNT DESC"

# group by rulename
Write-Host "[2005] group by rulename"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select COUNT(*) as CNT, extract_token(strings, 1, '|') as rulename from 'Microsoft-Windows-Windows Firewall With Advanced Security%4Firewall.evtx' WHERE EventID = 2005 GROUP BY rulename ORDER BY CNT DESC"

# group by servicename
Write-Host "[2005] group by service name"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select COUNT(*) as CNT, extract_token(strings, 4, '|') as servicename from 'Microsoft-Windows-Windows Firewall With Advanced Security%4Firewall.evtx' WHERE EventID = 2005 GROUP BY servicename ORDER BY CNT DESC"

# group by local port
Write-Host "[2005] group by local part"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select COUNT(*) as CNT, extract_token(strings, 7, '|') as localport from 'Microsoft-Windows-Windows Firewall With Advanced Security%4Firewall.evtx' WHERE EventID = 2005 GROUP BY localport ORDER BY CNT DESC"

# group by modifyingapp
Write-Host "[2005] group by modifying app"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select COUNT(*) as CNT, extract_token(strings, 22, '|') as modifyingapp from 'Microsoft-Windows-Windows Firewall With Advanced Security%4Firewall.evtx' WHERE EventID = 2005 GROUP BY modifyingapp ORDER BY CNT DESC"

# event id 2006
# rule was deleted
Write-Host "[2006] rule was deleted"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select TimeGenerated AS Date, extract_token(Strings, 1, '|') as rulename, extract_token(strings, 3, '|') as changedapp from 'Microsoft-Windows-Windows Firewall With Advanced Security%4Firewall.evtx' WHERE EventID = 2006"

# group by rulename
Write-Host "[2006] group by rulename"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select COUNT(*) as CNT, extract_token(strings, 1, '|') as rulename from 'Microsoft-Windows-Windows Firewall With Advanced Security%4Firewall.evtx' WHERE EventID = 2006 GROUP BY rulename ORDER BY CNT DESC"

# group by changedapp
Write-Host "[2006] group by changed app"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select COUNT(*) as CNT, extract_token(strings, 3, '|') as changedapp from 'Microsoft-Windows-Windows Firewall With Advanced Security%4Firewall.evtx' WHERE EventID = 2006 GROUP BY changedapp ORDER BY CNT DESC"

# EventID 2011
# Firewall blocked inbound connections to the application, but did not notify the user
Write-Host "[2011] Firewall blocked inbound connections to the application, but did not notify the user"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select Timegenerated as date, extract_token(strings, 1, '|') as file, extract_token(strings, 4, '|') as port INTO '[2011] Firewall blocked inbound connections to the application but did not notify the user.csv' from 'Microsoft-Windows-Windows Firewall With Advanced Security%4Firewall.evtx' WHERE EventID = 2011"

# group by application
Write-Host "[2011] group by application"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select COUNT(*) as CNT, extract_token(strings, 1, '|') as file from'Microsoft-Windows-Windows Firewall With Advanced Security%4Firewall.evtx' WHERE EventID = 2011 GROUP BY file ORDER BY CNT DESC"

######################
# RDP LocalSession Log
# Local logins
######################
# Event id 21
# Successful logon
Write-Host "[21] RDP LocalSession Successful logon"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select timegenerated as Date, extract_token(strings, 0, '|') as user, extract_token(strings, 2, '|') as sourceip INTO '[21] RDP LocalSession Successful logon.csv' FROM 'Microsoft-Windows-TerminalServices-LocalSessionManager%4Operational.evtx' WHERE EventID = 21"

# find specific user
Write-Host "[21] administrator"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select timegenerated as Date, extract_token(strings, 0, '|') as user, extract_token(strings, 2, '|') as sourceip FROM 'Microsoft-Windows-TerminalServices-LocalSessionManager%4Operational.evtx' WHERE EventID = 21 AND user LIKE '%Administrator%'"

# group by user
Write-Host "[21] group by specific user"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select extract_token(strings, 0, '|') as user, count(*) as CNT FROM 'Microsoft-Windows-TerminalServices-LocalSessionManager%4Operational.evtx' WHERE EventID = 21 GROUP BY user ORDER BY CNT DESC"

#######################
# RDP RemoteSession Log
#######################
# Event ID 1149
# Successful logon
Write-Host "[1149] RDP RemoteSession Successful logon"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select timegenerated as Date, extract_token(strings, 0, '|') as user, extract_token(strings, 2, '|') as sourceip INTO '[1149] RDP RemoteSession Successful logon.csv' FROM 'Microsoft-Windows-TerminalServices-RemoteConnectionManager%4Operational.evtx' WHERE EventID = 1149"

# group by user
Write-Host "[1149] group by specific user"
& 'C:\Program Files (x86)\Log Parser 2.2\LogParser.exe' -rtp:-1 -stats:OFF -i:EVT "Select extract_token(strings, 0, '|') as user, count(*) as CNT FROM 'Microsoft-Windows-TerminalServices-RemoteConnectionManager%4Operational.evtx' WHERE EventID = 1149 GROUP BY user ORDER BY CNT DESC"
