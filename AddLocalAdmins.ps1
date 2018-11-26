<##
 # Arguments:
 #   goodAdmins - the list of admins you want removed on the local machine, using the information from Step 1
 #>


Function Add-Admins {
    Param($goodAdmins, $ResolvedServers)

    $command = {
            param ($goodAdmins)

            Function Get-LocalAdmins {
            $lines = net localgroup administrators | % {$_.trim()}
            if ($lines -contains "The command completed successfully.") {
                $first = [array]::LastIndexOf($lines, "-------------------------------------------------------------------------------") + 1
                $end   = [array]::IndexOf($lines, "The command completed successfully.") - 1
                $admins = $lines[$first..$end]
                return $admins | Sort | Unique 
            } else {
                throw "Error finding local admins"
            } 
        } $presentAdmins = Get-LocalAdmins 
        $toadd = @()
        [array]$toAdd = $goodAdmins |  where {$_ -notin $presentAdmins} 
        $group = [ADSI]("WinNT://$env:COMPUTERNAME/Administrators,group")
        $toAdd = $toAdd | Foreach {$_.Replace("\","/")} 
        foreach ($i in $toAdd) {$group.Add("WinNT://" + $i)}}
        #net localgroup administrators $toAdd /ADD}
    
    Invoke-Command -ComputerName $ResolvedServers -ScriptBlock $command -ArgumentList (,$goodAdmins)
 

}

Function ResolveDNS ($servers)
{
    $ResolvedServers = $servers | foreach {Resolve-DnsName $_ | select Name -ExpandProperty Name}
    return $ResolvedServers
}

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
            $List += $name
        }       
        $objExcel.quit()
        return $List
   
} 

#$AddAdminsPath = "C:\Users\mohussai\Desktop\trash\goodAdmins.xlsx"
#$ServerListPath = "C:\Users\mohussai\Desktop\trash\serverList.xlsx"

Function addRemoteAdmins
{
 Param(
                [Parameter(Mandatory=$True,Position=1)]
                [string]$ServerListPath,
                [Parameter(Mandatory=$True)]
                [string]$AddAdminsPath,
                [switch]$force = $false
                )

try
    {
        Resolve-Path $ServerListPath > $null  -ErrorAction Stop 
        Resolve-Path $AddAdminsPath > $null  -ErrorAction Stop
        
        Write-Verbose -Verbose "Getting the list of Admins to add..." 
        $goodAdmins = pullList ($AddAdminsPath)
        
        Write-Verbose -Verbose "Pulling the Server List..."
        $servers = pullList ($ServerListPath)
        
        Write-Verbose -Verbose "Resolving FQDN for Server List..."
        $ResolvedServers = ResolveDNS ($servers)
        
        Write-Verbose -Verbose "Adding Remote Admins..."
        Add-Admins $goodAdmins $ResolvedServers
        Write-Host "Completed" -ForegroundColor Green
    }

Catch
    {
        Write-Warning $_.Exception.Message
    }
}