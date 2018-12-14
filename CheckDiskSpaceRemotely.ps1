$computers = @("VM1","VM2"

)
$cred = $cred
$computers | foreach {
$computer = $_
Try {
  
  Get-WMIObject Win32_Logicaldisk -ComputerName $computer -Credential $cred
}
Catch {
  Write-Warning $_.Exception.Message
}
} | Select PSComputername,
@{Name="SizeGB";Expression={$_.Size/1GB -as [int]}},
@{Name="FreeGB";Expression={[math]::Round($_.Freespace/1GB,2)}},
@{Name="%Free";Expression={($_.Freespace/$_.size).ToString("P")}} |
Sort FreeGB | 
Format-Table –AutoSize