$computers = @("VM1","VM2"

)
$cred = $cred
$computers | foreach {
#define a named variable for the computername so that it can be used the Catch
#scriptblock
$computer = $_
Try {
  
  Get-WMIObject Win32_Logicaldisk -ComputerName $computer -Credential $cred
}
Catch {
  #$_ is the error object
  Write-Warning "Failed to get OperatingSystem information from $computer. $($_.Exception.Message)"
}
} | Select PSComputername,DeviceID,
@{Name="SizeGB";Expression={$_.Size/1GB -as [int]}},
@{Name="FreeGB";Expression={[math]::Round($_.Freespace/1GB,2)}},
@{Name="%Free";Expression={($_.Freespace/$_.size).ToString("P")}} |
Sort FreeGB | 
Format-Table –AutoSize