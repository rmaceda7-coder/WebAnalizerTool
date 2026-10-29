#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ExpectedUrl,
    [Parameter(Mandatory)][long]$ExpectedWindowHandle
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object Text.UTF8Encoding $false
Import-Module (Join-Path $PSScriptRoot '../src/WindowsBrowser.psm1') -Force -DisableNameChecking
Get-BrowserPageImage @PSBoundParameters | ConvertTo-Json -Depth 6 -Compress
