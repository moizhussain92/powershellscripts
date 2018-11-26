#Install-Module ImportExcel -Force
#Mkdir "C:\Temp"

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") 
#Create a new SqlConnection object
$objSQLConnection = New-Object System.Data.SqlClient.SqlConnection

$ServerListPath = "C:\Temp\listner.txt" 

$sqlServerName = get-content -path $ServerListPath
#$JobDetails = $null 
#$JobDetails = @()
$localObject = @()
foreach ($serverName in $sqlServerName) {
    Try {
        $objSQLConnection.ConnectionString = "Server=$ServerName;Integrated Security=SSPI;"
        Write-Host "Trying to connect to SQL Server instance on $ServerName..." -NoNewline -ForegroundColor Yellow
        $objSQLConnection.Open()
        Write-Host "Success." -ForegroundColor Green
        $objSQLConnection.Close()
    }
    Catch {
        Write-Host -BackgroundColor Red -ForegroundColor White "Fail"
        $errText = $Error[0].ToString()
        if ($errText.Contains("network-related"))
        {Write-Host "Connection Error. Check server name, port, firewall."}
 
        Write-Warning $errText
        continue
    }
    $sqlServer = New-Object Microsoft.SqlServer.Management.Smo.Server($serverName) 

    foreach ($job in $sqlServer.JobServer.Jobs) { 
        $Exportpath = "C:\Temp\sqlJobs.xlsx"
    
        $Job = $job | select Name, IsEnabled, EventLogLevel
        $localObject += New-Object PSObject -Property @{ 
        "JobName" = $Job.Name;
        "Enabled" = $Job.isEnabled;
        "EventLogLevel" = $Job.EventLogLevel;
        "ComputerName" = $serverName}
    
    } 
   
}
return $localObject | select JobName, Enabled, EventLogLevel, ComputerName | where {$_.Enabled -eq "TRUE" -and $_.EventLogLevel -ne "OnFailure"} | Export-Excel C:\Users\temp\Jobs2.xlsx -FreezeTopRow -FreezeFirstColumn -Show