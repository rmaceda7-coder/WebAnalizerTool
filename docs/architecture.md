# Architecture

## Web testing scope

The project supports web test automation through application inspection, scenario/assertion design, evidence collection, and guarded preparation of test code. The Windows adapter implements discovery, accessibility reading, viewport capture, and editor transfer. General clicks, form entry, navigation, and end-to-end execution require separately implemented, verified capabilities. Reports must distinguish proposed scenarios, prepared scripts, observed UI state, and executed assertion results.

## Layers

1. **Operating contract:** AGENTS.md records monitor selection, passive discovery, and approval policy.
2. **OpenCode agent:** `.opencode/agents/web-analyzer.md` coordinates relevant skills; project config selects it as the default primary agent.
3. **Skills:** context discovery, page analysis, editor capture/write/review.
4. **CLI:** `scripts/*.ps1` provides JSON wrappers with mandatory target preconditions.
5. **Adapter:** `src/WindowsBrowser.psm1` implements UI Automation and editor transfer; `NativeDesktop.cs` isolates Win32 monitor/Z-order/focus calls.
6. **Verification:** dependency-free checks run in Windows PowerShell 5.1 and PowerShell 7. Manual tests cover the real desktop.

## Target identity

Native EnumWindows supplies top-to-bottom Z-order. MonitorFromWindow/GetMonitorInfo identifies the monitor with the greatest overlap for each window. Only primary-monitor Chrome window candidates are retained. Minimized, cloaked, invisible, and untitled windows are rejected. Global foreground focus does not override this policy.

UI Automation must expose exactly one visible HTTP(S) Document. Its URL, native window handle, monitor identity, and page title form the reported context. Commands re-resolve and compare URL/handle before operating and again after reading/transferring. A changed URL (including path case or test-scenario query parameters) invalidates the binding.

The binding is not a stable browser tab ID: two tabs can share the same URL, or a page may mutate without URL changes. The content fingerprint additionally protects editor writes. A future CDP/extension adapter may add stable tab/document IDs, but only if it can attach without side-effect navigation.

## Visual capture

The project-local `browser_vision` MCP (`scripts/browser-vision-mcp.mjs`) uses Node.js 22+ standard-library stdio JSON-RPC. It exposes discovery, accessibility reading, and capture only. Script paths resolve relative to the server file, not the client's working directory. OpenCode launches it from the project root via `opencode.json`; restarting OpenCode is required after configuration changes.

`Get-BrowserPageImage.ps1` calls `Get-BrowserPageImage` in the Windows adapter. The operation binds the expected primary-monitor window/URL, temporarily sets the calling thread's DPI awareness for physical coordinates, calls `PrintWindow(PW_RENDERFULLCONTENT)`, and crops to the UI Automation Document bounds. It captures the Chrome surface even when another application overlaps it; it never uses desktop `CopyFromScreen`. It checks viewport/window bounds and target identity again, releases GDI resources, and restores thread DPI context in `finally`.

PNG encoding and base64 transfer are in memory. The bridge translates the JSON result into MCP `image` content plus text metadata. It does not write screenshot files or print image data in logs. OpenCode sessions and the model provider may retain the image according to their configuration; in-memory capture does not imply zero downstream retention.

Uniform/black viewport detection is a sampled-color heuristic. It deliberately excludes Chrome tabs/toolbars, whose varied colors could otherwise hide a black page surface. It cannot verify every region rendered correctly, identify the meaning of pixels, or detect all partially blank GPU content. A genuinely uniform page also fails this check. Captures are viewport-only, not full-page; there is no automatic scroll, focus, navigation, editor action, or secondary-monitor fallback. The existing same-URL tab/in-place-content identity limitations apply.

Tool errors are returned explicitly without image content. Runtime process limits bound capture time and stdout size. The bridge requires Windows PowerShell 5.1 and uses execution-policy bypass only for that child process. The MCP supports newline-delimited stdio, not HTTP/network listening. MCP annotations declare read-only behavior; host permissions still apply.

## Editor transfer

```text
bind page -> unique editor -> materialize clipboard snapshot -> focus target
-> select/copy current code -> check expected content hash
-> recheck page/focus -> paste -> select/copy readback -> compare hash
-> recheck page -> collapse selection -> restore clipboard -> report
```

Get-BrowserEditor uses the same transfer without paste. Hashing normalizes CRLF/CR to LF but preserves other whitespace and code differences. Clipboard copy is used because some browser editors expose an empty ValuePattern or their accessible label rather than their code. A sentinel detects stale clipboard data. A silent SetValue call is never treated as proof.

No automatic execution occurs. Focus changes are deliberate only during editor operations, after passive target discovery. Clipboard restoration happens in finally, with restoration status reported on success and a warning on failure.

### Transfer verification boundary

`New-EditorDesktop` supplies private scriptblock operations for page/editor binding, clipboard snapshot/restore, focus checks, keyboard input, clipboard text, polling delay, and accessibility confirmation of emptiness. `Invoke-EditorTransfer` and `Copy-EditorText` run the same orchestration with either those operations or a fully simulated desktop. Public editor commands always select the real operations; injection is not exposed as a CLI option or a new browser adapter.

`tests/EditorTransfer.Tests.ps1` replaces every desktop operation, including delays, and runs real transfer orchestration with an in-memory editor/clipboard. These tests verify guard ordering, failure propagation, bounded polling, restoration attempts, and no blind retry/rollback. They do not prove Windows focus behavior, clipboard format fidelity, Chrome accessibility support, or keyboard delivery. The opt-in [local editor procedure](verification-scenarios.md#disposable-local-editor-fixture) covers the separate desktop boundary.

## Approval boundary

The agent's behavioral contract distinguishes independently verified Run operations from form submission, persistent application changes, and workflow completion. Approval is scoped to the current test code/action plan, environment, and page. Bundled scripts expose no execution or submission capability. This is not a sandbox: inherited global tools can still perform actions, so their use must follow the contract. There is no persistent "approved" flag that can accidentally authorize a future code revision.

## Limitations

- Windows 10/11 desktop and Chrome only. No headless or service session support.
- Foremost **Chrome** window on primary monitor is selected even if another app is in front of it. No secondary page content is traversed. The user must resolve any mismatch between "monitor 1" and Windows' configured primary display.
- Spanning windows use Windows' largest-overlap monitor assignment.
- UI Automation visibility/document semantics vary; ambiguous pages fail closed rather than guessing.
- Exact editor naming and reliable Ctrl+A/C/V are required. There is no claim of universal CodeMirror/Monaco support.
- A truly empty editor whose accessibility text and copy behavior do not expose emptiness is unsupported.
- Focus and clipboard calls are desktop-wide and non-atomic; user activity can race with them. Do not interact with the desktop during transfers.
- Materialized clipboard snapshots preserve ordinary text/files/images where supported; delayed rendering, app-private formats, clipboard managers/history/cloud sync may not be fully reversible. A successful API restore does not guarantee every external clipboard consumer is unchanged.
- Clipboard or editor failures do not trigger blind retries or automatic editor rollback.
- URL/handle checks cannot distinguish all same-URL tab switches or in-place application-state changes.
- Automated CI checks policy/logic/syntax/compilation, not live desktop automation or the OpenCode runtime loader.

## Extension contract

A future adapter must expose passive context discovery, bound page reading, editor capture, guarded writing, and verified readback. Document OS/browser requirements, target identity, focus/navigation effects, and unsupported cases. Add deterministic selection tests and opt-in manual scenarios. Never silently substitute a launched browser session for the user's existing one.
