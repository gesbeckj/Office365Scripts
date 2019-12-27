Function Get-LicenseName {
    [CmdletBinding()]
    Param(
        [psobject[]]$licenseParts)
    $Sku = @{ 
        AAD_BASIC                          = 'Azure Active Directory Basic'
        AAD_PREMIUM                        = 'Azure Active Directory Premium'
        ATA                                = 'Advanced Threat Analytics'
        ATP_ENTERPRISE                     = 'MS O365 Add-On - Advanced Threat Protection'
        BI_AZURE_P1                        = 'Power BI Reporting and Analytics'
        BI_AZURE_P2                        = 'Power BI Pro'
        CRMINSTANCE                        = 'Dynamics CRM Online Additional Production Instance'
        CRMIUR                             = 'CRM for Partners'
        CRMPLAN1                           = 'Dynamics CRM Online Essential'
        CRMPLAN2                           = 'Dynamics CRM Online Basic'
        CRMSTANDARD                        = 'CRM Online'
        CRMSTORAGE                         = 'Dynamics CRM Online Additional Storage'
        CRMTESTINSTANCE                    = 'CRM Test Instance'
        DESKLESS                           = 'Microsoft StaffHub'
        DESKLESSPACK                       = 'Office 365 (Plan K1)'
        DESKLESSPACK_GOV                   = 'Office 365 (Plan K1) for Government'
        DESKLESSPACK_YAMME                 = 'Office 365 (Plan K1) with Yammer'
        DESKLESSWOFFPACK                   = 'Office 365 (Plan K2)'
        DESKLESSWOFFPACK_GOV               = 'Office 365 (Plan K2) for Government'
        DYN365_ENTERPRISE_P1_IW            = 'Dynamics 365 P1 Trial for Information Workers'
        DYN365_ENTERPRISE_PLAN1            = 'Dynamics 365 Customer Engagement Plan Enterprise Edition'
        DYN365_ENTERPRISE_SALES            = 'Dynamics Office 365 Enterprise Sales'
        DYN365_ENTERPRISE_TEAM_MEMBERS     = 'Dynamics 365 For Team Members Enterprise Edition'
        DYN365_FINANCIALS_BUSINESS_SKU     = 'Dynamics 365 for Financials Business Edition'
        DYN365_FINANCIALS_TEAM_MEMBERS_SKU = 'Dynamics 365 for Team Members Business Edition'
        ECAL_SERVICES                      = 'ECAL'
        EMS                                = 'Enterprise Mobility Suite'
        ENTERPRISEPACK                     = 'MS O365 Subscription - E3'
        ENTERPRISEPACK_B_PILOT             = 'Office 365 (Enterprise Preview)'
        ENTERPRISEPACK_FACULTY             = 'Office 365 (Plan A3) for Faculty'
        ENTERPRISEPACK_GOV                 = 'Office 365 (Plan G3) for Government'
        ENTERPRISEPACK_STUDENT             = 'Office 365 (Plan A3) for Students'
        ENTERPRISEPACKLRG                  = 'MS O365 Subscription - E3'
        ENTERPRISEPACKWSCAL                = 'Office 365 (Plan E4)'
        ENTERPRISEPREMIUM                  = 'MS O365 Subscription - E5'
        ENTERPRISEPREMIUM_NOPSTNCONF       = 'MS O365 Subscription - E5'
        ENTERPRISEWITHSCAL                 = 'Office 365 (Plan E4)'
        ENTERPRISEWITHSCAL_FACULTY         = 'Office 365 (Plan A4) for Faculty'
        ENTERPRISEWITHSCAL_GOV             = 'Office 365 (Plan G4) for Government'
        ENTERPRISEWITHSCAL_STUDENT         = 'Office 365 (Plan A4) for Students'
        EOP_ENTERPRISE                     = 'MS O365 Subscription - Exchange Online Protection'
        EOP_ENTERPRISE_FACULTY             = 'Exchange Online Protection for Faculty'
        EQUIVIO_ANALYTICS                  = 'Office 365 Advanced eDiscovery'
        ESKLESSWOFFPACK_GOV                = 'Office 365 (Plan K2) for Government'
        EXCHANGE_ANALYTICS                 = 'Delve Analytics'
        EXCHANGE_L_STANDARD                = 'MS O365 Subscription - Exchange Plan 1'
        EXCHANGE_S_ARCHIVE_ADDON_GOV       = 'Exchange Online Archiving for Government'
        EXCHANGE_S_DESKLESS                = 'MS O365 Subscription - Exchange Online Kiosk'
        EXCHANGE_S_DESKLESS_GOV            = 'Exchange Kiosk for Government'
        EXCHANGE_S_ENTERPRISE              = 'MS O365 Subscription - Exchange Plan 2'
        EXCHANGE_S_ENTERPRISE_GOV          = 'Exchange (Plan G2) for Government'
        EXCHANGE_S_STANDARD                = 'Exchange Online (Plan 2)'
        EXCHANGE_S_STANDARD_MIDMARKET      = 'MS O365 Subscription - Exchange Plan 1'
        EXCHANGEARCHIVE                    = 'MS O365 Subscription - Exchange Online Archiving'
        EXCHANGEARCHIVE_ADDON              = 'MS O365 Add-On - Exch Onl Arch - Exchange Online Archiving'
        EXCHANGEDESKLESS                   = 'MS O365 Subscription - Exchange Online Kiosk'
        EXCHANGEENTERPRISE                 = 'MS O365 Subscription - Exchange Plan 2'
        EXCHANGEENTERPRISE_GOV             = 'Office 365 Exchange Online (Plan 2) for Government'
        EXCHANGESTANDARD                   = 'MS O365 Subscription - Exchange Plan 1'
        EXCHANGESTANDARD_GOV               = 'Office 365 Exchange Online (Plan 1) for Government'
        EXCHANGESTANDARD_STUDENT           = 'Exchange Online (Plan 1) for Students'
        EXCHANGETELCO                      = 'Exchange Online POP'
        FLOW_FREE                          = 'Microsoft Flow'
        FLOW_P1                            = 'Microsoft Flow Plan 1'
        FLOW_P2                            = 'Microsoft Flow Plan 2'
        INTUNE_A                           = 'MS O365 Subscription - Windows Intune'
        INTUNE_A_VL                        = 'MS O365 Subscription - Windows Intune'
        INTUNE_O365                        = 'MS O365 Subscription - Windows Intune'
        INTUNE_STORAGE                     = 'Intune Extra Storage'
        IT_ACADEMY_AD                      = 'Microsoft Imagine Academy'
        LITEPACK                           = 'Office 365 (Plan P1)'
        LITEPACK_P2                        = 'Office 365 Small Business Premium'
        LOCKBOX                            = 'Customer Lockbox'
        LOCKBOX_ENTERPRISE                 = 'Customer Lockbox'
        MCOEV                              = 'Skype for Business Cloud PBX'
        MCOIMP                             = 'MS O365 Subscription - Skype for Business Plan 1'
        MCOLITE                            = 'MS O365 Subscription - Skype for Business Plan 1'
        MCOMEETADV                         = 'MS O365 Subscription - Skype for Business PSTN'
        MCOPLUSCAL                         = 'Skype for Business Plus CAL'
        MCOPSTN1                           = 'MS O365 Subscription - Domestic Calling Plan'
        MCOPSTN2                           = 'Skype for Business PSTN Domestic and International Calling plan'
        MCOPSTNC                           = 'Skype for Business Communication Credits - None?'
        MCOPSTNPP                          = 'Skype for Business Communication Credits - Paid?'
        MCOSTANDARD                        = 'MS O365 Subscription - Skype for Business Plan 2'
        MCOSTANDARD_GOV                    = 'Skype for Business (Plan G2) for Government'
        MCOSTANDARD_MIDMARKET              = 'MS O365 Subscription - Skype for Business Plan 1'
        MCOVOICECONF                       = 'Lync Online (Plan 3)'
        MCVOICECONF                        = 'Skype for Business Online (Plan 3)'
        MFA_PREMIUM                        = 'Azure Multi-Factor Authentication'
        MICROSOFT_BUSINESS_CENTER          = 'Microsoft Business Center'
        MIDSIZEPACK                        = 'Office 365 Midsize Business'
        'MS-AZR-0145P'                     = 'Azure'
        NBPOSTS                            = 'Social Engagement Additional 10K Posts'
        NBPROFESSIONALFORCRM               = 'Social Listening Professional'
        O365_BUSINESS                      = 'MS O365 Subscription - Business'
        O365_BUSINESS_ESSENTIALS           = 'MS O365 Subscription - Business Essentials'
        O365_BUSINESS_PREMIUM              = 'MS O365 Subscription - Business Premium'
        OFFICE_PRO_PLUS_SUBSCRIPTION_SMBIZ = 'MS O365 Subscription - ProPlus'
        OFFICESUBSCRIPTION                 = 'MS O365 Subscription - ProPlus'
        OFFICESUBSCRIPTION_FACULTY         = 'Office 365 ProPlus for Faculty'
        OFFICESUBSCRIPTION_GOV             = 'Office ProPlus for Government'
        OFFICESUBSCRIPTION_STUDENT         = 'Office ProPlus Student Benefit'
        ONEDRIVESTANDARD                   = 'OneDrive'
        PARATURE_ENTERPRISE                = 'Parature Enterprise'
        PARATURE_FILESTORAGE_ADDON         = 'Parature File Storage Addon'
        PARATURE_SUPPORT_ENHANCED          = 'Parature Support Enhanced'
        PLANNERSTANDALONE                  = 'Planner Standalone'
        POWER_BI_ADDON                     = 'Power BI for Office 365 Add-On'
        POWER_BI_INDIVIDUAL_USE            = 'Power BI Individual User'
        POWER_BI_INDIVIDUAL_USER           = 'Power BI for Office 365 Individual'
        POWER_BI_PRO                       = 'Power BI Pro'
        POWER_BI_STANDALONE                = 'Power BI for Office 365'
        POWER_BI_STANDARD                  = 'Power BI Standard'
        POWERAPPS_INDIVIDUAL_USER          = 'Microsoft PowerApps and Logic flows'
        POWERAPPS_VIRAL                    = 'Microsoft Power Apps & Flow'
        PROJECT_CLIENT_SUBSCRIPTION        = 'MS O365 Subscription - Project Pro'
        PROJECT_ESSENTIALS                 = 'Project Lite'
        PROJECT_MADEIRA_PREVIEW_IW_SKU     = 'Dynamics 365 for Financials for IWs'
        PROJECTCLIENT                      = 'MS O365 Subscription - Project Pro'
        PROJECTESSENTIALS                  = 'Project Lite'
        PROJECTONLINE_PLAN_1               = 'Project Online (Plan 1)'
        PROJECTONLINE_PLAN_1_FACULTY       = 'Project Online for Faculty Plan 1'
        PROJECTONLINE_PLAN_1_STUDENT       = 'Project Online for Students Plan 1'
        PROJECTONLINE_PLAN_2               = 'Project Online (Plan 2)'
        PROJECTONLINE_PLAN_2_FACULTY       = 'Project Online for Faculty Plan 2'
        PROJECTONLINE_PLAN_2_STUDENT       = 'Project Online for Students Plan 2'
        PROJECTONLINE_PLAN1_FACULTY        = 'Project Online for Faculty'
        PROJECTONLINE_PLAN1_STUDENT        = 'Project Online for Students'
        ProjectPremium                     = 'Project Online Premium'
        PROJECTPROFESSIONAL                = 'MS O365 Subscription - Project Pro'
        PROJECTWORKMANAGEMENT              = 'Office 365 Planner Preview'
        RIGHTSMANAGEMENT                   = 'MS O365 Subscription - Azure Rights Management'
        RIGHTSMANAGEMENT_ADHOC             = 'MS O365 Subscription - Azure Rights Management'
        RIGHTSMANAGEMENT_STANDARD_FACULTY  = 'Information Rights Management for Faculty'
        RIGHTSMANAGEMENT_STANDARD_STUDENT  = 'Information Rights Management for Students'
        RMS_S_ENTERPRISE                   = 'MS O365 Subscription - Azure Rights Management'
        RMS_S_ENTERPRISE_GOV               = 'Windows Azure Active Directory Rights Management for Government'
        SHAREPOINT_PROJECT_EDU             = 'Project Online for Education'
        SHAREPOINTDESKLESS                 = 'SharePoint Online Kiosk'
        SHAREPOINTDESKLESS_GOV             = 'SharePoint Online Kiosk for Government'
        SHAREPOINTENTERPRISE               = 'MS O365 Subscription - SharePoint Online Plan 2'
        SHAREPOINTENTERPRISE_EDU           = 'SharePoint (Plan 2) for EDU'
        SHAREPOINTENTERPRISE_GOV           = 'SharePoint (Plan G2) for Government'
        SHAREPOINTENTERPRISE_MIDMARKET     = 'SharePoint Online (Plan 1)'
        SHAREPOINTLITE                     = 'SharePoint Online (Plan 1)'
        SHAREPOINTPARTNER                  = 'SharePoint Online Partner Access'
        SHAREPOINTSTANDARD                 = 'SharePoint Online (Plan 1)'
        SHAREPOINTSTANDARD_YAMMER          = 'Sharepoint Standard with Yammer'
        SHAREPOINTSTORAGE                  = 'MS O365 Sub - Extra File Storage Per GB'
        SHAREPOINTWAC                      = 'Office Online'
        SHAREPOINTWAC_EDU                  = 'Office Online for Education'
        SHAREPOINTWAC_GOV                  = 'Office Online for Government'
        SPE_E3                             = 'Microsoft 365 E3'
        SPE_E5                             = 'Microsoft 365 E5'
        SPZA_IW                            = 'App Connect'
        SQL_IS_SSIM                        = 'MS O365 Subscription - Power BI Add On'
        STANDARD_B_PILOT                   = 'Office 365 (Small Business Preview)'
        STANDARDPACK                       = 'MS O365 Subscription - E1'
        STANDARDPACK_FACULTY               = 'Office 365 (Plan A1) for Faculty'
        STANDARDPACK_GOV                   = 'Office 365 (Plan G1) for Government'
        STANDARDPACK_STUDENT               = 'Office 365 (Plan A1) for Students'
        STANDARDWOFFPACK                   = 'Office 365 (Plan E2)'
        STANDARDWOFFPACK_FACULTY           = 'Office 365 Education E1 for Faculty'
        STANDARDWOFFPACK_GOV               = 'Office 365 (Plan G2) for Government'
        STANDARDWOFFPACK_IW_FACULTY        = 'Office 365 Education for Faculty'
        STANDARDWOFFPACK_IW_STUDENT        = 'Office 365 Education for Students'
        STANDARDWOFFPACK_STUDENT           = 'Office 365 (Plan A2) for Students'
        STANDARDWOFFPACKPACK_FACULTY       = 'Office 365 (Plan A2) for Faculty'
        STANDARDWOFFPACKPACK_STUDENT       = 'Office 365 (Plan A2) for Students'
        STREAM                             = 'Stream'
        SWAY                               = 'SWAY'
        VIDEO_INTEROP                      = 'Polycom Skype Meeting Video Interop for Skype for Business'
        VISIO_CLIENT_SUBSCRIPTION          = 'MS O365 Subscription - Visio Online Plan 2'
        VISIOCLIENT                        = 'MS O365 Subscription - Visio Online Plan 2'
        VISIOONLINE_PLAN1                  = 'MS O365 Subscription - Visio Online Plan 1'
        WACONEDRIVEENTERPRISE              = 'OneDrive for Business (Plan 2)'
        WACONEDRIVESTANDARD                = 'OneDrive Pack'
        WACSHAREPOINTENT                   = 'Office Web Apps with SharePoint (Plan 2)'
        WACSHAREPOINTSTD                   = 'Office Web Apps with SharePoint (Plan 1)'
        WINDOWS_STORE                      = 'Windows Store for Business'
        YAMMER_ENTERPRISE                  = 'Yammer'
        YAMMER_ENTERPRISE_STANDALONE       = 'Yammer Enterprise'
        YAMMER_MIDSIZE                     = 'Yammer'
        NONPROFIT_PORTAL                   = 'Non-Profit Portal'
        SMB_APPS                           = 'Business Apps (free)'
        ATP_ENTERPRISE_FACULTY             = 'Exchange Online Advanced Threat Protection'
    } 
    $Tassignedlicense = ""
    $Fassignedlicense = ""
    $assignedlicense = ""
    $userlicense = ""
    foreach ($license in $licenseparts) { 
        if ($Sku.Item($license)) { 
            $Tassignedlicense = $Sku.Item("$($license)") + "::" + $Tassignedlicense 
        } else { 
            Write-Warning -Message "user $($user) has an unrecognized license $license. Please update script." 
            $Fassignedlicense = "UNKNOWN" + "::" + $Fassignedlicense 
        } 
        $assignedlicense = $Tassignedlicense + $Fassignedlicense 
         
    } 
    $userLicense = $assignedlicense
    if ($userLicense -eq "")
    {
        Write-Verbose "User has no license"
        return ""
    }
    Write-Verbose "License name is $userLicense"
    $LicName = $userlicense.Substring(0, $userlicense.Length - 2)
    if($null -ne $LicName){
    return $userlicense.Substring(0, $userlicense.Length - 2)
    }
    else {
        return "UNKNOWN"
    }
}
