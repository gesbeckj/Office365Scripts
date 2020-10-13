function Connect-Office365 {
    [CmdletBinding()]
    param(
        [switch]$ConnectMSOLOnly,
        [switch]$SkipMSOL,
        [pscredential]$Credential,
        [string]$refreshToken,
        [string]$tenantID
    )
    Write-Verbose "ConnectMSOLOnly is $ConnectMSOLOnly"
    Write-Verbose "SkipMSOL is $SkipMSOL"
    #Attempt to Import the MSOnline Module
    try {
        Write-Verbose "Trying Module Import"
        Import-Module MSOnline
    } catch {
        Write-Error "Unable to Load MSOnline Module. Try running Install-Module MSonline"
        return $null
    }
    Write-Verbose "MSOnline Module Loaded"
    #Get User Credentials
    if ($null -eq $Credential) {
    $Credential = Get-Credential
        if ($null -eq $Credential) {
            Write-Error "No credentials entered"
            return $null
        }
        Write-Verbose "Credentials entered"
    }
    if (-not ($SkipMSOL)) {
        Write-Warning "Connecting to MsolService"
        $aadGraphToken = New-PartnerAccessToken -ApplicationId $Credential.UserName -RefreshToken $refreshToken -Scopes 'https://graph.windows.net/.default' -ServicePrincipal -Credential $credential -Tenant $tenantID
        $graphToken =  New-PartnerAccessToken -ApplicationId $Credential.UserName -RefreshToken $refreshToken  -Scopes 'https://graph.microsoft.com/.default' -ServicePrincipal -Credential $credential -TenantId $tenantID
        if($null -eq $aadGraphToken)
        {
            Write-Warning "Failed to get aadGraphToken"
            $aadGraphToken = New-PartnerAccessToken -ApplicationId $Credential.UserName -RefreshToken $refreshToken -Scopes 'https://graph.windows.net/.default' -ServicePrincipal -Credential $credential -Tenant $tenantID
        }

        Connect-MsolService -AdGraphAccessToken $aadGraphToken.AccessToken -MsGraphAccessToken $graphToken.AccessToken
        #Connect-MsolService -Credential $Credential
    }
    if (-not ($ConnectMSOLOnly)) {
        Write-Verbose "Creating PSSession"
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Credential -Authentication Basic -AllowRedirection
    }
    return $Session
}
