#Requires -Version 2.0

<#
    Copyright (c) Alya Consulting: 2020

    This file is part of the Alya Base Configuration.
    The Alya Base Configuration is free software: you can redistribute it
	and/or modify it under the terms of the GNU General Public License as
	published by the Free Software Foundation, either version 3 of the
	License, or (at your option) any later version.
    Alya Base Configuration is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of 
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
	Public License for more details: https://www.gnu.org/licenses/gpl-3.0.txt

    Diese Datei ist Teil der Alya Basis Konfiguration.
    Alya Basis Konfiguration ist Freie Software: Sie koennen es unter den
	Bedingungen der GNU General Public License, wie von der Free Software
	Foundation, Version 3 der Lizenz oder (nach Ihrer Wahl) jeder neueren
    veroeffentlichten Version, weiter verteilen und/oder modifizieren.
    Alya Basis Konfiguration wird in der Hoffnung, dass es nuetzlich sein wird,
	aber OHNE JEDE GEWAEHRLEISTUNG, bereitgestellt; sogar ohne die implizite
    Gewaehrleistung der MARKTFAEHIGKEIT oder EIGNUNG FUER EINEN BESTIMMTEN ZWECK.
    Siehe die GNU General Public License fuer weitere Details:
	https://www.gnu.org/licenses/gpl-3.0.txt

    To design your own SharePoint Theme use the UI Fabric Theme Designer
    https://fabricweb.z5.web.core.windows.net/pr-deploy-site/refs/heads/master/theming-designer/index.html

    History:
    Date       Author               Description
    ---------- -------------------- ----------------------------
    06.03.2020 Konrad Brunner       Initial Version

#>

[CmdletBinding()]
Param(
)

#Reading configuration
. $PSScriptRoot\..\..\01_ConfigureEnv.ps1

#Starting Transscript
Start-Transcript -Path "$($AlyaLogs)\scripts\sharepoint\Configure-AzureB2BIntegration-$($AlyaTimeString).log" | Out-Null

# Checking modules
Write-Host "Checking modules" -ForegroundColor $CommandInfo
Install-ModuleIfNotInstalled "Microsoft.Online.Sharepoint.PowerShell"
Install-ModuleIfNotInstalled "AzureAdPreview"

# Logging in
LoginTo-AD
LoginTo-SPO

# =============================================================
# O365 stuff
# =============================================================

Write-Host "`n`n=====================================================" -ForegroundColor $CommandInfo
Write-Host "SharePoint | Configure-AzureB2BIntegration | O365" -ForegroundColor $CommandInfo
Write-Host "=====================================================`n" -ForegroundColor $CommandInfo

# Configuring AzureB2BIntegration
Write-Host "Configuring AzureB2BIntegration" -ForegroundColor $CommandInfo
$TenantConfig = Get-SPOTenant
if (-Not $TenantConfig.EnableAzureADB2BIntegration)
{
    Write-Warning "AzureB2B integration was not enabled. Enabling now AzureB2B integration"
    Set-SPOTenant -EnableAzureADB2BIntegration $true
    Set-SPOTenant -SyncAadB2BManagementPolicy $true
    Write-Warning "Enabling one-time-passcode authentication"
    $currentpolicy =  Get-AzureADPolicy | where {$_.Type -eq 'B2BManagementPolicy' -and $_.IsOrganizationDefault -eq $true} | select -First 1
    if (-Not $currentpolicy)
    {
        Write-Warning "Creating B2BManagementPolicy"
        $policyValue=@("{`"B2BManagementPolicy`":{`"PreviewPolicy`":{`"Features`":[`"OneTimePasscode`"]}}}")
        New-AzureADPolicy -Definition $policyValue -DisplayName B2BManagementPolicy -Type B2BManagementPolicy -IsOrganizationDefault $true
        $currentpolicy =  Get-AzureADPolicy | where {$_.Type -eq 'B2BManagementPolicy' -and $_.IsOrganizationDefault -eq $true} | select -First 1
    }
    $policy = $currentpolicy.Definition | ConvertFrom-Json
    $features = [PSCustomObject]@{'Features'=@('OneTimePasscode')}; $policy.B2BManagementPolicy | Add-Member 'PreviewPolicy' $features -Force; $policy.B2BManagementPolicy
    $updatedPolicy = $policy | ConvertTo-Json -Depth 3
    Set-AzureADPolicy -Definition $updatedPolicy -Id $currentpolicy.Id
}
else
{
    Write-Host "AzureB2B integration was already enabled." -ForegroundColor $CommandSuccess
}

#Stopping Transscript
Stop-Transcript