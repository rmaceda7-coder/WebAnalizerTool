#Requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $root 'src/WindowsBrowser.psm1') -Force -DisableNameChecking
$script:count = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    $script:count++
    Write-Output "PASS: $Message"
}

function Assert-Throws {
    param([scriptblock]$Action, [string]$Message)
    $threw = $false
    try { $null = & $Action } catch { $threw = $true }
    Assert-True $threw $Message
}

function New-TestWindow {
    param([long]$Handle = 1, [bool]$Primary = $true, [string]$Process = 'chrome',
        [bool]$Visible = $true, [bool]$Minimized = $false, [bool]$Cloaked = $false,
        [string]$Title = 'Example - Google Chrome')
    [pscustomobject]@{
        Handle = $Handle; IsPrimary = $Primary; ProcessName = $Process
        Visible = $Visible; Minimized = $Minimized; Cloaked = $Cloaked; Title = $Title
    }
}

$secondary = New-TestWindow -Handle 9 -Primary $false
$terminal = New-TestWindow -Handle 8 -Process 'WindowsTerminal'
$primary = New-TestWindow -Handle 7
$otherPrimary = New-TestWindow -Handle 6
$selected = Select-PrimaryBrowserWindow -Windows @($secondary, $terminal, $primary, $otherPrimary)
Assert-True ($selected.Handle -eq 7) 'Primary-display Chrome wins even when terminal or secondary Chrome is first'
$selected = Select-PrimaryBrowserWindow -Windows @($otherPrimary, $primary)
Assert-True ($selected.Handle -eq 6) 'Highest Z-order eligible Chrome wins'
$bad = @(
    (New-TestWindow -Minimized $true),
    (New-TestWindow -Visible $false),
    (New-TestWindow -Cloaked $true),
    (New-TestWindow -Title '')
)
$selected = Select-PrimaryBrowserWindow -Windows @($bad + @($primary))
Assert-True ($selected.Handle -eq 7) 'Minimized, invisible, cloaked and untitled windows are rejected'
Assert-Throws { Select-PrimaryBrowserWindow -Windows @($secondary, $terminal) } 'Never falls back to another monitor or application'
Assert-Throws { Select-PrimaryBrowserWindow -Windows @() } 'Missing browser fails explicitly'

$context = [pscustomobject]@{
    WindowHandle = 7; Url = 'https://example.test/Exercise?question=1'
    Monitor = [pscustomobject]@{ IsPrimary = $true }
}
$null = Assert-ExpectedContext -Context $context -ExpectedWindowHandle 7 -ExpectedUrl $context.Url
Assert-True $true 'Matching context is accepted'
Assert-Throws { Assert-ExpectedContext -Context $context -ExpectedWindowHandle 6 -ExpectedUrl $context.Url } 'Window switch invalidates context'
Assert-Throws { Assert-ExpectedContext -Context $context -ExpectedWindowHandle 7 -ExpectedUrl 'https://example.test/Exercise?question=2' } 'Exercise switch invalidates context'
Assert-Throws { Assert-ExpectedContext -Context $context -ExpectedWindowHandle 7 -ExpectedUrl 'https://example.test/exercise?question=1' } 'URL path comparison is case-sensitive'
$context.Monitor.IsPrimary = $false
Assert-Throws { Assert-ExpectedContext -Context $context -ExpectedWindowHandle 7 -ExpectedUrl $context.Url } 'Secondary-display context is rejected'

Assert-True ((Get-ContentSha256 -Text '') -eq 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855') 'Empty editor hash matches SHA-256 standard'
Assert-True ((Get-ContentSha256 -Text "SELECT`r`n1;") -eq (Get-ContentSha256 -Text "SELECT`n1;")) 'Readback tolerates CRLF versus LF only'
Assert-True ((Get-ContentSha256 -Text 'SELECT 1;') -ne (Get-ContentSha256 -Text 'SELECT 2;')) 'Code changes invalidate content fingerprint'
Assert-True ((Get-ContentSha256 -Text 'SELECT 1;') -ne (Get-ContentSha256 -Text 'SELECT 1; ')) 'Whitespace edits remain observable'

$files = @(Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {
    $_.Extension -in @('.ps1', '.psm1') -and $_.FullName -notmatch '[\\/]\.git[\\/]'
})
foreach ($file in $files) {
    $tokens = $null; $errors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
    Assert-True ($errors.Count -eq 0) "PowerShell syntax: $($file.Name)"
}

$config = [IO.File]::ReadAllText((Join-Path $root 'opencode.json')) | ConvertFrom-Json
Assert-True ($config.'$schema' -eq 'https://opencode.ai/config.json') 'OpenCode declares its official schema'
Assert-True ($config.default_agent -eq 'web-analyzer') 'OpenCode selects the installed primary agent'
Assert-True (Test-Path -LiteralPath (Join-Path $root '.opencode/agents/web-analyzer.md')) 'Default agent file exists'
$skills = @(Get-ChildItem -LiteralPath (Join-Path $root '.opencode/skills') -Directory)
Assert-True ($skills.Count -eq 3) 'All three workflow skills are installed'
foreach ($skill in $skills) {
    $body = [IO.File]::ReadAllText((Join-Path $skill.FullName 'SKILL.md'))
    Assert-True ($body -match ('(?m)^name: ' + [regex]::Escape($skill.Name) + '$')) "Skill name matches folder: $($skill.Name)"
    Assert-True ($body -match '(?m)^description: .+') "Skill has discoverable description: $($skill.Name)"
}

if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
    if (-not ('WebAnalyzer.NativeDesktop' -as [type])) {
        Add-Type -Path (Join-Path $root 'src/NativeDesktop.cs')
    }
    Assert-True ($null -ne ('WebAnalyzer.NativeDesktop' -as [type])) 'Native Windows adapter compiles'
}

Write-Output "All $script:count checks passed. No live browser/editor was changed."
