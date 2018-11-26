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
        
    $ResolvedServers = $servers | foreach { Try { Resolve-DnsName $_ -ErrorAction Stop | select Name -ExpandProperty Name -First 1} Catch { Write-Host $_.Exception.Message -BackgroundColor DarkBlue } }
    return $ResolvedServers

}

Function Get-ComputerDomain 
{
    Param(

        [Parameter(Mandatory = $True,
            Position = 0)]
        #[Parameter(Mandatory=$True,
        #Position=0,ParameterSetName='AllGroup')]
        #[ValidateNotNullOrEmpty()]
        [string[]]$ServerName)

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

    Write-Verbose -Verbose "Resolving FQDN for Server Name..."
    $resolvedServers = ResolveDns $newServerName
    $localObject = @()

    Foreach ($resolvedServer in $resolvedServers) { 

        $localObject += New-Object PSObject -Property @{ 

            "VMHostName" = $resolvedServer.split(".", 2)[0]
            "Domain"     = $resolvedServer.split(".", 2)[1]

        }
    }

    <#Foreach ($server in $newServerName) {
    $server = $server.split(".", 2)[0]
        if ($server -notin $resolvedServers) {
            $localObject += New-Object PSObject -Property @{ 

                "VMHostName" = $server
                "Domain"     = "DNS name does not exist OR Not able to resolve"

            }
        }
    
    }#>
    return $localObject
}
#Export-ModuleMember -Function Get-ComputerDomain