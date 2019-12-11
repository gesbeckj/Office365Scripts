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
$sqlServerFQDN = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'PowerBISSQLServer'
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
New-Item -Name "Get-MFASummary" -ItemType Directory -Path $Env:Temp
$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/Dev/Get-MFASummary/Get-MFASummary.ps1'
$TempFile = $ENV:Temp + '\Get-MFASummary\Get-MFASummary.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile
. $TempFile
New-Item -Name "Common" -ItemType Directory -Path $Env:Temp


$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/Dev/Common/Connect-Office365.ps1'
$TempFile = $Env:Temp + '\Common\Connect-Office365.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile

$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/Dev/Common/Get-LicenseName.ps1'
$TempFile = $Env:Temp + '\Common\Get-LicenseName.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile

$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/Dev/Get-AllTenantMFAUsers/Get-AllTenantMFAUsers.ps1'
New-Item -Name "Get-AllTenantMFAUsers" -ItemType Directory -Path $Env:Temp
$TempFile = $Env:Temp + '\Get-AllTenantMFAUsers\Get-AllTenantMFAUsers.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile


$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/Dev/Get-TenantMFAUsers/Get-TenantMFAUsers.ps1'
New-Item -Name "Get-TenantMFAUsers" -ItemType Directory -Path $Env:Temp
$TempFile = $Env:Temp + '\Get-TenantMFAUsers\Get-TenantMFAUsers.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile

$ALLMFA = Get-MFASummary -Credential $Office365Creds -RefreshToken $RefreshToken.SecretValueText -TenantID $TenantID.SecretValueText

#Check for Table, create if it not exist
$SQLQuery = "IF NOT EXISTS (SELECT * 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME = 'AzureADMFAUsage')
CREATE TABLE [dbo].[AzureADMFAUsage] (
[Date] datetime,
[MFAUsers] smallint,
[Tenant] varchar(100),
[LicensedUsers] smallint
)"
$params.query = $SQLQuery
$Result = Invoke-SQLCmd @params

#EmptyTableBeforeAddingData
#$params.Query = "DELETE FROM [dbo].[LicenseSummary]"
#$Result = Invoke-SQLCmd @params

$replace = "'"
$new = "''"

foreach($MFA in $ALLMFA)
{
    $Tenant = $MFA.Tenant.replace($replace, $new)
    $LicensedUsers = $MFA.LicensedUsers
    $Date = $MFA.date
    $MFAUsers = $MFA.MFAUsers

    $params.Query = "
    INSERT INTO [dbo].[AzureADMFAUsage] (
        [Date],
        [MFAUsers],
        [Tenant],
        [LicensedUsers])
    VALUES
    ('$Date',
    '$MFAUsers',
    '$Tenant',
    '$LicensedUsers');
    GO"
    $Result = Invoke-SQLCmd @params
}