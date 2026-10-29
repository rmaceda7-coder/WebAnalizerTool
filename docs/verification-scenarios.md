# Verification scenarios

## Automated checks (no browser mutation)

```powershell
powershell.exe -NoProfile -STA -File tests/Run-Tests.ps1
pwsh -NoProfile -STA -File tests/Run-Tests.ps1
node --test tests/browser-vision-mcp.test.mjs tests/editor-fixture.test.mjs
```

Checks cover primary-monitor priority, Z-order, excluded windows, missing browser behavior, stale URL/window rejection, exact URL comparison, normalized hashes, PowerShell syntax, agent/skill configuration, and native C# compilation. Editor-transfer tests inject all desktop operations and cover capture/replacement, Unicode/multiline code, changed fingerprints, stale context at each binding, ambiguous editors, clipboard snapshot/set/read/restore failures, refused/lost focus, unsupported copy, confirmed/unconfirmed empty editors, delayed copy, paste failure, and readback mismatch. They do not read actual page contents or touch the clipboard.

Node tests exercise the MCP transport and the fixture HTTP server. The fixture server test listens briefly on loopback but never opens a browser or invokes the desktop adapter. Both PowerShell suites and both Node test files run in CI.

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

### Disposable local editor fixture

This is an **opt-in manual desktop check**, separate from `Run-Tests.ps1` and CI. It may focus Chrome and temporarily replace the clipboard. Use synthetic code and ordinary disposable clipboard text. No step runs, submits, or grades code.

1. From the project root, start the dependency-free local server:

   ```powershell
   node tests/Serve-EditorFixture.mjs
   ```

   It prints an HTTP URL with a random available port and listens only on `127.0.0.1`. It does not open Chrome. Open the printed URL **manually** in Chrome on the primary monitor. Keep the editor visible. Do not open `editor.html` as a `file:` URL; the adapter intentionally identifies only HTTP(S) pages.

2. In a second interactive STA shell at the same elevation as Chrome, identify the target:

   ```powershell
   Import-Module ./src/WindowsBrowser.psm1 -DisableNameChecking
   $context = Get-PrimaryBrowserContext
   $context | ConvertTo-Json -Depth 6
   ```

   Confirm the title is `Web Analyzer disposable editor fixture`, the URL matches the printed local URL, and the reported monitor is primary before continuing.

3. Read the bound page and capture its editor:

   ```powershell
   $binding = @{ ExpectedUrl = $context.Url; ExpectedWindowHandle = $context.WindowHandle }
   $page = Read-BrowserPage @binding
   $page.Editors | Format-Table
   $before = Get-BrowserEditor @binding -EditorName 'Disposable code editor'
   $before | Select-Object Text, ContentSha256, Written, Verified, Executed, ClipboardRestored
   ```

   Verify sample code is captured, `Written=False`, `Verified=True`, `Executed=False`, and the original clipboard is restored. If the browser does not expose the textarea's exact accessible name or reliable copy behavior, record it as unsupported rather than assuming success.

4. Replace synthetic code and inspect the actual editor and readback:

   ```powershell
   $result = Set-BrowserEditor @binding -EditorName 'Disposable code editor' `
     -ExpectedContentSha256 $before.ContentSha256 -Code "SELECT 'fixture';`nSELECT 2;"
   $result | Select-Object Text, PreviousText, Written, Verified, Executed, ClipboardRestored
   ```

   Expect `Written=True`, `Verified=True`, `Executed=False`, `ClipboardRestored=True`, and matching text. Do not type or switch tabs during a transfer. Test `-Code ''` separately; confirm empty readback or document an explicit unsupported-editor error.

5. Reset or reload between scenarios. Toggle only one failure simulation at a time **before** starting the next transfer:

   | Fixture action | Expected observation |
   |---|---|
   | Capture code, then manually edit it before replacement | Old fingerprint is rejected; manual edits remain |
   | Capture binding, then click **Change exercise URL** | Old URL binding is rejected; rediscover before continuing |
   | Enable duplicate editor | Both editors must be visible; ambiguity is rejected before input |
   | Enable **Block copying**, keeping nonempty code | Copy times out explicitly; no paste; clipboard restored |
   | Enable **Move focus outside the editor after the next copy** | Next focus guard rejects the transfer; no further keyboard input |
   | Enable **Replace pasted text** | Readback mismatch; marker remains for inspection; no automatic retry/rollback |
   | Click **Clear editor**, then capture/replace | Empty content must be confirmed through accessibility; otherwise an explicit unsupported error |

   Real clipboard API failures are tested through injection, not by disrupting the system clipboard manually. UI/browser event timing and clipboard-manager behavior still require real-desktop observation.

6. Stop the server with Ctrl+C and close the fixture manually. Record runtime/Chrome versions, scenario, observed editor state, and restoration status using synthetic evidence only. Do not claim these manual scenarios passed based on automated results.

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

Editor-transfer test extension verification on Windows, 2026-10-29:

- Windows PowerShell 5.1 and PowerShell 7: all 118 checks passed in each runtime, including fully simulated editor-transfer failure scenarios. The local Windows PowerShell execution policy required the documented process-only `-ExecutionPolicy Bypass` invocation.
- Node.js 24.20.0: all 6 tests passed across the MCP transport and loopback fixture server suites.
- Hosted verification: [Verify run 40934112636](https://github.com/rmaceda7-coder/WebAnalizerTool/actions/runs/40934112636) passed the Node.js 22 suite and both PowerShell steps for implementation commit [fc2dfcb](https://github.com/rmaceda7-coder/WebAnalizerTool/commit/fc2dfcb8204b46a656894c0f97cfcd78c4961a25).
- `git diff --check` passed. Automated checks did not open Chrome, inspect page contents, change desktop focus, or access the real clipboard.
- The disposable fixture's live Chrome/UI Automation scenarios have not been executed; the manual procedure above is not a claim of compatibility or successful desktop verification.

## Direct visual capture (opt-in desktop check)

1. Restart OpenCode from the project root using an image-capable model. Confirm `browser_vision` connects without opening/focusing Chrome or creating a tab.
2. Keep a page with a visible image/table in the foremost eligible primary-display Chrome window. Use `get_primary_browser_context` and report its title/URL/device.
3. Call `capture_browser_page` with that exact URL/handle. Confirm the model receives image content and can read an actual label/value from the table, rather than just reporting PNG metadata.
4. Repeat with a terminal overlapping Chrome. The returned image should show the page viewport, not the terminal, and keyboard focus/clipboard/page selection must remain unchanged.
5. Check mixed-DPI displays and a resized primary-monitor window. Image dimensions must correspond to the page viewport with no toolbar included or clipping caused by scale.
6. Change the selected page URL before calling capture with the old binding: expect an error and no image. A same-URL/in-place content change cannot always be detected; use fresh captures.
7. Confirm no screenshot file appears in the repository. If the viewport is clipped/unreadable, the agent must say so and not infer missing values. A denied tool must not trigger a permission-bypass workaround.

Automated transport tests use synthetic image payloads and do not inspect the desktop. This live procedure is necessary to validate rendering and model vision end to end on the installed OpenCode version.
