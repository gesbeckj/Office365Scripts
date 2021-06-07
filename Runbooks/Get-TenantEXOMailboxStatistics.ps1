param (
    [string]$TenantDomainName,
    [string]$TenantName
)
# Ensures that any credentials apply only to the execution of this runbook
Disable-AzureRmContextAutosave -Scope Process | Out-Null


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
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint}
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
$Office365UPN = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'ExchangeUPN'
$Office365RefreshToken = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'ExchangeRefreshToken'
$databaseName = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'PowerBIDatabasename'
$sqlServerFQDN = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'PowerBISQLServer'
$sqlAdministratorLogin = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'PowerBISQLLogin'
$sqlAdministratorLoginPassword = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'PowerBISQLPassword' 
$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/Dev/Common/Connect-Office365.ps1'
$TempFile = $Env:Temp + '\Common\Connect-Office365.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile
. $TempFile
$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/Dev/Common/Connect-TenantExchangeOnline.ps1'
$TempFile = $Env:Temp + '\Common\Connect-TenantExchangeOnline.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile
. $TempFile
$session = Connect-TenantExchangeOnline -TenantDomainName $TenantDomainName -UPN $Office365UPN.SecretValueText -ExchangeRefreshToken $Office365RefreshToken.SecretValueText
if ($null -eq $session) {
Write-Error "Connection to Office 365 Failed Attempt 1"
$session = Connect-TenantExchangeOnline -TenantDomainName $TenantDomainName -UPN $Office365UPN.SecretValueText -ExchangeRefreshToken $Office365RefreshToken.SecretValueText
if ($null -eq $session) {
    Write-Error "Connection to Office 365 Failed Attempt 2"
    $session = Connect-TenantExchangeOnline -TenantDomainName $TenantDomainName -UPN $Office365UPN.SecretValueText -ExchangeRefreshToken $Office365RefreshToken.SecretValueText
    if($null -eq $session)
    {
        Write-Error "Connection attempt has failed three times. Aborting"
        throw "Unable to login"
    }
    }
}
$ImportSession = Import-PSSession -Session $session | Out-Null
$Records = Get-EXOMailbox | Get-EXOMailboxStatistics -Properties *
Remove-PSSession -Session $session

