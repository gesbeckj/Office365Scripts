$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Function Get-Office365AuditLogs {
    [CmdletBinding()]
    param 
    (
        [int]$Days = 30, 
        [datetime]$startDate = (Get-Date).AddDays(-$days),
        [datetime] $endDate = (Get-Date),
        [string]$Operations = "UserLoggedIn"
    )

    . "$here\..\Common\Connect-Office365.ps1"
    $session = Connect-Office365
    import-pssession $session 
    $Logs = @()
    Write-Information "Retrieving logs"
    do {
        $logs += Search-unifiedAuditLog -SessionCommand ReturnLargeSet -SessionId "UALSearch" -ResultSize 5000 -StartDate $startDate -EndDate $endDate -Operations $operations #-SessionId "$($customer.name)"
        Write-Information "Retrieved $($logs.count) logs"
    }while ($Logs.count % 5000 -eq 0 -and $logs.count -ne 0)
    Write-Information "Finished Retrieving logs"
    Remove-PSSession $Session
    Return $logs
}