#!/usr/bin/pwsh

#    Copyright (C) 2021 Dan Galbraith
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

if (!(Test-Path "$env:HOME/.local/share/powershell/Modules/JWT")) {
    Install-Module JWT -Force
}
Import-Module JWT

function New-AuthJWT {
    [CmdletBinding()]
    param (
        [Parameter()][Hashtable]$Claims,
        [Parameter()][String]$Secret
    )
    New-Jwt -Header "{""alg"":""HS256"",""typ"":""JWT""}" -Secret $Secret -PayloadJson ($Claims|ConvertTo-Json)
}

function Test-AuthJWT {
    [CmdletBinding()]
    param (
        [Parameter()][String]$Token,
        [Parameter()][String]$Secret
    )
    Test-Jwt -Secret $Secret -jwt $Token
}

function Get-AuthJWTContent {
    [CmdletBinding()]
    param (
        [Parameter()][String]$Token
    )
    $Token | Get-JwtPayload
}

function Get-AuthJWTContentAndVerify {
    [CmdletBinding()]
    param (
        [Parameter()][String]$Token,
        [Parameter()][String]$Secret
    )
    if (Test-AuthJWT -Token $Token -Secret $Secret) {
        $Token | Get-JwtPayload
    }
}