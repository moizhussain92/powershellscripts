#Login-AzureRmAccount

#Get list of all subscriptions associated with the account.
Function GetSubscription {
    $SubscriptionsList = @()
    Write-Host ("Getting the subscriptions for this account...") -ForegroundColor Green
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
    $values = $value.split(",",[StringSplitOptions]::RemoveEmptyEntries).trim() | sort -Unique        
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
            Write-Host $toDisplay
            #getWebTest $selectedSubscriptionsList
        }
        Catch {
            Write-Warning $_
            Break
            #selectSubscription $SubscriptionsList
        }
    }
    return $selectedSubscriptionsList
}

#Fetch WebTest details for selected Subscriptions
Function getWebTest ($selectedSubscriptionsList) {
    Write-Host "Getting webtest details..." -ForegroundColor Green
    $webTestList = $selectedSubscriptionsList| foreach {Select-AzureRmSubscription -SubscriptionName $_ > $null; 
        Get-AzureRmResource | select -Property resourcetype, resourceid | where -property resourcetype -like "*webtest*" | select -property resourceid -ExpandProperty resourceid}

    $testStatusList = Foreach ($_ in $webTestList) {Get-AzureRmResource -ResourceId $_ }
    $testStatusList | select @{Name = "TestName"; Expression = {$_.Name}},
    @{Name = "SubscriptionId"; Expression = {$_.SubscriptionId}}, 
    @{Name = "ResourceGroupName"; Expression = {$_.ResourceGroupName}},
    @{Name = "Enabled?"; Expression = {$_.Properties.Enabled}} | Export-Excel C:/Temp/WebtestList.xlsx -BoldTopRow -FreezeTopRow
}

function Main {
    #Login-AzureRmAccount
    $SubscriptionsList = GetSubscription
    $values = SelectSubscription $SubscriptionsList
    $selectedSubscriptionsList = checkValues $values $SubscriptionsList
    Write-Host $selectedSubscriptionsList -BackgroundColor DarkBlue
    #getWebTest $selectedSubscriptionsList
}

Main
