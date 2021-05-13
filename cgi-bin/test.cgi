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

# ---------------------------------------------------------------------
# Writing the content type is necessary when working with CGI scripts.

Write-Host "Content-type: text/html"
Write-Host ""

# ---------------------------------------------------------------------

function Convert-FromMarkdown {
    Param([string[]]$markdown)
    $markdown | pandoc --from=markdown --to=html -o -
}



Write-Host "<html>"
Write-Host "<head>"
Write-Host "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">"
Write-Host "<title>Bash CGI script</title>"
Write-Host "</head>"
Write-Host "<body>"
Write-Host (Convert-FromMarkdown -markdown (Get-Content test.md))
Write-Host "<pre>"
env
Write-Host "</pre>"
Write-Host "</body>"
Write-Host "</html>"