
function Resolve-SID {
    Param(
        [Parameter(Mandatory = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^S-\d-\d+-(\d+-){1,14}\d+$")]
        [string[]]$SID
    )

    $localObject = @()
    Foreach ($item in $SID) {
        Try {
            $objSID = New-Object System.Security.Principal.SecurityIdentifier($item) -ErrorAction stop
        }
        Catch {
            $exception = $_.Exception.Message
        }
        $objUser = $objSID.Translate([System.Security.Principal.NTAccount])
        if ($objUser.Value.Length -ne 0) {
            $FullName = $objUser.Value
        }
        else {
            $FullName = $exception
        }
        
        $localObject += New-Object PSObject -Property @{
            "Name" = $FullName;
            "SID"  = $item
        }
    }
    return $localObject
}