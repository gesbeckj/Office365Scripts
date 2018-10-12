function Connect-Office365
{
    [CmdletBinding()]
    param(
    [switch]$ConnectMSOLOnly
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
    $Credential = Get-Credential
    if ($null -eq $Credential)
    {
        Write-Error "No credentials entered"
    }
    Connect-MsolService -Credential $Credential
    if (-not ($ConnectMSOLOnly))
    {
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Credential -Authentication Basic -AllowRedirection
    }
    return $Session
}
