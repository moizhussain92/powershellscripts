

##################################################################################################


Function PullList ($filepath) {
    $sheetName = "Sheet1" 
    $objExcel = New-Object -ComObject Excel.Application
    $workbook = $objExcel.Workbooks.Open($filepath)
    $sheet = $workbook.Worksheets.Item($sheetName)
    $rowMax = ($sheet.UsedRange.Rows).count
    $rowName, $colName = 1, 1
    $List = @()
    for ($i = 1; $i -le $rowMax - 1; $i++) {
        $name = $sheet.Cells.Item($rowName + $i, $colName).text
        $List += $name.trim()
    }       
    $objExcel.quit()
    return $List   
} 

Function ResolveDNS ($servers) {
        
    $ResolvedServers = $servers | foreach { Try { Resolve-DnsName $_ -ErrorAction Stop | select Name -ExpandProperty Name -First 1} Catch { Write-Warning $_.Exception.Message } }
    if ($ResolvedServers) {
        return $ResolvedServers
    }
    else {
        Break
    }
}

Function Test-ServerPatchandRegistry {

    Param(

        [Parameter(Mandatory = $True,
            Position = 0)]
        #[Parameter(Mandatory=$True,
        #Position=0,ParameterSetName='AllGroup')]
        #[ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $true,
            Position = 1)]
        [string[]]$KBNumber)


    Try {

        if ($ComputerName -match "^*.xlsx$") {                       
            Resolve-Path $ComputerName > $null  -ErrorAction Stop 
            Write-Verbose -Verbose "Pulling the Server List..."                        
            $newComputerName = PullList ($ComputerName)                        
        }

        else {
            $newComputerName = $ComputerName
        }
    } # Try Close
        
    Catch {
        Write-Warning $_.Exception.Message
    }  


    Write-Verbose -Verbose "Resolving FQDN for Server Name..."
    [string[]]$ResolvedServers = ResolveDNS ($newComputerName)
    Write-Verbose -Verbose "Checking Computer for KB and Registry settings..."
    [PSCredential]$cred = Get-Credential
    $localObject = @()

    $num = $ResolvedServers.count

    $line = 20
    $iss = [system.management.automation.runspaces.initialsessionstate]::createdefault()
    $pool = [runspacefactory]::createrunspacepool(1, $line, $iss, $Host)
    $pool.open()

    $script = {
        param([string]$server, [string[]]$KBNumber, [PSCredential]$cred)
        $toRun = {
            param([string[]]$KBNumber)
            $hotfix = Get-HotFix -Id $KBNumber
            $RegKey = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name FeatureSettingsOverride, FeatureSettingsOverrideMask
            #[string]$winVer = (Get-WmiObject Win32_OperatingSystem).Name.split("|")[0]
            Try {
                $localObject += New-Object PSObject -Property @{
                    "ComputerName"                = $env:COMPUTERNAME;
                    #"WindowsVersion"              = $winVer;
                    "HotfixId"                    = $hotfix.hotfixID;
                    "FeatureSettingsOverride"     = $RegKey.FeatureSettingsOverride;
                    "FeatureSettingsOverrideMask" = $RegKey.FeatureSettingsOverrideMask
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Warning "$ErrorMessage"
    
            }
            return $localObject
        }
        $result = @()
        $result = Invoke-Command -ComputerName $server -Credential $cred -ScriptBlock $toRun -ArgumentList (, $KBNumber)
        return $result | select ComputerName, HotfixId, FeatureSettingsOverride, FeatureSettingsOverrideMask
    } #ScriptEnd






    $threads = @()

    [array]$handles = for ($x = 1; $x -le $num; $x++) {
        $powershell = [powershell]::create().addscript($script).addargument($ResolvedServers[$x - 1]).addargument($KBNumber).addargument($cred)
        $powershell.Runspacepool = $pool
        $powershell.BeginInvoke()
        $threads += $powershell
    }


    do {
        $i = 0
        $done = $true
        foreach ($handle in $handles) {
            if ($handle -ne $null) {
                if ($handle.IsCompleted) {
                    $threads[$i].endinvoke($handle)
                    [array]$result += $threads[$i].endinvoke($handle)
                    $threads[$i].dispose()
                    $handles[$i] = $null
                }
                else {
                    $done = $false
                }        
            }
            $i++
        }
        if (-not $done) {start-sleep -Milliseconds 500}
    }
    until($done)

    
        
        
} #function end Test-ServerPatchandRegistry
    
#Export-ModuleMember -Function Test-ServerPatchandRegistry