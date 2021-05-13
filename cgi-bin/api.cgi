#!/usr/bin/pwsh

Write-Host "Content-type: text/html"
Write-Host ""

Write-Host "<html>"
Write-Host "<head>"
Write-Host "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">"
Write-Host "<title>Bash CGI script - API</title>"
Write-Host "</head>"
Write-Host "<body>"
Write-Host "<pre>"
env
Write-Host "</pre>"
Write-Host "</body>"
Write-Host "</html>"

