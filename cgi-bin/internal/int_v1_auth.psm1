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



function ConvertTo-Base64() {
    <#
        .DESCRIPTION
        Converts a string to base64.

        .EXAMPLE
        [Example](/api/v1/auth/ConvertTo-Base64?string=AAAA)
    #>
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage="Input String.")][String]$string
    )
    [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($string))
}

function ConvertFrom-Base64() {
    <#
        .DESCRIPTION
        Converts base64 to a string.

        .EXAMPLE
        [Example](/api/v1/auth/ConvertFrom-Base64?string=AAAA)
    #>
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage="Input Base64.")][String]$base64
    )
    [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64))
}

function Test-Authorised() {
    $cfg = (. "$PSScriptRoot/int_v1_auth_conf.ps1")
    $authorised = $false

    $authScheme = $env:HTTP_AUTHORIZATION.Split(" ")[0]
    $authValue = $env:HTTP_AUTHORIZATION.Split(" ")[1]

    if ($authScheme -eq "Basic") {
        $authValue = ConvertFrom-Base64 -base64 $authValue
        $key = $authValue.Split(":")[1]
        $validUser = ($cfg.acls | Where-Object key -eq $key)
        if ($null -ne $validUser) {
            $validUser.permissions."HTTP_$env:REQUEST_METHOD" | ForEach-Object {
                if ($env:DOCUMENT_URI -like $_) {
                    $authorised = $true
                }
            }
        }
    }

    $authorised
}