# Verification scenarios

## Automated checks (no browser mutation)

```powershell
powershell.exe -NoProfile -STA -File tests/Run-Tests.ps1
pwsh -NoProfile -STA -File tests/Run-Tests.ps1
```

Checks cover primary-monitor priority, Z-order, excluded windows, missing browser behavior, stale URL/window rejection, exact URL comparison, normalized hashes, PowerShell syntax, agent/skill configuration, and native C# compilation. They do not read actual page contents or touch the clipboard.

## Optional passive smoke check

With Chrome open on the primary display, run `scripts/Get-PrimaryBrowserContext.ps1`, then `scripts/Read-BrowserPage.ps1` with returned URL/handle. Verify the title/URL correspond to the selected page and that focus, tabs, URL, session, and clipboard remain unchanged. Do not save real page contents in Git.

## Opt-in manual editor checks

Perform these only on an explicitly authorized disposable editor. The user should expect Chrome to receive focus and clipboard contents to be temporarily replaced. Do not use production forms or submit exercise answers as tests.

| Scenario | Expected evidence |
|---|---|
| Terminal focused on display 2, Chrome on primary | Discovery selects primary Chrome; terminal focus remains during discovery/read |
| Chrome only on secondary | Clear missing-primary-Chrome error; no fallback |
| Two overlapping primary Chrome windows | Highest eligible Chrome is selected |
| Primary Chrome minimized/cloaked | Excluded; no unminimize or workspace switching |
| Tab changes after discovery | Read/write rejects stale URL/handle |
| Two visible Documents or duplicate editor names | Ambiguity error; no guessed edit |
| Existing code changes after capture | Fingerprint mismatch; no paste |
| Quotes, accents, brackets, multiple lines | Readback matches intended code; no keyboard-layout corruption |
| Empty editor unsupported by accessibility/copy | Explicit failure, never guessed as blank |
| User steals focus during transfer | Stop at next focus guard; report actual state |
| Ordinary text in clipboard before edit | Text restored afterward; `ClipboardRestored=True` |
| Write succeeds | New code visible; `Executed=False`; no result/completion change |
| SQL Practice Online Run requested without approval | Agent pauses and asks before action |
| Approval followed by code revision | Old approval not reused |
| Unverified Run semantics | Agent asks instead of assuming independence |

## Verification record

Initial local verification on Windows, 2026-10-28:

- Windows PowerShell 5.1: all 31 checks passed. The restrictive local policy required `-ExecutionPolicy Bypass` for that process only; no persistent policy was changed.
- PowerShell 7.6.9: all 31 checks passed.
- OpenCode 1.19.1: `opencode agent list` successfully loaded `web-analyzer (primary)` and discovered the three project skill directories.
- Passive native/UI Automation discovery: identified the existing Chrome selected page on the Windows primary display while another application held foreground focus. No browser tab was opened or navigated, and no editor was modified.

Live editor transfer was not exercised against the user's current page during project setup. It is not covered by unattended CI. Do not interpret the manual scenarios listed above as already executed evidence.
