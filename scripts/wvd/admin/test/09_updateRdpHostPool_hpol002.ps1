#Requires -Version 2.0
#Requires -RunAsAdministrator

<#
    Copyright (c) Alya Consulting: 2020

    This unpublished material is proprietary to Alya Consulting.
    All rights reserved. The methods and techniques described
    herein are considered trade secrets and/or confidential. 
    Reproduction or distribution, in whole or in part, is 
    forbidden except by express written permission of Alya Consulting.

    History:
    Date       Author               Description
    ---------- -------------------- ----------------------------
    12.03.2020 Konrad Brunner       Initial Version

#>

[CmdletBinding()]
Param(
)

Write-Error "Update does not work yet. Please remove and recreate the hostpool"
exit

#Reading configuration
. $PSScriptRoot\..\..\..\..\01_ConfigureEnv.ps1

#Starting Transscript
Start-Transcript -Path "$($AlyaLogs)\scripts\wvd\admin\test\09_updateRdpHostPool_hpol002-$($AlyaTimeString).log" | Out-Null

# Constants
$ErrorActionPreference = "Stop"
$HostPoolName = "$($AlyaNamingPrefixTest)hpol002"
$ResourceGroupName = "$($AlyaNamingPrefixTest)resg052"
$NamePrefix = "$($AlyaNamingPrefixTest)vd52"
$ImageSourceName = "alyainfpvimg001"
$ImageSourceResourceGroupName = "lmagtinfresg050"
$NumberOfInstances = 3
$VmSize = "Standard_D2s_v3"
$EnableAcceleratedNetworking = $false
$AdminDomainUPN = "adm_alya_kobr@alyaconsulting.ch"
$WvdHostName = "$($NamePrefix)-"
$DiagnosticStorageAccountName = "alyainfpstrg003"
$OuPath = "OU=TEST,OU=WVD,OU=COMPUTERS,OU=CLOUD,DC=ALYACONSULTING,DC=LOCAL"
$ExistingVnetName = "lmagtinfvnet000"
$ExistingSubnetName = "lmagtinfvnet000snet01"
$virtualNetworkResourceGroupName = "lmagtinfresg000"
$ShareServer = $env:COMPUTERNAME.ToLower()
$KeyVaultName = "$($AlyaNamingPrefix)keyv$($AlyaResIdMainKeyVault)"

# Checking modules
Write-Host "Checking modules" -ForegroundColor $CommandInfo
Install-ModuleIfNotInstalled "Az"
Install-ModuleIfNotInstalled "Microsoft.RDInfra.RDPowershell"

# Logins
LoginTo-Az -SubscriptionName $AlyaSubscriptionName

# Domain credentials
Write-Host "Domain credentials" -ForegroundColor $CommandInfo
if (-Not $Global:AdminDomainCred)
{
    Write-Host "  Account requireements: domain admin" -ForegroundColor Red
    $Global:AdminDomainCred = Get-Credential -UserName $AdminDomainUPN -Message "Please specify admins domain password" -ErrorAction Stop
}

# =============================================================
# Azure stuff
# =============================================================

Write-Host "`n`n=====================================================" -ForegroundColor $CommandInfo
Write-Host "WVD | 09_updateRdpHostPool_hpol002 | AZURE" -ForegroundColor $CommandInfo
Write-Host "=====================================================`n" -ForegroundColor $CommandInfo

# Getting context
$Context = Get-AzContext
if (-Not $Context)
{
    Write-Error -Message "Can't get Az context! Not logged in?"
    Exit 1
}

# Checking application
Write-Host "Checking application" -ForegroundColor $CommandInfo
$AzureAdApplication = Get-AzADApplication -DisplayName $AlyaWvdServicePrincipalNameTest -ErrorAction SilentlyContinue
if (-Not $AzureAdApplication)
{
    throw "Azure AD Application not found. Please create the Azure AD Application $AlyaWvdServicePrincipalNameTest"
}
$AzureAdServicePrincipal = Get-AzADServicePrincipal -DisplayName $AlyaWvdServicePrincipalNameTest

