. $PSScriptRoot\getUserTypefromAD.ps1
<#
.DESCRIPTION
This script scans the servers for persistent users and returns the Analysis showing which users are invalid

.NOTES
Prerequisites for this script:
Install-module ImportExcel
Install-module RemoteAdmins
Install-module sqlserver
Install RSAT tools to get ActiveDirectory PowerShell cmdlets
Have a Default SG Excel File ready with Default SGs/Users in it that are added to the computer by default (Eg: when a computer joins the OU or the Domain.)
#Have a Server list Excel File ready that contains the list of servers you want to run this script against.
Get access to SNOW backend. Join SG: CloudMS BI Backend Users
#>
function GetRemoteAdmins ($servers, $exportServerAdminsPath) {

    Get-RemoteAdmins -ComputerName $servers.ServerName -Credential Get-Credential | Export-Excel -Path $exportServerAdminsPath -WorkSheetname Admins -BoldTopRow -AutoSize -AutoFilter
}



function AddClasstoAdmins ($Admins_FirstPass_select) {
    $AdminsList = @()

    foreach ($i in $Admins_FirstPass_select) {
        try {
            $domain = $i.split("\")[0]
            $Alias = $i.split("\")[1]
            If ($domain -eq "Partners") {
                $domain = $domain + ".extranet.microsoft.com"
            }
            else {
                $domain = $domain + ".corp.microsoft.com"
            }

            $AdminName = Get-ADGroup $Alias -Server $domain | select -Property SamAccountName -ExpandProperty SamAccountName -ErrorAction Stop
            $AdminsList += New-Object psobject @{
                "Name"  = $i;
                "Class" = "Group"

            }  
        }          
        catch {
            $AdminsList += New-Object psobject @{
                "Name"  = $i;
                "Class" = "User"
            }
        }
    
    }
    return $AdminsList
}
function Analysis ($exportServerAdminsPath) {
    Try {
        $Analysis = Import-Excel -Path $exportServerAdminsPath -WorkSheetname 'Admins'
    }
    catch {
        Write-Warning $_.Exception.Message
    }
    $totalAdmins_count = $Analysis.Name.Count
    $serversScanned = ($Analysis | select ComputerName -ExpandProperty ComputerName -Unique)
    $Admins_FirstPass = @()
    Foreach ($i in $Analysis) {
        $Admins_FirstPass += New-Object psobject -Property @{
            "Name"  = $i.Name.ToUpper();
            "Class" = $i.Class.ToUpper()
        }
    }
    $Admins_FirstPass_select = $Admins_FirstPass | select Name -ExpandProperty Name -Unique
    $uniqueAdmins = @()
    $UniqueAdmins = AddClasstoAdmins $Admins_FirstPass_select
    return $uniqueAdmins, $serversScanned, $totalAdmins_count, $Analysis
    
}

function menuSelectEnv {
    #Menu for user to select Environment
    $title = "Environment Selection"
    $message = "Select the environment for which you would like to execute this script."

    $Prod = New-Object System.Management.Automation.Host.ChoiceDescription "&Prod", `
        "Selects Prod and SvcCont Environments."

    $NonProd = New-Object System.Management.Automation.Host.ChoiceDescription "&NonProd", `
        "Selects Dev, Test, UAT and Spare Environments."

    $exit = New-Object System.Management.Automation.Host.ChoiceDescription "E&XIT", `
        "Exits the script."
		
    $EnvOptions = [System.Management.Automation.Host.ChoiceDescription[]]($Prod, $NonProd, $exit)

    $result = $host.ui.PromptForChoice($title, $message, $EnvOptions, 0) 

    switch ($result) {
        0 {return 0}
        1 {return 1}
        2 {exit}
    }
}

function menuSelectSL {
    #Menu for user to select Service Line
    $title = "Service Line Selection"
    $message = "Select the Service Line that you want to Scan."

    $VL = New-Object System.Management.Automation.Host.ChoiceDescription "&VL", `
        "Selects Servers from VL."

    $OEM = New-Object System.Management.Automation.Host.ChoiceDescription "&OEM", `
        "Selects Servers from OEM."

    $MBS = New-Object System.Management.Automation.Host.ChoiceDescription "&MBS", `
        "Selects Servers from MBS."

    $exit = New-Object System.Management.Automation.Host.ChoiceDescription "E&XIT", `
        "Exits the script."
		
    $SLOptions = [System.Management.Automation.Host.ChoiceDescription[]]($VL, $OEM, $MBS, $exit)

    $result = $host.ui.PromptForChoice($title, $message, $SLOptions, 0) 

    switch ($result) {
        0 {return "VL"}
        1 {return "OEM"}
        2 {return "MBS"}
        3 {exit}
    }
}

function menuSelectServerData {
    #Menu for user to select if the server list should populate from SNOW or given by user?
    $title = "Environment Selection"
    $message = "Do you want to pull the servers from SNOW or through your custom server list."

    $Snow = New-Object System.Management.Automation.Host.ChoiceDescription "&SNOW", `
        "Pulls servers from SNOW based on the Service line and environment you selected."

    $CustomList = New-Object System.Management.Automation.Host.ChoiceDescription "&CustomList", `
        "Selects all servers from your custom list. Make sure to store the list in the appropriate path with appropriate name"

    $exit = New-Object System.Management.Automation.Host.ChoiceDescription "E&XIT", `
        "Exits the script."
		
    $ServerDataOptions = [System.Management.Automation.Host.ChoiceDescription[]]($Snow, $CustomList, $exit)

    $result = $host.ui.PromptForChoice($title, $message, $ServerDataOptions, 0) 

    switch ($result) {
        0 {return "SNOW"}
        1 {return "CustomList"}
        2 {exit}
    }
}

function ExecuteSQLQuery ($EnvOption, $SLOption) {
    $query_NonProd = "SELECT Servername, SRV_stateOperational, SRV_environment, SRV_domain, SRV_applicationsList, Org_Owner03_Org
FROM   ITI_Reporting.StayCurrent.StandardView
WHERE  Org_Owner01_Org = 'UST'
AND Org_Owner02_Org = 'EC Srvc ENG'
AND Org_Owner03_Org in ('$SLOption')
AND SRV_environment not in ('Prod','SvcCont')"

    $query_Prod = "SELECT Servername, SRV_stateOperational, SRV_environment, SRV_domain, SRV_applicationsList, Org_Owner03_Org
FROM   ITI_Reporting.StayCurrent.StandardView
WHERE  Org_Owner01_Org = 'UST'
AND Org_Owner02_Org = 'EC Srvc ENG'
AND Org_Owner03_Org in ('$SLOption')
AND SRV_environment in ('Prod','SvcCont')"

    if ($EnvOption -eq 0) {
        Try {
            $servers = Invoke-Sqlcmd -ServerInstance SDOBISQL -Database ITI_Reporting -Query $query_Prod
        }
        Catch {
            Write-Warning $_.Exception.Message
        }
    }
    elseif ($EnvOption -eq 1) {
        Try {
            $servers = Invoke-Sqlcmd -ServerInstance SDOBISQL -Database ITI_Reporting -Query $query_NonProd
        }
        Catch {
            Write-Warning $_.Exception.Message
        }
    }

    return $servers

}

function GetComputerList {
    $SLOption = menuSelectSL
    $EnvOption = menuSelectEnv
    $ServerDataOptions = menuSelectServerData



    $DirPathProd = "C:\Users\mohussai\OneDrive\JIT\$SLOption Prod"
    $DirPathNonProd = "C:\Users\mohussai\OneDrive\JIT\$SLOption non Prod"

    If ($EnvOption -eq 0) {
        $DirPath = $DirPathProd
        $excelName = "Prod"
    }
    else {
        $DirPath = $DirPathNonProd
        $excelName = "NonProd"
    }
    $ServerListPath = Join-Path -Path $DirPath -ChildPath ($SLOption + $excelName + "Servers.xlsx")

    if ($ServerDataOptions -eq "SNOW") {
        $servers = ExecuteSQLQuery $EnvOption $SLOption
        $servers | Export-Excel -Path $ServerListPath -WorkSheetname Sheet1
    }
    
	if(Test-Path $ServerListPath)
	{
	$servers = Import-Excel $ServerListPath -WorkSheetname Sheet1
	}
	else{
	Write-Warning "Check the File Name. The expected path is $ServerListPath..."
		break
	}
	
    #$servers = Import-Excel $ServerListPath -WorkSheetname Sheet1
    $servers = $servers | where {$_.Org_Owner03_Org -eq "$SLOption"} #| select ServerName -ExpandProperty serverName
    return $servers, $DirPath, $excelName, $SLOption
}

function Main {    
	
    $servers, $DirPath, $excelName, $SLOption = GetComputerList

	
    
    $ImportDefaultSGPath = Join-Path -Path $DirPath -ChildPath 'DefaultSGs.xlsx'
    $Date = Get-Date
    [string]$AdminsFileName = $SLOption + $excelName + "Admins_" + $Date.Month + "_" + $Date.Day + ".xlsx"
    $exportServerAdminsPath = Join-Path -Path $DirPath -ChildPath $AdminsFileName   

    
    $TotalServers_Count = ($servers.serverName | measure).Count
    Write-Host "Total Servers Pulled: $TotalServers_Count" -BackgroundColor Red -ForegroundColor White
    GetRemoteAdmins $servers $exportServerAdminsPath
    
    Write-Verbose -Verbose "Beginning Analysis..."        
    $UniqueAdmins, $serversScanned, $totalAdmins_count, $Analysis = Analysis $exportServerAdminsPath
    $uniqueAdmins_Count = $uniqueAdmins.Name.Count
    $ServersNotScanned = $servers | where {$_.ServerName -notin $serversScanned} 
	$ServersNotScanned.serverName | Export-Excel -Path $exportServerAdminsPath -WorkSheetname NotReachable
    Write-Host ("Servers Scanned Count: {0}" -f $serversScanned.Count) -BackgroundColor Red -ForegroundColor White
    Write-Output "Servers Not Scanned:" $ServersNotScanned.serverName
    Write-Host ("Total Admins Pulled: {0}" -f $totalAdmins_count) -BackgroundColor Red -ForegroundColor White
    Write-Host ("Unique Users/Groups: {0}" -f $uniqueAdmins_Count)  -BackgroundColor Red -ForegroundColor White  
    
    Write-Verbose -Verbose "Beginnig Admin Validation..."
    $Results = Output $uniqueAdmins $ImportDefaultSGPath
    $Results | Select Name, Class, Required, Comments  | Export-Excel -Path $exportServerAdminsPath -WorkSheetname "Analysis-Script" -FreezeTopRow -BoldTopRow -AutoSize -AutoFilter
    $InvalidAdmins = $Results | Select Name, Class, Required | where {$_.Required -eq "No"}
    $InvalidAdmins_Count = $InvalidAdmins.Name.Count
    Write-Host "Invalid Users/Groups Count: $InvalidAdmins_Count" -BackgroundColor Red -ForegroundColor White
    if ($InvalidAdmins_Count -gt 0) {
        Write-Host "Invalid Users" ; $Analysis | where {$_.Name -in $InvalidAdmins.Name}
		$Analysis | where {$_.Name -in $InvalidAdmins.Name} | Export-Excel -Path $exportServerAdminsPath -WorkSheetname InvalidAdmins -AutoSize -AutoFilter -BoldTopRow
    }
    #Write-Host "OutPut Ready!  $exportServerAdminsPath" -ForegroundColor White -BackgroundColor DarkGreen
    
    #SendEmail $Email $TotalServers $serversScanned $totalAdmins $uniqueAdmins_Count $

   
}
Main