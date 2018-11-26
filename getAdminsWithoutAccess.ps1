$localObject = $null
$com = '<ComputerName>'
#$g = 'Administrators'
       $localObject = @()
       $Computer = [ADSI]"WinNT://$com,computer"
        $Groups = $Computer.psbase.Children | Where {$_.psbase.schemaClassName -eq "group"}
            foreach ($j in $Groups) {
                $b = $j.Path.split('/', [StringSplitOptions]::RemoveEmptyEntries)
                [string[]]$GroupName += $b[-1] }
        
        Foreach ($g in $GroupName) {
        Try{
        $Group = [ADSI]("WinNT://$com/$g,group")
        $Members = @($Group.psbase.Invoke("Members"))
        if ($Members) {
            ForEach ($Member In $Members) {
                $AdsPath = $Member.GetType().InvokeMember("Adspath", "GetProperty", $null, $Member, $null)
                $a = $AdsPath.split('/', [StringSplitOptions]::RemoveEmptyEntries)
                $Name = $a[-1]
                $domain = $a[-2] 
                if ($domain -eq $com)
                {$FullName = $Name}
                elseif ($domain -eq "WinNT:") {
                    Try {
                        $objSID = New-Object System.Security.Principal.SecurityIdentifier($Name) -ErrorAction stop
                        $objUser = $objSID.Translate( [System.Security.Principal.NTAccount])
                        $FullName = $objUser.Value 
                    }
                    Catch {$FullName = $domain + "\" + $Name}
                }  
                Else
                {$FullName = $domain + "\" + $Name}       
                $Class = $Member.GetType().InvokeMember("Class", 'GetProperty', $Null, $Member, $Null)

                $localObject += New-Object PSObject -Property @{ 
                    "Name"         = $FullName;
                    "Class"        = $class;
                    "GroupName"    = $g;
                    "ComputerName" = $com
                }            
            } #Forloop 2 close 
        } # if close
        
        else {
            $localObject += New-Object PSObject -Property @{ 
                "Name"         = "-";
                "Class"        = "-";
                "GroupName"    = $g;
                "ComputerName" = $com
            } #property close
        }# else close
     }#Try close
    Catch {
        $ErrorMessage = $_.Exception.Message
        Write-Warning "$g - $ErrorMessage"
        $localObject += New-Object PSObject -Property @{ 
            "Name"         = "-";
            "Class"        = "-";
            "GroupName"    = "$g NOT found!";
            "ComputerName" = $com
        } #property close
    }
 }#Forloop 1 close
return $localObject