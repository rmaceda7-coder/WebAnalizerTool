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
- GitHub Actions: the Windows verification job passed both PowerShell steps on `main` and `feat/initial-project` after publication. Current status is available on the repository's Actions tab.

Live editor transfer was not exercised against the user's current page during project setup. It is not covered by unattended CI. Do not interpret the manual scenarios listed above as already executed evidence.

Visual extension verification on Windows, 2026-10-29:

- Windows PowerShell 5.1 and PowerShell 7: all 36 checks passed in each runtime.
- Node.js 24: all 5 MCP transport tests passed, including real stdio request/response framing.
- Live passive capture through the bridge returned a valid PNG image content block, 2561 x 1347 pixels, without writing an image file. This confirms capture/transport, not the model's interpretation of its pixels.
- OpenCode's restarted MCP loader/model-image interpretation and the mixed-DPI/overlap manual scenarios below remain to be verified in the new session.

## Direct visual capture (opt-in desktop check)

1. Restart OpenCode from the project root using an image-capable model. Confirm `browser_vision` connects without opening/focusing Chrome or creating a tab.
2. Keep a page with a visible image/table in the foremost eligible primary-display Chrome window. Use `get_primary_browser_context` and report its title/URL/device.
3. Call `capture_browser_page` with that exact URL/handle. Confirm the model receives image content and can read an actual label/value from the table, rather than just reporting PNG metadata.
4. Repeat with a terminal overlapping Chrome. The returned image should show the page viewport, not the terminal, and keyboard focus/clipboard/page selection must remain unchanged.
5. Check mixed-DPI displays and a resized primary-monitor window. Image dimensions must correspond to the page viewport with no toolbar included or clipping caused by scale.
6. Change the selected page URL before calling capture with the old binding: expect an error and no image. A same-URL/in-place content change cannot always be detected; use fresh captures.
7. Confirm no screenshot file appears in the repository. If the viewport is clipped/unreadable, the agent must say so and not infer missing values. A denied tool must not trigger a permission-bypass workaround.

Automated transport tests use synthetic image payloads and do not inspect the desktop. This live procedure is necessary to validate rendering and model vision end to end on the installed OpenCode version.
