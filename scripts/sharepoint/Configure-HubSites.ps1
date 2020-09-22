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

    History:
    Date       Author               Description
    ---------- -------------------- ----------------------------
    15.09.2020 Konrad Brunner       Initial Version

#>

[CmdletBinding()]
Param(
)

#Reading configuration
. $PSScriptRoot\..\..\01_ConfigureEnv.ps1

#Starting Transscript
Start-Transcript -Path "$($AlyaLogs)\scripts\sharepoint\Configure-HubSites-$($AlyaTimeString).log" | Out-Null

# Checking modules
Write-Host "Checking modules" -ForegroundColor $CommandInfo
Install-ModuleIfNotInstalled "Microsoft.Online.Sharepoint.PowerShell"
Install-ModuleIfNotInstalled "SharePointPnPPowerShellOnline" -exactVersion "3.23.2007.1" #TODO Upgrade after bug is fixed https://github.com/pnp/PnP-PowerShell/issues/2849

# Logging in
LoginTo-SPO

# Constants
if ((Test-Path "$AlyaData\sharepoint\HubSitesConfiguration.ps1"))
{
    Write-Host "Using hub site configuration from: $($AlyaData)\sharepoint\HubSitesConfiguration.ps1"
    . $AlyaData\sharepoint\HubSitesConfiguration.ps1
}
else
{
    Write-Host "Using hub site configuration from: $($PSScriptRoot)\HubSitesConfigurationTemplate.ps1"
    . $PSScriptRoot\HubSitesConfigurationTemplate.ps1
}

# =============================================================
# O365 stuff
# =============================================================

Write-Host "`n`n=====================================================" -ForegroundColor $CommandInfo
Write-Host "SharePoint | Configure-HubSites | O365" -ForegroundColor $CommandInfo
Write-Host "=====================================================`n" -ForegroundColor $CommandInfo

