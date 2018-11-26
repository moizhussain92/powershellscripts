Function ResolveDNS ($Computers) {
    Write-Verbose -Verbose "Resolving the Computer Name..." 
    $ResolvedComputers = $Computers | foreach { 
        Try { 
            Resolve-DnsName $_ -ErrorAction Stop | select Name -ExpandProperty Name -First 1
        } 
        Catch { Write-Warning ($_.Exception.Message + ". " + "Try using FQDN.") }
    }
    if ($ResolvedComputers) {
        return $ResolvedComputers
    }
    else {
        Break
    }
}


#computer Name is the name of the primary replica in AG

function GetCurrentSettings ($computerName) {
    $command1 = {
        Write-Host "Current Multisubnet settings for Computer $ENV:COMPUTERNAME"
        $ListnerNetworkName = Get-ClusterResource | where {$_.ResourceType -eq "Network Name" -and $_.OwnerGroup -ne "Cluster Group"} | select Name -ExpandProperty Name
        $value = Get-ClusterResource $ListnerNetworkName | Get-ClusterParameter Registerallprovidersip
        if ($value.Value -eq 1) {Write-Host "Multisubnet Feature is Enabled" -ForegroundColor White -BackgroundColor DarkGreen}
        else {Write-Host "Multisubnet Feature is Disabled" -ForegroundColor White -BackgroundColor DarkRed}
        return $value
    }
    $settings = Invoke-Command -ComputerName $computerName -ScriptBlock $command1
    return $settings
}


Function SetFeature ($result) {

    $command2 = {
        param($RegisterAllProvidersIp, $resolvedComputerName)

        function RestartClusterResource {
            $ListnerNetworkName = Get-ClusterResource | where {$_.ResourceType -eq "Network Name" -and $_.OwnerGroup -ne "Cluster Group"}
            Write-Host ("Stopping Cluster Resource {0}..." -f $ListnerNetworkName.Name) -ForegroundColor White -BackgroundColor DarkRed
            Stop-ClusterResource -Name $ListnerNetworkName.Name
            Write-Host ("Starting Cluster Resource {0}..." -f $ListnerNetworkName.Name) -ForegroundColor White -BackgroundColor DarkGreen
            Start-ClusterResource -Name $ListnerNetworkName.Name
        }
        function GetCurrentSettings {

            Write-Host "Current Multisubnet settings for Computer $ENV:COMPUTERNAME"
            $ListnerNetworkName = Get-ClusterResource | where {$_.ResourceType -eq "Network Name" -and $_.OwnerGroup -ne "Cluster Group"} | select Name -ExpandProperty Name
            $value = Get-ClusterResource $ListnerNetworkName | Get-ClusterParameter Registerallprovidersip
            return $value
        }

        $ListnerNetworkName = Get-ClusterResource | where {$_.ResourceType -eq "Network Name" -and $_.OwnerGroup -ne "Cluster Group"} | select Name -ExpandProperty Name
        $CurrentSetting = Get-ClusterResource $ListnerNetworkName | Get-ClusterParameter Registerallprovidersip

        if ($RegisterAllProvidersIp -eq 1 -and $CurrentSetting.Value -eq 0) {
            Write-Verbose -Verbose "Enabling Multisubnet Feature..."
            Get-ClusterResource $ListnerNetworkName | set-ClusterParameter Registerallprovidersip $RegisterAllProvidersIp
            RestartClusterResource
            GetCurrentSettings
            

        }
        elseif ($RegisterAllProvidersIp -eq 0 -and $CurrentSetting.Value -eq 1) {
            Write-Verbose -Verbose "Disabling Multisubnet Feature..."
            Get-ClusterResource $ListnerNetworkName | set-ClusterParameter Registerallprovidersip $RegisterAllProvidersIp
            RestartClusterResource
            GetCurrentSettings
            
        }
        elseif ($RegisterAllProvidersIp -eq $CurrentSetting.value) {
            Write-host "Conflict! Check the Multi-Subnet Settings..." -ForegroundColor White -BackgroundColor DarkRed 
        }
    }

    Invoke-Command -ComputerName $resolvedComputerName -ScriptBlock $command2 -ArgumentList $result
}

function menuSelect {
    #Menu for user to select options to Enable/Disable webtests
    $title = "Enable/Disable Multi-subnet Feature"
    $message = "Do you want to Enable or Disable the Multi-Subnet Feature?"

    $enable = New-Object System.Management.Automation.Host.ChoiceDescription "&Enable", `
        "Enables the Multisubnet feature by setting RegisterAllProvidersIp = 1"

    $disable = New-Object System.Management.Automation.Host.ChoiceDescription "&Disable", `
        "Disables the Multisubnet feature by setting RegisterAllProvidersIp = 0."

    $CheckSettings = New-Object System.Management.Automation.Host.ChoiceDescription "&CheckSettings", `
        "Get the current Multi-Subnet settings for the Computer"

    $exit = New-Object System.Management.Automation.Host.ChoiceDescription "E&xit", `
        "Exits the script."
		
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($enable, $disable, $CheckSettings, $exit)

    $result = $host.ui.PromptForChoice($title, $message, $options, 0) 

    switch ($result) {
        0 {return $RegisterAllProvidersIp = 1}
        1 {return $RegisterAllProvidersIp = 0}
        2 {return 2}
        3 {exit}
    }
}
Function Main {
    $computerName = Read-Host "Enter the computerName of the primary Replica"
    $resolvedComputerName = ResolveDNS $computerName
    #$value = GetCurrentSettings
    #$value
    $result = menuSelect
    if ($result -in (0, 1)) {
        SetFeature $result $resolvedComputerName    
    }
    elseif ($result -eq 2) {
        GetCurrentSettings $resolvedComputerName
    }
    else {
        Break
    }
    

}
Main
