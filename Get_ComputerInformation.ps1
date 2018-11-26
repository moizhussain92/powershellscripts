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

Function Get-ComputerInformation {

    Param(

        [Parameter(Mandatory = $True,
            Position = 0)]
        #[Parameter(Mandatory=$True,
        #Position=0,ParameterSetName='AllGroup')]
        #[ValidateNotNullOrEmpty()]
        [string[]]$ComputerName)

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

    Write-Verbose -Verbose "Getting Computer Information..."

    $localObject = @()
    Foreach ($entry in $ResolvedServers)   
    {
    
        
        $Computer = $entry.split(".",2)[0]
        $domain = $entry.split(".",2)[1]

        $ComputerDetails = Get-ADComputer $Computer -Server $domain -Properties * | select DistinguishedName, DNSHostName, IPv4Address,createTimeStamp, OperatingSystem, PasswordLastSet, SID, whenCreated, whenChanged, LastLogonDate, BadLogonCount, badPasswordTime, badPwdCount
        #$OU = $ComputerDetails.DistinguishedName.split(",",2)[1]
        $localObject += New-Object PSObject -Property @{

        "DistinguishedName" = $ComputerDetails.DistinguishedName;
        "OU" = $ComputerDetails.DistinguishedName.split(",",2)[1];
        "DNSHostName" = $ComputerDetails.DNSHostName;
        "IPv4Address" = $ComputerDetails.IPv4Address;
        "createTimeStamp" = $ComputerDetails.createTimeStamp;
        "OperatingSystem" = $ComputerDetails.OperatingSystem;
        "PasswordLastSet" = $ComputerDetails.PasswordLastSet;
        "SID" = $ComputerDetails.SID;
        "whenCreated" = $ComputerDetails.whenCreated;
        "whenChanged" = $ComputerDetails.whenChanged;
        "LastLogonDate" = $ComputerDetails.LastLogonDate;
        "BadLogonCount" = $ComputerDetails.BadLogonCount;
        "badPasswordTime" = $ComputerDetails.badPasswordTime;
        "badPwdCount" = $ComputerDetails.badPwdCount

        }
    }

    return $localObject | select DistinguishedName, OU, DNSHostName, IPv4Address,createTimeStamp, OperatingSystem, PasswordLastSet, SID, whenCreated, whenChanged, LastLogonDate, BadLogonCount, badPasswordTime, badPwdCount

    }