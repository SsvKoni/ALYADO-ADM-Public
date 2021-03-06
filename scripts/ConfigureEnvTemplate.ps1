#Requires -Version 2.0

<#
    Copyright (c) Alya Consulting: 2020

    This file is part of the Alya Base Configuration.
	https://alyaconsulting.ch/Loesungen/BasisKonfiguration
    The Alya Base Configuration is free software: you can redistribute it
	and/or modify it under the terms of the GNU General Public License as
	published by the Free Software Foundation, either version 3 of the
	License, or (at your option) any later version.
    Alya Base Configuration is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
	Public License for more details: https://www.gnu.org/licenses/gpl-3.0.txt

    Diese Datei ist Teil der Alya Basis Konfiguration.
	https://alyaconsulting.ch/Loesungen/BasisKonfiguration
    Alya Basis Konfiguration ist Freie Software: Sie koennen es unter den
	Bedingungen der GNU General Public License, wie von der Free Software
	Foundation, Version 3 der Lizenz oder (nach Ihrer Wahl) jeder neueren
    veroeffentlichten Version, weiter verteilen und/oder modifizieren.
    Alya Basis Konfiguration wird in der Hoffnung, dass es nuetzlich sein wird,
	aber OHNE JEDE GEWAEHRLEISTUNG, bereitgestellt; sogar ohne die implizite
    Gewaehrleistung der MARKTFAEHIGKEIT oder EIGNUNG FUER EINEN BESTIMMTEN ZWECK.
    Siehe die GNU General Public License fuer weitere Details:
	https://www.gnu.org/licenses/gpl-3.0.txt

    History:
    Date       Author               Description
    ---------- -------------------- ----------------------------
    14.09.2020 Konrad Brunner       Initial version
#>

[CmdletBinding()]
Param(
)

Write-Host "Loading custom configuration" -ForegroundColor Cyan

<# TENANT SETTINGS #>
$AlyaTenantId = "PleaseSpecify" #Example:"11111111-2222-3333-4444-555555555555"
$AlyaTenantNameId = "PleaseSpecify" #Example:"alyaconsulting"
$AlyaTenantName = "PleaseSpecify" #Example:"$($AlyaTenantNameId).onmicrosoft.com"
$AlyaCompanyName = "PleaseSpecify" #Example:"Alya Consulting"
$AlyaCompanyNameShort = "PleaseSpecify" #Example:"alya"
$AlyaDomainName = "PleaseSpecify" #Example:"alyaconsulting.ch"
$AlyaLocalDomainName = "PleaseSpecify" #Example:"alyaconsulting.ch"
$AlyaEnvName = "PleaseSpecify" #Example:"$($AlyaCompanyNameShort)1stp"
$AlyaEnvNameTest = "PleaseSpecify" #Example:"$($AlyaCompanyNameShort)1stt"
$AlyaSubscriptionName = "PleaseSpecify" #Example:"$($AlyaEnvName)"
$AlyaNamingPrefix = "PleaseSpecify" #Example:"$($AlyaEnvName)"
$AlyaNamingPrefixTest = "PleaseSpecify" #Example:"$($AlyaEnvNameTest)"
$AlyaLocation = "PleaseSpecify" #Example:"westeurope"
$AlyaWebPage = "PleaseSpecify" #Example:"https://alyaconsulting.ch"
$AlyaPrivacyUrl = "PleaseSpecify" #Example:"https://alyaconsulting.ch/Home/Privacy"
$AlyaPrivacyEmail = "PleaseSpecify" #Example:"datenschutz@$($AlyaDomainName)"
$AlyaSecurityEmail = "PleaseSpecify" #Example:"security@$($AlyaDomainName)"
$AlyaGeneralInformEmail = "PleaseSpecify" #Example:"cloud@$($AlyaDomainName)"
$AlyaTimeZone = "PleaseSpecify" #Example:"W. Europe Standard Time"
$AlyaGeoId = "PleaseSpecify" #Example:223
$AlyaDefaultUsageLocation = "PleaseSpecify" #Example:"CH"
$AlyaPasswordResetEnabled = "PleaseSpecify" #Example:$true
$AlyaB2BCompStart = "PleaseSpecify" #Example:"["
$AlyaB2BCompEnd = "PleaseSpecify" #Example:"]"
$AlyaVMLicenseTypeClient = "PleaseSpecify" #Example:"None" #Windows_Client=HybridBenefit, None=PAYG
$AlyaVMLicenseTypeServer = "PleaseSpecify" #Example:"None" #Windows_Server=HybridBenefit, None=PAYG

