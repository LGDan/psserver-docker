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

function Get-Thing() {
    <#
        .DESCRIPTION
        This gets a thing. Requires the /api/v1/dsystem/Get-Thing permission.

        .EXAMPLE
        [Example](/api/v1/auth/Get-Thing?string=AAAA)
    #>
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage="Test")][String]$Token,
        [Parameter()][String]$Secret,
        [Parameter()][String]$Secret2,
        [Parameter()][String]$Secret3,
        [Parameter()][String]$Secret4,
        [Parameter()][String]$Secret5
    )
    @{
        "1"=$Token
        "2"=$Secret
        "3"=$Secret2
        "4"=$Secret3
    }
}

function Set-Thing() {
    <#
        .DESCRIPTION
        This sets a thing.

        .EXAMPLE
        [Example](/api/v1/DSystem/Set-Thing?Value=abc)
    #>
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage="The value to set.")][String]$Value
    )
    "$Value"
}

Export-ModuleMember -Function Get-Thing
Export-ModuleMember -Function Set-Thing