# Checking azure key vault secret
Write-Host "Checking azure key vault secret" -ForegroundColor $CommandInfo
$AlyaWvdServicePrincipalAssetName = "$($AlyaWvdServicePrincipalNameTest)Key"
$AzureKeyVaultSecret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $AlyaWvdServicePrincipalAssetName -ErrorAction SilentlyContinue
if (-Not $AzureKeyVaultSecret)
{
    throw "Key Vault secret not found. Please create the secret $AlyaWvdServicePrincipalAssetName"
}
$AlyaWvdServicePrincipalPassword = $AzureKeyVaultSecret.SecretValueText
$AlyaWvdServicePrincipalPasswordSave = ConvertTo-SecureString $AlyaWvdServicePrincipalPassword -AsPlainText -Force

# Login to WVD
if (-Not $Global:RdsContext)
{
	Write-Host "Logging in to wvd" -ForegroundColor $CommandInfo
	$rdsCreds = New-Object System.Management.Automation.PSCredential($AzureAdServicePrincipal.ApplicationId, $AlyaWvdServicePrincipalPasswordSave)
	$Global:RdsContext = Add-RdsAccount -DeploymentUrl $AlyaWvdRDBroker -Credential $rdsCreds -ServicePrincipal -AadTenantId $AlyaTenantId
	#LoginTo-Wvd -AppId $AzureAdServicePrincipal.ApplicationId -SecPwd $AlyaWvdServicePrincipalPasswordSave
}

# Getting members
Write-Host "Getting members" -ForegroundColor $CommandInfo
$RootDir = "$AlyaRoot\scripts\wvd\admin\test"
$subscription = Get-AzSubscription -SubscriptionName $AlyaSubscriptionName
$ApplicationCred = New-Object System.Management.Automation.PSCredential($AzureAdServicePrincipal.ApplicationId, $AlyaWvdServicePrincipalPasswordSave)

# Preparing parameters
Write-Host "Configuring deployment parameters" -ForegroundColor $CommandInfo
$TemplateFilePath = "$($RootDir)\template\templateUpdate.json"
$ParametersFilePath = "$($RootDir)\template\parametersUpdate.json"
$params = Get-Content -Path $ParametersFilePath -Raw -Encoding UTF8 | ConvertFrom-Json
$ParametersObject = @{}
$params.parameters.psobject.properties | Foreach { $ParametersObject[$_.Name] = $_.Value.value }
$ParametersObject["rdshCustomImageSourceName"] = $ImageSourceName
$ParametersObject["rdshCustomImageSourceResourceGroup"] = $ImageSourceResourceGroupName
$ParametersObject["enableAcceleratedNetworking"] = $EnableAcceleratedNetworking
$ParametersObject["domainToJoin"] = $AlyaLocalDomainName
$ParametersObject["ouPath"] = $OuPath
$ParametersObject["existingVnetName"] = $ExistingVnetName
$ParametersObject["existingSubnetName"] = $ExistingSubnetName
$ParametersObject["virtualNetworkResourceGroupName"] = $virtualNetworkResourceGroupName
$ParametersObject["rdBrokerURL"] = $AlyaWvdRDBroker
$ParametersObject["existingTenantGroupName"] = $AlyaWvdTenantGroupName
$ParametersObject["aadTenantId"] = $AlyaTenantId
$ParametersObject["rdshNumberOfInstances"] = $NumberOfInstances
$ParametersObject["rdshVmSize"] = $VmSize
$ParametersObject["existingDomainUPN"] = $AdminDomainUPN
$ParametersObject["hostPoolName"] = $HostPoolName
$ParametersObject["defaultDesktopUsers"] = ($AlyaWvdAdmins -join ",")
$ParametersObject["tenantAdminUpnOrApplicationId"] = $AzureAdServicePrincipal.ApplicationId.Guid.ToString()
$ParametersObject["location"] = $AlyaLocation
$ParametersObject["rdshNamePrefix"] = $NamePrefix
$ParametersObject["existingTenantName"] = $AlyaWvdTenantNameTest
$ParametersObject["existingDomainPassword"] = $Global:AdminDomainCred.Password
$ParametersObject["tenantAdminPassword"] = $ApplicationCred.Password

