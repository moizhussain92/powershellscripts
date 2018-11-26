Set-ExecutionPolicy Bypass -Force
#install ACS Module
Install-Module -Name Acs.Namespaces

#Connect to ACS
Connect-AcsAccount ###Select Azure AD authentication

#Login to Azure RM Account
Login-AzureRmAccount

###########################STEP1.########################
#Get the list of Azure subscriptions and get the list of ACS subscriptions
$acsSubs = Get-AcsSubscription
$subs = Get-AzureRmSubscription | select Name, ID
$localobject = @()
foreach ($sub in $subs){
$localObject += New-Object PSObject -Property @{
    "Name" = $Sub.Name;
    "Id" = $sub.Id.replace('-','')}
    }

$subs = $localobject
$localobject = $null
$localobject = @()

Foreach ($sub in $Subs)
{
if($sub.ID -in $acsSubs.subscriptionID)
{
$localObject += New-Object PSObject -Property @{
    "Name" = $Sub.Name;
    "Id" = $sub.Id}
    }

}

#$acsSubs | sort SubscriptionId
#$localobject | Select Name, ID| sort Id

$acsSubs = $localobject


#############Step 2. check for each subscription if there are ACSNamespaces and get the Active ACSNamespaces from Subscriptions that have more than 0 ACSNameSpaces#################
$localobject = $null
$localobject = @()
Foreach ($acssub in $acsSubs)
{
$result = Get-AcsNamespace -SubscriptionID $acssub.Id
$ActiveNameSpaces = $result | where {$_.State -eq "Active" }
$localObject += New-Object PSObject -Property @{
    "Name" = $AcsSub.Name;
    "Id" = $ACSSub.Id
    "TotalNamespaces" = $result.Count
    "ActiveNameSpaces" = $ActiveNameSpaces.Count
    }

}
$ACSNamespcaces = $localobject
$localobject = $null
$ACSNamespcaces | sort ActiveNamespaces, TotalNamespaces | Format-Table



<#
Id                               Name                            
--                               ----                            
0e7a2f385f7241719ba78b9af8698b45 MSFT-UST-EC-MBS-DOTNET-SETEST-01
16084a5810a54edbbddf225db7e540f8 MBS - D2                        
3c891056ae254e19bc6a979bbaa17243 MBS-PreProd-G2C-1               
59577881d14f43e5ba30e43f48f3ba51 MSFT-UST-EC-MBS-DOTNET-PROD-01  
5d6d104b419641fea0cd5fb965443da3 MBS-Prod-G2C-1                  
5ecbebb7084e41ee90f1c06b8f53e817 ECIT-MBS DITC                   
7248b8746c7e4335aa282ff520183d23 EC-MBS-D4                       
87ec465edd4d4fad9306a5612b8c2254 MSFT-UST-EC-MBS-SP-SETEST-01    
88732baa1911487785f24786bb9bd254 MBS - D3                        
a12abab7cc8d4115a4cbe0f919be7f10 MSFT-UST-EC-MBS-AX-PROD-02      
aeea084ef4fb4cc79a47c564a9d281f5 MSFT-UST-EC-MBS-DOTNET-PROD-02  
dc07895f9dc9424d93bb9a1d06118685 Visual Studio Enterprise        
de714c514793444598ddf23b5c74c155 MSFT-UST-EC-MBS-AX-SETEST-01    
e1f51488c32b44b0a81acc9eb448402b MSFT-UST-EC-MBS-SP-Prod-01      
e5fa8f8d0e7246e58a2edd9320fe07c2 MSFT-UST-EC-MBS-AX-PROD-01      
f6fc479fe45048afbd3049b8108fa038 MBS-Prod-Support-01             
fac58dc43b954f4f8ec019012e082d00 EC-MBS-D1 


#>