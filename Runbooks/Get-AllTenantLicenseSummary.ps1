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
New-Item -Name "Get-AllTenantLicenseSummary" -ItemType Directory -Path $Env:Temp
$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/Dev/Get-AllTenantLicenseSummary/Get-AllTenantLicenseSummary.ps1'
$TempFile = $ENV:Temp + '\Get-AllTenantLicenseSummary\Get-AllTenantLicenseSummary.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile
. $TempFile
New-Item -Name "Common" -ItemType Directory -Path $Env:Temp


$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/Dev/Common/Connect-Office365.ps1'
$TempFile = $Env:Temp + '\Common\Connect-Office365.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile

$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/Dev/Common/Get-LicenseName.ps1'
$TempFile = $Env:Temp + '\Common\Get-LicenseName.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile


$ALLMFA = Get-AllTenantLicenseSummary -Credential $Office365Creds -RefreshToken $RefreshToken.SecretValueText -TenantID $TenantID.SecretValueText

#Check for Table, create if it not exist
$SQLQuery = "IF NOT EXISTS (SELECT * 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME = 'LicenseSummary')
CREATE TABLE [dbo].[LicenseSummary] (
[Tenant] varchar(100),
[Owned_Licenses] int,
[isCSP] bit,
[UnusuedLicenses] int,
[Date] datetime,
[InUse_Licenses] smallint,
[License] varchar(100)
)"
$params.query = $SQLQuery
$Result = Invoke-SQLCmd @params

#EmptyTableBeforeAddingData
#$params.Query = "DELETE FROM [dbo].[LicenseSummary]"
#$Result = Invoke-SQLCmd @params

$replace = "'"
$new = "''"

foreach($license in $Licenses)
{
    $Tenant = $license.Tenant.replace($replace, $new)
    $Owned_Licenses = $license.Owned_Licenses
    $isCSP = $license.isCSP
    $UnusuedLicenses = $license.UnusuedLicenses
    $Date = $license.date
    $InUse_Licenses = $license.InUse_Licenses
    $LicenseName = $license.License


    $params.Query = "
    INSERT INTO [dbo].[LicenseSummary]
    ([Tenant],
    [Owned_Licenses],
    [isCSP],
    [UnusuedLicenses],
    [Date],
    [InUse_Licenses],
    [License])
    VALUES
    ('$Tenant',
    '$Owned_Licenses',
    '$isCSP',
    '$UnusuedLicenses',
    '$Date',
    '$InUse_Licenses',
    '$LicenseName');
    GO"
    $Result = Invoke-SQLCmd @params
}