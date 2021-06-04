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
$Records = Get-MobileDeviceMailboxPolicy
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
INSERT INTO [dbo].[MobileDeviceMailboxPolicy] (
[AdminDisplayName],
[AllowApplePushNotifications],
[AllowBluetooth],
[AllowBrowser],
[AllowCamera],
[AllowConsumerEmail],
[AllowDesktopSync],
[AllowExternalDeviceManagement],
[AllowGooglePushNotifications],
[AllowHTMLEmail],
[AllowInternetSharing],
[AllowIrDA],
[AllowMicrosoftPushNotifications],
[AllowMobileOTAUpdate],
[AllowNonProvisionableDevices],
[AllowPOPIMAPEmail],
[AllowRemoteDesktop],
[AllowSimplePassword],
[AllowSMIMEEncryptionAlgorithmNegotiation],
[AllowSMIMESoftCerts],
[AllowStorageCard],
[AllowTextMessaging],
[AllowUnsignedApplications],
[AllowUnsignedInstallationPackages],
[AllowWiFi],
[AlphanumericPasswordRequired],
[ApprovedApplicationList],
[AttachmentsEnabled],
[DeviceEncryptionEnabled],
[DevicePolicyRefreshInterval],
[DistinguishedName],
[ExchangeObjectId],
[ExchangeVersion],
[Guid],
[Id],
[Identity],
[IrmEnabled],
[IsDefault],
[IsValid],
[MaxAttachmentSize],
[MaxCalendarAgeFilter],
[MaxEmailAgeFilter],
[MaxEmailBodyTruncationSize],
[MaxEmailHTMLBodyTruncationSize],
[MaxInactivityTimeLock],
[MaxPasswordFailedAttempts],
[MinPasswordComplexCharacters],
[MinPasswordLength],
[MobileOTAUpdateMode],
[Name],
[ObjectCategory],
[ObjectClass],
[ObjectState],
[OrganizationId],
[OriginatingServer],
[PasswordEnabled],
[PasswordExpiration],
[PasswordHistory],
[PasswordRecoveryEnabled],
[RequireDeviceEncryption],
[RequireEncryptedSMIMEMessages],
[RequireEncryptionSMIMEAlgorithm],
[RequireManualSyncWhenRoaming],
[RequireSignedSMIMEAlgorithm],
[RequireSignedSMIMEMessages],
[RequireStorageCardEncryption],
[UnapprovedInROMApplicationList],
[UNCAccessEnabled],
[WhenChanged],
[WhenChangedUTC],
[WhenCreated],
[WhenCreatedUTC],
[WSSAccessEnabled],
[Tenant],[Date])
VALUES (
'$($Record.AdminDisplayName)',
'$($Record.AllowApplePushNotifications)',
'$($Record.AllowBluetooth)',
'$($Record.AllowBrowser)',
'$($Record.AllowCamera)',
'$($Record.AllowConsumerEmail)',
'$($Record.AllowDesktopSync)',
'$($Record.AllowExternalDeviceManagement)',
'$($Record.AllowGooglePushNotifications)',
'$($Record.AllowHTMLEmail)',
'$($Record.AllowInternetSharing)',
'$($Record.AllowIrDA)',
'$($Record.AllowMicrosoftPushNotifications)',
'$($Record.AllowMobileOTAUpdate)',
'$($Record.AllowNonProvisionableDevices)',
'$($Record.AllowPOPIMAPEmail)',
'$($Record.AllowRemoteDesktop)',
'$($Record.AllowSimplePassword)',
'$($Record.AllowSMIMEEncryptionAlgorithmNegotiation)',
'$($Record.AllowSMIMESoftCerts)',
'$($Record.AllowStorageCard)',
'$($Record.AllowTextMessaging)',
'$($Record.AllowUnsignedApplications)',
'$($Record.AllowUnsignedInstallationPackages)',
'$($Record.AllowWiFi)',
'$($Record.AlphanumericPasswordRequired)',
'$($Record.ApprovedApplicationList)',
'$($Record.AttachmentsEnabled)',
'$($Record.DeviceEncryptionEnabled)',
'$($Record.DevicePolicyRefreshInterval)',
'$($Record.DistinguishedName)',
'$($Record.ExchangeObjectId)',
'$($Record.ExchangeVersion)',
'$($Record.Guid)',
'$($Record.Id)',
'$($Record.Identity)',
'$($Record.IrmEnabled)',
'$($Record.IsDefault)',
'$($Record.IsValid)',
'$($Record.MaxAttachmentSize)',
'$($Record.MaxCalendarAgeFilter)',
'$($Record.MaxEmailAgeFilter)',
'$($Record.MaxEmailBodyTruncationSize)',
'$($Record.MaxEmailHTMLBodyTruncationSize)',
'$($Record.MaxInactivityTimeLock)',
'$($Record.MaxPasswordFailedAttempts)',
'$($Record.MinPasswordComplexCharacters)',
'$($Record.MinPasswordLength)',
'$($Record.MobileOTAUpdateMode)',
'$($Record.Name)',
'$($Record.ObjectCategory)',
'$($Record.ObjectClass)',
'$($Record.ObjectState)',
'$($Record.OrganizationId)',
'$($Record.OriginatingServer)',
'$($Record.PasswordEnabled)',
'$($Record.PasswordExpiration)',
'$($Record.PasswordHistory)',
'$($Record.PasswordRecoveryEnabled)',
'$($Record.RequireDeviceEncryption)',
'$($Record.RequireEncryptedSMIMEMessages)',
'$($Record.RequireEncryptionSMIMEAlgorithm)',
'$($Record.RequireManualSyncWhenRoaming)',
'$($Record.RequireSignedSMIMEAlgorithm)',
'$($Record.RequireSignedSMIMEMessages)',
'$($Record.RequireStorageCardEncryption)',
'$($Record.UnapprovedInROMApplicationList)',
'$($Record.UNCAccessEnabled)',
'$($Record.WhenChanged)',
'$($Record.WhenChangedUTC)',
'$($Record.WhenCreated)',
'$($Record.WhenCreatedUTC)',
'$($Record.WSSAccessEnabled)',
'$TenantName','$Date');
GO"
$Result = Invoke-SQLCmd @params
}
