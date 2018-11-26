Function ResolveDNS ($servers) {
        
    $ResolvedServers = $servers | foreach { Try { Resolve-DnsName $_ -ErrorAction Stop | select Name -ExpandProperty Name -First 1} Catch { Write-Warning $_.Exception.Message } }
    if ($ResolvedServers) {
        return $ResolvedServers
    }
    else {
        Break
    }
}

$importpath = 'C:\Temp\servers.xlsx'
$servers = Import-Excel $importpath -WorkSheetname Sheet1
$servers = ResolveDNS $servers.ServerName
$cred = Get-Credential
foreach ($server in $servers)
{
Write-Host "Trying...$server" -BackgroundColor Magenta
$result = Invoke-Command -ComputerName $server -ScriptBlock {hostname} -Credential $cred  -ErrorAction Continue
Write-Host $result -BackgroundColor DarkGreen
}
