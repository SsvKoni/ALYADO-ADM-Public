﻿#Requires -Version 2.0

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
    02.04.2020 Konrad Brunner       Initial Version

#>

#Reading configuration
. $PSScriptRoot\..\..\..\..\01_ConfigureEnv.ps1

#Starting Transscript
Start-Transcript -Path "$($AlyaLogs)\scripts\wvd\admin\test\41_getDiagnostics-$($AlyaTimeString).log" | Out-Null

# Constants
$ErrorActionPreference = "Stop"
$KeyVaultName = "$($AlyaNamingPrefix)keyv$($AlyaResIdMainKeyVault)"

# Checking modules
Write-Host "Checking modules" -ForegroundColor $CommandInfo
Install-ModuleIfNotInstalled "Az"
Install-ModuleIfNotInstalled "Microsoft.RDInfra.RDPowershell"

# Logins
LoginTo-Az -SubscriptionName $AlyaSubscriptionName

# =============================================================
# WVD stuff
# =============================================================

Write-Host "`n`n=====================================================" -ForegroundColor $CommandInfo
Write-Host "WVD | 41_getDiagnostics | WVD" -ForegroundColor $CommandInfo
Write-Host "=====================================================`n" -ForegroundColor $CommandInfo

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

#Main
$reportStartTime = Get-Date | Get-Date -Hour 0 -Minute 0 -Second 0 

Write-Host "Getting diagnostics" -ForegroundColor $CommandInfo
$acts = Get-RdsDiagnosticActivities -TenantName $AlyaWvdTenantNameTest -Detailed -StartTime $reportStartTime -ErrorAction SilentlyContinue # | where {$_.UserName -like "*$($AlyaDomainName)"}

Write-Host ""
Write-Host "Activities:" -ForegroundColor $CommandInfo
$acts | select ActivityType, Status, StartTime, UserName | Out-String | % {Write-Host $_}

Write-Host "Disconnects:" -ForegroundColor $CommandInfo
$acts = $acts | where {$_.CheckPoints.Name -eq "OnClientDisconnected"}
if (-Not $acts)
{
    Write-Host "No disconnects found`n"
}
else
{
    $errors = @()
    foreach($act in $acts)
    {
        foreach($err in $act.CheckPoints | where {$_.Name -eq "OnClientDisconnected"})
        {
            $obj = New-Object -TypeName psobject
            $obj | Add-Member -MemberType NoteProperty -Name UserName -Value $act.UserName
            $obj | Add-Member -MemberType NoteProperty -Name Time -Value $err.Time
            $obj | Add-Member -MemberType NoteProperty -Name Code -Value $err.Parameters.DisconnectCode
            $initiatedBy = ""
            if ($err.Parameters.IsProxyServerInitiated -eq 1) {$initiatedBy = "ProxyServer"}
            if ($err.Parameters.IsServerStackInitiated -eq 1) {$initiatedBy = "ServerStack"}
            if ($err.Parameters.IsUserInitiated -eq 1) {$initiatedBy = "User"}
            $obj | Add-Member -MemberType NoteProperty -Name InitiatedBy -Value $initiatedBy
            $obj | Add-Member -MemberType NoteProperty -Name DisconnectCodeSymbolic -Value $err.Parameters.DisconnectCodeSymbolic
            $errors += $obj
        }
    }
    $errors | ft | Out-String | % {Write-Host $_}
}

Write-Host "Errors:" -ForegroundColor $CommandInfo
$acts = Get-RdsDiagnosticActivities -TenantName $AlyaWvdTenantNameTest -Detailed -StartTime $reportStartTime -Outcome Failure -ErrorAction SilentlyContinue
if (-Not $acts)
{
    Write-Host "No errors found`n"
}
else
{
    $errors = @()
    foreach($act in $acts)
    {
        foreach($err in $act.Errors)
        {
            $obj = New-Object -TypeName psobject
            $obj | Add-Member -MemberType NoteProperty -Name UserName -Value $act.UserName
            $obj | Add-Member -MemberType NoteProperty -Name Time -Value $err.Time
            $obj | Add-Member -MemberType NoteProperty -Name ErrorCode -Value $err.ErrorCodeSymbolic
            $obj | Add-Member -MemberType NoteProperty -Name ReportedBy -Value $err.ReportedBy
            $errors += $obj
        }
    }
    $errors  | Out-String | % {Write-Host $_}
}

Write-Host ""
Write-Host "Health check:" -ForegroundColor $CommandInfo
$hpools = Get-RdsHostPool -TenantName $AlyaWvdTenantNameTest
foreach ($hpool in $hpools)
{
    Write-Host " + HostPool: $($hpool.HostPoolName)"
    Write-Host "   - Hosts"
    $hosts = Get-RdsSessionHost -TenantName $AlyaWvdTenantNameTest -HostPoolName $hpool.HostPoolName
    foreach ($hosti in $hosts)
    {
        Write-Host "     - $($hosti.SessionHostName) AllowNew:$($hosti.AllowNewSession) Status:$($hosti.Status) LastHeartBeat:$($hosti.LastHeartBeat)"
        Write-Host "       Agents: AgentVersion: $($hosti.AgentVersion) SxSStackVersion:$($hosti.SxSStackVersion)"
        Write-Host "       Update: UpdateState: $($hosti.UpdateState) LastUpdateTime:$($hosti.LastUpdateTime) UpdateErrorMessage:$($hosti.UpdateErrorMessage)"
        if ($hosti.SessionHostHealthCheckResult)
        {
            $hosti.SessionHostHealthCheckResult | ConvertFrom-Json | fl *
        }
        else
        {
            Write-Host "       Host health check is null"
        }
    }
}

#Get-RdsDiagnosticActivities -TenantName $AlyaWvdTenantNameTest -UserName Renata.Tozzi@alyaconsulting.ch -Detailed -StartTime "18.09.2019 13:00:00"
#((Get-RdsDiagnosticActivities -TenantName $AlyaWvdTenantNameTest -UserName alex.papadopoulos@alyaconsulting.ch -Detailed -StartTime "18.09.2019 13:00:00").CheckPoints | where {$_.Name -eq "OnClientDisconnected"}).Parameters
#Get-RdsDiagnosticActivities -TenantName $AlyaWvdTenantNameTest -UserName alex.papadopoulos@alyaconsulting.ch -Detailed -StartTime "19.08.2019 17:00:00" | ft ActivityType,StartTime,Outcome
#Get-RdsDiagnosticActivities -TenantName $AlyaWvdTenantNameTest -UserName test.user@alyaconsulting.ch -Detailed -StartTime "19.08.2019 17:00:00" | ft ActivityType,StartTime,Outcome
#(Get-RdsDiagnosticActivities -TenantName $AlyaWvdTenantNameTest -UserName first.last@alyaconsulting.ch -Detailed -StartTime "19.08.2019 17:00:00" | where { $_.Outcome -eq "Failure" }).Errors
#Get-RdsDiagnosticActivities -TenantName $AlyaWvdTenantNameTest -Detailed -ActivityId 05427ab5-6582-4346-8e12-30a1262b89b0

#Stopping Transscript
Stop-Transcript
