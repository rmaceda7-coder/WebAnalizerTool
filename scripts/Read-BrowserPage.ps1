#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ExpectedUrl,
    [Parameter(Mandatory)][long]$ExpectedWindowHandle
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../src/WindowsBrowser.psm1') -Force -DisableNameChecking
Read-BrowserPage @PSBoundParameters | ConvertTo-Json -Depth 6