foreach($hubSite in $hubSites)
{
    ###Processing designs
    Write-Host "Processing designs for Hub Site $($hubSite.title)" -ForegroundColor $TitleColor

    $SiteScriptName = "$($AlyaCompanyName) $($hubSite.short) SiteScript"
    $SiteDesignNameTeam = "$($AlyaCompanyName) $($hubSite.short) Team Site"
    $SiteDesignNameComm = "$($AlyaCompanyName) $($hubSite.short) Communication Site"

    # Getting theme
    Write-Host "Getting theme" -ForegroundColor $CommandInfo
    try { $Theme = Get-SPOTheme -Name $themeName -ErrorAction SilentlyContinue } catch {}
    if (-Not $Theme)
    {
        throw "Theme does not exist. Please create it first"
    }

    # Checking site script
    Write-Host "Checking site script" -ForegroundColor $CommandInfo
    $SiteScript = Get-SPOSiteScript | where { $_.Title -eq "$SiteScriptName"}
    if (-Not $SiteScript)
    {
        Write-Warning "Site script not found. Creating now site script $SiteScriptName"
        $SiteScript = Add-SPOSiteScript -Title $SiteScriptName -Content $hubSite.siteScript -Description $hubSite.siteScriptDescription
    }
    else
    {
        Write-Host "Updating site script $SiteScriptName"
        $tmp = Set-SPOSiteScript -Identity $SiteScript -Title $SiteScriptName -Content $hubSite.siteScript -Description $hubSite.siteScriptDescription
        $SiteScript = Get-SPOSiteScript | where { $_.Title -eq "$SiteScriptName"}
    }

    # Checking site design
    Write-Host "Checking team site design" -ForegroundColor $CommandInfo
    $SiteDesignTeam = Get-SPOSiteDesign | where { $_.Title -eq "$SiteDesignNameTeam"}
    if (-Not $SiteDesignTeam)
    {
        Write-Warning "Team site design not found. Creating now team site design $SiteDesignNameTeam"
        $SiteDesignTeam = Add-SPOSiteDesign -Title $SiteDesignNameTeam -WebTemplate "64" -SiteScripts $SiteScript.Id -Description $hubSite.siteScriptDescription
    }
    else
    {
        Write-Host "Updating Team site design $SiteDesignNameTeam"
        $tmp = Set-SPOSiteDesign -Identity $SiteDesignTeam -Title $SiteDesignNameTeam -WebTemplate "64" -SiteScripts $SiteScript.Id -Description $hubSite.siteScriptDescription
        $SiteDesignTeam = Get-SPOSiteDesign | where { $_.Title -eq "$SiteDesignNameTeam"}
    }

    # Checking site design
    Write-Host "Checking communication site design" -ForegroundColor $CommandInfo
    $SiteDesignComm = Get-SPOSiteDesign | where { $_.Title -eq "$SiteDesignNameComm"}
    if (-Not $SiteDesignComm)
    {
        Write-Warning "Communication site design not found. Creating now Communication site design $SiteDesignNameComm"
        $SiteDesignComm = Add-SPOSiteDesign -Title $SiteDesignNameComm -WebTemplate "68" -SiteScripts $SiteScript.Id -Description $hubSite.siteScriptDescription
    }
    else
    {
        Write-Host "Updating Communication site design $SiteDesignNameComm"
        $tmp = Set-SPOSiteDesign -Identity $SiteDesignComm -Title $SiteDesignNameComm -WebTemplate "68" -SiteScripts $SiteScript.Id -Description $hubSite.siteScriptDescription
        $SiteDesignComm = Get-SPOSiteDesign | where { $_.Title -eq "$SiteDesignNameComm"}
    }

    # Checking site script for sub sites
    if ($hubSite.subSiteScript)
    {
        $SubSiteScriptName = "$($AlyaCompanyName) $($hubSite.short) Sub SiteScript"
        $SubSiteDesignNameTeam = "$($AlyaCompanyName) $($hubSite.short) Sub Team Site"
        $SubSiteDesignNameComm = "$($AlyaCompanyName) $($hubSite.short) Sub Communication Site"

        # Checking site script
        Write-Host "Checking site script" -ForegroundColor $CommandInfo
        $SubSiteScript = Get-SPOSiteScript | where { $_.Title -eq "$SubSiteScriptName"}
        if (-Not $SubSiteScript)
        {
            Write-Warning "Site script not found. Creating now site script $SubSiteScriptName"
            $SubSiteScript = Add-SPOSiteScript -Title $SubSiteScriptName -Content $hubSite.subSiteScript -Description $hubSite.siteScriptDescription
        }
        else
        {
            Write-Host "Updating site script $SubSiteScriptName"
            $tmp = Set-SPOSiteScript -Identity $SubSiteScript -Title $SubSiteScriptName -Content $hubSite.subSiteScript -Description $hubSite.siteScriptDescription
            $SubSiteScript = Get-SPOSiteScript | where { $_.Title -eq "$SubSiteScriptName"}
        }

        # Checking site design
        Write-Host "Checking team site design" -ForegroundColor $CommandInfo
        $SubSiteDesignTeam = Get-SPOSiteDesign | where { $_.Title -eq "$SubSiteDesignNameTeam"}
        if (-Not $SubSiteDesignTeam)
        {
            Write-Warning "Team site design not found. Creating now team site design $SubSiteDesignNameTeam"
            $SubSiteDesignTeam = Add-SPOSiteDesign -Title $SubSiteDesignNameTeam -WebTemplate "64" -SiteScripts $SubSiteScript.Id -Description $hubSite.siteScriptDescription
        }
        else
        {
            Write-Host "Updating Team site design $SubSiteDesignNameTeam"
            $tmp = Set-SPOSiteDesign -Identity $SubSiteDesignTeam -Title $SubSiteDesignNameTeam -WebTemplate "64" -SiteScripts $SubSiteScript.Id -Description $hubSite.siteScriptDescription
            $SubSiteDesignTeam = Get-SPOSiteDesign | where { $_.Title -eq "$SubSiteDesignNameTeam"}
        }

        # Checking site design
        Write-Host "Checking communication site design" -ForegroundColor $CommandInfo
        $SubSiteDesignComm = Get-SPOSiteDesign | where { $_.Title -eq "$SubSiteDesignNameComm"}
        if (-Not $SubSiteDesignComm)
        {
            Write-Warning "Communication site design not found. Creating now Communication site design $SubSiteDesignNameComm"
            $SubSiteDesignComm = Add-SPOSiteDesign -Title $SubSiteDesignNameComm -WebTemplate "68" -SiteScripts $SubSiteScript.Id -Description $hubSite.siteScriptDescription
        }
        else
        {
            Write-Host "Updating Communication site design $SubSiteDesignNameComm"
            $tmp = Set-SPOSiteDesign -Identity $SubSiteDesignComm -Title $SubSiteDesignNameComm -WebTemplate "68" -SiteScripts $SubSiteScript.Id -Description $hubSite.siteScriptDescription
            $SubSiteDesignComm = Get-SPOSiteDesign | where { $_.Title -eq "$SubSiteDesignNameComm"}
        }
    }

    ###Processing site
    Write-Host "Processing site for Hub Site $($hubSite.title)" -ForegroundColor $TitleColor

    $site = $null
    try { $site = Get-SPOSite -Identity "$($AlyaSharePointUrl)/sites/$($hubSite.url)" -Detailed -ErrorAction SilentlyContinue } catch {}
    if (-Not $site)
    {
        Write-Warning "Hub site not found. Creating now hub site $($hubSite.title)"
        LoginTo-PnP -Url $AlyaSharePointAdminUrl
        $site = New-PnPSite -Type $hubSite.template -Title $hubSite.title -Alias $hubSite.url -Description $hubSite.description
        do {
            Start-Sleep -Seconds 15
            $site = Get-SPOSite -Identity "$($AlyaSharePointUrl)/sites/$($hubSite.url)" -Detailed
        } while (-Not $site)
    }
    else
    {
        #Write-Host "Updating hub site $($hubSite.title)"
        #$tmp = Set-SPOSite -Identity $site -Owner $AlyaSharePointNewSiteOwner
    }
    if (-Not $site.IsHubSite)
    {
        Write-Host "Registering site as hub site"
        $siteReg = Register-SPOHubSite -Site "$($AlyaSharePointUrl)/sites/$($hubSite.url)" -Principals $null
        #TODO Principals
    }

    if ($hubSite.template -eq "TeamSite")
    {
        Invoke-SPOSiteDesign -Identity $SiteDesignTeam.Id -WebUrl "$($AlyaSharePointUrl)/sites/$($hubSite.url)"
    }
    if ($hubSite.template -eq "Communication")
    {
        Invoke-SPOSiteDesign -Identity $SiteDesignComm.Id -WebUrl "$($AlyaSharePointUrl)/sites/$($hubSite.url)"
    }

    LoginTo-PnP -Url "$($AlyaSharePointUrl)/sites/$($hubSite.url)"
    $web = Get-PnPWeb -Includes HeaderEmphasis,HeaderLayout,SiteLogoUrl,QuickLaunchEnabled
    $web.HeaderLayout = $hubSite.headerLayout
    $web.HeaderEmphasis = $hubSite.headerEmphasis
    $web.QuickLaunchEnabled = $false
    $web.Update()
    Invoke-PnPQuery
    if ([string]::IsNullOrEmpty($web.SiteLogoUrl))
    {
        Set-PnpWeb -Web $web -SiteLogoUrl $hubSite.siteLogoUrl
    }

}

