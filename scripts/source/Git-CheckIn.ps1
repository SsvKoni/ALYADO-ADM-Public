#Requires -Version 2.0

<#
    Copyright (c) Alya Consulting, 2019, 2020

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
    11.11.2019 Konrad Brunner       Initial Version

#>

[CmdletBinding()]
Param(
)

# Loading configuration
. $PSScriptRoot\..\..\01_ConfigureEnv.ps1

#Starting Transscript
Start-Transcript -Path "$($AlyaLogs)\scripts\source\Git-CheckIn-$($AlyaTimeString).log" -IncludeInvocationHeader -Force | Out-Null

#Checkin
Write-Host "Commit of latest changes" -ForegroundColor $CommandInfo
$errAct = $ErrorActionPreference
Push-Location
try {
    Set-Location "$($almRootDir)"
    $ErrorActionPreference = 'SilentlyContinue'
    Write-Host "git add" -ForegroundColor $CommandInfo
    & "$($GitRoot)\cmd\git.exe" "add .".Split(" ")
    Wait-UntilProcessEnds -processName "git"
    Write-Host "Please provide your checkin message and hit enter:" -ForegroundColor $CommandInfo
    $comMsg = Read-Host
    Write-Host "git commit" -ForegroundColor $CommandInfo
    & "$($GitRoot)\cmd\git.exe" "commit -a -m `"$comMsg`"".Split(" ")
    Wait-UntilProcessEnds -processName "git"
}
finally {
    Pop-Location
    $ErrorActionPreference = $errAct
}

#Stopping Transscript
Stop-Transcript