# Deploying hostpool
Write-Host "Deploying hostpool" -ForegroundColor $CommandInfo
& "$($RootDir)\template\deploy.ps1" `
    -Subscription $Subscription `
    -ResourceGroupName $ResourceGroupName `
    -ResourceGroupLocation $AlyaLocation `
    -TemplateFilePath $TemplateFilePath `
    -ParametersObject $ParametersObject `
    -ErrorAction Stop
#Deployment error? Get-AzLog -CorrelationId 4711348d-5b11-408e-929b-cbf541b4302e -DetailedOutput



# Checking share for hostpool
Write-Host "Checking share for hostpool" -ForegroundColor $CommandInfo
$hostpoolShareDir = "E:\sharesWvd\$($HostPoolName)"
$hostpoolShareName = "$($HostPoolName)$"
$hostpoolSharePath = "\\$($ShareServer)\$hostpoolShareName"
if (-Not (Test-Path $hostpoolSharePath))
{
    Write-Warning -Message "Share does not exist. Creating share $($hostpoolSharePath)"
    if ($ShareServer -ne $env:COMPUTERNAME.ToLower())
    {
        Write-Host "Please login to $ShareServer and run there the script" -ForegroundColor $QuestionColor
        Write-Host ".\05_prepareShare.ps1 -hostpoolShareDir $hostpoolShareDir -hostpoolShareName $hostpoolShareName" -ForegroundColor $QuestionColor
        pause
    }
    else
    {
        & "$($RootDir)\05_prepareShare.ps1" -hostpoolShareDir $hostpoolShareDir -hostpoolShareName $hostpoolShareName
    }
}

