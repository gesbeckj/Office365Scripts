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
        $KeyVault = Get-AzureRmKeyVault -VaultName "AberdeanCSP-Vault"
        $Office365UPN = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'ExchangeUPN'
        $Office365RefreshToken = Get-AzureKeyVaultSecret -VaultName $keyVault.VaultName -Name 'ExchangeRefreshToken'
        $session = Connect-TenantExchangeOnline -TenantDomainName $TenantDomainName -UPN $Office365UPN.SecretValueText -ExchangeRefreshToken $Office365RefreshToken.SecretValueText
        if($null -eq $session)
        {
            Write-Error "Connection to Office 365 Failed Attempt 3"
            throw "Unable to login"
        }
        }
    }
$ImportSession = Import-PSSession -Session $session | Out-Null
$TenantAdminAuditLogStatus = (Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled
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


$Date = $item.date
$params.Query = "
INSERT INTO [dbo].[ExchangeOnlineAdminAuditLogStatus]
([Tenant],
[ExchangeOnlineAdminAuditLogStatus],
[Date])
VALUES
('$TenantName',
'$TenantAdminAuditLogStatus',
'$Date');
GO"
$Result = Invoke-SQLCmd @params

