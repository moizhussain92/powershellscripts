
$localObject = @()
$list = GET-ADUSER –Identity <alias> -server domain.com –Properties MemberOf | Select-Object MemberOf -ExpandProperty MemberOf
foreach ($i in $list){
    $pattern = "(?<=CN=)[^,]*"
    $message = [Regex]::Match($i, $pattern)
    
    $localObject += New-Object PSObject -Property @{ 
                        "CN"         = $message.Value;
                        "Path"        = "$i";

                    } #property close

}

return $localObject | Export-Csv -Path '<path.csv>'