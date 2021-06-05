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

function Get-PSServerAPIv1ModuleList() {
    # .DESCRIPTION
    # Gets a list of available modules within this PSServer v1 API Instance.

    $sb = [System.Text.StringBuilder]::new()

    $sb.AppendLine("# PSServer API v1`n") | Out-Null
    $sb.AppendLine((@"

This page provides a list of all available modules within this PSServer instance. All requests *should* be authenticated
using the ``Authorization`` header, using ``Basic <base64>`` with ``X`` as the username, and the API Key as the password.

"@)) | Out-Null

    Get-ChildItem "internal/" -filter *.psm1 | Where-Object Name -like "v1_*" | Select-Object -ExpandProperty Name | ForEach-Object {
        $module = $_.Substring(3).Split(".")[0]

        $sb.AppendLine(("- [$($module)](/api/v1/$($module))")) | Out-Null
        (Get-Module -ListAvailable "internal/v1_auth.psm1").ExportedCommands.GetEnumerator() | ForEach-Object {
            $sb.AppendLine(("    - " + $_.Key)) | Out-Null
        }
    }

    $body = (Convert-FromMarkdown -markdown $sb.ToString() | Out-String)
    $style = @"
table, th, td {
  border: 1px solid black;
}

th, td {
  padding: 10px;
}

pre {
    background-color: #000;
    color: white;
    padding: 5px;
}
"@
    Get-DocsTemplate -title $moduleName -body $body -style $style

    $sb.AppendLine("") | Out-Null
    
    #Write-Host ("Content-Type: text/plain `n")
    #Write-Host ("v1 - PSServer API Subsystem.")
    #Write-Host ("----------------------------")
    #Get-ChildItem "internal/" -filter *.psm1 | Where Name -like "v1_*" | Select -ExpandProperty Name | % {
    #    $_.Substring(3).Split(".")[0]
    #}
}

function Get-MarkdownFromCmdlet() {
    # .DESCRIPTION
    # Generates documentation in markdown format based on the name of a given cmdlet.
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage="The name of the cmdlet to generate documentation from.")][String]$cmdletName
    )

    $sb = [System.Text.StringBuilder]::new()
    $cmdletMeta = Get-DocStruct -cmdletName $cmdletName

    if ($null -ne $cmdletMeta) {
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

        # Heading
        $sb.AppendLine(("## [" + $cmdletMeta.Method + "] " + $cmdletMeta.Name + "`n`n")) | Out-Null

        # Example
        $sb.AppendLine("``````") | Out-Null
        $sb.Append(($cmdletMeta.Method + " /api/v1/" + $cmdletMeta.ModuleNice + "/" + $cmdletMeta.Name + ".[json|csv|html]?")) | Out-Null
        $cmdletMeta.Params | Where-Object Name -notin $excludedParams | ForEach-Object {
            $sb.Append(($_.Name + "=[placeholder]&")) | Out-Null
        }
        $sb.Remove(($sb.Length - 1),1) | Out-Null
        $sb.AppendLine() | Out-Null
        $sb.AppendLine("Authorization: Basic WDpBUElLRVk=") | Out-Null
        $sb.AppendLine("```````n`n") | Out-Null

        # Description
        $sb.AppendLine(($cmdletMeta.Description + "`n")) | Out-Null

        # Example
        $sb.AppendLine(($cmdletMeta.Example + "`n")) | Out-Null

        # Parameters
        $sb.AppendLine("### Parameters") | Out-Null
        $sb.AppendLine("| Name | Data Type | Description |") | Out-Null
        $sb.AppendLine("|------|-----------|-------------|") | Out-Null

        $cmdletMeta.Params | Where-Object Name -notin $excludedParams | ForEach-Object {
            $sb.AppendLine(("|" + $_.Name + "|" + $_.DataType + "|" + $_.HelpMessage + "|")) | Out-Null
        }
        $sb.ToString()
    }
}

