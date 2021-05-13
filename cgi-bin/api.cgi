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

# ---------------------------------------------------------------------
# Writing the content type is necessary when working with CGI scripts.

Write-Host "Content-type: text/html"
Write-Host ""

# ---------------------------------------------------------------------

. ./internal/authentication.ps1

Write-Host "<html>"
Write-Host "<head>"
Write-Host "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">"
Write-Host "<title>PowerShell CGI script - API</title>"
Write-Host "</head>"
Write-Host "<body>"
Write-Host "<pre>"
env
Write-Host "</pre>"
if ($null -ne $env:HTTP_AUTHORIZATION) {
    if ($env:HTTP_AUTHORIZATION -like "Bearer *") {
        $Token = ([String]$env:HTTP_AUTHORIZATION).Split(" ")[1]
        if (Test-AuthJWT -Token $Token -Secret $env:JWT_SECRET) {
            Get-AuthJWTContentAndVerify -Token $Token -Secret $env:JWT_SECRET
        }else{
            Write-Host "JWT Invalid."
        }
    }else{
        Write-Host "Authorization header needs Bearer ..."
    }
}else{
    Write-Host "JWT not present."
}
Write-Host "</body>"
Write-Host "</html>"

