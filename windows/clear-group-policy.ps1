#Clear existing GPO configuration from the device.

# -ref: https://www.reddit.com/r/msp/comments/m215uh/local_group_policies_using_lgpo_lgpoexe_to_deploy/

# Remove local GPO objects.
Remove-Item -Recurse -Path "$($ENV:windir)\System32\GroupPolicyUsers" -Force -ErrorAction silentlycontinue
Remove-Item -Recurse -Path "$($ENV:windir)\System32\GroupPolicy" -Force -ErrorAction silentlycontinue

# Remove the policies applied by direct registry edit rather than GPO objects.
if ((Get-PSDrive -PSProvider Registry).name -notcontains "HKU"){
    write-host "Creating PSDrive for HKEY_USERS."
    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
}
$Registrykeys=@('HKLM:\SOFTWARE\Policies\*','HKU:\*\SOFTWARE\Policies\*')
$policies=get-item $Registrykeys
foreach ($item in $policies) {
    $item.pspath | remove-item -recurse -force
}

# Finally, update the local group policy cache. Any domain assigned GPOs will be re-applied.
Write-Host "Running GPUpdate to clear local policy cache."
gpupdate /force
