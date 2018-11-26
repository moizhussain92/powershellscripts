ls | where {$_.Name -like "EC.MBS*"} | ls -Recurse | where {$_.Name -like "*.config" -or $_.Name -like "*.cfcsg"} | Select-String "E8889E2129EDF380D748E976913218662CE3BED1" -List | Format-Table Filename

$importPathXls = ""
$FindPath = "D:\repos\"
$CertDetails = Import-Excel -Path $importPathXls
$serialNumbers = $CertDetails.SerialNumber
$Thumbprints = $CertDetails.Thumbprint
$CertName = $CertDetails.Name
cd $FindPath
$LocalObject = @()
Foreach ($certname in $CertDetails)

{

    $SNExist = ls | where {$_.Name -like "EC.MBS*"} | ls -Recurse | where {$_.Name -like "*.config" -or $_.Name -like "*.cfcsg"} | Select-String -Pattern $CertName.SerialNumber | select Path -ExpandProperty path
    $TBExist = ls | where {$_.Name -like "EC.MBS*"} | ls -Recurse | where {$_.Name -like "*.config" -or $_.Name -like "*.cfcsg"} | Select-String -Pattern $CertName.Thumbprint | select Path -ExpandProperty path

    if ($SNExist) 
    {
        foreach ($SNPath in $SNExist) {
            $LocalObject += New-Object psobject -Property
            
        }
        
    }
}

ls | where {$_.Name -like "EC.MBS*"} | ls -Recurse | where {$_.Name -like "*.config" -or $_.Name -like "*.cfcsg"}