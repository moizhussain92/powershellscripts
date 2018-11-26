Login-AzureRmAccount
$RGname = '<RG>'
Select-AzureRmSubscription -SubscriptionName '<subscriptionName>'
$vmname = @('VMName')

foreach ($vm in $vmname) {
Try {
Stop-AzureRmVM -ResourceGroupName $RGname -Name $vm -Verbose -Force
$vmdetails = Get-AzureRmVM -ResourceGroupName $RGname -Name $vm
$vmdetails.StorageProfile.OsDisk.DiskSizeGB = 130 
Update-AzureRmVM -ResourceGroupName $RGname -VM $vmdetails
Start-AzureRmVM -ResourceGroupName $RGname -Name $vm -Verbose
}
Catch { $_.Exception.Message }
}