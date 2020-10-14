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


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$APIKey = $ConnectwiseAPIKey.SecretValueText
$ClientID = $ClientID.SecretValueText
$headers = @()
$headers = @{"Content-Type" = 'application/json'}
$headers += @{"Authorization" = "Basic $APIKey"}
$headers += @{"clientId" = "$ClientID"}
$CWParams = @{
    PageSize = 1000
    Conditions = 'Name = "O365 Subscription" or Name = "O365 Subscription Only"'
}
$uri = 'https://api-na.myconnectwise.net/v4_6_release/apis/3.0/finance/agreements'
Write-Verbose 'Getting all Office 365 Agreements'
$O365Agreements = Invoke-RestMethod -Uri $uri -Headers $headers -Body $CWparams

$AllData = @()
$CWParams = @{
    PageSize = 1000
    Conditions = 'Description != "O365 Back Charge" and Description != "O365 Credit"'
}

Write-Verbose 'Staring Loop Through Office 365 Agreements'
foreach($O365Agreement in $O365Agreements)
{
    Write-Verbose "Agreement for $($O365Agreement.company.name)"
    Write-Verbose "Agreement ID: $($O365Agreement.id)"
    $AgreementID = $O365Agreement.id
    $uri = "https://api-na.myconnectwise.net/v4_6_release/apis/3.0/finance/agreements/$AgreementID/additions"
    Write-Verbose "Getting License Information"
    $Licenses = Invoke-RestMethod -Uri $uri -Headers $headers -Body $CWparams
    foreach($license in $Licenses)
    {
        Write-Verbose "License found for $($license.description)"
        $data = New-Object PSObject -Property @{
            CompanyName = $O365Agreement.company.name
            LicenseName = $license.description
            Quantity = $license.Quantity
            Price = $license.unitPrice
            Date = [System.DateTime]::Today
        }
        if ($null -eq $license.cancelleddate)
        {
            Write-Verbose "License is active"
            $AllData += $data
        }
    }
}

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

foreach($license in $AllData)
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