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
$Record = Get-SafeLinksPolicy
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
INSERT INTO [dbo].[SafeLinksPolicy] (
[AdminDisplayName],
[AllowClickThrough],
[CustomNotificationText],
[DeliverMessageAfterScan],
[DisableUrlRewrite],
[DistinguishedName],
[DoNotAllowClickThrough],
[DoNotRewriteUrls],
[DoNotTrackUserClicks],
[EnableForInternalSenders],
[EnableOrganizationBranding],
[EnableSafeLinksForTeams],
[ExchangeObjectId],
[ExchangeVersion],
[ExcludedUrls],
[Guid],
[Id],
[Identity],
[IsDefault],
[IsEnabled],
[IsValid],
[LocalizedNotificationTextList],
[Name],
[ObjectCategory],
[ObjectClass],
[ObjectState],
[OrganizationId],
[OriginatingServer],
[RecommendedPolicyType],
[ScanUrls],
[TrackClicks],
[WhenChanged],
[WhenChangedUTC],
[WhenCreated],
[WhenCreatedUTC],
[WhiteListedUrls],
[Tenant],[Date])
VALUES (
'$($Record.AdminDisplayName)',
'$($Record.AllowClickThrough)',
'$($Record.CustomNotificationText)',
'$($Record.DeliverMessageAfterScan)',
'$($Record.DisableUrlRewrite)',
'$($Record.DistinguishedName)',
'$($Record.DoNotAllowClickThrough)',
'$($Record.DoNotRewriteUrls)',
'$($Record.DoNotTrackUserClicks)',
'$($Record.EnableForInternalSenders)',
'$($Record.EnableOrganizationBranding)',
'$($Record.EnableSafeLinksForTeams)',
'$($Record.ExchangeObjectId)',
'$($Record.ExchangeVersion)',
'$($Record.ExcludedUrls)',
'$($Record.Guid)',
'$($Record.Id)',
'$($Record.Identity)',
'$($Record.IsDefault)',
'$($Record.IsEnabled)',
'$($Record.IsValid)',
'$($Record.LocalizedNotificationTextList)',
'$($Record.Name)',
'$($Record.ObjectCategory)',
'$($Record.ObjectClass)',
'$($Record.ObjectState)',
'$($Record.OrganizationId)',
'$($Record.OriginatingServer)',
'$($Record.RecommendedPolicyType)',
'$($Record.ScanUrls)',
'$($Record.TrackClicks)',
'$($Record.WhenChanged)',
'$($Record.WhenChangedUTC)',
'$($Record.WhenCreated)',
'$($Record.WhenCreatedUTC)',
'$($Record.WhiteListedUrls)',
'$TenantName','$Date');
GO"
$Result = Invoke-SQLCmd @params