Write-Host "Configuring hostpool" -ForegroundColor $CommandInfo
LoginTo-Az -SubscriptionName $AlyaSubscriptionName
for ($hi=0; $hi -lt $NumberOfInstances; $hi++)
{
    #$hi=0
    $actHostName = "$($WvdHostName)$($hi)"
    Write-Host "  $($actHostName)" -ForegroundColor $CommandInfo
    Write-Host "    Copying files"
    if (-Not (Test-Path "\\$($actHostName)\C$\$($AlyaCompanyName)"))
    {
        $tmp = New-Item -Path "\\$($actHostName)\C$" -Name $AlyaCompanyName -ItemType Directory
    }
    robocopy /mir "$($RootDir)\..\..\WvdIcons" "\\$($actHostName)\C$\$($AlyaCompanyName)\WvdIcons"
    robocopy /mir "$($RootDir)\..\..\WvdStartApps\$($AlyaCompanyName)" "\\$($actHostName)\C$\ProgramData\Microsoft\Windows\Start Menu\Programs\$($AlyaCompanyName)"
    #TODO $tmp = Copy-Item "$($RootDir)\..\..\..\..\o365\defenderatp\WindowsDefenderATPLocalOnboardingScript.cmd" "\\$($actHostName)\C$\$($AlyaCompanyName)\WindowsDefenderATPLocalOnboardingScript.cmd" -Force
    $tmp = Copy-Item "$($RootDir)\..\..\WvdTheme\$($AlyaCompanyName)Test.theme" "\\$($actHostName)\C$\Windows\resources\Themes\$($AlyaCompanyName).theme" -Force

    Write-Host "    Adding diagnostics"
    $diagConfig = Get-Content -Path "$($RootDir)\diagnosticConfig.xml" -Encoding UTF8 -Raw
    $vmResourceId = "/subscriptions/$($subscription)/resourceGroups/$($ResourceGroupName)/providers/Microsoft.Compute/virtualMachines/$($actHostName)"
    $diagConfig = $diagConfig.Replace("##VMRESOURCEID##", $vmResourceId).Replace("##DIAGSTORAGEACCOUNTNAME##", $DiagnosticStorageAccountName)
    $tmpFile = New-TemporaryFile
    $diagConfig | Set-Content -Path $tmpFile.FullName -Encoding UTF8 -Force
    Set-AzVMDiagnosticsExtension -ResourceGroupName $ResourceGroupName -VMName $actHostName -DiagnosticsConfigurationPath $tmpFile.FullName
    Remove-Item -Path $tmpFile.FullName -Force

    Write-Host "    Anti malware"
    #TODO braucht es den?

    Write-Host "    Remote session"
    $session = New-PSSession -ComputerName $actHostName
    Invoke-Command -Session $session {
        $HostPoolName = $args[0]
        $AdminDomainUPN = $args[1]
        $AlyaTenantId = $args[2]
        $AlyaTimeZone = $args[3]
        $AlyaGeoId = $args[4]
        Set-Timezone -Id $AlyaTimeZone
        Set-WinHomeLocation -GeoId $AlyaGeoId
        $fslogixAppsRegPath = "HKLM:\SOFTWARE\FSLogix\Apps"
        $fslogixProfileRegPath = "HKLM:\SOFTWARE\FSLogix\Profiles"
        $fslogixContainerRegPath = "HKLM:\SOFTWARE\Policies\FSLogix\ODFC"
        if (!(Test-Path $fslogixAppsRegPath))
        {
            New-Item -Path $fslogixAppsRegPath -Force
        }
        #New-ItemProperty -Path $fslogixAppsRegPath -Name "RoamSearch" -Value "2" -PropertyType DWORD -Force
        if (!(Test-Path $fslogixProfileRegPath))
        {
            New-Item -Path $fslogixProfileRegPath -Force
        }
        New-ItemProperty -Path $fslogixProfileRegPath -Name "Enabled" -Value "1" -PropertyType DWORD -Force
        New-ItemProperty -Path $fslogixProfileRegPath -Name "VHDLocations" -Value "\\$($ShareServer)\$($HostPoolName)$\Profiles" -PropertyType MultiString -Force
        #New-ItemProperty -Path $fslogixProfileRegPath -Name "DeleteLocalProfileWhenVHDShouldApply" -Value "1" -PropertyType DWORD -Force
        #New-ItemProperty -Path $fslogixProfileRegPath -Name "PreventLoginWithFailure" -Value "1" -PropertyType DWORD -Force
        #New-ItemProperty -Path $fslogixProfileRegPath -Name "PreventLoginWithTempProfile" -Value "1" -PropertyType DWORD -Force
        #New-ItemProperty -Path $fslogixProfileRegPath -Name "SizeInMBs" -Value "51200" -PropertyType DWORD -Force
        if (!(Test-Path $fslogixContainerRegPath))
        {
            New-Item -Path $fslogixContainerRegPath -Force
        }
        New-ItemProperty -Path $fslogixContainerRegPath -Name "Enabled" -Value "1" -PropertyType DWORD -Force
        New-ItemProperty -Path $fslogixContainerRegPath -Name "VHDLocations" -Value "\\$($ShareServer)\$($HostPoolName)$\Containers" -PropertyType MultiString -Force
        #New-ItemProperty -Path $fslogixContainerRegPath -Name "DeleteLocalProfileWhenVHDShouldApply" -Value "1" -PropertyType DWORD -Force
        #New-ItemProperty -Path $fslogixContainerRegPath -Name "PreventLoginWithFailure" -Value "1" -PropertyType DWORD -Force
        #New-ItemProperty -Path $fslogixContainerRegPath -Name "PreventLoginWithTempProfile" -Value "1" -PropertyType DWORD -Force
        #New-ItemProperty -Path $fslogixContainerRegPath -Name "IncludeOneDrive" -Value "1" -PropertyType DWORD -Force
        #New-ItemProperty -Path $fslogixContainerRegPath -Name "IncludeOneNote" -Value "1" -PropertyType DWORD -Force
        #New-ItemProperty -Path $fslogixContainerRegPath -Name "IncludeOneNote_UWP" -Value "1" -PropertyType DWORD -Force
        #New-ItemProperty -Path $fslogixContainerRegPath -Name "IncludeOutlook" -Value "1" -PropertyType DWORD -Force
        #New-ItemProperty -Path $fslogixContainerRegPath -Name "IncludeOutlookPersonalization" -Value "1" -PropertyType DWORD -Force
        #New-ItemProperty -Path $fslogixContainerRegPath -Name "IncludeSharepoint" -Value "1" -PropertyType DWORD -Force
        #New-ItemProperty -Path $fslogixContainerRegPath -Name "IncludeSkype" -Value "1" -PropertyType DWORD -Force
        #New-ItemProperty -Path $fslogixContainerRegPath -Name "IncludeTeams" -Value "1" -PropertyType DWORD -Force
        #New-ItemProperty -Path $fslogixContainerRegPath -Name "RoamSearch" -Value "2" -PropertyType DWORD -Force
        #$OneDriveHKLMregistryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'
        #$OneDriveDiskSizeregistryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive\DiskSpaceCheckThresholdMB'
        #if (!(Test-Path $OneDriveHKLMregistryPath))
        #{
        #    New-Item -Path $OneDriveHKLMregistryPath -Force
        #}
        #if (!(Test-Path $OneDriveDiskSizeregistryPath))
        #{
        #    New-Item -Path $OneDriveDiskSizeregistryPath -Force
        #}
        #New-ItemProperty -Path $OneDriveHKLMregistryPath -Name 'SilentAccountConfig' -Value "1" -PropertyType DWORD -Force
        #New-ItemProperty -Path $OneDriveDiskSizeregistryPath -Name $AlyaTenantId -Value "51200" -PropertyType DWORD -Force
        <# TODO
        $themeRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes"
        $themePersonalizeRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        $themeDWMRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\DWM"
        if (!(Test-Path $themeRegPath))
        {
            New-Item -Path $themeRegPath -Force
        }
        if (!(Test-Path $themePersonalizeRegPath))
        {
            New-Item -Path $themePersonalizeRegPath -Force
        }
        if (!(Test-Path $themeDWMRegPath))
        {
            New-Item -Path $themeDWMRegPath -Force
        }
        New-ItemProperty -Path $themeRegPath -Name "InstallTheme" -Value "C:\Windows\resources\Themes\$($AlyaCompanyName).theme" -PropertyType String -Force
        New-ItemProperty -Path $themePersonalizeRegPath -Name "EnableTransparency" -Value "1" -PropertyType DWORD -Force
        New-ItemProperty -Path $themePersonalizeRegPath -Name "AppsUseLightTheme" -Value "1" -PropertyType DWORD -Force
        New-ItemProperty -Path $themePersonalizeRegPath -Name "ColorPrevalence" -Value "1" -PropertyType DWORD -Force
        New-ItemProperty -Path $themeDWMRegPath -Name "ColorPrevalence" -Value "1" -PropertyType DWORD -Force
		#>
        #Get-Service -Name "WSearch" | Set-Service -StartupType Automatic
        Add-LocalGroupMember -Group "FSLogix ODFC Exclude List" -Member $AdminDomainUPN
        Add-LocalGroupMember -Group "FSLogix Profile Exclude List" -Member $AdminDomainUPN
        # TODO C:\$($AlyaCompanyName)\WindowsDefenderATPLocalOnboardingScript.cmd
    } -Args $HostPoolName, $AdminDomainUPN, $AlyaTenantId, $AlyaTimeZone, $AlyaGeoId
    Remove-PSSession -Session $session
}

