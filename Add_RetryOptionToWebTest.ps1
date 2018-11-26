Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName "MBS-Prod-G2C-1"
$webTestList = Get-AzureRmResource -Verbose | select -Property resourcetype, resourceid | where -property resourcetype -like "*webtest*" | select -property resourceid -ExpandProperty resourceid
$Properties = $webTestList | foreach { Get-AzureRmResource -ResourceId $_ }
[String]$Log = $null

Try 
{
    foreach ($_ in $Properties)
    {
        [string]$Status = $_.Properties | Get-Member -MemberType NoteProperty -Name RetryEnabled -ErrorAction Stop; 
        $Check = $Status.Contains("RetryEnabled=True"); 
    
        if($check -eq $true) 
            {                
                Write-Output ("FOUND! Name: {0}, RetryEnabled= {1}" -f $_.Properties.Name, $_.Properties.RetryEnabled);
                $Log += Write-Output ("`nFOUND! Name: {0}, RetryEnabled= {1}" -f $_.Properties.Name, $_.Properties.RetryEnabled) -ErrorAction Stop;
                continue;
            } 
        
        Else 
            {
                Write-Output ("Adding RetryEnabled=true to {0}" -f $_.Properties.Name);
                $_.Properties | Add-Member -MemberType NoteProperty -Name RetryEnabled -Value $true -ErrorAction Stop;
                $_ | Set-AzureRmResource -Force > $null -ErrorAction Stop;
                $Log += Write-Output ("`nAdded RetryEnabled=true to {0}" -f $_.Properties.Name) -ErrorAction Stop;
            } 
    } 
} 

Catch
{
    Write-Warning "$_"
}

Try
{
    $Log | Out-File C:\Temp\Log.txt -ErrorAction Stop
}

Catch
{
    Write-Warning "$_"
}