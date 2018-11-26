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

Function Get-OS {

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
        Write-Verbose -Verbose "Checking Process(es)...."
        [PSCredential]$cred = Get-Credential


            $toRun = {
            
                $localObject = @()
            
                $Os = (Get-WmiObject Win32_OperatingSystem).Name.split("|")[0]
                #$Service = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name Status, StatusMask
                #[string]$winVer = (Get-WmiObject Win32_OperatingSystem).Name.split("|")[0]
                if ($Os.Length -ne 0) {
                    Try {
                        $localObject += New-Object PSObject -Property @{
                            "ComputerName" = $env:COMPUTERNAME;
                            #"WindowsVersion"              = $winVer;
                            "Name"         = $Os
                            #"Status"       = $status
                            #"StatusMask" = $Service.StatusMask
                        }
                    }
                    catch {
                        $ErrorMessage = $_.Exception.Message
                        Write-Warning "$ErrorMessage"
        
                    }
                }
                else {
                    Try {
                        $localObject += New-Object PSObject -Property @{
                            "ComputerName" = $env:COMPUTERNAME;
                            #"WindowsVersion"              = $winVer;
                            "Name"         = "Not Found!"
                            #"Status"       = $status
                            #"StatusMask" = $Service.StatusMask
                        }
                    }
                    catch {
                        $ErrorMessage = $_.Exception.Message
                        Write-Warning "$ErrorMessage"
        
                    }
                }
                
            
                return $localObject
            }
            $result = @()
            $result = Invoke-Command -ComputerName $ResolvedServers -Credential $cred -ScriptBlock $toRun
            return $result | select ComputerName, Name

}