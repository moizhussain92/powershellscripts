
function menuSelect {
#Menu for user to select options to Enable/Disable webtests
	$title = "Enable/Disable web-tests"
	$message = "Do you want to Enable or Disable the web-tests?"

	$enable = New-Object System.Management.Automation.Host.ChoiceDescription "&Enable", `
		"Enables all the web-tests for the subscription(s)."

	$disable = New-Object System.Management.Automation.Host.ChoiceDescription "&Disable", `
		"Disables all the web-tests for the subscription(s)."

	$exit = New-Object System.Management.Automation.Host.ChoiceDescription "E&XIT", `
		"Exits the script."
		
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($enable, $disable, $exit)

	$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

	switch ($result)
		{
			0 {$script:temp = $true; $script:var = "Enabling"}
			1 {$script:temp = $false; $script:var = "Disabling"}
			2 {exit}
		}
}


function subscriptionLevel {
	#User prompted to select a subscription from the list or go with all the subscriptions.
	do {
	$value = Read-host "`nPlease type the subscription you want to use or type ALL to select all subsciptions `n"
	if ($SubscriptionsList.contains($value) -eq $true) {$SubscriptionsList = $value; $flag = $true;}
	elseif ($value -eq "all") {echo '`nSelected all Subscriptions'; $flag = $true}
	else {echo '`nTry again!'; $flag = $false}
	}
	while ($flag -ne $true)

	menuSelect

	echo "`nCompiling the list of web-tests associalted with all the subscriptions in the account..."
	#Gets list of resourceID of all the webtests that are associated with all the subscriptions in the account.
	$webTestList = $subscriptionsList| foreach {Select-AzureRmSubscription -SubscriptionName $_ > $null ;Get-AzureRmResource -Verbose | select -Property resourcetype, resourceid | where -property resourcetype -like "*webtest*" | select -property resourceid -ExpandProperty resourceid}

	#Disables all the web-tests for all the subscriptions associated with the account.
	echo ("`n{0} {1} web-tests..." -f $var, $webTestList.Count)
	try{
	#$webTestList | foreach {$Status = Get-AzureRmResource -ResourceId $_; $Status.Properties.Enabled = $temp; echo ("`n{0} `t`t{1}" -f $Status.Properties.Enabled, $Status.Properties.name)}
	$webTestList | foreach {$Status = Get-AzureRmResource -ResourceId $_; $Status.Properties.Enabled = $temp;$Status | Set-AzureRmResource -Force > $null; echo ("`n{0} `t`t{1}" -f $Status.Properties.Enabled, $Status.Properties.name)} 
	}
	Catch{
	Write-Warning "$_"
	}
	
}


function webTestLevel {
	menuSelect
	
	echo "`nPlease create a csv file `'WebTest.csv' containing the ResourceIDs of the Webtests in the Location: C:\Temp\WebTest.csv"

	$reply = Read-Host "`nPress ENTER to continue ...`nType 'exit' to EXIT the script"
	if ($reply -eq "EXIT") { exit; }
	#$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

	#Disables all the web-tests for all the subscriptions associated with the account.
	
	try{
		$webTestList = Get-Content -Path C:\Temp\WebTest.csv
		echo ("`n{0} {1} web-tests..." -f $var, $webTestList.Count)
		#$webTestList | foreach {$Status = Get-AzureRmResource -ResourceId $_; $Status.Properties.Enabled = $temp; echo ("`n{0} `t`t{1}" -f $Status.Properties.Enabled, $Status.Properties.name)}
		$webTestList | foreach {$Status = Get-AzureRmResource -ResourceId $_; $Status.Properties.Enabled = $temp;$Status | Set-AzureRmResource -Force > $null; echo ("`n{0} `t`t{1}" -f $Status.Properties.Enabled, $Status.Properties.name)}
		}
	Catch{
		Write-Warning "$_"
		}
}


$GetCred = Get-Credential
#in the form of xyz@microsoft.com
#Add-azurermaccount -credential $GetCred

try
{
	#Add-azurermaccount 
	Login-AzureRmAccount -Credential $GetCred -ErrorAction Stop
}
Catch
{
	Write-Warning "$_"

}	

#gets list of all the subscriptions that belong to the account.
echo "`nGetting the subscriptions for this account..."
$script:SubscriptionsList = Get-AzureRmSubscription | select -Property SubscriptionName -ExpandProperty SubscriptionName | sort
echo "`nFollowing is the list of all the subscriptions: " `n
for ($i = 1; $i -le $SubscriptionsList.Count; $i++) {Write-Host ("$i. {0}" -f $SubscriptionsList[$i-1])}


$title = "OPTIONS`n"
$message = "Please choose if you want to enable/disable webtests at Subscription Level or Individual Webtest level"

$sublevel = New-Object System.Management.Automation.Host.ChoiceDescription "&Subscription Level", `
"Enables/Disables all the Web-tests for the selected subscription."

$webtestlevel = New-Object System.Management.Automation.Host.ChoiceDescription "&Web-test Level", `
"Enables/Disables Web-tests which are selected individually; irrespective of the subscription they belong to."

$exit = New-Object System.Management.Automation.Host.ChoiceDescription "E&XIT", `
"Exits the script."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($sublevel, $webtestlevel, $exit)

$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

switch ($result)
{
	0 {subscriptionLevel}
	1 {webTestLevel}
	2 {exit}
}
