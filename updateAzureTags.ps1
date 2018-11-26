Login-azurermaccount
Select-AzureRmSubscription -SubscriptionId '87ec465e-dd4d-4fad-9306-a5612b8c2254'

$resource = Get-AzureRmResource | where {$_.Tags.appID -match 'ICTO-3168.'}
foreach ($res in $resource) {$res.Tags.appID = 'ICTO-3168'; $res | Set-AzureRmResource}