###Processing navigation
Write-Host "Processing navigation" -ForegroundColor $TitleColor
foreach($hubSite in $hubSites)
{
    if ($hubSite.short -ne "COL")
    {
        Write-Host "Hub Site $($hubSite.title)"
        ReloginTo-PnP -Url "$($AlyaSharePointUrl)/sites/$($hubSite.url)"
        $site = Get-PnPSite
        $topNavs = Get-PnPNavigationNode -Location TopNavigationBar
        foreach($hubSiteI in $hubSites)
        {
            if ($hubSiteI.url -ne $hubSite.url)
            {
                $nav = $topNavs | where {$_.Title -eq $hubSiteI.title}
                if (-Not $nav)
                {
                    Write-Host ("Adding nav node title={0} url={1}" -f $hubSiteI.title, $hubSiteI.url)
                    $tmp = Add-PnPNavigationNode -Location TopNavigationBar -Title $hubSiteI.title -Url "$($AlyaSharePointUrl)/sites/$($hubSiteI.url)"
                }
            }
        }
    }
}

###Processing designs
Write-Host "Processing site designs of connected sites" -ForegroundColor $TitleColor
foreach($hubSite in $hubSites)
{
    if ($hubSite.subSiteScript)
    {
        Write-Host "Hub Site $($hubSite.title)"
        $SubSiteDesignNameTeam = "$($AlyaCompanyName) $($hubSite.short) Sub Team Site"
        $SubSiteDesignNameComm = "$($AlyaCompanyName) $($hubSite.short) Sub Communication Site"
        $SubSiteDesignTeam = Get-SPOSiteDesign | where { $_.Title -eq "$SubSiteDesignNameTeam"}
        $SubSiteDesignComm = Get-SPOSiteDesign | where { $_.Title -eq "$SubSiteDesignNameComm"}

        ReloginTo-PnP -Url "$($AlyaSharePointUrl)/sites/$($hubSite.url)"
        $site = Get-PnPSite
        $hubSiteObj = Get-PnPHubSite -Identity $site
        $childs = Get-PnPHubSiteChild -Identity $hubSiteObj
        foreach($child in $childs)
        {
            try
            {
                ReloginTo-PnP -Url $child
                $site = Get-PnPWeb -Includes WebTemplate, Configuration
                $template = $site.WebTemplate + "#" + $site.Configuration
                if ($template -eq "GROUP#0")
                {
                    Invoke-SPOSiteDesign -Identity $SubSiteDesignTeam.Id -WebUrl $child
                }
                if ($template -eq "SITEPAGEPUBLISHING#0")
                {
                    Invoke-SPOSiteDesign -Identity $SubSiteDesignComm.Id -WebUrl $child
                }
            } catch
            {
                Write-Error $_
            }
        }
    }
}

###SharePoint Home Featured Links
Write-Host "Processing SharePoint Home Featured Links" -ForegroundColor $TitleColor
ReloginTo-PnP -Url "$($AlyaSharePointUrl)"
$list = Get-PnPList -Identity "SharePointHomeOrgLinks"
$items = Get-PnPListItem -List $list -Fields "Title","Url"
foreach($hubSite in $hubSites)
{
    $fnd = $false
    foreach($item in $items)
    {
        if ($item["Title"] -eq $hubSite.title)
        {
            $fnd = $true
            break
        }
    }
    if (-Not $fnd)
    {
        Write-Host "Adding $($hubSite.title)"
        Add-PnPListItem -List $list -Values @{"Title"=$hubSite.title; "Url"="$($AlyaSharePointUrl)/sites/$($hubSite.url)"; "MobileAppVisible"=$true; "Priority"=1000 }
    }
    else
    {
        Write-Host "Already there $($hubSite.title)"
    }
}

###SharePoint Start Pages
Write-Host "Processing SharePoint Start Pages" -ForegroundColor $TitleColor
#TODO
#TODO Get-PnPClientSidePage -Identity " NewPage"

#Stopping Transscript
Stop-Transcript