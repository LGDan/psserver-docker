#!/usr/bin/pwsh

function Convert-FromMarkdown {
    Param([string[]]$markdown)
    $markdown | pandoc --from=markdown --to=html -o -
}

Write-Host "Content-type: text/html"
Write-Host ""

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