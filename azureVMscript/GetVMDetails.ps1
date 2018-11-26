. $PSScriptRoot\selectSubscription.ps1

function GetVM ($selectedSubscriptionsList, $path) {
    $localObject = @()
    Write-Host "Getting VM details..." -ForegroundColor Green
    foreach ($sub in $selectedSubscriptionsList) {
        Write-Verbose -Verbose "Getting details for $sub"
        Select-AzureRmSubscription -SubscriptionName $sub > $null
        $VMs_ClassicResourceId = Get-AzureRmResource | where -Property ResourceType -EQ "Microsoft.ClassicCompute/virtualMachines" | select -Property ResourceId -ExpandProperty ResourceId
        #$VMs_ARM = Get-AzureRmVM -Status
        $VMs_ARMResourceId = Get-AzureRmResource | where -Property ResourceType -EQ "Microsoft.Compute/virtualMachines" | select -Property ResourceId -ExpandProperty ResourceId
        
        if ($VMs_ClassicResourceId) {
        
            $VMs_ClassicResourceId | foreach {$VMDetails = Get-AzureRmResource -ResourceId $_ 
                $localObject += New-Object PSObject -Property @{ 
                    "ComputerName"      = $VMDetails.Name;
                    #"PowerState"        = $VMDetails.Properties.instanceView.powerState;
                    "Size"              = $VMDetails.Properties.hardwareProfile.size;
                    #"PrivateIpAddress"  = $VMDetails.Properties.instanceView.PrivateIpAddress
                    "Location"          = $VMDetails.Location;
                    "ResourceGroupName" = $VMDetails.ResourceGroupName;
                    "SubscriptionName"  = $sub;
                    "ResourceType"      = "Classic VM"
                }
            }
        }   

        if ($VMs_ARMResourceId) {    
            $VMs_ARMResourceId | foreach {$VMDetails = Get-AzureRmResource -ResourceId $_
                $localObject += New-Object PSObject -Property @{ 
                    "ComputerName"      = $VMDetails.Name;
                    #"PowerState"        = $_.PowerState.split(" ")[1];
                    "Size"              = $VMDetails.Properties.hardwareProfile.vmSize
                    #"PrivateIpAddress"  = ;
                    "Location"          = $VMDetails.Location;
                    "ResourceGroupName" = $VMDetails.ResourceGroupName;
                    "SubscriptionName"  = $sub;
                    "ResourceType"      = "ARM VM"


                }
            }
        
        }
        if ($VMs_ClassicResourceId.Length -eq 0 -and $VMs_ARMResourceId.Length -eq 0) {
            Write-Warning "No Virtual Machines found in the subscription: $sub"
        }
    }
    
    #$localobject = $localObject | Format-Table
    $newObject = New-Object psobject
    $newObject = $localObject | select -Property ComputerName, size, ResourceType, ResourceGroupName,PowerState, Location, SubscriptionName
    if ($path) {
        try {
            $newObject | Export-Csv $path -NoTypeInformation
            Write-Host "Exported to $path" -ForegroundColor Yellow
        }
        catch {Write-Warning $_.Exception.Message}
    }
    else {
        return $newObject | Format-Table
    }
}

function ExportPath {
    $path = Read-Host "Enter the path (csv) to export the results OR Press 'ENTER' to skip"
    if ($path -match "^*.csv$" -or $path.Length -eq 0) {
        return $path
    }
    else {
        Write-Warning "Enter a valid CSV file name"
        Break
    }
    
}

function Main {
    $subscriptions = Subscriptions
    $path = ExportPath
    GetVM $subscriptions $path
}


Main