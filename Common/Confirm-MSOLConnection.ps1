try {
    Get-MsolDomain -ErrorAction Stop > $null
} catch {
    if ($cred -eq $null) {
        $cred = Get-Credential $O365Adminuser
    }
    Write-Output "Connecting to Office 365..."
    Connect-MsolService -Credential $cred
}
