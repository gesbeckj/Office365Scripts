Function Get-TenantGraphAPIData {
    [CmdletBinding()]
    param (
        [psobject]$Tenant,
        [pscredential]$DelegatedAdminCred,
        [string]$GraphAPIURI,
        [string]$refreshToken,
        [string]$tenantID
    )
    $ApplicationName = "GraphAPIQuery"
    $ApplicationPermissions = "Directory.Read.All SecurityEvents.Read.All Reports.Read.All"
    if ($PSScriptRoot -eq $null) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $here = $PSScriptRoot
    }
    . "$here\..\Common\AzureAdCommon.ps1"


    $azureToken = New-PartnerAccessToken -RefreshToken $refreshToken -Resource https://management.azure.com/ -Credential $credential -TenantId $tenantID
    $graphToken =  New-PartnerAccessToken -RefreshToken $refreshToken -Resource https://graph.microsoft.com -Credential $credential -TenantId $tenantID
    $TempResults = Connect-AzureRmAccount -AccessToken $azureToken.AccessToken -GraphAccessToken $graphToken.AccessToken -TenantId $Tenant.CustomerContextId 
    
    
    
    Write-Verbose "Creating Azure AD App for $((Get-AzureADTenantDetail).displayName)"

    # Check for a Microsoft Graph Service Principal. If it doesn't exist already, create it.
    $graphsp = GetOrCreateMicrosoftGraphServicePrincipal -Customer $Tenant -DelegatedAdminCred $DelegatedAdminCred

    #Purge the App for GraphAPI Queries if it already exists
    $existingapp = $null
    $existingapp = get-azureadapplication -SearchString $applicationName
    if ($existingapp) {
        $TempResults = Remove-Azureadapplication -ObjectId $existingApp.objectId
    }

    $rsps = @()
    if ($graphsp) {
        $rsps += $graphsp
        $tenant_id = (Get-AzureADTenantDetail).ObjectId
        #$tenantName = (Get-AzureADTenantDetail).DisplayName
        $azureadsp = Get-AzureADServicePrincipal -SearchString "Windows Azure Active Directory"
        $rsps += $azureadsp
        # Add Required Resources Access (Microsoft Graph)
        $requiredResourcesAccess = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.RequiredResourceAccess]
        $microsoftGraphRequiredPermissions = GetRequiredPermissions -reqsp $graphsp -requiredApplicationPermissions $ApplicationPermissions
        $requiredResourcesAccess.Add($microsoftGraphRequiredPermissions)  
        # Get an application key
        $pw = Compute-Password
        $fromDate = [System.DateTime]::Now
        $appKey = CreateAppKey -fromDate $fromDate -durationInYears 2 -pw $pw
        Write-Verbose "Creating the AAD application $applicationName"
        $aadApplication = New-AzureADApplication -DisplayName $applicationName -RequiredResourceAccess $requiredResourcesAccess -PasswordCredentials $appKey
        # Creating the Service Principal for the application
        $servicePrincipal = New-AzureADServicePrincipal -AppId $aadApplication.AppId
        Write-Verbose "Assigning Permissions"
        foreach ($app in $requiredResourcesAccess) {
        
            $reqAppSP = $rsps | Where-Object {$_.appid -contains $app.ResourceAppId}
            Write-Verbose "Assigning Application permissions for $($reqAppSP.displayName)" 
        
            foreach ($resource in $app.ResourceAccess) {
                if ($resource.Type -match "Role") {
                    $TempResults = New-AzureADServiceAppRoleAssignment -ObjectId $serviceprincipal.ObjectId -PrincipalId $serviceprincipal.ObjectId -ResourceId $reqAppSP.ObjectId -Id $resource.Id | out-null
                }
            }
        }
        Write-Verbose "App Created"
        $client_id = $aadApplication.AppId;
        $client_secret = $appkey.Value
        $tenant_id = (Get-AzureADTenantDetail).ObjectId
        $resource = "https://graph.microsoft.com"
        $authority = "https://login.microsoftonline.com/$tenant_id"
        $tokenEndpointUri = "$authority/oauth2/token"
        $content = "grant_type=client_credentials&client_id=$client_id&client_secret=$client_secret&resource=$resource"
        # Try to execute the API call 6 times
        $Stoploop = $false
        [int]$Retrycount = "0"
        do {
            try {
                $response = Invoke-RestMethod -Uri $tokenEndpointUri -Body $content -Method Post -UseBasicParsing
                Write-Verbose "Retrieved Access Token"
                $access_token = $response.access_token
                $body = $null
                $headers = @{"Authorization" = "Bearer $access_token"}
                $body = Invoke-RestMethod -Uri $GraphAPIURI -Headers $headers -ContentType "application/json" -method GET
                Write-Verbose "Retrieved Graph content"
                $Stoploop = $true
            }
            Catch
            {
                if ($Retrycount -gt 6) {
                    Write-Warning "Could not get Graph content after 7 retries." 
                    $Stoploop = $true
                }
                else {
                    Write-Verbose "Could not get Graph content. Retrying in 5 seconds..." 
                    Start-Sleep -Seconds 5
                    $Retrycount ++
                }
            }
        }
        While ($Stoploop -eq $false)
        Remove-AzureADApplication -ObjectId $aadApplication.ObjectId | out-null
    }
    else {
        Write-Warning "Microsoft Graph Service Principal could not be found or created" 
    }
    if($null -ne $body.value)
    {
    $body.value | Add-Member TenantName $Tenant.DisplayName    
    #$body.value | Add-Member Date [System.DateTime]::Today
    return $body.value
    }
    else {
        $body | Add-Member TenantName $tenant.DisplayName
        #$body | Add-Member Date [System.DateTime]::Today
        return $body
    }
}