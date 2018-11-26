function RemoveInvalidAdmins ($serversScanned, $InvalidAdmins, [PSCredential]$cred) {
    Write-Verbose -Verbose "Removing Invalid Users from the Computers..."
    Remove-RemoteAdmins -ComputerName $serversScanned -RemoveAdmin $InvalidAdmins -Credential $cred

}