$params = @{
    'Database' = $databaseName.SecretValueText
    'ServerInstance' = $sqlServerFQDN.SecretValueText
    'Username' = $sqlAdministratorLogin.SecretValueText
    'Password' = $sqlAdministratorLoginPassword.SecretValueText
    'OutputSqlErrors' = $true
    'Query' = 'SELECT GETDate()'
}
$replace = "'"
$new = "''"
foreach($record in $records)
{
$TenantName = $TenantName.replace($replace, $new)
$Date = [System.DateTime]::Today
$params.Query = "
INSERT INTO [dbo].[EXOMailboxStatistics] (
[AssociatedItemCount],
[AttachmentTableAvailableSize],
[AttachmentTableTotalSize],
[DatabaseIssueWarningQuota],
[DatabaseName],
[DatabaseProhibitSendQuota],
[DatabaseProhibitSendReceiveQuota],
[DeletedItemCount],
[DisconnectDate],
[DisconnectReason],
[DisplayName],
[DumpsterMessagesPerFolderCountReceiveQuota],
[DumpsterMessagesPerFolderCountWarningQuota],
[ExternalDirectoryOrganizationId],
[FastIsEnabled],
[FolderHierarchyChildrenCountReceiveQuota],
[FolderHierarchyChildrenCountWarningQuota],
[FolderHierarchyDepthReceiveQuota],
[FolderHierarchyDepthWarningQuota],
[FoldersCountReceiveQuota],
[FoldersCountWarningQuota],
[IsAbandonedMoveDestination],
[IsArchiveMailbox],
[IsDatabaseCopyActive],
[IsHighDensityShard],
[IsMoveDestination],
[IsQuarantined],
[ItemCount],
[LastLoggedOnUserAccount],
[LastLogoffTime],
[LastLogonTime],
[LegacyDN],
[MailboxGuid],
[MailboxMessagesPerFolderCountReceiveQuota],
[MailboxMessagesPerFolderCountWarningQuota],
[MailboxType],
[MailboxTypeDetail],
[MessageTableAvailableSize],
[MessageTableTotalSize],
[NamedPropertiesCountQuota],
[NeedsToMove],
[OtherTablesAvailableSize],
[OtherTablesTotalSize],
[OwnerADGuid],
[QuarantineClients],
[QuarantineDescription],
[QuarantineEnd],
[QuarantineFileVersion],
[QuarantineLastCrash],
[ResourceUsageRollingAvgDatabaseReads],
[ResourceUsageRollingAvgRop],
[ResourceUsageRollingClientTypes],
[ServerName],
[StorageLimitStatus],
[SystemMessageCount],
[SystemMessageSize],
[SystemMessageSizeShutoffQuota],
[SystemMessageSizeWarningQuota],
[TablesTotalAvailableSize],
[TablesTotalSize],
[TotalDeletedItemSize],
[TotalItemSize],
[Tenant],[Date])
VALUES (
'$($Record.AssociatedItemCount)',
'$($Record.AttachmentTableAvailableSize)',
'$($Record.AttachmentTableTotalSize)',
'$($Record.DatabaseIssueWarningQuota)',
'$($Record.DatabaseName)',
'$($Record.DatabaseProhibitSendQuota)',
'$($Record.DatabaseProhibitSendReceiveQuota)',
'$($Record.DeletedItemCount)',
'$($Record.DisconnectDate)',
'$($Record.DisconnectReason)',
'$($Record.DisplayName)',
'$($Record.DumpsterMessagesPerFolderCountReceiveQuota)',
'$($Record.DumpsterMessagesPerFolderCountWarningQuota)',
'$($Record.ExternalDirectoryOrganizationId)',
'$($Record.FastIsEnabled)',
'$($Record.FolderHierarchyChildrenCountReceiveQuota)',
'$($Record.FolderHierarchyChildrenCountWarningQuota)',
'$($Record.FolderHierarchyDepthReceiveQuota)',
'$($Record.FolderHierarchyDepthWarningQuota)',
'$($Record.FoldersCountReceiveQuota)',
'$($Record.FoldersCountWarningQuota)',
'$($Record.IsAbandonedMoveDestination)',
'$($Record.IsArchiveMailbox)',
'$($Record.IsDatabaseCopyActive)',
'$($Record.IsHighDensityShard)',
'$($Record.IsMoveDestination)',
'$($Record.IsQuarantined)',
'$($Record.ItemCount)',
'$($Record.LastLoggedOnUserAccount)',
'$($Record.LastLogoffTime)',
'$($Record.LastLogonTime)',
'$($Record.LegacyDN)',
'$($Record.MailboxGuid)',
'$($Record.MailboxMessagesPerFolderCountReceiveQuota)',
'$($Record.MailboxMessagesPerFolderCountWarningQuota)',
'$($Record.MailboxType)',
'$($Record.MailboxTypeDetail)',
'$($Record.MessageTableAvailableSize)',
'$($Record.MessageTableTotalSize)',
'$($Record.NamedPropertiesCountQuota)',
'$($Record.NeedsToMove)',
'$($Record.OtherTablesAvailableSize)',
'$($Record.OtherTablesTotalSize)',
'$($Record.OwnerADGuid)',
'$($Record.QuarantineClients)',
'$($Record.QuarantineDescription)',
'$($Record.QuarantineEnd)',
'$($Record.QuarantineFileVersion)',
'$($Record.QuarantineLastCrash)',
'$($Record.ResourceUsageRollingAvgDatabaseReads)',
'$($Record.ResourceUsageRollingAvgRop)',
'$($Record.ResourceUsageRollingClientTypes)',
'$($Record.ServerName)',
'$($Record.StorageLimitStatus)',
'$($Record.SystemMessageCount)',
'$($Record.SystemMessageSize)',
'$($Record.SystemMessageSizeShutoffQuota)',
'$($Record.SystemMessageSizeWarningQuota)',
'$($Record.TablesTotalAvailableSize)',
'$($Record.TablesTotalSize)',
'$($Record.TotalDeletedItemSize)',
'$($Record.TotalItemSize)',
'$TenantName','$Date');
GO"
$Result = Invoke-SQLCmd @params
}
