function ValidateGroups ($DomainAliasGroups, $DefaultSGs) {
    $User = @()
    foreach ($entry in $DomainAliasGroups) {
        if ($entry.Name -in $DefaultSGs.Name) {
            $Required = "Yes"
            $comment = "Default SG/ NT Authority Account"
        }
        elseif ($entry.Name -like "*\JIT_*_ElevatedAccess") {
            $Required = "Yes"
            $comment = "Valid JIT SG"
        }
        Else {
            $Required = "No"
            $comment = "External SG, check the members"
        }
        $User += New-Object PSObject -Property @{ 
            "Name"     = $entry.Name;
            "Class"    = $entry.class;
            "Required" = $Required;
            "Comments" = $comment
        }    
    }
    return $User
}
function ValidateUsers ($DomainAliasUsers, $DefaultSGs) {    
    $User = @()
    Foreach ($entry in $DomainAliasUsers) {

        if ($entry.Name -in $DefaultSGs.Name) {
            $Required = "Yes"
            $comment = "Default User"
        }

        elseif ($entry.Name -like "NT Authority\*") {
            $Required = "Yes"
            $comment = "NT Authority Account"
        }
        
        elseif ($entry.Name -match "^S-\d-\d+-(\d+-){1,14}\d+$" -or ($entry.Name -like "*\v-*")) {
            $Required = "No"
            $comment = "Invalid SID/ Vendor Account"
        }
        elseif ($entry.Name -like "*$" -or $entry.Name -notlike "*\*") {
            $Required = "Yes"
            $comment = "Computer Account / Built In Account"
        }
        else {
            $domain = $entry.Name.split("\")[0]
            $alias = $entry.Name.split("\")[1]
            If ($domain -eq "Partners") {
                $domain = $domain + ".extranet.microsoft.com"
            }
            else {
                $domain = $domain + ".corp.microsoft.com"
            }
            Try {
                $Manger = Get-ADUser $alias -Server $domain -Properties Manager | select Manager -ExpandProperty Manager
                $Name = Get-ADUser $alias -Server $domain -Properties Name | select Name -ExpandProperty Name
            }
            Catch {
                $Required = "?"
                $comment = "Not Resolved in AD"
            }
            if ($Manger) {
                $Required = "No"
                $comment = "Invalid User Account"
            }
            elseif (!($Manger) -and $Name.Contains('ALT)') -eq $true){
                $Required = "No"
                $comment = "Smart Card Account"
            }
            else
            {
                $Required = "Yes"
                $comment = "Service Account"
            }
        }
    
    
        $User += New-Object PSObject -Property @{ 
            "Name"     = $entry.Name;
            "Class"    = $entry.class;
            "Required" = $Required;
            "Comments" = $comment
        }   

    }
    return $User
}

function Output ($DomainAlias, $ImportPath) {
    
    $DomainAliasUsers = $DomainAlias | where {$_.class -eq "User"}    
    $DomainAliasGroups = $DomainAlias | where {$_.class -eq "Group"}
    try {
        $DefaultSGs = Import-Excel -Path $ImportPath -WorkSheetname "Default SGs"    
    }
    catch {
        Write-Warning $_.Exception.Message
    }
    

    $Results = @()
    $Results += ValidateGroups $DomainAliasGroups $DefaultSGs
    $Results += ValidateUsers $DomainAliasUsers $DefaultSGs
    #$Results = $Results | select Name, Class, Required, Comments | ft
    
    return $Results

}

