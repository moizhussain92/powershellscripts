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
        
    $ResolvedServers = $servers | foreach { Try{ Resolve-DnsName $_ -ErrorAction Stop | select Name -ExpandProperty Name -First 1} Catch{ Write-Host $_.Exception.Message -BackgroundColor DarkBlue } }
    return $ResolvedServers

}

Function Try-Access
{
    
}

Function Test-Access 
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
    $ResolvedServers = ResolveDNS ($newServerName)
    Write-Verbose -Verbose "Checking Access..."
    Foreach ($server in $ResolvedServers)
    {
        
        Try{
             
        $result = Invoke-Command -ComputerName $server -ScriptBlock {hostname} -ErrorAction Stop
        Write-Host $result -BackgroundColor DarkGreen }
        
        Catch { 
        if($_.Exception.Message -cmatch "Access is denied") {Write-Host "$server - Access Denied!" -BackgroundColor DarkRed} 
        elseif($_.Exception.Message -cmatch "WinRM cannot complete the operation"){Write-Host "$server - WinRM cannot complete Operation." -BackgroundColor DarkRed}
        else{ Write-Host $_.Exception.Message -BackgroundColor DarkRed }
        
        }
    }
    
}
    
Export-ModuleMember -Function Test-Access