<# LOGOS #>
$AlyaLogoUrlQuad = "PleaseSpecify" #Example:"https://alyainfpstrg001.blob.core.windows.net/corporate/images/LogoSchwarzQuadrat_256x248_wbg.png"
$AlyaLogoUrlRect = "PleaseSpecify" #Example:"https://alyainfpstrg001.blob.core.windows.net/corporate/images/LogoSchwarzMittel_640x240.png"

<# RESOURCE IDS #>
$AlyaResIdMainNetwork = "PleaseSpecify" #Example:"000"
$AlyaResIdMainInfra = "PleaseSpecify" #Example:"001"
$AlyaResIdAuditing = "PleaseSpecify" #Example:"002"
$AlyaResIdAutomation = "PleaseSpecify" #Example:"003"
$AlyaResIdAdResGrp = "PleaseSpecify" #Example:"005"
$AlyaResIdJumpHostResGrp = "PleaseSpecify" #Example:"010"
$AlyaResIdWvdImageResGrp = "PleaseSpecify" #Example:"040"

$AlyaResIdLogAnalytics = "PleaseSpecify" #Example:"002"
$AlyaResIdVirtualNetwork = "PleaseSpecify" #Example:"000"
$AlyaResIdMainKeyVault = "PleaseSpecify" #Example:"001"
$AlyaResIdDiagnosticStorage = "PleaseSpecify" #Example:"003"
$AlyaResIdAuditStorage = "PleaseSpecify" #Example:"002"
$AlyaResIdPublicStorage = "PleaseSpecify" #Example:"001"
$AlyaResIdPrivateStorage = "PleaseSpecify" #Example:"004"
$AlyaResIdRecoveryVault = "PleaseSpecify" #Example:"001"
$AlyaResIdAutomationAccount = "PleaseSpecify" #Example:"001"
$AlyaResIdAdSrv1 = "PleaseSpecify" #Example:"001"
$AlyaResIdAdSrv2 = "PleaseSpecify" #Example:"002"
$AlyaResIdAdSNet = "PleaseSpecify" #Example:"04"
$AlyaResIdJumpHost = "PleaseSpecify" #Example:"010"
$AlyaResIdJumpHostSNet = "PleaseSpecify" #Example:"05"
$AlyaResIdVpnGateway = "PleaseSpecify" #Example:"001"
$AlyaResIdWvdImageClient = "PleaseSpecify" #Example:"041"
$AlyaResIdWvdImageServer = "PleaseSpecify" #Example:"042"
$AlyaResIdWvdImageSNet = "PleaseSpecify" #Example:"05"

<# SHARING SETTINGS #>
$AlyaSharingPolicy = "PleaseSpecify" #Example:"KnownAccountsOnly" # AdminOnly, KnownAccountsOnly, ByLink
$AlyaOnlyEmailVerifiedUsers = "PleaseSpecify" #Example:$true

<# APPLICATION SETTINGS #>
$AlyaAllowUsersToCreateLOBApps = "PleaseSpecify" #Example:$false

<# JUMP HOST SETTINGS #>
$AlyaJumpHostSKU = "PleaseSpecify" #Example:"Standard_D2s_v3"
$AlyaJumpHostAcceleratedNetworking = "PleaseSpecify" #Example:$false
$AlyaJumpHostEdition = "PleaseSpecify" #Example:"2019-Datacenter"
$AlyaJumpHostBackupEnabled = "PleaseSpecify" #Example:$false
$AlyaJumpHostStartTime = "PleaseSpecify" #Example:$null
$AlyaJumpHostStopTime = "PleaseSpecify" #Example:"20:00"
$AlyaJumpHostBackupPolicy = "PleaseSpecify" #Example:"NightlyPolicy"

<# GROUP SETTINGS #>
$AlyaMfaDisabledGroupName = "PleaseSpecify" #Example:"ALYASG-ADM-MFADISABLED"
$AlyaMfaDisabledForGroups = "PleaseSpecify" #Example:@("ALYAOG-ADM-AlleExternen")
$AlyaGroupManagerGroupName = "PleaseSpecify" #Example:"ALYASG-ADM-O365GROUPMANAGERS" # Only members can create groups
#TODO $AlyaGroupManagerMembers = @()
$AlyaAllInternals = "PleaseSpecify" #Example:"ALYAOG-ADM-AlleInternen"
$AlyaAllExternals = "PleaseSpecify" #Example:"ALYAOG-ADM-AlleExternen"

