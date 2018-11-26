Select-AzureRmSubscription -SubscriptionName "<subname>"
$webTestList = Get-AzureRmResource | select -Property resourcetype, resourceid | where -property resourcetype -like "*alertrules*" | select -property resourceid -ExpandProperty resourceid
$testStatusList = Foreach ($_ in $webTestList) {Get-AzureRmResource -ResourceId $_ }
$toSet = $testStatusList | where {$_.Properties.actions.customemails -contains "email@email.com" -or $_.Properties.actions.customemails -contains "email@email.com"}
$toSet | foreach {$_.Properties.actions.customEmails = "newemail@email.com"} 



