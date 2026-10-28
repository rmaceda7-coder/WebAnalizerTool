#Requires -Version 5.1
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../src/WindowsBrowser.psm1') -Force -DisableNameChecking
Get-PrimaryBrowserContext | ConvertTo-Json -Depth 6
