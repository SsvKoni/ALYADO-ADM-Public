#Requires -Version 2.0

<#
    Copyright (c) Alya Consulting, 2019

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
    17.03.2020 Konrad Brunner       Initial Version
    01.05.2020 Konrad Brunner       Added RDS stuff

#>

param(
    [Parameter(Mandatory = $true)]
    [string] $Subscriptions,
    [Parameter(Mandatory = $true)]
    [string] $TimeZone,
    [Parameter(Mandatory = $true)]
    [string] $AzureEnvironment
)
$ErrorActionPreference = "Stop"

# Constants
$RunAsConnectionName = "AzureRunAsConnection"
$RunAsCertificateName = "AzureRunAsCertificate"
$ConnectionTypeName = "AzureServicePrincipal"

# Login-AzureAutomation
try {
    $RunAsConnection = Get-AutomationConnection -Name $RunAsConnectionName
    Write-Output "Logging in to AzureRm ($AzureEnvironment)..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $RunAsConnection.TenantId `
        -ApplicationId $RunAsConnection.ApplicationId `
        -CertificateThumbprint $RunAsConnection.CertificateThumbprint `
        -Environment $AzureEnvironment
    $Context = Get-AzureRmContext
} catch {
    if (!$RunAsConnection) {
        Write-Output $RunAsConnectionName
        try { Write-Output ($_.Exception | ConvertTo-Json) -ErrorAction Continue } catch {}
        Write-Output "Connection $RunAsConnectionName not found."
    }
    throw
}

# RDS stuff
$AlyaTenantId = "##AlyaTenantId##"
$AlyaLocalDomainName = "##AlyaLocalDomainName##"
$AlyaWvdRDBroker = "##AlyaWvdRDBroker##"
$AlyaWvdTenantNameProd = "##AlyaWvdTenantNameProd##"
$AlyaWvdTenantNameTest = "##AlyaWvdTenantNameTest##"
$AlyaWvdServicePrincipalNameProd = "##AlyaWvdServicePrincipalNameProd##"
$AlyaWvdServicePrincipalNameTest = "##AlyaWvdServicePrincipalNameTest##"
$AlyaWvdTenantGroupName = "##AlyaWvdTenantGroupName##"

$MessageTitle = "Warnung"
$MessageBody = "Windows Virtual Desktop wird um {0} automatisch heruntergefahren"

$LmagWvdProdAppCred = Get-AutomationPSCredential -Name $AlyaWvdServicePrincipalNameProd
$LmagWvdTestAppCred = Get-AutomationPSCredential -Name $AlyaWvdServicePrincipalNameTest

# Members
$subs = $Subscriptions.Split(",")
$runTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($(Get-Date), [System.TimeZoneInfo]::Local.Id, 'W. Europe Standard Time')
"Run time $($runTime)"

