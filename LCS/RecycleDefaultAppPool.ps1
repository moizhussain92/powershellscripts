#Restart Web App Pool
Import-Module WebAdministration
$pool = (Get-childItem "IIS:\Sites\"| Select-Object applicationPool).applicationPool
foreach ($poolName in $pool){
if ($poolName -eq 'DefaultAppPool'){
Restart-WebAppPool $poolName
Write-Host "$poolName Restarted on $env:COMPUTERNAME" 
        }
    }


#Recycle Default AppPool
$appPoolName = "DefaultAppPool" 
$appPool = Get-WmiObject -namespace "root\MicrosoftIISv2" -class "IIsApplicationPool" | Where-Object { $_.Name -eq "W3SVC/APPPOOLS/$appPoolName" }
          
$appPool.Recycle()
