#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ExpectedUrl,
    [Parameter(Mandatory)][long]$ExpectedWindowHandle,
    [Parameter(Mandatory)][string]$EditorName,
    [Parameter(Mandatory)][ValidatePattern('^[a-f0-9]{64}$')][string]$ExpectedContentSha256,
    [Parameter(Mandatory)][string]$CodePath
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../src/WindowsBrowser.psm1') -Force -DisableNameChecking
$resolved = (Resolve-Path -LiteralPath $CodePath -ErrorAction Stop).Path
$code = [IO.File]::ReadAllText($resolved, [Text.Encoding]::UTF8)
$parameters = @{} + $PSBoundParameters
$parameters.Remove('CodePath')
$parameters.Code = $code
Set-BrowserEditor @parameters | ConvertTo-Json -Depth 6