# Processing subscriptions
foreach($sub in $subs)
{
    "Processing subscription: $($sub)"
    Select-AzureRmSubscription -SubscriptionId $sub | Out-Null

    Get-AzureRmResourceGroup | foreach {
        $ResGName = $_.ResourceGroupName
        "  Checking ressource group $($ResGName)"
        foreach($vm in (Get-AzureRmVM -ResourceGroupName $ResGName))
        {
            "    Checking VM $($vm.Name)"
            $tags = $vm.Tags
            $tKeys = $tags | select -ExpandProperty keys
            $startTime = $null
            $stopTime = $null
            foreach ($tkey in $tkeys)
            {
                if ($tkey.ToUpper() -eq "STARTTIME")
                {
                    $startTimeTag = $tags[$tkey]
                    "- startTimeTag: $($startTimeTag)"
                    try { $startTime = [DateTime]::parseexact($startTimeTag,"HH:mm",$null) }
                    catch { $startTime = $null }
                    "- startTime parsed: $($startTime)"
                }
                if ($tkey.ToUpper() -eq "STOPTIME")
                {
                    $stopTimeTag = $tags[$tkey]
                    "- stopTimeTag: $($stopTimeTag)"
                    try { $stopTime = [DateTime]::parseexact($stopTimeTag,"HH:mm",$null) }
                    catch { $stopTime = $null }
                    "- stopTime parsed: $($stopTime)"
                }
            }
            if ($startTime)
            {
                if ($runTime -gt $startTime -and -not ($stopTime -and $startTime -lt $stopTime -and $runTime -gt $stopTime))
                {
                    $VMDetail = Get-AzureRmVM -ResourceGroupName $ResGName -Name $vm.Name -Status
                    foreach ($VMStatus in $VMDetail.Statuses)
                    {
                        "- VM Status: $($VMStatus.Code)"
                        if($VMStatus.Code.CompareTo("PowerState/deallocated") -eq 0)
                        {
                            "- Starting VM"
                            Start-AzureRmVM -ResourceGroupName $ResGName -Name $vm.Name
                        }
                    }
                }
            }
            if ($stopTime)
            {
                if ($runTime -gt $stopTime -and -not ($startTime -and $startTime -gt $stopTime -and $runTime -gt $startTime))
                {
                    $VMDetail = Get-AzureRmVM -ResourceGroupName $ResGName -Name $vm.Name -Status
                    foreach ($VMStatus in $VMDetail.Statuses)
                    { 
                        "- VM Status: $($VMStatus.Code)"
                        if($VMStatus.Code.CompareTo("PowerState/running") -eq 0)
                        {
                            $hostName = $vm.Name + "." + $AlyaLocalDomainName
                            $tmp = Add-RdsAccount -DeploymentUrl $AlyaWvdRDBroker -Credential $LmagWvdTestAppCred -ServicePrincipal -AadTenantId $AlyaTenantId
                            $hpools = Get-RdsHostPool -TenantName $AlyaWvdTenantNameTest
                            foreach ($hpool in $hpools)
                            {
                                $hosti = Get-RdsSessionHost -TenantName $AlyaWvdTenantNameTest -HostPoolName $hpool.HostPoolName -Name $hostName -ErrorAction SilentlyContinue
                                if ($hosti)
                                {
                                    $sessns = Get-RdsUserSession -TenantName $AlyaWvdTenantNameTest -HostPoolName $hpool.HostPoolName -ErrorAction SilentlyContinue
                                    foreach ($sessn in $sessns)
                                    {
                                        Invoke-RdsUserSessionLogoff -TenantName $AlyaWvdTenantNameTest -HostPoolName $hpool.HostPoolName -SessionHostName $sessn.SessionHostName -SessionId $sessn.SessionId -NoUserPrompt -ErrorAction SilentlyContinue
                                    }
                                    if ($sessns.Count -gt 0)
                                    {
                                        Start-Sleep -Seconds 30
                                    }
                                }
                            }
                            $tmp = Add-RdsAccount -DeploymentUrl $AlyaWvdRDBroker -Credential $LmagWvdProdAppCred -ServicePrincipal -AadTenantId $AlyaTenantId
                            $hpools = Get-RdsHostPool -TenantName $AlyaWvdTenantNameProd
                            foreach ($hpool in $hpools)
                            {
                                $hosti = Get-RdsSessionHost -TenantName $AlyaWvdTenantNameProd -HostPoolName $hpool.HostPoolName -Name $hostName -ErrorAction SilentlyContinue
                                if ($hosti)
                                {
                                    $sessns = Get-RdsUserSession -TenantName $AlyaWvdTenantNameProd -HostPoolName $hpool.HostPoolName -ErrorAction SilentlyContinue
                                    foreach ($sessn in $sessns)
                                    {
                                        if ($sessn.SessionHostName -eq $hostName)
                                        {
                                            Invoke-RdsUserSessionLogoff -TenantName $AlyaWvdTenantNameProd -HostPoolName $hpool.HostPoolName -SessionHostName $sessn.SessionHostName -SessionId $sessn.SessionId -NoUserPrompt -ErrorAction SilentlyContinue
                                        }
                                    }
                                    if ($sessns.Count -gt 0)
                                    {
                                        Start-Sleep -Seconds 30
                                    }
                                }
                            }
                            "- Stopping VM"
                            Stop-AzureRmVM -ResourceGroupName $ResGName -Name $vm.Name -Force
                        }
                    }
                }
                else
                {
                    $warnTime = $stopTime.AddHours(-2)
                    if ($runTime -gt $warnTime -and -not ($startTime -and $startTime -gt $warnTime -and $runTime -gt $startTime))
                    {
                        $hostName = $vm.Name + "." + $AlyaLocalDomainName
                        $tmp = Add-RdsAccount -DeploymentUrl $AlyaWvdRDBroker -Credential $LmagWvdTestAppCred -ServicePrincipal -AadTenantId $AlyaTenantId
                        $hpools = Get-RdsHostPool -TenantName $AlyaWvdTenantNameTest
                        foreach ($hpool in $hpools)
                        {
                            $hosti = Get-RdsSessionHost -TenantName $AlyaWvdTenantNameTest -HostPoolName $hpool.HostPoolName -Name $hostName -ErrorAction SilentlyContinue
                            if ($hosti)
                            {
                                $sessns = Get-RdsUserSession -TenantName $AlyaWvdTenantNameTest -HostPoolName $hpool.HostPoolName -ErrorAction SilentlyContinue
                                foreach ($sessn in $sessns)
                                {
                                    if ($sessn.SessionHostName -eq $hostName)
                                    {
                                        Send-RdsUserSessionMessage -TenantName $AlyaWvdTenantNameTest -HostPoolName $hpool.HostPoolName -SessionHostName $sessn.SessionHostName -SessionId $sessn.SessionId -MessageTitle $MessageTitle -MessageBody ($MessageBody -f $stopTimeTag) -ErrorAction SilentlyContinue
                                    }
                                }
                            }
                        }
                        $tmp = Add-RdsAccount -DeploymentUrl $AlyaWvdRDBroker -Credential $LmagWvdProdAppCred -ServicePrincipal -AadTenantId $AlyaTenantId
                        $hpools = Get-RdsHostPool -TenantName $AlyaWvdTenantNameProd
                        foreach ($hpool in $hpools)
                        {
                            $hosti = Get-RdsSessionHost -TenantName $AlyaWvdTenantNameProd -HostPoolName $hpool.HostPoolName -Name $hostName -ErrorAction SilentlyContinue
                            if ($hosti)
                            {
                                $sessns = Get-RdsUserSession -TenantName $AlyaWvdTenantNameProd -HostPoolName $hpool.HostPoolName -ErrorAction SilentlyContinue
                                foreach ($sessn in $sessns)
                                {
                                    if ($sessn.SessionHostName -eq $hostName)
                                    {
                                        Send-RdsUserSessionMessage -TenantName $AlyaWvdTenantNameProd -HostPoolName $hpool.HostPoolName -SessionHostName $sessn.SessionHostName -SessionId $sessn.SessionId -MessageTitle $MessageTitle -MessageBody ($MessageBody -f $stopTimeTag) -ErrorAction SilentlyContinue
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

