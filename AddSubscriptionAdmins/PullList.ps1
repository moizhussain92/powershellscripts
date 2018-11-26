#Pulls the items from the excel sheet starting from [column 1, row 2] and [Column 2 , row 2]
Function ReadExcel ($filepath) {
    Write-Verbose -Verbose "Pulling the contents from $filepath"
    $sheetName = "Sheet1" 
    $objExcel = New-Object -ComObject Excel.Application
    $workbook = $objExcel.Workbooks.Open($filepath)
    $sheet = $workbook.Worksheets.Item($sheetName)
    $rowMax = ($sheet.UsedRange.Rows).count    
    $rowCol1, $col1Value = 1, 1
    $rowCol2, $col2Value = 1, 2
    $rowCol3, $col3Value = 1, 3
    $rowCol4, $col4Value = 1, 4

    $List = @()
    for ($i = 1; $i -le $rowMax - 1 ; $i++) {
        $User = $sheet.Cells.Item($rowCol1 + $i, $col1Value).text.trim()
        $class = $sheet.Cells.Item($rowCol2 + $i, $col2Value).text.trim()
        $Role = $sheet.Cells.Item($rowCol3 + $i, $col3Value).text.trim()
        $SubscriptionId = $sheet.Cells.Item($rowCol4 + $i, $col4Value).text.trim()
        if (![string]::IsNullOrWhitespace($User) -and ![string]::IsNullOrWhitespace($Role) -and ![string]::IsNullOrWhitespace($SubscriptionId) -and ![string]::IsNullOrWhitespace($class)) {
            $List += New-Object psobject -Property @{
                "User"           = $user;
                "Class"          = $class;
                "Role"           = $Role;
                "SubscriptionId" = $SubscriptionId
            }
        }
    }          
    $objExcel.quit()
    return $List   
} 

function ValidatePath ($filepath) {
    $testPath = Test-Path $filepath
    if ($testPath -eq $true -and $filepath -match "^*.xlsx$") {
        return $filepath
    }
    else {
        Write-Warning "Specify correct excel path"
        Break
    }
}

function PullList ($filepath) {
    try {
        $validPath = ValidatePath $filepath
        $Contents = ReadExcel $validPath
        return $Contents
    }
    catch {
        Write-Warning $_.Exception.Message
    }
    
}