---
name: browser-code-editor
description: Prepares web automation test code in the identified browser editor, captures existing text, verifies replacements, and pauses for review before execution or state-changing actions.
---

# Edit, verify, and request review

1. For current-page tasks, load `active-browser-context` first. Load `mcp-tool-orchestration` and identify/report the session mode; for a verified managed session use the runner's identity. Analyze the application and test requirements using `web-page-analysis`. The script steps below apply to the Windows adapter only.
2. Editing tools require an editing request; desktop capture focuses the editor and temporarily uses the clipboard. Capture current code before designing a replacement:

   ```powershell
   powershell.exe -NoProfile -STA -File scripts/Get-BrowserEditor.ps1 -ExpectedUrl '<URL>' -ExpectedWindowHandle <handle> -EditorName '<exact accessible editor name>'
   ```

   If the name is unknown, inspect `Editors` from `Read-BrowserPage.ps1`. Multiple matching editors are an error, never "take first".
3. Explain the intended test scenarios, preconditions, and assertions. Keep existing useful work. When files are permitted, put the intended test code in a UTF-8 file outside tracked source, such as `artifacts/login-validation.spec.js`. Under a no-file instruction, prepare code in the response or use a verified in-memory transfer instead; do not invoke the file-backed CLI flow. Confirm the intended test framework and target environment rather than assuming the page provides a runner. Never include credentials.
4. Write using an exact URL, window handle, accessible name, and a SHA-256 precondition from the capture result:

   ```powershell
   powershell.exe -NoProfile -STA -File scripts/Set-BrowserEditor.ps1 -ExpectedUrl '<URL>' -ExpectedWindowHandle <handle> -EditorName '<exact name>' -ExpectedContentSha256 '<capture ContentSha256>' -CodePath artifacts/login-validation.spec.js
   ```

5. Check `Verified`, `ContentSha256`, `PreviousContentSha256`, and `ClipboardRestored`. A failed readback is a failure, not a completed edit. Do not blindly retry after failure; inspect current state first. Preserve `PreviousText` locally only as needed; never commit it.
6. Show the test code and explain its assertions. State explicitly that it has **not been run**. Ask for approval if execution would submit a form, save application data, finalize a workflow, or has unknown effects.

## Other editor transports

A verified runner may edit an explicitly identified editor when requested. Capture existing text before designing changes, use an unambiguous locator and stale-content precondition, preserve useful work, and read back the resulting text. Do not assume a successful fill/evaluate call proves the edit. Review script/API side effects and follow host permissions. Do not silently fall back to hidden textareas, guessed editor APIs, or another session when unsupported.

## Execution policy

- The bundled tooling has no execution/submit entry point. There is no automatic Ctrl+Enter.
- User approval applies to the current test code/action plan, environment, and planned routes only. A material code/effect change invalidates it.
- Test steps that submit forms, save records, or finalize workflows require explicit approval of their effects on the identified application.
- Run is allowed without approval only with affirmative evidence that it does not submit forms, change persistent application data, or finalize a workflow. A label or guessed keyboard shortcut is insufficient.
- After approval, use a verified transport in the agreed session. Same-page execution requires verified attachment to that page. Intentional connection/managed-session setup follows `docs/mcp-capabilities.md`; disclose setup effects and obtain approval where required rather than treating every connection page as forbidden. Never execute a different copy of the code without inspection and appropriate approval.

## Adapter limitations

The initial adapter supports one uniquely named, enabled, visible UI Automation Edit control with reliable Ctrl+A/C/V behavior. It validates focus and clipboard readback. It is not a universal Monaco/CodeMirror adapter. Stop on unsupported behavior. Do not select hidden textareas, send keys to the address bar, or use SetValue success as proof of an edit.
