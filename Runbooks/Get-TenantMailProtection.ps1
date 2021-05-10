param (
    [string]$TenantDomainName,
    [string]$TenantName
)
# Ensures that any credentials apply only to the execution of this runbook
Disable-AzureRmContextAutosave –Scope Process | Out-Null


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
$ProtectionRecord = get-hostedcontentfilterpolicy

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
$TenantName = $TenantName.replace($replace, $new)
$Date = [System.DateTime]::Today
$params.Query = "
INSERT INTO [dbo].[ExchangeOnlineMailProtection] (
[TenantName],
[PSComputerName],
[RunspaceId],
[PSShowComputerName],
[AdminDisplayName],
[AddXHeaderValue],
[ModifySubjectValue],
[RedirectToRecipients],
[TestModeBccToRecipients],
[FalsePositiveAdditionalRecipients],
[QuarantineRetentionPeriod],
[EndUserSpamNotificationFrequency],
[TestModeAction],
[IncreaseScoreWithImageLinks],
[IncreaseScoreWithNumericIps],
[IncreaseScoreWithRedirectToOtherPort],
[IncreaseScoreWithBizOrInfoUrls],
[MarkAsSpamEmptyMessages],
[MarkAsSpamJavaScriptInHtml],
[MarkAsSpamFramesInHtml],
[MarkAsSpamObjectTagsInHtml],
[MarkAsSpamEmbedTagsInHtml],
[MarkAsSpamFormTagsInHtml],
[MarkAsSpamWebBugsInHtml],
[MarkAsSpamSensitiveWordList],
[MarkAsSpamSpfRecordHardFail],
[MarkAsSpamFromAddressAuthFail],
[MarkAsSpamBulkMail],
[MarkAsSpamNdrBackscatter],
[IsDefault],
[LanguageBlockList],
[RegionBlockList],
[HighConfidenceSpamAction],
[SpamAction],
[EnableEndUserSpamNotifications],
[DownloadLink],
[EnableRegionBlockList],
[EnableLanguageBlockList],
[EndUserSpamNotificationCustomFromAddress],
[EndUserSpamNotificationCustomFromName],
[EndUserSpamNotificationCustomSubject],
[EndUserSpamNotificationLanguage],
[EndUserSpamNotificationLimit],
[BulkThreshold],
[AllowedSenders],
[AllowedSenderDomains],
[BlockedSenders],
[BlockedSenderDomains],
[ZapEnabled],
[InlineSafetyTipsEnabled],
[BulkSpamAction],
[PhishSpamAction],
[SpamZapEnabled],
[PhishZapEnabled],
[ApplyPhishActionToIntraOrg],
[HighConfidencePhishAction],
[RecommendedPolicyType],
[SpamQuarantineTag],
[HighConfidenceSpamQuarantineTag],
[PhishQuarantineTag],
[HighConfidencePhishQuarantineTag],
[BulkQuarantineTag],
[Identity],
[Id],
[IsValid],
[ExchangeVersion],
[Name],
[DistinguishedName],
[ObjectCategory],
[ObjectClass],
[WhenChanged],
[WhenCreated],
[WhenChangedUTC],
[WhenCreatedUTC],
[ExchangeObjectId],
[OrganizationId],
[Guid],
[OriginatingServer],
[ObjectState],
[Date]
)
VALUES
(
    '$TenantName',
    '$($ProtectionRecord.PSComputerName)',
    '$($ProtectionRecord.RunspaceId)',
    '$($ProtectionRecord.PSShowComputerName)',
    '$($ProtectionRecord.AdminDisplayName)',
    '$($ProtectionRecord.AddXHeaderValue)',
    '$($ProtectionRecord.ModifySubjectValue)',
    '$($ProtectionRecord.RedirectToRecipients)',
    '$($ProtectionRecord.TestModeBccToRecipients)',
    '$($ProtectionRecord.FalsePositiveAdditionalRecipients)',
    '$($ProtectionRecord.QuarantineRetentionPeriod)',
    '$($ProtectionRecord.EndUserSpamNotificationFrequency)',
    '$($ProtectionRecord.TestModeAction)',
    '$($ProtectionRecord.IncreaseScoreWithImageLinks)',
    '$($ProtectionRecord.IncreaseScoreWithNumericIps)',
    '$($ProtectionRecord.IncreaseScoreWithRedirectToOtherPort)',
    '$($ProtectionRecord.IncreaseScoreWithBizOrInfoUrls)',
    '$($ProtectionRecord.MarkAsSpamEmptyMessages)',
    '$($ProtectionRecord.MarkAsSpamJavaScriptInHtml)',
    '$($ProtectionRecord.MarkAsSpamFramesInHtml)',
    '$($ProtectionRecord.MarkAsSpamObjectTagsInHtml)',
    '$($ProtectionRecord.MarkAsSpamEmbedTagsInHtml)',
    '$($ProtectionRecord.MarkAsSpamFormTagsInHtml)',
    '$($ProtectionRecord.MarkAsSpamWebBugsInHtml)',
    '$($ProtectionRecord.MarkAsSpamSensitiveWordList)',
    '$($ProtectionRecord.MarkAsSpamSpfRecordHardFail)',
    '$($ProtectionRecord.MarkAsSpamFromAddressAuthFail)',
    '$($ProtectionRecord.MarkAsSpamBulkMail)',
    '$($ProtectionRecord.MarkAsSpamNdrBackscatter)',
    '$($ProtectionRecord.IsDefault)',
    '$($ProtectionRecord.LanguageBlockList)',
    '$($ProtectionRecord.RegionBlockList)',
    '$($ProtectionRecord.HighConfidenceSpamAction)',
    '$($ProtectionRecord.SpamAction)',
    '$($ProtectionRecord.EnableEndUserSpamNotifications)',
    '$($ProtectionRecord.DownloadLink)',
    '$($ProtectionRecord.EnableRegionBlockList)',
    '$($ProtectionRecord.EnableLanguageBlockList)',
    '$($ProtectionRecord.EndUserSpamNotificationCustomFromAddress)',
    '$($ProtectionRecord.EndUserSpamNotificationCustomFromName)',
    '$($ProtectionRecord.EndUserSpamNotificationCustomSubject)',
    '$($ProtectionRecord.EndUserSpamNotificationLanguage)',
    '$($ProtectionRecord.EndUserSpamNotificationLimit)',
    '$($ProtectionRecord.BulkThreshold)',
    '$($ProtectionRecord.AllowedSenders)',
    '$($ProtectionRecord.AllowedSenderDomains)',
    '$($ProtectionRecord.BlockedSenders)',
    '$($ProtectionRecord.BlockedSenderDomains)',
    '$($ProtectionRecord.ZapEnabled)',
    '$($ProtectionRecord.InlineSafetyTipsEnabled)',
    '$($ProtectionRecord.BulkSpamAction)',
    '$($ProtectionRecord.PhishSpamAction)',
    '$($ProtectionRecord.SpamZapEnabled)',
    '$($ProtectionRecord.PhishZapEnabled)',
    '$($ProtectionRecord.ApplyPhishActionToIntraOrg)',
    '$($ProtectionRecord.HighConfidencePhishAction)',
    '$($ProtectionRecord.RecommendedPolicyType)',
    '$($ProtectionRecord.SpamQuarantineTag)',
    '$($ProtectionRecord.HighConfidenceSpamQuarantineTag)',
    '$($ProtectionRecord.PhishQuarantineTag)',
    '$($ProtectionRecord.HighConfidencePhishQuarantineTag)',
    '$($ProtectionRecord.BulkQuarantineTag)',
    '$($ProtectionRecord.Identity)',
    '$($ProtectionRecord.Id)',
    '$($ProtectionRecord.IsValid)',
    '$($ProtectionRecord.ExchangeVersion)',
    '$($ProtectionRecord.Name)',
    '$($ProtectionRecord.DistinguishedName)',
    '$($ProtectionRecord.ObjectCategory)',
    '$($ProtectionRecord.ObjectClass)',
    '$($ProtectionRecord.WhenChanged)',
    '$($ProtectionRecord.WhenCreated)',
    '$($ProtectionRecord.WhenChangedUTC)',
    '$($ProtectionRecord.WhenCreatedUTC)',
    '$($ProtectionRecord.ExchangeObjectId)',
    '$($ProtectionRecord.OrganizationId)',
    '$($ProtectionRecord.Guid)',
    '$($ProtectionRecord.OriginatingServer)',
    '$($ProtectionRecord.ObjectState)',
    '$Date'
);
GO"

$Result = Invoke-SQLCmd @params