
ls -Recurse | where {$_.Name -like "environment.config"}
###Find config value of the certificate
cd C:\MBSObjects\data\
ls | where {$_.name -like "Environment*.config"} | Select-String "searchservice"
cat .\Environment.config | Select-String "<string>"

#Find the certificate by Thumbprint in Cert Store. #  <add key="WIFServiceCertificateThumbprint" value="<string>" />
$ScriptblockOldCertificate = {
cd Cert:\LocalMachine\
ls -Recurse | where {$_.ThumbPrint -eq "<string>"
}

$ScriptblockNewCertificate = {
cd Cert:\LocalMachine\
ls -Recurse | where {$_.ThumbPrint -eq "<string>"}
}


$ScriptblockDeleteCertificate = {
cd Cert:\LocalMachine\
ls -Recurse | where {$_.ThumbPrint -eq "<string>"} | Remove-Item -Verbose
}

$Scriptblock2 = {
cd C:\MBSObjects\data
ls | where {$_.name -like "environment*.config"} | Select-String "<string>"
}


$Scriptblock2 = {
cd Cert:\LocalMachine\
ls -Recurse | where {$_.Subject -like "<string>"} | Select Subject, Thumbprint, SerialNumber, NotAfter
}

#*****************************************************************************************************************
$old_certs = Invoke-Command -ComputerName $servers -Credential $cred -ScriptBlock $ScriptblockOldCertificate
$new_Certs = Invoke-Command -ComputerName $servers -Credential $cred -ScriptBlock $ScriptblockNewCertificate
Write-Host ("Servers Checked: {0}" -f $servers.Count) -ForegroundColor White -BackgroundColor Red
Write-Host ("Old Certificate Count: {0}" -f $old_certs.count) -ForegroundColor White -BackgroundColor Red
Write-Host ("New Certificate Count: {0}" -f $new_Certs.Count) -ForegroundColor White -BackgroundColor Red

#*****************************************************************************************************************

#REMOVE CERTIFICATE***********************************************************************************************

Invoke-Command -ComputerName $servers -Credential $cred -ScriptBlock $ScriptblockDeleteCertificate

#EMOVE CERTIFICATE************************************************************************************************
$Scriptblock2 = {
cd C:\MBSObjects\data
ls | where {$_.name -like "*.config"} | Select-String "<string>"
}

$Scriptblock3 = 
{
iisreset
}

ls | where {$_.name -like "environment*.config"} | cat | Select-String "<string>"

#Script to check certificate with serial number in Cert Store
$Scriptblock = {
cd Cert:\LocalMachine\
ls -Recurse | where {$_.SerialNumber -eq "<string>"}
}

$CheckThumbPrint = {
cd C:\MBSObjects\data\
ls | where {$_.name -like "Environment_LIVE*.config"} | Select-String "<string>"
}


###Script to copy Environment files from servers to localmachine

$directory = "C:\MBSObjects\data\"
$fileNamestoCopy = "Environment_LIVE.Config"
$destination = "<Destination>"
$tempPSDrive = "R"

New-PSDrive -Name $tempPSDrive -PSProvider FileSystem -Root $destination
cd $directory
Copy-Item  "Environment_LIVE.config" -Destination $destination
Remove-PSDrive $tempPSDrive -Force


$oldENcryption = ""
$newEncryption = ""
$OldTB = ""
$NEWTB = ""

ls | where {$_.Name -like "Environment*.config"} | Select-String ''



##############Script to update values in environment.config files############################
$Scriptblock = {
$directory = "C:\MBSObjects\data\"
cd $directory
$oldValue = "<string>"
$newvalue = "<string>"

$before1 = (ls | where {$_.name -like "Environment.config" -or $_.name -like "Environment_LIVE.config" -or $_.name -like "Environment_LIVEREPORTING.config"} | Select-String $oldValue).Count
$before2 = (ls | where {$_.name -like "Environment.config" -or $_.name -like "Environment_LIVE.config" -or $_.name -like "Environment_LIVEREPORTING.config"} | Select-String $newValue).Count
Write-Host "$env:COMPUTERNAME : Before:: $before1 , $before2"

(Get-Content .\Environment_LIVE.config).replace($oldValue, $newvalue) | Set-Content .\Environment_LIVE.config
(Get-Content .\Environment_LIVEREPORTING.config).replace($oldValue, $newvalue) | Set-Content .\Environment_LIVEREPORTING.config
(Get-Content .\Environment.config).replace($oldValue, $newvalue) | Set-Content .\Environment.config

$after1 = (ls | where {$_.name -like "Environment.config" -or $_.name -like "Environment_LIVE.config" -or $_.name -like "Environment_LIVEREPORTING.config"} | Select-String $oldValue).Count
$after2 = (ls | where {$_.name -like "Environment.config" -or $_.name -like "Environment_LIVE.config" -or $_.name -like "Environment_LIVEREPORTING.config"} | Select-String $newValue).Count
Write-Host "$env:COMPUTERNAME : After:: $after1 , $after2"
}
##############Script to update values in environment.config files############################



#Script to check if the values are updated in environment.config files
$ScriptblockCheck = {
$directory = "C:\MBSObjects\data\"
cd $directory
$oldValue = "<string>"
$newvalue = "<string>"
$before1 = (ls | where {$_.name -like "Environment.config" -or $_.name -like "Environment_LIVE.config" -or $_.name -like "Environment_LIVEREPORTING.config"} | Select-String $oldValue).Count
$before2 = (ls | where {$_.name -like "Environment.config" -or $_.name -like "Environment_LIVE.config" -or $_.name -like "Environment_LIVEREPORTING.config"} | Select-String $newValue).Count
Write-Host "$env:COMPUTERNAME : Check:: $before1 , $before2"}

#*****************************************************************************************
Invoke-Command -ComputerName $servers -Credential $cred -ScriptBlock $ScriptblockCheck
Invoke-Command -ComputerName $servers -Credential $cred -ScriptBlock $Scriptblock
Invoke-Command -ComputerName $servers -Credential $cred -ScriptBlock {iisreset}
#*****************************************************************************************


#Script to check if the values are updated in environment.config files
$ScriptblockCheck = {
$directory = "C:\MBSObjects\data\"
cd $directory
$oldValue = "<string>"
$newvalue = "<string>"
$before1 = (ls | where {$_.name -like "environment.config"} | Select-String $oldValue).Count
$before2 = (ls | where {$_.name -like "environment.config"} | Select-String $newValue).Count
Write-Host "$env:COMPUTERNAME : Check:: $before1 , $before2"}


$CustomScript = {


$path1 = "E:\inetpub\wwwroot\Web.config" #########all webnet servers
$path2 = "E:\inetpub\wwwroot\ecsts\Config\" #STSConfig-*.json ######Exists only in external WEBNET
$path3 = "C:\MBSObjects\data\WebRoot\webroot.config" ###########all servers
$oldValue = ""
$newvalue = ""

#$before1 = ((cat $path1 | Select-String $oldValue).Count) + ((cat $path3 | Select-String $oldValue).Count)
#$before2 = ((cat $path1 | Select-String $newvalue).Count) + ((cat $path3 | Select-String $newvalue).Count)
#Write-Host "$env:COMPUTERNAME : Before:: $before1 , $before2"

#if(Test-Path $path1)
    #{

        #(Get-Content $path1).replace($oldValue, $newvalue) | Set-Content $path1
        #return "$path1 exists: $env:COMPUTERNAME"
    #}

if(Test-Path $path2){

$before1 = ((ls $path2 | Select-String $oldValue).Count)
$before2 = ((ls $path2 | Select-String $newvalue).Count)
Write-Host "$env:COMPUTERNAME : Before:: $before1 , $before2"

$filestoModify = ls $path2 | where {$_.Name -notlike "*prod*"}
$filestoModify | foreach {$tempPath = Join-Path -path $path2 -childpath "$_";
(Get-Content $tempPath).replace($oldValue, $newvalue) | Set-Content $tempPath

}

#$filestoModify | foreach { (Get-Content "$path2" + "\" + "$_.Name" ).replace($oldValue, $newvalue) | Set-Content $path1}

#(Get-Content $path1).replace($oldValue, $newvalue) | Set-Content $path1

$after1 = ((ls $path2 | Select-String $oldValue).Count)
$after2 = ((ls $path2 | Select-String $newvalue).Count)
Write-Host "$env:COMPUTERNAME : After:: $after1 , $after2"


#return "$path2 exists: $env:COMPUTERNAME"
}

#if(Test-Path $path3)
    #{
        #(Get-Content $path3).replace($oldValue, $newvalue) | Set-Content $path3
        #return "$path3 exists: $env:COMPUTERNAME"
    #}


#Write-Host "$env:COMPUTERNAME : Check:: $before1 , $before2"
}

$serversToCheck

$ScriptblockV6 = {



}

$ScriptDelteUserProfile = {
$userName = "sc-mh513"
Get-WmiObject -Class Win32_UserProfile | where {$_.LocalPath -like "*$userName*"} | foreach {$_.Delete()} -Verbose
}


$ScriptSendQualysLogFiles = {
$QualysLogPath = "C:\ProgramData\Qualys\QualysAgent\Log.txt"
$NewLogPathName = "C:\ProgramData\Qualys\QualysAgent\Log_$env:COMPUTERNAME.txt"
Copy-Item -Path $QualysLogPath -Destination $NewLogPathName
Send-MailMessage -From mohussai@microsoft.com -To mohussai@microsoft.com -Subject QualysLogFiles -Attachments $NewLogPathName -SmtpServer 'microsoft-com.mail.protection.outlook.com'
Remove-Item $NewLogPathName -Force
}


$ScriptSendQualysLogFiles = {
$QualysLogPath = "C:\ProgramData\Qualys\QualysAgent\Log.txt"
$NewLogPathName = "C:\ProgramData\Qualys\QualysAgent\Log_$env:COMPUTERNAME.txt"

$Data = Get-Content $QualysLogPath

return $Data }

foreach ($server in $servers){$data = Invoke-Command -ComputerName $server -ScriptBlock $ScriptSendQualysLogFiles
$data 
} 