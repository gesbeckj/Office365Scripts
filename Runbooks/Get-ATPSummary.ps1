$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

$KeyVault = Get-AzureRmKeyVault -VaultName "AberdeanCSP-Vault"
$databaseName = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'PowerBIDatabasename'
$sqlServerFQDN = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'PowerBISQLServer'
$sqlAdministratorLogin = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'PowerBISQLLogin'
$sqlAdministratorLoginPassword = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'PowerBISQLPassword'
$Office365Login = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'AutomationAppID'
$Office365LoginPassword = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'AutomationAppSecret'
$RefreshToken = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'AutomationRefreshToken'
$TenantID = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'PartnerDomainName'

$secpassword = ConvertTo-SecureString $Office365LoginPassword.SecretValueText -AsPlainText -Force
$Office365Creds = New-Object System.Management.Automation.PSCredential($Office365Login.SecretValueText,$secpassword)

$params = @{
    'Database' = $databaseName.SecretValueText
    'ServerInstance' = $sqlServerFQDN.SecretValueText
    'Username' = $sqlAdministratorLogin.SecretValueText
    'Password' = $sqlAdministratorLoginPassword.SecretValueText
    'OutputSqlErrors' = $true
    'Query' = 'SELECT GETDate()'
}

#Download Script File
New-Item -Name "Get-AllTenantAllUsers" -ItemType Directory -Path $Env:Temp
$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/master/Get-AllTenantAllUsers/Get-AllTenantAllUsers.ps1'
$TempFile = $ENV:Temp + '\Get-AllTenantAllUsers\Get-AllTenantAllUsers.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile
. $TempFile
New-Item -Name "Common" -ItemType Directory -Path $Env:Temp

$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/master/Common/Connect-Office365.ps1'
$TempFile = $Env:Temp + '\Common\Connect-Office365.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile

$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/master/Common/Get-LicenseName.ps1'
$TempFile = $Env:Temp + '\Common\Get-LicenseName.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile

New-Item -Name "Get-TenantAllUsers" -ItemType Directory -Path $Env:Temp
$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/master/Get-TenantAllUsers/Get-TenantAllUsers.ps1'
$TempFile = $Env:Temp + '\Get-TenantAllUsers\Get-TenantAllUsers.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile

$Users = Get-AllTenantAllUsers -credential $Office365Creds -RefreshToken $RefreshToken.SecretValueText -TenantID $TenantID.SecretValueText

$AllUsers = $users | Where-Object {$_.usertype -ne "guest" -and $_.isLicensed -eq $true}

$Tenants = $allusers.Tenant | Sort-Object -Unique

$summary = @()
foreach ($tenant in $tenants) {
    $LicensedUsers = $AllUsers | Where-Object {$_.Tenant -eq $tenant} | Where-Object {$_.userLicense.length -gt 2} 
    $ATPUsers = $LicensedUsers | Where-Object {$_.userLicense -like "*Advanced Threat*"}
    if ($LicensedUsers.GetType().Name -eq "PSCustomObject") {
        $LicensedUserCount = 1
    } else {
        $LicensedUserCount = $LicensedUsers.count
    }
    $ATPUserCount = $ATPUsers.count
    if ($null -eq $ATPUsers) {
        $ATPUserCount = 0
    } elseif ($ATPUsers.GetType().Name -eq "PSCustomObject") {
        $ATPUserCount = 1
    } else {
        $ATPUserCount = $ATPUsers.count
    }
    $data = New-Object PSObject -Property @{
        Tenant           = $tenant
        LicensedUsers    = $LicensedUserCount
        ATPUsers         = $ATPUserCount
        Date = [System.DateTime]::Today
    }
    $Summary += $data
}

#Check for Table, create if it not exist
$SQLQuery = "IF NOT EXISTS (SELECT * 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME = 'ATPSummary')
CREATE TABLE [dbo].[ATPSummary] (
[Tenant] varchar(100),
[ATPUsers] int,
[LicensedUsers] int,
[Date] datetime
)"
$params.query = $SQLQuery
$Result = Invoke-SQLCmd @params

#EmptyTableBeforeAddingData
#$params.Query = "DELETE FROM [dbo].[LicenseSummary]"
#$Result = Invoke-SQLCmd @params

$replace = "'"
$new = "''"

foreach($item in $summary)
{
    $Tenant = $item.Tenant.replace($replace, $new)
    $ATPUsers = $item.ATPUsers
    $LicensedUsers = $item.LicensedUsers
    $Date = $item.date


    $params.Query = "
    INSERT INTO [dbo].[ATPSummary]
    ([Tenant],
    [ATPUsers],
    [LicensedUsers],
    [Date])
    VALUES
    ('$Tenant',
    '$ATPUsers',
    '$LicensedUsers',
    '$Date');
    GO"
    $Result = Invoke-SQLCmd @params
}