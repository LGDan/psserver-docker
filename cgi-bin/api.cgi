#!/usr/bin/pwsh

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

# This file is the router for the api endpoint.

$debug = $false

if ($debug) {
    Write-Host "Content-type: text/html"
    Write-Host ""
}

$global:path = $env:DOCUMENT_URI.Split("/")

if ($null -ne $global:path[2]) {
    Switch ($global:path[2]) {
        "v1" {
            try {
                . ./v1.ps1
            }catch{
                Write-Host ("Status: 500 Internal Server Error")
                Write-Host ("Content-Type: text/html; charset=utf-8`n")
                Write-Host ("<h1>500 - There was an error running part of the API.</h1>")
                Write-Host ("<p>Category:" + $_.CategoryInfo + "</p>")
                Write-Host
                $errorMessage = ($_ | Out-String)
                $toReplace = ("[91m","[0m","[96m")
                $toReplace | ForEach-Object {
                    $errorMessage = $errorMessage.Replace($_,"")
                }
                Write-Host ("<h2>Error</h2> <pre>" + $errorMessage + "</pre>")
                Write-Host ("<h2>Small Stack Trace</h2>")
                Write-Host $_.ScriptStackTrace.ToString()
                Write-Host ("<h2>Full Stack Trace</h2><pre>")
                Write-Host $_.Exception
                Write-Host ("</pre>")
            }
            break;
        }
        default {
            Write-Host ("No API Found matching request.")
        }
    }
}