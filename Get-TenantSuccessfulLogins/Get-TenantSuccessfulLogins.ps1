Function Get-TenantSuccessfulLogins
{
[CmdletBinding()]
param (
    [string]$TenantDomainName,
    [pscredential]$DelegatedAdminCred
)
if ($PSScriptRoot -eq $null)
{
    $here = Split-Path -Parent $MyInvocation.MyCommand.Path
}
else {
    $here = $PSScriptRoot
}

. "$here\..\Common\Get-TenantOffice365AuditLogs.ps1"
$mergedObject = @()
$logs = Get-TenantOffice365AuditLogs -Operations "UserLoggedIn" -TenantDomainName $TenantDomainName -DelegatedAdminCred $DelegatedAdminCred
$userIds = $logs.userIds | Sort-Object -Unique
foreach ($userId in $userIds) 
{
    Write-Verbose "Getting logons for $userId"
    $Result = ($logs | Where-Object {$_.userIds -contains $userId}).auditdata | ConvertFrom-Json -ErrorAction SilentlyContinue
    Write-Verbose "$userId has $($Result.count) logs"

    foreach ($singleResult in $Result)
    {
        $UserAgent = $singleResult.extendedproperties.value[0]
        $event = New-Object -TypeName PSObject
        $event | add-Member -Name 'UserID' -MemberType NoteProperty -Value $singleResult.UserId
        $event | add-Member -Name 'UserAgent' -MemberType NoteProperty -Value $UserAgent
        $event | add-Member -Name 'Time' -MemberType NoteProperty -Value $singleResult.CreationTime
        $event | add-Member -Name 'IP' -MemberType NoteProperty -Value $singleResult.ClientIP
        $mergedObject += $event
    }
}
return $mergedObject
}