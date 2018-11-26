. $PSScriptRoot\PullList.ps1
function ValidateRoles ($contents) {
    $UserRoles = @()
    $validRoles = Get-AzureRmRoleDefinition | select Name -ExpandProperty Name
    for ($i = 0; $i -lt $contents.Count; $i++) {
        if ($contents.Role[$i] -in $validRoles) {
            $UserRoles += New-Object psobject -Property @{
                "User"           = $contents.User[$i];
                "Class"          = $contents.Class[$i];
                "Role"           = $contents.Role[$i];
                "SubscriptionId" = $Contents.SubscriptionId[$i]
            }
            
        }
        else {
            Write-Warning ("Invalid Role: {0} for User: {1}" -f $contents.Role[$i], $contents.User[$i]) 
        }        
    }
    return $UserRoles
}

function AddUserRole ($UserRoles, $subscriptions) {
    foreach ($UserRole in $UserRoles) {
        try {
            $scope = "/subscriptions/" + $UserRole.SubscriptionId
            if ($UserRole.Class -eq "User") {
                Write-Verbose -Verbose ("Adding User: {0} to subscriptionId: {1} with Role: {2}" -f $UserRole.User, $UserRole.subscriptionId, $UserRole.Role)
                New-AzureRmRoleAssignment -SignInName $UserRole.User -RoleDefinitionName $UserRole.Role -Scope $scope -ErrorAction Stop
            }
            elseif ($UserRole.Class -eq "Group") {
                Write-Verbose -Verbose ("Adding User: {0} to subscriptionId: {1} with Role: {2}" -f $UserRole.User, $UserRole.subscriptionId, $UserRole.Role)
                New-AzureRmRoleAssignment -ObjectId $UserRole.User -RoleDefinitionName $UserRole.Role -Scope $scope -ErrorAction Stop
            }
            else {
                Write-Warning ("Class: {0} not valid for User: {1}" -f $UserRole.class, $UserRole.User)
            }
            <#$server = $UserRole.User.split("\")[0]
            $User = $UserRole.User.split("\")[1]
            if ($server -eq "partners") {
                $server = "partners.extranet.microsoft.com"
            }
            else {
                $server += ".corp.microsoft.com"
            }
            try {
                $GUID = Get-ADUser $User -Server $server | select ObjectGUID
            }
            catch {
                try {
                    $GUID = Get-ADGroup $User -Server $server  | select ObjectGUID
                }
                catch {
                    Write-Warning $_.Exception.Message   
                }
            } #>
            
        }
        catch {
            Write-Warning $_.Exception.Message
        }
    }
    
}
function Main {
    Login-AzureRmAccount
    $path = Read-Host "Enter the Excel Path that contains Users and Roles"
    $contents = PullList $path
    $UserRoles = ValidateRoles $contents
    AddUserRole $UserRoles $subscriptions    
}

Main