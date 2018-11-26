#$GetCred = Get-Credential
#Add-azurermaccount 
Login-AzureRmAccount #-Credential $GetCred -ErrorAction Stop

echo "`nGetting the subscriptions for this account..."
$script:SubscriptionsList = Get-AzureRmSubscription | select -Property SubscriptionName -ExpandProperty SubscriptionName | sort
echo "`nFollowing is the list of all the subscriptions: " `n
for ($i = 1; $i -le $SubscriptionsList.Count; $i++) {Write-Host ("$i. {0}" -f $SubscriptionsList[$i-1])}

do {
	$value = Read-host "`nPlease type the subscription you want to use or type ALL to select all subsciptions `n"
	if ($SubscriptionsList.contains($value) -eq $true) {$SubscriptionsList = $value; $flag = $true;}
	elseif ($value -eq "all") {echo '`nSelected all Subscriptions'; $flag = $true}
	else {echo '`nTry again!'; $flag = $false}
	}
	while ($flag -ne $true)
	
echo "`nCompiling the list of web-tests associalted with selected subscriptions in the account..."
	#Gets list of resourceID of all the webtests that are associated with all the subscriptions in the account.
	$webTestList = $subscriptionsList| foreach {Select-AzureRmSubscription -SubscriptionName $_ > $null ;Get-AzureRmResource -Verbose | select -Property resourcetype, resourceid | where -property resourcetype -like "*webtest*" | select -property resourceid -ExpandProperty resourceid}
    
	#Gets test status for all the web-tests for selected subscriptions associated with the account.
	<#
    echo ("`n{0} {1} web-tests..." -f "Showing", $webTestList.Count)
	try{
	$webTestList | foreach {$Status = Get-AzureRmResource -ResourceId $_; echo ("`n{0} `t`t{1}" -f $Status.Properties.name, $Status.Properties.Enabled ) -ErrorAction Continue}
	}
	Catch{
	Write-Warning "$_" -ErrorAction Continue
	}
	#>

$testStatusList = Foreach ($_ in $webTestList) {Get-AzureRmResource -ResourceId $_ }
$testStatusList | select @{Name="TestName"; Expression={$_.Name}},
@{Name="SubscriptionId"; Expression={$_.SubscriptionId}}, 
@{Name="ResourceGroupName"; Expression={$_.ResourceGroupName}},
@{Name="Enabled?"; Expression={$_.Properties.Enabled}} | Export-Excel C:/Temp/WebtestList.xlsx