function Connect-Office365
{
    [CmdletBinding()]
    param(
    [switch]$ConnectMSOLOnly,
    [switch]$SkipMSOL,
    [string]$tenantDomainName = ""
    )
    #Attempt to Import the MSOnline Module
    try {
        Import-Module MSOnline
    }
    catch {
        Write-Error "Unable to Load MSOnline Module. Try running Install-Module MSonline"
        return $null
    }
    #Get User Credentials
    if (-not ($tenantDomainName -eq ""))
    {
    $Credential = Get-Credential
    }
    if ($null -eq $Credential)
    {
        Write-Error "No credentials entered"
    }
    if (-not ($SkipMSOL))
    {
        Connect-MsolService -Credential $Credential
    }
    if ((-not ($ConnectMSOLOnly)) -and $tenantDomainName -eq "")
    {
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Credential -Authentication Basic -AllowRedirection
    }
    elseif (-not ($ConnectMSOLOnly)){
        $DelegatedAdminCred = Get-Credential -Message "Enter delegated administrative credentials. This will not work with MFA"
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://ps.outlook.com/powershell-liveid?DelegatedOrg=$tenantDomainName" -Credential $DelegatedAdminCred  -Authentication Basic -AllowRedirection
    }
    return $Session
}
