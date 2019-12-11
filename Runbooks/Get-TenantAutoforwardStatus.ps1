param (
    [string]$TenantDomainName
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

$URI = 'https://raw.githubusercontent.com/gesbeckj/Office365Scripts/Dev/Common/Connect-TenantExchangeOnline.ps1'
$TempFile = $Env:Temp + '\Common\Connect-TenantExchangeOnline.ps1'
Invoke-WebRequest -Uri $URI -OutFile $TempFile
. $TempFile

$session = Connect-TenantExchangeOnline -TenantDomainName $TenantDomainName -UPN $Office365UPN.SecretValueText -ExchangeRefreshToken $Office365RefreshToken.SecretValueText
if ($null -eq $session) {
Write-Error "Connection to Office 365 Failed"
throw "Unable to Connect to Office 365"
}
$ImportSession = Import-PSSession -Session $session | Out-Null
$AutoforwardRules = Get-TransportRule | Where-Object {$_.MessageTypeMatches -eq "AutoForward" -and $_.State -eq "Enabled" -and $_.Mode -eq "Enforce" -and $_.FromScope -eq "InOrganization" -and $_.SentToScope -eq "NotInOrganization" -and $_.RejectMessageEnhancedStatusCode -eq "5.7.1"}
Remove-PSSession -Session $session
if ($null -eq $AutoforwardRules) {
return $false
} else {
return $true
}