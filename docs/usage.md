# Installation and usage

This workflow supports web test automation: inspect an application, identify test scenarios and assertions, prepare automation code, and report observed behavior with evidence. The bundled adapter provides passive page inspection and guarded code-editor transfers. It does not provide general form interaction or end-to-end test execution.

## Install for OpenCode

1. Install Git, Chrome, and OpenCode on Windows 10/11.
2. Clone `https://github.com/rmaceda7-coder/WebAnalizerTool.git`.
3. Open a PowerShell terminal in the clone's root directory.
4. Run `powershell.exe -NoProfile -STA -File tests/Run-Tests.ps1`.
5. Open Chrome on the Windows primary display with the target tab selected.
6. Run `opencode` from this project. Quit and restart an already running OpenCode session to load the new config, agent, and skills.

No global OpenCode files are modified. If using another project's shell, use your terminal's working-directory setting or open a new terminal in this clone. Skills and instructions are local to this project.

Downloaded files can be marked as originating from the Internet. Follow your organization's execution policy; review and unblock trusted files if needed. The project does not change execution policy automatically.

On this development machine, Windows PowerShell 5.1 uses a restrictive execution policy. After reviewing and trusting the checkout, a process-scoped invocation can be used without changing persistent machine/user policy:

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File tests/Run-Tests.ps1
```

The same process-only flag may be needed for CLI entry points. Do not use it to circumvent centrally enforced organizational policy. PowerShell 7 is another supported shell when installed and permitted.

## Identify the active primary-display page

```powershell
Import-Module ./src/WindowsBrowser.psm1 -DisableNameChecking
$context = Get-PrimaryBrowserContext
$context | ConvertTo-Json -Depth 6
```

Run the shell in STA mode for desktop commands (`powershell.exe -STA` or `pwsh -STA`). `Monitor.Device` names the Windows device; `Monitor.IsPrimary` is authoritative. The device suffix is not assumed to be the Windows Settings display number. `ForegroundWindowHandle` is informational only and may refer to your secondary-display terminal.

Discovery selects the highest eligible Chrome window on the primary display. If Chrome windows overlap, bring your intended window to the front yourself before discovery. Discovery never changes their order.

Tell the user the detected title and URL before continuing.

## Read the page

```powershell
$binding = @{
    ExpectedUrl = $context.Url
    ExpectedWindowHandle = $context.WindowHandle
}
$page = Read-BrowserPage @binding
$page.Text
$page.Editors | Format-Table
```

Reading does not modify focus or the clipboard. It fails if the selected page or target changes. The browser's accessibility provider must expose exactly one visible HTTP(S) Document. Multiple candidates are treated as ambiguous.

## Analyze application behavior and plan tests

Use the captured page text and, when needed, bound viewport images to identify controls, accessible names, validation messages, and visible application states. Compare these observations with explicit acceptance criteria. For example:

| Test area | Proposed scenarios | Evidence needed to claim a result |
|---|---|---|
| Login validation | Required fields, invalid credentials, keyboard navigation | Actual validation messages and focus behavior after authorized steps |
| Dashboard smoke test | Expected headings, status labels, visible totals | Current labels/values compared with supplied requirements |
| Data-grid regression | Empty/loading/error states, sorting, filtering | Observed state transitions and output after authorized interactions |

Record preconditions, expected results, observed results, and gaps. Scenario design is not test execution. If a transition requires an unsupported interaction, report the limitation and prepare a test for a separately verified runner.

## Prepare test code in an identified editor

These operations are appropriate only after the user asks for editing. They may bring Chrome to the foreground. Use an accessible editor in a QA tool or the opt-in disposable fixture; an application page is not assumed to contain a code editor. If the user opens a different page for editing, rediscover it and create a new binding first. Obtain the editor's exact accessible name from `$page.Editors`; multiple identical names are unsupported.

```powershell
$editorName = 'Disposable code editor' # Example name from the local fixture; use the observed name.
$before = Get-BrowserEditor @binding -EditorName $editorName
$before.Text
```

Read the existing test code and design the replacement. Store the intended code in a UTF-8 file; for example, create an ignored `artifacts/login-validation.spec.js` containing:

```javascript
import { test, expect } from '@playwright/test';

test('login shows required-field feedback', async ({ page }) => {
  await page.goto('https://example.test/login');
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(page.getByRole('alert')).toContainText('Email is required');
});
```

This is illustrative prepared code for a separate Playwright project, not a bundled runnable test. Replace the URL, accessible names, and expected message with the actual test environment and acceptance criteria. Review the effects of clicking the form action before any execution.

Then write with the captured fingerprint:

```powershell
$code = [IO.File]::ReadAllText((Join-Path $PWD 'artifacts/login-validation.spec.js'))
$result = Set-BrowserEditor @binding -EditorName $editorName `
    -ExpectedContentSha256 $before.ContentSha256 -Code $code
$result | Select-Object Written, Verified, Executed, ClipboardRestored
```

Expected successful state: `Written=True`, `Verified=True`, `Executed=False`, `ClipboardRestored=True`. The result also includes `PreviousText` for inspection; do not commit it. The tool rejects an editor that changed since capture.

CLI entry points return equivalent JSON; see the skill for `-CodePath` syntax. These commands never run the test. A failed write may leave modified text in the editor; inspect it before retrying. Restoration of editor contents is not automatic, because a concurrent user edit must not be overwritten.

## Review and execution

Show the prepared test code, explain the assertions, and state that it remains unexecuted. Ask for approval before form submission, saving application data, workflow-finalizing actions, or Run with unknown effects. Approval applies to the current test code/action plan, target environment, and page.

The bundled adapter does not implement Run/Submit. Following approval, an agent needs a separately verified same-page interaction capability; it must not open a welcome/connection page. Without that capability, let the user execute manually rather than pretending execution happened.

After an actual test run, inspect runner output and assertion results. Report execution attempted, execution completed, and assertions passed/failed separately. A prepared script, a successful editor transfer, or an old result on the page does not prove that a test passed.

## Troubleshooting

| Error | Resolution |
|---|---|
| Requires Windows / STA | Use an interactive Windows shell with `-STA` |
| No eligible Chrome window | Open/unminimize Chrome on the configured primary monitor yourself |
| Multiple/no visible HTTP(S) Documents | Accessibility provider/page is unsupported; stop rather than guessing |
| Context changed | Rediscover, report the page, and bind to its current URL/handle |
| No unique editor | Inspect accessible names; initial adapter requires one exact match |
| Focus refused or lost | Keep desktop unlocked and use same elevation; inspect current state before retrying |
| Copy did not expose text | Editor is unsupported; do not assume blank code |
| Content changed since capture | Capture and review the user's latest code |
| Readback differs | Inspect editor manually; no execution was requested |
| Clipboard restoration failed | Check clipboard manually; do not automatically retry |

Do not type or switch tabs during editor transfers. Guards reduce stale-target risk but cannot make desktop interaction atomic.
