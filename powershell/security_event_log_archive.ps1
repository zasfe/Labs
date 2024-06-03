# Title:   MonitorSecurityLog.ps1
# Version: 1.0.0, 18JAN17
# Author:  James Sanders
# Purpose: Monitor the security log and automatically archive and clear the log if it's over 250 MB in size.
# URL: https://www.thelazyitadmin.com/archive-windows-security-event-log/


# Set the archive location
$ArchiveFolder = "D:\Logs\OS"

# How big can the security event log get in MB before we automatically archive?
$ArchiveSize = 250

# Verify the archive folder exists
If (!(Test-Path $ArchiveFolder)) {
  Write-Host
  Write-Host "Archive folder $ArchiveFolder does not exist, aborting ..." -ForegroundColor Red
  Exit
}

# Configure environment
$sysName        = $env:computername
$eventName      = "Security Event Log Monitoring"
$mailMsgServer  = "your.smtp.server.name"
$mailMsgSubject = "$sysName Security Event Log Monitoring"
$mailMsgFrom    = "from@email.address"
$mailMsgTo      = "to@email.address"

# Add event source to application log if necessary 
If (-NOT ([System.Diagnostics.EventLog]::SourceExists($eventName))) { 
  New-EventLog -LogName Application -Source $eventName
} 

# Check the security log
$Log = Get-WmiObject Win32_NTEventLogFile -Filter "logfilename = 'security'"
$SizeCurrentMB = [math]::Round($Log.FileSize / 1024 / 1024,2)
$SizeMaximumMB = [math]::Round($Log.MaxFileSize / 1024 / 1024,2)
Write-Host

# Archive the security log if over the limit
If ($SizeCurrentMB -gt $ArchiveSize) {
  $ArchiveFile = $ArchiveFolder + "\Security-" + (Get-Date -Format "yyyy-MM-dd@HHmm") + ".evt"
  $EventMessage = "The security event log size is currently " + $SizeCurrentMB + " MB.  The maximum allowable size is " + $SizeMaximumMB + " MB.  The security event log size has exceeded the threshold of $ArchiveSize MB."
  $Results = ($Log.BackupEventlog($ArchiveFile)).ReturnValue
  If ($Results -eq 0) {
    # Successful backup of security event log
    $Results = ($Log.ClearEventlog()).ReturnValue
    $EventMessage += "The security event log was successfully archived to $ArchiveFile and cleared."
    Write-Host $EventMessage
    Write-EventLog -LogName Application -Source $eventName -EventId 11 -EntryType Information -Message $eventMessage -Category 0
    $mailMsgBody = $EventMessage
    Send-MailMessage -From $mailMsgFrom -to $MailMsgTo -subject $mailMsgSubject -Body $mailMsgBody -SmtpServer $mailMsgServer
  }
  Else {
    $EventMessage += "The security event log could not be archived to $ArchiveFile and was not cleared.  Review and resolve security event log issues on $sysName ASAP!"
    Write-Host $EventMessage
    Write-EventLog -LogName Application -Source $eventName -EventId 11 -EntryType Error -Message $eventMessage -Category 0
    $mailMsgBody = $EventMessage
    Send-MailMessage -From $mailMsgFrom -to $MailMsgTo -subject $mailMsgSubject -Body $mailMsgBody -SmtpServer $mailMsgServer
  }
}
Else {
  # Write an informational event to the application event log
  $EventMessage = "The security event log size is currently " + $SizeCurrentMB + " MB.  The maximum allowable size is " + $SizeMaximumMB + " MB.  The security event log size is below the threshold of $ArchiveSize MB so no action was taken."
  Write-Host $EventMessage
  Write-EventLog -LogName Application -Source $eventName -EventId 11 -EntryType Information -Message $eventMessage -Category 0
}
# Close the log
$Log.Dispose()
