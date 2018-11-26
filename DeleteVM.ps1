#Get list of servers/Vms from Excel
$VMName = @()
$file = "C:\Users\mohussai\Desktop\ToDeleteVM.xlsx"
$sheetName = "Sheet1" 

$objExcel = New-Object -ComObject Excel.Application
$workbook = $objExcel.Workbooks.Open($file)
$sheet = $workbook.Worksheets.Item($sheetName)

$rowMax = ($sheet.UsedRange.Rows).count

$rowName,$colName = 1,1
#populate all VMs to variable $name
for ($i=1; $i -le $rowMax-1; $i++)
    {
        $name = $sheet.Cells.Item($rowName+$i,$colName).text
        $VMName += $name
    }
$objExcel.quit() 


#Login Azure
Login-AzureRmAccount
#$Subscriptions = @('MSFT-UST-EC-MBS-DOTNET-PROD-01','MSFT-UST-EC-MBS-DOTNET-PROD-02','MSFT-UST-EC-MBS-AX-PROD-01','MSFT-UST-EC-MBS-AX-PROD-02')
$Sub = 'MSFT-UST-EC-MBS-DOTNET-PROD-02'
Select-AzureRmSubscription -SubscriptionName $Sub
$Success = @()
foreach ($VM in $VMname)
{
    
    Try
    { 
        $ResourceId = Get-AzureRmResource | where {$_.ResourceType -EQ "Microsoft.ClassicCompute/virtualMachines" -and $_.Name -EQ $VM} | select -Property ResourceId -ExpandProperty ResourceId -ErrorAction Stop
        Remove-AzureRmResource -ResourceId $ResourceId -WhatIf -ErrorAction Stop
        Write-Host "Deleting - $VM" -foregroundcolor "Green"
        $Success += $VM
    }

    Catch
    {
        
       Write-Warning ("The VM does not exist in this subscription ($Sub) or has been deleted. - $VM")
    }
 
      
}

Write-Output $Success