function Get-DocStruct() {
    # .DESCRIPTION
    # Returns a generic object with all the information needed to make documentation from.
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage="The name of the cmdlet to extract metadata from.")][String]$cmdletName
    )

    $cmdlet = Get-Command -Name $cmdletName
    if ($null -ne $cmdlet) {
        $verbToHttpMethod = @{
            "Get"="GET"
            "Set"="POST"
            "New"="POST"
            "Invoke"="GET"
            "Remove"="DELETE"
            "Add"="POST"
            "ConvertFrom"="POST"
            "ConvertTo"="POST"
            "Test"="GET"
        }
        $httpMethod = $verbToHttpMethod[$cmdlet.Verb]

        $params = $cmdlet.Parameters.GetEnumerator() | ForEach-Object {
            [pscustomobject]@{
                "Name"=$_.Key
                "DataType"=$_.Value.ParameterType.Name
                "HelpMessage"=$_.Value.Attributes.HelpMessage
            }
        }
        [pscustomobject]@{
            "Name"=$cmdletName
            "Method"=$httpMethod
            "Module"=$cmdlet.Module
            "ModuleNice"=($cmdlet.Module.ToString().Substring(3))
            "Params"=$params
            "Description"=(Get-Help $cmdletName).description.text
            "Example"=(Get-Help $cmdletName).examples.example.code
        }
    }
}

function Get-HTMLFromCmdlet($cmdletName) {
    
}

function Convert-FromMarkdown() {
    # .DESCRIPTION
    # Uses Pandoc to convert markdown to HTML.
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage="Raw markdown text to convert to HTML.")][String[]]$markdown
    )

    $markdown | pandoc --from=markdown --to=html -o -
}

function Get-DocsTemplate() {
    # .DESCRIPTION
    # Returns a text template with bootstrap for docs pages.
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage="The value to place in the html <title> tag.")][String]$title,
        [Parameter(HelpMessage="The raw HTML to place inside the main document body.")][String]$body,
        [Parameter(HelpMessage="CSS to put between the <style> tags in the header.")][String]$style
    )

    @"
<!doctype html>
<html lang="en">
    <head>
        <!-- Required meta tags -->
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <!-- Bootstrap CSS -->
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.1/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-+0n0xVW2eSR5OomGNYDnhzAbDsOXxcvSN1TPprVMTNDbiYZCxYbOOl7+AMvyTG2x" crossorigin="anonymous">
        <title>$title</title>
        <style>
$style
        </style>
    </head>
    <body class="d-flex flex-column h-100">
        <main class="flex-shrink-0">
            <div class="container">
$body
            </div>
        </main>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.1/dist/js/bootstrap.bundle.min.js" integrity="sha384-gtEjrD/SeCtmISkJkNUaaKMoLD0//ElJ19smozuHV6z3Iehds+3Ulb9Bn9Plx0x4" crossorigin="anonymous"></script>
    </body>
</html>
"@
}

function Get-Docs() {
    # .DESCRIPTION
    # Generates documentation pages for PowerShell Modules.
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage="The name of the PowerShell module to generate documentation for.")][String]$moduleName
    )

    $moduleNameNice = $moduleName.Substring(3)
    $sb = [System.Text.StringBuilder]::new()
    $sb.AppendLine("# PSServer API v1 - $moduleNameNice module`n") | Out-Null
    $sb.AppendLine((@"

This page provides API Documentation for the $moduleNameNice module. All requests *should* be authenticated
using the ``Authorization`` header, using ``Basic <base64>`` with ``X`` as the username, and the API Key as the password.
All API endpoints can be suffixed with a file extension to attempt to convert the command's output to the desired content type.

"@)) | Out-Null
    $moduleCommands = Get-Command -Module $moduleName
    if (($moduleCommands | Measure-Object).Count -eq 0) {
        $sb.AppendLine("### There doesn't appear to be any functions exported from this module.") | Out-Null
    }
    $moduleCommands | ForEach-Object {
        $sb.AppendLine((Get-MarkdownFromCmdlet -cmdletName $_.Name)) | Out-Null
        $sb.AppendLine("`n---`n") | Out-Null
    }
    $body = (Convert-FromMarkdown -markdown $sb.ToString() | Out-String)
    $style = @"
table, th, td {
  border: 1px solid black;
}

th, td {
  padding: 10px;
}

pre {
    background-color: #000;
    color: white;
    padding: 5px;
}
"@
    Get-DocsTemplate -title $moduleName -body $body -style $style
}