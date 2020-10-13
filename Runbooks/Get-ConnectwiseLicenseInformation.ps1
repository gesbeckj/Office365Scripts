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
$ConnectwiseAPIKey = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'ConnectwiseAPIKey'
$ClientID = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'ConnectwiseAppID'

$params = @{
    'Database' = $databaseName.SecretValueText
    'ServerInstance' = $sqlServerFQDN.SecretValueText
    'Username' = $sqlAdministratorLogin.SecretValueText
    'Password' = $sqlAdministratorLoginPassword.SecretValueText
    'OutputSqlErrors' = $true
    'Query' = 'SELECT GETDate()'
}

#Download Script File
$URI = 'https://raw.githubusercontent.com/gesbeckj/ConnectwiseRestAPIScripts/master/Get-ConnectwiseOffice365Licenses/Get-ConnectwiseOffice365Licenses.ps1'
$TempFile = $ENV:Temp + '\Get-ConnectwiseOffice365Licenses.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile
. $TempFile
$Licenses = Get-ConnectwiseOffice365Licenses -APIkey $ConnectwiseAPIKey.SecretValueText -ClientID $ClientID.SecretValueText

#Check for Table, create if it not exist
$SQLQuery = "IF NOT EXISTS (SELECT * 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME = 'ConnectwiseOffice365Licenses')
CREATE TABLE [dbo].[ConnectwiseOffice365Licenses] (
[Date] datetime,
[Quantity] int,
[LicenseName] varchar(100),
[CompanyName] varchar(100)
)"
$params.query = $SQLQuery
$Result = Invoke-SQLCmd @params

#EmptyTableBeforeAddingData
#$params.Query = "DELETE FROM [dbo].[ConnectwiseOffice365Licenses]"
#$Result = Invoke-SQLCmd @params
$replace = "'"
$new = "''"

foreach($license in $Licenses)
{
    $CompanyName = $license.CompanyName.replace($replace, $new)
    $LicenseName = $license.LicenseName
    $Quantity = [int]$license.Quantity
    $date = $license.date
    $Price = [float]$license.Price
    $params.Query = "
    INSERT INTO [dbo].[ConnectwiseOffice365Licenses]
        ([Date],
        [Quantity],
        [CompanyName],
        [LicenseName],
        [UnitPrice])
    VALUES
    ('$Date',
    '$Quantity',
    '$CompanyName',
    '$LicenseName',
    '$Price');
    GO"
    $Result = Invoke-SQLCmd @params
}