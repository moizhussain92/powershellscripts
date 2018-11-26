Function pullSecretId
{
    $VaultName = Read-Host "Enter the Key Vault Name"  
    #Get-AzureKeyVaultSecret -VaultName $VaultName | select -Property Name, Id, Enabled | Export-Csv C:\Temp\keyVaultSecret.csv -NoTypeInformation
    Get-AzureKeyVaultSecret -VaultName $VaultName | select * | Export-Excel C:\Temp\keyVaultSecret_$VaultName.xlsx -BoldTopRow -FreezeTopRow -WorkSheetname "SecretId"
}

Function Main 
{

    $SubscriptionsList = @()
    $SubscriptionsList = ("<subId>") 

    $SubscriptionsList | foreach     {
        Try 
        {
            Select-AzureRmSubscription -SubscriptionId $_ -ErrorAction Stop
            pullSecretId
        }
        catch 
        {
            Write-Warning $_.Exception.Message
        }

    }

}
#Install-Module ImportExcel -Force
##Can comment out the above line after the module is installed.
Login-AzureRmAccount
Main