#$GetCred = Get-Credential
#in the form of xyz@microsoft.com
#Add-azurermaccount -credential $GetCred
try
{
	#Add-azurermaccount
	Login-AzureRmAccount  #-Credentials $GetCred -ErrorAction Stop
}
Catch
{
	Write-Warning "$_"

}	

echo "Getting the subscriptions for this account..."
#gets list of all the subscriptions that belong to the account.	
$SubscriptionsList = Get-AzureRmSubscription | select -Property SubscriptionName -ExpandProperty SubscriptionName | sort
echo "`nFollowing is the list of all the subscriptions: " `n $subscriptionsList `n

do {
	$value = Read-host "`nPlease type the subscription you want to use or type ALL to select all subsciptions `n"
	if ($SubscriptionsList.contains($value) -eq $true) {$SubscriptionsList = $value; $flag = $true;}
	elseif ($value -eq "all") {echo '`nSelected all Subscriptions'; $flag = $true}
	else {echo '`nTry again!'; $flag = $false}
	}
	while ($flag -ne $true)


echo "Getting the Resource IDs of all webtests in all subscriptions associated with the Account..."
$webTestList = $subscriptionsList| foreach {Select-AzureRmSubscription -SubscriptionName $_ > $null ;Get-AzureRmResource -Verbose | select -Property resourcetype, resourceid | where -property resourcetype -like "*webtest*" | select -property resourceid -ExpandProperty resourceid}



echo "Exporting to csv file..."
New-Item -Path C:\ -Name Temp -ItemType Directory > $null
$webTestList | Export-csv -Path C:\Temp\WebTestResourceID.csv -NoTypeInformation
echo "`nPlease check the file in the location C:\Temp\WebtestResourceIDs"
