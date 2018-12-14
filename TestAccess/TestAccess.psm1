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

Function Test-Access {

    Param(

        [Parameter(Mandatory = $True,
            Position = 0)]
        #[Parameter(Mandatory=$True,
        #Position=0,ParameterSetName='AllGroup')]
        #[ValidateNotNullOrEmpty()]
        [string[]]$ServerName,

        [Parameter(Mandatory = $false,
            Position = 1)]
        [switch]$ALTCredential)


    Try {

        if ($ServerName -match "^*.xlsx$") {                       
            Resolve-Path $ServerName > $null  -ErrorAction Stop 
            Write-Verbose -Verbose "Pulling the Server List..."                        
            $newServerName = PullList ($ServerName)                        
        }

        else {
            $newServerName = $ServerName
        }
    } # Try Close
        
    Catch {
        Write-Warning $_.Exception.Message
    }  

    if ($ALTCredential -eq $True) {
        Write-Host "Enter your ALT account credentials..."
        Start-Sleep -s 1
        $credFlag = 1;
        $credential = Get-Credential
    }

    else {$credFlag = 0}

    Write-Verbose -Verbose "Resolving FQDN for Server Name..."
    [string[]]$ResolvedServers = ResolveDNS ($newServerName)
    Write-Verbose -Verbose "Checking Access..."
    $access = @()

    $num = $ResolvedServers.count

    $line = 20
    $iss = [system.management.automation.runspaces.initialsessionstate]::createdefault()
    $pool = [runspacefactory]::createrunspacepool(1, $line, $iss, $Host)
    $pool.open()

    $script = {
        param([string]$server, [int]$credflag, [Parameter(Mandatory = $false)]$credential)
        
        Try {
            $result = Invoke-Command -ComputerName $server -ScriptBlock {hostname} -ErrorAction Stop
            Write-Host $result -BackgroundColor DarkGreen 
            $access = New-Object PSObject -Property @{
                "Server"  = $server;
                "Status"  = "Accessible";
                "Account" = $env:USERNAME
            }
        } #main Try close
        
        Catch {
            if ($credFlag = 1 -and $credential) {
                Try {	
                    $result = Invoke-Command -ComputerName $server -ScriptBlock {hostname} -Credential $credential -ErrorAction Stop
                    Write-Host $result -BackgroundColor DarkGreen 
                    $access = New-Object PSObject -Property @{
                        "Server"  = $server;
                        "Status"  = "Accessible";
                        "Account" = "ALT account"
                    }
            
                } #nested try close
                Catch {
                    Write-Warning "$server - Inaccessible"
                    #Write-Warning $_.Exception.Message
                    $access = New-Object PSObject -Property @{
                        "Server"  = $server;
                        "Status"  = "Inaccessible";
                        "Account" = "None"
                    }

                } #nested catch close
            } # if close
            else {
                Write-Warning "$server - Inaccessible"
                #Write-Warning $_.Exception.Message
                $access = New-Object PSObject -Property @{
                    "Server"  = $server;
                    "Status"  = "Inaccessible";
                    "Account" = "None"
                }
        
            } #else close
        
            
        } #main catch close

        return $access 
    } # script end






    $threads = @()

    [array]$handles = for ($x = 1; $x -le $num; $x++) {
        $powershell = [powershell]::create().addscript($script).addargument($ResolvedServers[$x - 1]).addargument($credflag).addargument($credential)
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

    
        
        
} #function end Test-access
    
Export-ModuleMember -Function Test-Access