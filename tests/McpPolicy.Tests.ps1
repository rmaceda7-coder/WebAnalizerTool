# Documentation/agent policy regression checks only. No server connection or browser action.
# Dot-sourced by Run-Tests.ps1, which supplies $root and Assert-True.
$contract = [IO.File]::ReadAllText((Join-Path $root 'AGENTS.md'))
$agent = [IO.File]::ReadAllText((Join-Path $root '.opencode/agents/web-analyzer.md'))
$guidePath = Join-Path $root 'docs/mcp-capabilities.md'
Assert-True (Test-Path -LiteralPath $guidePath) 'Connected MCP capability guide exists'
$guide = [IO.File]::ReadAllText($guidePath)
$orchestration = [IO.File]::ReadAllText((Join-Path $root '.opencode/skills/mcp-tool-orchestration/SKILL.md'))

Assert-True ($contract.Contains('## MCP capability routing') -and
    $contract.Contains('### Existing/current-page mode') -and
    $contract.Contains('### Tool-driven test-session mode')) 'Contract separates capability routing and browser session modes'
Assert-True ($agent.Contains('mcp-tool-orchestration') -and
    $agent.Contains('docs/mcp-capabilities.md')) 'Primary agent routes work through the orchestration skill and guide'
Assert-True (-not ($agent -match 'Do not launch Selenium\.|Do not use extension-based Playwright discovery that opens a connection page\.')) 'Primary agent has no obsolete blanket runner startup ban'
Assert-True ($contract.Contains('must not open tabs, navigate, launch a browser, change focus/clipboard, or initiate extension setup')) 'Current-page discovery retains passive boundaries'
Assert-True ($contract.Contains('Matching URLs alone are insufficient') -and
    $guide.Contains('unambiguous attachment mapping')) 'Same-page control requires more than matching URLs'
Assert-True ($contract.Contains('Announce known effects') -and
    $guide.Contains('User-controlled extension consent must remain with the user')) 'Intentional setup discloses effects and preserves user consent'
Assert-True ($contract.Contains('A URL-only test request') -and
    $guide.Contains('does not alone authorize a new browser or extension setup')) 'URL-only tests do not silently authorize browser startup'
Assert-True ($contract.Contains('A functional-test request authorizes routine, non-persistent UI checks') -and
    $guide.Contains('autosave')) 'Functional checks are permitted with side-effect review'
Assert-True ($contract.Contains('Do not run unverified test code, submit forms, save records') -and
    $guide.Contains('Explicit approval tied to the current plan/code')) 'State-changing and unknown-effect execution retains scoped approval'
Assert-True ($contract.Contains('Publishing, destructive operations, and load generation need explicit scoped authorization')) 'Publication, destructive actions, and load require explicit authorization'
Assert-True ($contract.Contains('A denial is not permission to retry through another tool') -and
    $guide.Contains('Do not use an alternative transport to bypass a permission denial')) 'Routing cannot bypass tool denials'
Assert-True ($contract.Contains('Do not blanket-allow permissions') -and
    $guide.Contains('Preserve inherited server definitions')) 'Capability policy preserves permissions and inherited configuration'
Assert-True ($contract.Contains('Honor no-file requests') -and
    $guide.Contains('Screenshot tools may save files even without a filename')) 'No-file policy includes implicit runner artifacts'
Assert-True ($guide.Contains('postman://instructions') -and
    $guide.Contains('Read `postman://instructions`') -and
    $guide.Contains('initial instructions before coding')) 'Guide records Postman and Serena initialization prerequisites'
foreach ($family in @('browser_vision', 'Playwright MCP', 'Selenium MCP', 'Postman MCP',
        'JMeter MCP', 'GitHub MCP', 'Filesystem / local editing tools', 'Serena MCP', 'OpenAI assistance MCP')) {
    Assert-True ($guide.Contains($family)) "Capability guide covers server family: $family"
}
Assert-True ($guide.Contains('assertion outcomes, skipped/blocked tests') -and
    $orchestration.Contains('AI-generated analyses or scripts do not establish execution')) 'Reports distinguish executed assertions from generated or blocked work'
Assert-True ($contract.Contains('Restart OpenCode') -and
    $agent.Contains('docs/mcp-capabilities.md') -and
    $guide.Contains('Quit and restart OpenCode')) 'Guidance explains reload and instruction-priority boundaries'

foreach ($skillName in @('active-browser-context', 'web-page-analysis', 'browser-code-editor')) {
    $skillText = [IO.File]::ReadAllText((Join-Path $root ".opencode/skills/$skillName/SKILL.md"))
    Assert-True ($skillText.Contains('docs/mcp-capabilities.md') -and
        $skillText.Contains('mcp-tool-orchestration')) "Browser skill routes through MCP session policy: $skillName"
}
