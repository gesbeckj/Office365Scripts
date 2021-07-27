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
$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/Dev/Get-AllTenantAllUsers/Get-AllTenantAllUsers.ps1'
$TempFile = $ENV:Temp + '\Get-AllTenantAllUsers\Get-AllTenantAllUsers.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile
. $TempFile
New-Item -Name "Common" -ItemType Directory -Path $Env:Temp


$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/Dev/Common/Connect-Office365.ps1'
$TempFile = $Env:Temp + '\Common\Connect-Office365.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile

$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/Dev/Common/Connect-TenantExchangeOnline.ps1'
$TempFile = $Env:Temp + '\Common\Connect-TenantExchangeOnline.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile

$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/Dev/Common/Get-LicenseName.ps1'
$TempFile = $Env:Temp + '\Common\Get-LicenseName.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile

New-Item -Name "Get-TenantAllUsers" -ItemType Directory -Path $Env:Temp
$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/Dev/Get-TenantAllUsers/Get-TenantAllUsers.ps1'
$TempFile = $Env:Temp + '\Get-TenantAllUsers\Get-TenantAllUsers.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile

$Users = Get-AllTenantAllUsers -credential $Office365Creds -RefreshToken $RefreshToken.SecretValueText -TenantID $TenantID.SecretValueText

$AllUsers = $users | where {$_.usertype -ne "guest"}


#Check for Table, create if it not exist
$SQLQuery = "IF NOT EXISTS (SELECT * 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME = 'UserDetails')
CREATE TABLE [dbo].[UserDetails] (
    [Tenant] varchar(100),
    [MFAStatus] varchar(20),
    [userLicense] varchar(250),
    [DisplayName] varchar(100),
    [FirstName] varchar(50),
    [LastName] varchar(100),
    [LastPasswordChangeTimestamp] datetime,
    [PasswordNeverExpires] bit,
    [UserPrincipalName] varchar(100),
    [WhenCreated] datetime,
    [date] datetime
)"
$params.query = $SQLQuery
$Result = Invoke-SQLCmd @params

#EmptyTableBeforeAddingData
#$params.Query = "DELETE FROM [dbo].[LicenseSummary]"
#$Result = Invoke-SQLCmd @params

$replace = "'"
$new = "''"

foreach($item in $AllUsers)
{
    $Tenant = $item.Tenant.replace($replace, $new)
    $MFAStatus = $item.MFAStatus
    $userLicense = $item.userLicense
    $Date = [System.DateTime]::Today
    $DisplayName = $item.DisplayName.replace($replace, $new)
    $FirstName = $item.FirstName.replace($replace, $new)
    $LastName = $Item.LastName.replace($replace, $new)
    $LastPasswordChange = $item.LastPasswordChangeTimestamp
    $userPrincipalName = $item.UserPrincipalName
    $whenCreated = $item.WhenCreated
    $PasswordNeverExpires = $item.PasswordNeverExpires

    $params.Query = "
    INSERT INTO [dbo].[UserDetails]
    ([Tenant],
    [MFAStatus],
    [userLicense],
    [DisplayName],
    [FirstName],
    [LastName],
    [LastPasswordChangeTimestamp],
    [PasswordNeverExpires],
    [UserPrincipalName],
    [WhenCreated],
    [date])
    VALUES
    ('$Tenant',
    '$MFAStatus',
    '$userLicense',
    '$DisplayName',
    '$FirstName',
    '$LastName',
    '$LastPasswordChange',
    '$PasswordNeverExpires',
    '$userPrincipalName',
    '$WhenCreated',
    '$Date');
    GO"
    $Result = Invoke-SQLCmd @params
}
