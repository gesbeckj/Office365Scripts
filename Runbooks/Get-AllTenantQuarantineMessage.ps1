Disable-AzureRmContextAutosave -Scope Process
$ServicePrincipalConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'
Add-AzureRmAccount `
    -ServicePrincipal `
    -TenantId $ServicePrincipalConnection.TenantId `
    -ApplicationId $ServicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint
$AzureContext = Select-AzureRmSubscription -SubscriptionId $ServicePrincipalConnection.SubscriptionID
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
$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/Dev/Common/Connect-Office365.ps1'
$TempFile = $Env:Temp + '\Common\Connect-Office365.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile
. $TempFile
$session = Connect-Office365 -ConnectMSOLOnly -credential $Office365Creds -refreshtoken $RefreshToken.SecretValueText -TenantId $TenantID.SecretValueText
$session | out-null
$tenants = Get-MsolPartnerContract
$params = @{
    'Database' = $databaseName.SecretValueText
    'ServerInstance' = $sqlServerFQDN.SecretValueText
    'Username' = $sqlAdministratorLogin.SecretValueText
    'Password' = $sqlAdministratorLoginPassword.SecretValueText
    'OutputSqlErrors' = $true
    'Query' = 'SELECT GETDate()'
}
$SQLQuery = "IF NOT EXISTS (SELECT * 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME = 'QuarantineMessage')
CREATE TABLE [dbo].[QuarantineMessage](
[CustomData] varchar(MAX),
[DeletedForRecipients] varchar(MAX),
[Direction] varchar(MAX),
[Expires] datetime,
[Identity] varchar(MAX),
[MessageId] varchar(MAX),
[Organization] varchar(MAX),
[PermissionToAllowSender] bit,
[PermissionToBlockSender] bit,
[PermissionToDelete] bit,
[PermissionToDownload] bit,
[PermissionToPreview] bit,
[PermissionToRelease] bit,
[PermissionToRequestRelease] bit,
[PermissionToViewHeader] bit,
[PolicyName] varchar(MAX),
[PolicyType] varchar(MAX),
[QuarantinedUser] varchar(MAX),
[QuarantineTypes] varchar(MAX),
[ReceivedTime] datetime,
[RecipientAddress] varchar(MAX),
[RecipientCount] int,
[RecipientTag] varchar(MAX),
[Released] bit,
[ReleasedUser] varchar(MAX),
[ReleaseStatus] varchar(MAX),
[Reported] bit,
[SenderAddress] varchar(MAX),
[Size] int,
[Subject] varchar(MAX),
[SystemReleased] bit,
[TagName] bit,
[Type] varchar(MAX),
[Tenant] varchar(100),[Date] datetime)"
$params.query = $SQLQuery
$Result = Invoke-SQLCmd @params

foreach ($tenant in $tenants) {
    $params = @{"TenantDomainName"=$tenant.DefaultDomainName;"TenantName"=$tenant.name}
    Start-Sleep -seconds 10

$job = Start-AzureRmAutomationRunbook -Name Get-TenantQuarantineMessage -AutomationAccountName "AzureAutomation" -ResourceGroupName "AberdeanPowerBI" -Parameters $params}
