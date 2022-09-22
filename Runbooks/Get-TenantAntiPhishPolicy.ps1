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
$Records = Get-AntiPhishPolicy
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

if($records.count -gt 1)
{
$records = $records | where {$_.IsDefault -eq $false}
}

foreach($record in $records)
{
$record.TargetedUsersToProtect = $record.TargetedUsersToProtect.replace($replace,$new)
$params.Query = "
INSERT INTO [dbo].[AntiPhishPolicy] (
[AdminDisplayName],
[AuthenticationFailAction],
[DistinguishedName],
[Enabled],
[EnableFirstContactSafetyTips],
[EnableMailboxIntelligence],
[EnableMailboxIntelligenceProtection],
[EnableOrganizationDomainsProtection],
[EnableSimilarDomainsSafetyTips],
[EnableSimilarUsersSafetyTips],
[EnableSpoofIntelligence],
[EnableSuspiciousSafetyTip],
[EnableTargetedDomainsProtection],
[EnableTargetedUserProtection],
[EnableUnauthenticatedSender],
[EnableUnusualCharactersSafetyTips],
[EnableViaTag],
[ExchangeObjectId],
[ExchangeVersion],
[ExcludedDomains],
[ExcludedSenders],
[Guid],
[Id],
[Identity],
[ImpersonationProtectionState],
[IsDefault],
[IsValid],
[MailboxIntelligenceProtectionAction],
[MailboxIntelligenceProtectionActionRecipients],
[MailboxIntelligenceQuarantineTag],
[Name],
[ObjectCategory],
[ObjectClass],
[ObjectState],
[OrganizationId],
[OriginatingServer],
[PhishThresholdLevel],
[PolicyTag],
[RecommendedPolicyType],
[SpoofQuarantineTag],
[TargetedDomainActionRecipients],
[TargetedDomainProtectionAction],
[TargetedDomainQuarantineTag],
[TargetedDomainsToProtect],
[TargetedUserActionRecipients],
[TargetedUserProtectionAction],
[TargetedUserQuarantineTag],
[TargetedUsersToProtect],
[WhenChanged],
[WhenChangedUTC],
[WhenCreated],
[WhenCreatedUTC],
[Tenant],[Date])
VALUES (
'$($Record.AdminDisplayName)',
'$($Record.AuthenticationFailAction)',
'$($Record.DistinguishedName)',
'$($Record.Enabled)',
'$($Record.EnableFirstContactSafetyTips)',
'$($Record.EnableMailboxIntelligence)',
'$($Record.EnableMailboxIntelligenceProtection)',
'$($Record.EnableOrganizationDomainsProtection)',
'$($Record.EnableSimilarDomainsSafetyTips)',
'$($Record.EnableSimilarUsersSafetyTips)',
'$($Record.EnableSpoofIntelligence)',
'$($Record.EnableSuspiciousSafetyTip)',
'$($Record.EnableTargetedDomainsProtection)',
'$($Record.EnableTargetedUserProtection)',
'$($Record.EnableUnauthenticatedSender)',
'$($Record.EnableUnusualCharactersSafetyTips)',
'$($Record.EnableViaTag)',
'$($Record.ExchangeObjectId)',
'$($Record.ExchangeVersion)',
'$($Record.ExcludedDomains)',
'$($Record.ExcludedSenders)',
'$($Record.Guid)',
'$($Record.Id)',
'$($Record.Identity)',
'$($Record.ImpersonationProtectionState)',
'$($Record.IsDefault)',
'$($Record.IsValid)',
'$($Record.MailboxIntelligenceProtectionAction)',
'$($Record.MailboxIntelligenceProtectionActionRecipients)',
'$($Record.MailboxIntelligenceQuarantineTag)',
'$($Record.Name)',
'$($Record.ObjectCategory)',
'$($Record.ObjectClass)',
'$($Record.ObjectState)',
'$($Record.OrganizationId)',
'$($Record.OriginatingServer)',
'$($Record.PhishThresholdLevel)',
'$($Record.PolicyTag)',
'$($Record.RecommendedPolicyType)',
'$($Record.SpoofQuarantineTag)',
'$($Record.TargetedDomainActionRecipients)',
'$($Record.TargetedDomainProtectionAction)',
'$($Record.TargetedDomainQuarantineTag)',
'$($Record.TargetedDomainsToProtect)',
'$($Record.TargetedUserActionRecipients)',
'$($Record.TargetedUserProtectionAction)',
'$($Record.TargetedUserQuarantineTag)',
'$($Record.TargetedUsersToProtect)',
'$($Record.WhenChanged)',
'$($Record.WhenChangedUTC)',
'$($Record.WhenCreated)',
'$($Record.WhenCreatedUTC)',
'$TenantName','$Date');
GO"
$Result = Invoke-SQLCmd @params
}
