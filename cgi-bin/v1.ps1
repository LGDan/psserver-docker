#!/usr/bin/pwsh
#requires -version 7

#    Copyright (C) 2021
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

# The point of this file is to examine the URL and figure out what powershell file
# needs to be loaded, and then what method in that file needs to be called.
# It's capable of looking at a provided file extension to shape the output
# as well as verifying names to prevent command injection etc.

Import-Module "$PSScriptRoot/internal/int_v1_auth.psm1"

function Get-PathIntention() {

    $apiBasePath = $null
    $apiVersion = $null
    $apiModule = $null
    $apiExpectedModuleName = $null
    $apiFunction = $null
    $apiFunctionFileExtension = $null
    $intention = $null

    if ($global:path.Length -ge 2) {$apiBasePath = $global:path[1];  $intention = "API Root Docs"}
    if ($global:path.Length -ge 3) {$apiVersion = $global:path[2];   $intention = "API v1 Module List"}
    if ($global:path.Length -ge 4) {$apiModule = $global:path[3]; $apiExpectedModuleName = "v1_$apiSubSystem.psm1";$intention = "Module Docs" }
    if ($global:path.Length -ge 5) {
        $apiFunction = $global:path[4]
        if ($apiFunction.Contains(".")) {
            $funcSplit = $apiFunction.Split(".")
            $apiFunctionFileExtension = $funcSplit[1]
            $apiFunction = $funcSplit[0]
        }
        $intention = "Function"
    }


    [PSCustomObject]@{
        "BasePath"=$apiBasePath
        "Version"=$apiVersion
        "Module"=$apiModule
        "ExpectedModuleName"=$apiExpectedModuleName
        "Function"=$apiFunction
        "FileExtension"=$apiFunctionFileExtension
        "Intention"=$intention
    }
}

function Get-RequestedContentType() {
    # .DESCRIPTION
    # Enumerate the requested content type, either through http Accept Header (TODO) or file extention.
    [CmdletBinding()]
    param(
        [Parameter(HelpMessage="The path intention object.")][PSCustomObject]$PathIntention
    )
    $contentType = "application/json"
    if ($PathIntention.Function.Contains(".")) {
        $functionNameArray = $PathIntention.Split(".")
        $extension = $functionNameArray[1]
        Switch ($extension) {
            "json" {$contentType = "application/json";Break} # Data
            "html" {$contentType = "text/html";Break}  # Docs/Reports
            "csv" {$contentType = "text/csv";Break} # Data
        }
    }
    $contentType
}

function Get-GetParameters() {
    $commandArgsHT = @{}

    if ($null -ne $env:QUERY_STRING) {
        if ($env:QUERY_STRING.Contains("&")) {
            $env:QUERY_STRING.Split("&") | ForEach-Object {
                $kv = $_.Split("=")
                $key = [System.Web.HttpUtility]::URLDecode($kv[0])
                $value = [System.Web.HttpUtility]::URLDecode($kv[1])
                $commandArgsHT.Add($key, $value) | Out-Null
            }
        }else{
            $kv = $env:QUERY_STRING.Split("=")
            $key = [System.Web.HttpUtility]::URLDecode($kv[0])
            $value = [System.Web.HttpUtility]::URLDecode($kv[1])
            $commandArgsHT.Add($key, $value) | Out-Null
        }
    }
    
    $commandArgsHT
}

function Optimize-Parameters() {
    # .DESCRIPTION
    # Takes a set of parameters and a cmdlet, and returns an ordered list to pass to a .Invoke() method.
    [CmdletBinding()]
    param(
        [Parameter(HelpMessage="A command from Get-Command.")][System.Management.Automation.FunctionInfo]$cmdlet,
        [Parameter(HelpMessage="A hashtable with names matching the parameters of the provided cmdlet.")][Hashtable]$parameters
    )
    $excludedParams = (
        "Verbose",
        "Debug",
        "ErrorAction",
        "WarningAction",	
        "InformationAction",	
        "ErrorVariable",
        "WarningVariable",		
        "InformationVariable",
        "OutVariable",	
        "OutBuffer",	
        "PipelineVariable"
    )
    $optimisedParameters = @()
    $command.Parameters.GetEnumerator() | Where-Object Key -notin $excludedParams | ForEach-Object {
        $optimisedParameters += $parameters[$_.Key]
    }
    $optimisedParameters
}

function Get-PSServerAPIv1ModuleList() {
    $sb = [System.Text.StringBuilder]::new()
    $sb.AppendLine("") | Out-Null

    Write-Host ("Content-Type: text/plain `n")
    Write-Host ("v1 - PSServer API Subsystem.")
    Write-Host ("----------------------------")
    Get-ChildItem "internal/" -filter *.psm1 | Where-Object Name -like "v1_*" | Select-Object -ExpandProperty Name | ForEach-Object {
        $_.Substring(3).Split(".")[0]
    }
}

function Test-ModuleImport() {
    # .DESCRIPTION
    # Verifies the existence of a module file and imports it. Otherwise abort.
    [CmdletBinding()]
    param(
        [Parameter(HelpMessage="The name of the module.")][String]$Name
    )

    if (Test-Path "$PSScriptRoot/internal/v1_$Name.psm1") {
        Import-Module "$PSScriptRoot/internal/v1_$Name.psm1"
    }else{
        "Status: 404 Not Found`n"
        Break
    }
}
function Invoke-v1APICommand() {
    # .DESCRIPTION
    # Takes a set of parameters and a cmdlet, and returns an ordered list to pass to a .Invoke() method.
    [CmdletBinding()]
    param(
        [Parameter(HelpMessage="The file name of the module.")][String]$Module,
        [Parameter(HelpMessage="The name of the cmdlet.")][String]$cmdletName,
        [Parameter(HelpMessage="A hashtable with names matching the parameters of the provided cmdlet.")][Hashtable]$parameters
    )

    if ($null -ne (Get-Command -Name $cmdletName -Module "v1_$Module")) {
        $command = (Get-Command -Name $cmdletName -Module "v1_$Module")
        $optimisedParameters = Optimize-Parameters -cmdlet $command -parameters $parameters
        "Content-Type: application/json`n"
        $command.ScriptBlock.Invoke($optimisedParameters) | ConvertTo-Json -Depth 4
    }else{
        "Status: 404 Not Found`n"
    }

}

function Invoke-v1API() {
    $intention = Get-PathIntention

    if (!(Test-Authorised)) {
        # Unauthorised
        Write-Host "Status: 401 Unauthorised"
        Write-Host "WWW-Authenticate: Basic"
        Write-Host ""
    }else{
        # Authorised
        #$global:requestedContentType = Get-RequestedContentType -PathIntention $intention

        Switch($intention.Intention) {
            "API Root Docs" {
                Import-Module "$PSScriptRoot/internal/int_v1_docsgen.psm1"
                Break;
            }
            "API v1 Module List" {
                Import-Module "$PSScriptRoot/internal/int_v1_docsgen.psm1"
                "Content-Type: text/html`n"
                Get-PSServerAPIv1ModuleList
                Break;
            }
            "Module Docs" {
                Import-Module "$PSScriptRoot/internal/int_v1_docsgen.psm1"
                Test-ModuleImport -Name $intention.Module
                "Content-Type: text/html`n"
                Get-Docs -moduleName "v1_$($intention.Module)"
                Break;
            }
            "Function" {
                Test-ModuleImport -Name $intention.Module
                Invoke-v1APICommand -Module $intention.Module -cmdletName $intention.Function -parameters (Get-GetParameters)
                Break;
            }
        }
    }
}

Invoke-v1API