Write-Host "Restarting session hosts" -ForegroundColor $CommandInfo
for ($hi=0; $hi -lt $NumberOfInstances; $hi++)
{
    $actHostName = "$($WvdHostName)$($hi)"
    Write-Host "  $($actHostName)"
    Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $actHostName -Force
    Start-AzVM -ResourceGroupName $ResourceGroupName -Name $actHostName
}

Start-Sleep -Seconds 120

Write-Host "Configuring hostpool" -ForegroundColor $CommandInfo
for ($hi=0; $hi -lt $NumberOfInstances; $hi++)
{
    $actHostName = "$($WvdHostName)$($hi)"
    Write-Host "  $($actHostName)" -ForegroundColor $CommandInfo
    Write-Host "    Remote session"
    $session = New-PSSession -ComputerName $actHostName
    Invoke-Command -Session $session {
        #Set-MpPreference -ExclusionPath "\\$($ShareServer)\*\*\*\*.vhd", "C:\Program Files\FSLogix\Apps"
        #Set-MpPreference -ExclusionExtension "vhd"
        #Set-MpPreference -DisableArchiveScanning $false
        #Set-MpPreference -DisableAutoExclusions $false
        #Set-MpPreference -DisableBehaviorMonitoring $false
        #Set-MpPreference -DisableBlockAtFirstSeen $false
        #Set-MpPreference -DisableCatchupFullScan $true
        #Set-MpPreference -DisableCatchupQuickScan $false
        #Set-MpPreference -DisableEmailScanning $false
        #Set-MpPreference -DisableIOAVProtection $false
        #Set-MpPreference -DisablePrivacyMode $false
        #Set-MpPreference -DisableRealtimeMonitoring $false
        #Set-MpPreference -DisableRemovableDriveScanning $true
        #Set-MpPreference -DisableRestorePoint $true
        #Set-MpPreference -DisableScanningMappedNetworkDrivesForFullScan $true
        #Set-MpPreference -DisableScanningNetworkFiles $false
        #Set-MpPreference -DisableScriptScanning $false
    } -Args $HostPoolName
    Remove-PSSession -Session $session
}

