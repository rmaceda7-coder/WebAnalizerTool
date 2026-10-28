# Installation and usage

## Install for OpenCode

1. Install Git, Chrome, and OpenCode on Windows 10/11.
2. Clone `https://github.com/rmaceda7-coder/web-analyzer-and-acting-tool.git`.
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

## Capture and replace editor text

These operations are appropriate only after the user asks for editing. They may bring Chrome to the foreground. Obtain the editor's exact accessible name from `$page.Editors`; multiple identical names are unsupported.

```powershell
$editorName = 'SQL editor. Press F6 to move to results controls, or Shift+F6 to move to query controls.'
$before = Get-BrowserEditor @binding -EditorName $editorName
$before.Text
```

Read the existing code and design the replacement. Store the intended code in a UTF-8 file; for example, create an ignored `artifacts/query.sql` containing:

```sql
SELECT
    first_name,
    salary,
    ROUND(salary / 12.0, 2) AS monthly_salary
FROM employees;
```

Then write with the captured fingerprint:

```powershell
$code = [IO.File]::ReadAllText((Join-Path $PWD 'artifacts/query.sql'))
$result = Set-BrowserEditor @binding -EditorName $editorName `
    -ExpectedContentSha256 $before.ContentSha256 -Code $code
$result | Select-Object Written, Verified, Executed, ClipboardRestored
```

Expected successful state: `Written=True`, `Verified=True`, `Executed=False`, `ClipboardRestored=True`. The result also includes `PreviousText` for inspection; do not commit it. The tool rejects an editor that changed since capture.

CLI entry points return equivalent JSON; see the skill for `-CodePath` syntax. These commands never run the query. A failed write may leave modified text in the editor; inspect it before retrying. Restoration of editor contents is not automatic, because a concurrent user edit must not be overwritten.

## Review and execution

Show the final code and state that it remains unexecuted. Ask for approval before Submit or a Run that grades/completes the exercise. On SQL Practice Online, Run completes the exercise and requires approval.

The bundled adapter does not implement Run/Submit. Following approval, an agent needs a separately verified same-page interaction capability; it must not open a welcome/connection page. Without that capability, let the user execute manually rather than pretending execution happened.

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