<# NETWORK SETTINGS #>
$AlyaAzureNetwork = "PleaseSpecify" #Example:"172.16.0.0/16"
$AlyaProdNetwork = "PleaseSpecify" #Example:"172.16.72.0/24"
$AlyaTestNetwork = "PleaseSpecify" #Example:"172.16.172.0/24"
$AlyaSubnetPrefixLength = "PleaseSpecify" #Example:26
$AlyaGatewayPrefixLength = "PleaseSpecify" #Example:28
$AlyaDeployGateway = "PleaseSpecify" #Example:$false

<# WVD SETTINGS #>
<#
$AlyaWvdRDBroker = "PleaseSpecify" #Example:"https://rdbroker.wvd.microsoft.com"
$AlyaWvdTenantNameProd = "PleaseSpecify" #Example:"ALYA Prod"
$AlyaWvdTenantNameTest = "PleaseSpecify" #Example:"ALYA Test"
$AlyaWvdAzureServicePrincipalName = "PleaseSpecify" #Example:"AlyaWvdAzureApp"
$AlyaWvdServicePrincipalNameProd = "PleaseSpecify" #Example:"AlyaWvdProdApp"
$AlyaWvdServicePrincipalNameTest = "PleaseSpecify" #Example:"AlyaWvdTestApp"
$AlyaWvdTenantGroupName = "PleaseSpecify" #Example:"Default Tenant Group"
$AlyaWvdAdmins = "PleaseSpecify" #Example:@("konrad.brunner@$($AlyaDomainName)")
$AlyaWvdStartTime = "PleaseSpecify" #Example:"06:00"
$AlyaWvdStopTime = "PleaseSpecify" #Example:"23:00"
#>

<# SHAREPOINT ONPREM SETTINGS #>
$AlyaSharePointOnPremMySiteUrl = "PleaseSpecify" #Example:"https://mysite.$($AlyaLocalDomainName)"
$AlyaSharePointOnPremClaimPrefix = "PleaseSpecify" #Example:"w:"
$AlyaSharePointOnPremVersion = "PleaseSpecify" #Example:"2019"

<# SHAREPOINT SETTINGS #>
$AlyaSharePointUrl = "https://$($AlyaTenantNameId).sharepoint.com"
$AlyaSharePointAdminUrl = "https://$($AlyaTenantNameId)-admin.sharepoint.com"
$AlyaSharePointNewSiteOwner = "PleaseSpecify" #Example:"konrad.brunner@$($AlyaDomainName)"
#https://fabricweb.z5.web.core.windows.net/pr-deploy-site/refs/heads/master/theming-designer/index.html
$AlyaSpThemeDef = @{ 
    "themePrimary" = "#000000";
    "themeLighterAlt" = "#898989";
    "themeLighter" = "#737373";
    "themeLight" = "#595959";
    "themeTertiary" = "#373737";
    "themeSecondary" = "#2f2f2f";
    "themeDarkAlt" = "#252525";
    "themeDark" = "#151515";
    "themeDarker" = "#0b0b0b";
    "neutralLighterAlt" = "#faf9f8";
    "neutralLighter" = "#f3f2f1";
    "neutralLight" = "#edebe9";
    "neutralQuaternaryAlt" = "#e1dfdd";
    "neutralQuaternary" = "#d0d0d0";
    "neutralTertiaryAlt" = "#c8c6c4";
    "neutralTertiary" = "#595959";
    "neutralSecondary" = "#373737";
    "neutralPrimaryAlt" = "#2f2f2f";
    "neutralPrimary" = "#000000";
    "neutralDark" = "#151515";
    "black" = "#0b0b0b";
    "white" = "#ffffff";
}

<# AIP SETTINGS #>
$AlyaAipApiServiceLocation = "PleaseSpecify" #Example:
<# PSTN SETTINGS #>
$AlyaPstnGateway = "PleaseSpecify" #Example:"pstn.provider.ch"
$AlyaPstnPort = "PleaseSpecify" #Example:"5080"
$AlyaPstnPolicyName = "PleaseSpecify" #Example:"ProviderName"

<# COLORS #>
$CommandInfo = "Cyan"
$CommandSuccess = "Green"
$CommandError = "Red"
$CommandWarning = "Yellow"
$AlyaColor = "White"
$TitleColor = "Green"
$MenuColor = "Magenta"
$QuestionColor = "Magenta"

