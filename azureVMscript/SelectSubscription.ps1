#Get list of all subscriptions associated with the account.
Function GetSubscription ($account) {
    $SubscriptionsList = @()
    Write-Host ("Getting the subscriptions for the account {0}..." -f $account.Context.Account.Id) -ForegroundColor Green
    $SubscriptionsList = Get-AzureRmSubscription | select -Property Name -ExpandProperty Name | sort    
    for ($i = 1; $i -le $SubscriptionsList.Count; $i++) {Write-Host ("$i. {0}" -f $SubscriptionsList[$i - 1]) -ForegroundColor Yellow}
    return $SubscriptionsList
    #SelectSubscription $SubscriptionsList
}

#Enter the subscription numbers
Function SelectSubscription ($SubscriptionsList) {   
    $value = $null    
    $value = @()    
    $value = Read-host ("`nType the Subscription line Number(s) separated by comma ',' OR type 'ALL' to select all subsciptions")
    $values = $value.split(",", [StringSplitOptions]::RemoveEmptyEntries).trim() | sort -Unique        
    return $values   
    #checkValues $values $SubscriptionsList
}

#Check if values entered are correct. Return the correct values back
Function checkValues ($values , $SubscriptionsList) {
 
    $wrongValues = $values | where {$_ -notin 1..$SubscriptionsList.Count}
    $indexOutofRange = $wrongValues.Length -ne 0
    $selectedSubscriptionsList = @()

    if ($values -eq 'All' -and $values.Count -eq 1) {
        Write-Host "Selected all Subscriptions" -ForegroundColor Green
        $selectedSubscriptionsList = $SubscriptionsList
        #getWebTest $selectedSubscriptionsList
    }      
    
    elseif ($indexOutofRange -eq $true) {
        Write-Warning "Index Out of range for one or more items. Select correct Numbers"
        Break
        #selectSubscription $SubscriptionsList
    }
    
    else {
        Try {            
            foreach ($i in $values) {$selectedSubscriptionsList += $SubscriptionsList[$i - 1]}
            Write-Host ("Selected following Subs:") -ForegroundColor Green
            $toDisplay = $selectedSubscriptionsList -join "`n"            
            Write-Host $toDisplay -BackgroundColor DarkBlue
            #getWebTest $selectedSubscriptionsList
        }
        Catch {
            Write-Warning $_.Exception.Message
            Break
            #selectSubscription $SubscriptionsList
        }
    }
    return $selectedSubscriptionsList
}

function Subscriptions {
    $account = Login-AzureRmAccount
    $SubscriptionsList = GetSubscription $account
    $values = SelectSubscription $SubscriptionsList
    $selectedSubscriptionsList = checkValues $values $SubscriptionsList
    return $selectedSubscriptionsList 
}

<#
## Include in Main function the following lines:
    $subscriptions = Subscriptions
#>