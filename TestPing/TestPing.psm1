Function PullList ($filepath) 
{
    $sheetName = "Sheet1" 
    $objExcel = New-Object -ComObject Excel.Application
    $workbook = $objExcel.Workbooks.Open($filepath)
    $sheet = $workbook.Worksheets.Item($sheetName)
    $rowMax = ($sheet.UsedRange.Rows).count
    $rowName,$colName = 1,1
    $List = @()
        for ($i=1; $i -le $rowMax-1; $i++)
        {
            $name = $sheet.Cells.Item($rowName+$i,$colName).text
            $List += $name.trim()
        }       
        $objExcel.quit()
        return $List   
} 

Function ResolveDNS ($servers)
{
        
    $ResolvedServers = $servers | foreach { Try{ Resolve-DnsName $_ -ErrorAction Stop | select Name -ExpandProperty Name -First 1} Catch{ Write-Warning $_.Exception.Message } }
    return $ResolvedServers

}

Function Test-Ping 
{

    Param(

                [Parameter(Mandatory=$True,
                Position=0)]
                #[Parameter(Mandatory=$True,
                #Position=0,ParameterSetName='AllGroup')]
                #[ValidateNotNullOrEmpty()]
                [string[]]$ServerName)


    Try{

        if($ServerName -match "^*.xlsx$")
            {                       
            Resolve-Path $ServerName > $null  -ErrorAction Stop 
            Write-Verbose -Verbose "Pulling the Server List..."                        
            $newServerName = PullList ($ServerName)                        
            }

        else
            {
            $newServerName = $ServerName
            }
        } # Try Close
        
    Catch{
        Write-Warning $_.Exception.Message
    }  

    Write-Verbose -Verbose "Resolving FQDN for Server Name..."
    [string[]]$ResolvedServers = ResolveDNS ($newServerName)
    Write-Verbose -Verbose "Pinging..."
    $result = @()


    $num=$ResolvedServers.count

    $line=20
    $iss=[system.management.automation.runspaces.initialsessionstate]::createdefault()
    $pool=[runspacefactory]::createrunspacepool(1,$line,$iss,$Host)
    $pool.open()

    $Script = {
        param($server)
        Try{
             
        $result = Test-NetConnection -ComputerName $server -ErrorAction Stop |  select -Property ComputerName, PingSucceeded 
        }        
        
        Catch { 
        $ErrorMessage = $_.Exception.Message
        #$pattern = "(?<=:).*(?=\.\s)"
        #$message = [Regex]::Match($ErrorMessage, $pattern)
        #$message = $ErrorMessage.split(":")[1].trim()
        Write-Host "$server - $ErrorMessage" -BackgroundColor DarkRed
        
        }

    return $result

    } # script end
    
    $threads=@()

    [array]$handles=for($x=1;$x -le $num; $x++){
    $powershell=[powershell]::create().addscript($script).addargument($ResolvedServers[$x-1])
    $powershell.Runspacepool=$pool
    $powershell.BeginInvoke()
    $threads+=$powershell
    }


    do{
    $i=0
    $done=$true
    foreach($handle in $handles){
        if($handle -ne $null){
            if($handle.IsCompleted){
                $threads[$i].endinvoke($handle)
                [array]$result+=$threads[$i].endinvoke($handle)
                $threads[$i].dispose()
                $handles[$i]=$null
                }
            else{
                $done=$false
                }        
            }
            $i++
        }
        if(-not $done){start-sleep -Milliseconds 500}
    }
    until($done)
  
} 
Export-ModuleMember -Function Test-Ping