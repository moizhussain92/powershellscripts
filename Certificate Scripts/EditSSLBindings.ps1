$scrtiptSSL = {
Import-Module WebAdministration
$thumbprint = ''
$CertShop=Get-ChildItem -Path Cert:\LocalMachine\My | where-Object {$_.Thumbprint -eq $thumbprint} | Select-Object -ExpandProperty Thumbprint
Get-Item IIS:\SslBindings\0.0.0.0!443 | Remove-Item
get-item -Path "cert:\LocalMachine\My\$certShop" | new-item -path IIS:\SslBindings\0.0.0.0!443
}

Invoke-Command -ComputerName $servers -Credential $cred -ScriptBlock $scrtiptSSL


$localobject = @()
$scriptGetSiteNames = {
Import-Module WebAdministration
$site = Get-ChildItem IIS:\Sites | select Name -ExpandProperty Name
    $localObject += New-Object PSObject -Property @{
        "SiteName" = $site;
        "ComputerName" = $env:COMPUTERNAME
                                                }
return $localObject | select SiteName, ComputerName
}

Invoke-Command -ComputerName $servers -Credential $cred -ScriptBlock $scriptGetSiteNames | Format-Table


$localobject = @()
$scriptGetSSLBindings = {
Import-Module WebAdministration
$site = Get-ChildItem IIS:\Sslbindings | where {$_.port -eq '443'}
    $localObject += New-Object PSObject -Property @{
        "SiteName" = $site.Sites.value;
        "Thumbprint" = $site.Thumbprint;
        "ComputerName" = $env:COMPUTERNAME
        "Port" = $site.Port;
        "IPAddress" = $site.IPAddress.IPAddressToString;
        "Store" = $site.store
                                                }
return $localObject 
}

$a = Invoke-Command -ComputerName $newServers -Credential $cred -ScriptBlock $scriptGetSSLBindings | Export-Excel -Path C:\Users\mohussai\Desktop\test.xlsx
$a.count


$startServiceIISADMIN = {
$status = Get-Service 'iisadmin'
if ($status.Status -eq 'Stopped') {
Start-Service $status.Name}
}


$startServiceW3SVC = {
$status = Get-Service 'w3svc'
if ($status.Status -eq 'Stopped') {
Start-Service $status.Name}
}


$Webapppool = {
Import-Module WebAdministration
$pool = (Get-childItem "IIS:\Sites\"| Select-Object applicationPool).applicationPool
foreach ($poolName in $pool){
if ($poolName -eq 'DefaultAppPool'){
Restart-WebAppPool $poolName
Write-Host "$poolName Restarted on $env:COMPUTERNAME" 
        }
    }
}

$RecycleApppool = {
$appPoolName = "DefaultAppPool" 
$appPool = Get-WmiObject -namespace "root\MicrosoftIISv2" -class "IIsApplicationPool" | Where-Object { $_.Name -eq "W3SVC/APPPOOLS/$appPoolName" }
          
$appPool.Recycle()
}


$newServers = $a | where {$_.computerName -notlike '*svcsp*' -and $_.siteName -notlike '*mbsinternal*' -and $_.siteName -notlike '*productionSorry*' } | select computername -ExpandProperty computername
$recyclePool = $newServers | where {$_ -like "*webprd*" -or $_ -like "*webnet*"}
Invoke-Command -ComputerName $recyclePool -Credential $cred -ScriptBlock $RecycleApppool