Write-Host "Setting hostpool to validation (test)" -ForegroundColor $CommandInfo
#TODO Comment for prod env
Set-RdsHostPool -TenantName $AlyaWvdTenantNameTest -Name $HostPoolName -ValidationEnv $true

Write-Host "Setting hostpool to depth first" -ForegroundColor $CommandInfo
Set-RdsHostPool -TenantName $AlyaWvdTenantNameTest -Name $HostPoolName -DepthFirstLoadBalancer -MaxSessionLimit 6

Write-Host "Setting tags on resource group" -ForegroundColor $CommandInfo
$resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if($resourceGroup)
{
    $tags = @{}
    $tags += @{displayName="WVD $($HostPoolName)"}
    $tags += @{ownerEmail=$Context.Account.Id}
    Set-AzResource -ResourceId $resourceGroup.ResourceId -Tag $tags -Force
}

Write-Host "Setting tags on vms" -ForegroundColor $CommandInfo
for ($hi=0; $hi -lt $NumberOfInstances; $hi++)
{
    $actHostName = "$($WvdHostName)$($hi)"
    Write-Host "  $($actHostName)"
    $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $actHostName
    $tags = @{}
    #TODO enable for prod if ($hi -eq 0) { $tags += @{startTime=$AlyaWvdStartTime} }
    $tags += @{stopTime=$AlyaWvdStopTime}
    $tmp = Set-AzResource -ResourceId $vm.Id -Tag $tags -Force
}

#Stopping Transscript
Stop-Transcript