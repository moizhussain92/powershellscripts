<#
.SYNOPSIS
Get AD user type User/Group

.DESCRIPTION
Lists out AD user type depending on the alias is a group, vendor, FTE, Smart card

.PARAMETER DomainAliasUsers
Parameter description

.EXAMPLE
Get-ADUserType -DomainAlias Redmond\user1
Get-ADUserType -ImportPath 'C:\Users\alias\Desktop\excel.xlsx'

.NOTES
The excel file to be imported must have a column name "Name". The worksheet name should be "Sheet1"
#>
function ValidateUsers ($DomainAliasUsers) {    
    $User = @()
    Foreach ($entry in $DomainAliasUsers) {

        if ($entry -notlike "*\*") {
            $Required = "-"
            $class = "-"
            $comment = "Invalid Argument. Must have a domain"
        }

        elseif ($entry -like "NT *\*" -or $entry -like "BUILTIN\*") {
            $Required = "Yes"
            $class = "-"
            $comment = "NT Account/BuiltIn account"
        }        
        
        elseif ($entry -like "*$" ) {
            $Required = "Yes"
            $class = "User"
            $comment = "Computer Account"
        }
        else {
            $domain = $entry.split("\")[0]
            $alias = $entry.split("\")[1]
            If ($domain -eq "Partners") {
                $domain = $domain + ".extranet.microsoft.com"
            }
            else {
                $domain = $domain + ".corp.microsoft.com"
            }
            Try {
                $Manger = Get-ADUser $alias -Server $domain -Properties Manager, samaccountname , Name | select Manager, samaccountname, Name
            }
            Catch {
                Try {
                    $Group = Get-ADGroup $alias -Server $domain
                    $Required = "?"
                    $class = "Group"
                    $comment = "AD Group"
                }
                Catch {
                    $Required = "?"
                    $class = "-"
                    $comment = "Not Resolved as AD User"
                }
            }
            if ($Manger.Manager.length -and $Manger.samaccountname.length -ne 0 ) {
                if ($Manger.samaccountname -like "v-*" ) {
                    $Required = "No"
                    $class = "User"
                    $comment = "Vendor Account"
                }
                else {
                    $Required = "No"
                    $class = "User"
                    $comment = "User Account"
                }
            }
            elseif ($Manger.Manager.length -eq 0 -and $Manger.samaccountname.length -ne 0) {
                if ($Manger.Name -like "*ALT)") {
                    $Required = "Yes"
                    $class = "User"
                    $comment = "Smart Card Account"

                }
                else {
                    $Required = "Yes"
                    $class = "User"
                    $comment = "Service Account"
                }
            
            }
        }
    
    
        $User += New-Object PSObject -Property @{ 
            "Name"     = $entry;
            "Class"    = $class;
            #"Required" = $Required;
            "Comments" = $comment
        }   

    }
    return $User
}

function Get-ADUserType {
    [CmdletBinding(DefaultParameterSetName = 'DomainAlias')]
    Param (
        [Parameter(Mandatory = $true,
            Position = 0, ParameterSetName = 'DomainAlias')]
        [ValidatePattern("^*\\*")]
        [string[]]$DomainAlias,

        [Parameter(Mandatory = $false,
            Position = 1, ParameterSetName = 'ExcelPath')]
        [ValidatePattern("^*.xlsx$")]    
        [string]$ImportPath

    )

    switch ($PsCmdlet.ParameterSetName) {
        "DomainAlias" {             
            $Results = @()
            $UserResults += ValidateUsers $DomainAlias
            return $UserResults
        }
    }
    switch ($PsCmdlet.ParameterSetName) {
        "ExcelPath" {
            $excel = Import-Excel -Path $ImportPath -WorksheetName Sheet1
            $DomainAlias = $excel.Name
            $Results = @()
            $UserResults += ValidateUsers $DomainAlias
            return $UserResults
        }
    }

}