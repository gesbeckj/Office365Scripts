Function Get-AllTenantLicensedSharedMailboxes
{
    [CmdletBinding()]
    param (
        [parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [psobject[]]$TenantsList
    )
    if ($PSScriptRoot -eq $null) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    else {
        $here = $PSScriptRoot
    }
    . "$here\..\Get-AllTenantUserLicenses\Get-AllTenantUserLicenses.ps1"
    $AllLicenses = Get-AllTenantUserLicenses $TenantsList
    $outputData = @()
    foreach ($license in $AllLicenses)
    {
        if ($license.Type -eq "SharedMailbox" -and ($license.License.Length -gt 2))
        {
        Write-Verbose "User account is shared mailbox with a license"
        $outputData += $license
        }
    }
    return $outputData
}