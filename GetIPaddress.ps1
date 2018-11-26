$file = "C:\Users\mohussai\Desktop\SPD4.xlsx"
$sheetName = "Sheet1" 

$objExcel = New-Object -ComObject Excel.Application
$workbook = $objExcel.Workbooks.Open($file)
$sheet = $workbook.Worksheets.Item($sheetName)

$rowMax = ($sheet.UsedRange.Rows).count

$rowName,$colName = 1,1
$resolvedName = @()
Write-Verbose "Resolving..." -Verbose
$resolvedName = @()
   for ($i=1; $i -le $rowMax-1; $i++)
    {
        $name = $sheet.Cells.Item($rowName+$i,$colName).text.trim() 
        #Write-Host $name
        $resolvedName += Resolve-DnsName $name | select Name, IPaddress

    }
        
     return $resolvedName   