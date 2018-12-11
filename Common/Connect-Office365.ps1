function Connect-Office365 {
    [CmdletBinding()]
    param(
        [switch]$ConnectMSOLOnly,
        [switch]$SkipMSOL,
        [pscredential]$Credential
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
        Write-Verbose "Connecting to MsolService"
        Connect-MsolService -Credential $Credential
    }
    if (-not ($ConnectMSOLOnly)) {
        Write-Verbose "Creating PSSession"
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Credential -Authentication Basic -AllowRedirection
    }
    return $Session
}
