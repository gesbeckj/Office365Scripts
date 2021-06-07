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
WHERE TABLE_NAME = 'EXOMailboxStatistics')
CREATE TABLE [dbo].[EXOMailboxStatistics](
[AssociatedItemCount] BIGINT,
[AttachmentTableAvailableSize] BIGINT,
[AttachmentTableTotalSize] BIGINT,
[DatabaseIssueWarningQuota] BIGINT,
[DatabaseName] varchar(MAX),
[DatabaseProhibitSendQuota] BIGINT,
[DatabaseProhibitSendReceiveQuota] BIGINT,
[DeletedItemCount] BIGINT,
[DisconnectDate] varchar(MAX),
[DisconnectReason] varchar(MAX),
[DisplayName] varchar(MAX),
[DumpsterMessagesPerFolderCountReceiveQuota] BIGINT,
[DumpsterMessagesPerFolderCountWarningQuota] BIGINT,
[ExternalDirectoryOrganizationId] varchar(100),
[FastIsEnabled] varchar(MAX),
[FolderHierarchyChildrenCountReceiveQuota] BIGINT,
[FolderHierarchyChildrenCountWarningQuota] BIGINT,
[FolderHierarchyDepthReceiveQuota] BIGINT,
[FolderHierarchyDepthWarningQuota] BIGINT,
[FoldersCountReceiveQuota] BIGINT,
[FoldersCountWarningQuota] BIGINT,
[IsAbandonedMoveDestination] varchar(MAX),
[IsArchiveMailbox] varchar(MAX),
[IsDatabaseCopyActive] varchar(MAX),
[IsHighDensityShard] varchar(MAX),
[IsMoveDestination] varchar(MAX),
[IsQuarantined] varchar(MAX),
[ItemCount] BIGINT,
[LastLoggedOnUserAccount] varchar(MAX),
[LastLogoffTime] datetime,
[LastLogonTime] datetime,
[LegacyDN] varchar(MAX),
[MailboxGuid] varchar(100),
[MailboxMessagesPerFolderCountReceiveQuota] BIGINT,
[MailboxMessagesPerFolderCountWarningQuota] BIGINT,
[MailboxType] varchar(MAX),
[MailboxTypeDetail] varchar(MAX),
[MessageTableAvailableSize] BIGINT,
[MessageTableTotalSize] BIGINT,
[NamedPropertiesCountQuota] BIGINT,
[NeedsToMove] varchar(MAX),
[OtherTablesAvailableSize] BIGINT,
[OtherTablesTotalSize] BIGINT,
[OwnerADGuid] varchar(100),
[QuarantineClients] varchar(MAX),
[QuarantineDescription] varchar(MAX),
[QuarantineEnd] varchar(MAX),
[QuarantineFileVersion] varchar(MAX),
[QuarantineLastCrash] varchar(MAX),
[ResourceUsageRollingAvgDatabaseReads] varchar(MAX),
[ResourceUsageRollingAvgRop] varchar(MAX),
[ResourceUsageRollingClientTypes] BIGINT,
[ServerName] varchar(MAX),
[StorageLimitStatus] varchar(MAX),
[SystemMessageCount] BIGINT,
[SystemMessageSize] BIGINT,
[SystemMessageSizeShutoffQuota] BIGINT,
[SystemMessageSizeWarningQuota] BIGINT,
[TablesTotalAvailableSize] BIGINT,
[TablesTotalSize] BIGINT,
[TotalDeletedItemSize] BIGINT,
[TotalItemSize] BIGINT,
[Tenant] varchar(100),[Date] datetime)"
$params.query = $SQLQuery
$Result = Invoke-SQLCmd @params

foreach ($tenant in $tenants) {
    $params = @{"TenantDomainName"=$tenant.DefaultDomainName;"TenantName"=$tenant.name}
    Start-Sleep -seconds 10

$job = Start-AzureRmAutomationRunbook -Name Get-TenantEXOMailboxStatistics -AutomationAccountName "AzureAutomation" -ResourceGroupName "PowerBI" -Parameters $params}
