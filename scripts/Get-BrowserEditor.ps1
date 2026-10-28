#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ExpectedUrl,
    [Parameter(Mandatory)][long]$ExpectedWindowHandle,
    [Parameter(Mandatory)][string]$EditorName
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../src/WindowsBrowser.psm1') -Force -DisableNameChecking
Get-BrowserEditor @PSBoundParameters | ConvertTo-Json -Depth 6
