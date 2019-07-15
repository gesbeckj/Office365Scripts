Function Compute-Password {
    $aesManaged = New-Object "System.Security.Cryptography.AesManaged"
    $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
    $aesManaged.BlockSize = 128
    $aesManaged.KeySize = 256
    $aesManaged.GenerateKey()
    return [System.Convert]::ToBase64String($aesManaged.Key)
}

function GetOrCreateMicrosoftGraphServicePrincipal 
{
[CmdletBinding()]
param (
    [parameter(
        Mandatory = $true,
        ValueFromPipelineByPropertyName = $true)]
    [psobject]$Customer,
    [parameter(Mandatory = $true)]
    [pscredential]$DelegatedAdminCred
)

    $graphsp = Get-AzureADServicePrincipal -SearchString "Microsoft Graph"
    if (!$graphsp) {
        $graphsp = Get-AzureADServicePrincipal -SearchString "Microsoft.Azure.AgregatorService"
    }
    if (!$graphsp) {
        #Login-AzureRmAccount -Credential $DelegatedAdminCred -TenantId $customer.CustomerContextId
        New-AzureADServicePrincipal -ApplicationId "00000003-0000-0000-c000-000000000000" | out-null
        $graphsp = Get-AzureADServicePrincipal -SearchString "Microsoft Graph"
    }
    return $graphsp
}

Function CreateAppKey($fromDate, $durationInYears, $pw) {
    $testKey = GenerateAppKey -fromDate $fromDate -durationInYears $durationInYears -pw $pw
    while ($testKey.Value -match "\+" -or $testKey.Value -match "/") {
        Write-Verbose "Secret contains + or / and may not authenticate correctly. Regenerating..." 
        $pw = Compute-Password
        $testKey = GenerateAppKey -fromDate $fromDate -durationInYears $durationInYears -pw $pw
    }
    Write-Verbose "Secret doesn't contain + or /. Continuing..." 
    return $testkey
}

Function GenerateAppKey ($fromDate, $durationInYears, $pw) {
    $endDate = $fromDate.AddYears($durationInYears) 
    $keyId = (New-Guid).ToString();
    $key = New-Object Microsoft.Open.AzureAD.Model.PasswordCredential($null, $endDate, $keyId, $fromDate, $pw)
    return $key
}

Function GetRequiredPermissions($requiredApplicationPermissions, $reqsp) {
    $sp = $reqsp
    $appid = $sp.AppId
    $requiredAccess = New-Object Microsoft.Open.AzureAD.Model.RequiredResourceAccess
    $requiredAccess.ResourceAppId = $appid
    $requiredAccess.ResourceAccess = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.ResourceAccess]
    AddResourcePermission $requiredAccess -exposedPermissions $sp.AppRoles -requiredAccesses $requiredApplicationPermissions -permissionType "Role"
    return $requiredAccess
}

Function AddResourcePermission($requiredAccess, $exposedPermissions, $requiredAccesses, $permissionType) {
    foreach ($permission in $requiredAccesses.Trim().Split(" ")) {
        $reqPermission = $null
        $reqPermission = $exposedPermissions | Where-Object {$_.Value -contains $permission}
        Write-Verbose "Collected information for $($reqPermission.Value) of type $permissionType" 
        $resourceAccess = New-Object Microsoft.Open.AzureAD.Model.ResourceAccess
        $resourceAccess.Type = $permissionType
        $resourceAccess.Id = $reqPermission.Id    
        $requiredAccess.ResourceAccess.Add($resourceAccess)
    }
}

