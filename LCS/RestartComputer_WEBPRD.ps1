#Check for in-flight web requests and any current sessions.

$req = Get-WebRequest

 
$Timeout = 300 #Seconds
## Start the timer
$timer = [Diagnostics.Stopwatch]::StartNew()

while (($req.Count -gt 0) -and ($timer.Elapsed.TotalSeconds -lt $Timeout))
{
    #Wait if there are some seesions in flight
    $totalSecs = [math]::Round($timer.Elapsed.TotalSeconds,0)
    Write-Host "Waiting for request, current inflight: " $req.Count
    Write-Host "Time elapsed:" $totalSecs
    Start-Sleep -Seconds 2
    #Check again for sessions
    $req = Get-WebRequest
}

$timer.Stop()
#Get-Counter "\asp.net applications(__total__)\sessions active" -ComputerName $env:COMPUTERNAME
#Get-Counter "web service(_total)\current connections" -ComputerName $env:COMPUTERNAME


# Restart the VM
Restart-Computer $env:COMPUTERNAME -Force

<#
$repeat = (New-TimeSpan -Hours 12)
$dt= ([DateTime]::Now)
$duration = $dt.AddYears(25)-$dt
$trigger = New-ScheduledTaskTrigger -Once -at 4:45pm -RepetitionInterval $repeat -RepetitionDuration $duration                                                                                                                                                                                                                                      
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument 'C:\RestartComputer_WEBPRD.ps1'                                                                                                                                                                            
$principal = New-ScheduledTaskPrincipal 'NT AUTHORITY\SYSTEM'  

                                                                                                                                                                                                                          
Register-ScheduledTask -Action $action -TaskName "RestartComputer" -Description "Restart computer every day. Task created as a workaround for LCS timeout issues." -Principal $principal -Trigger $trigger
#>