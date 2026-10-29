---
name: browser-code-editor
description: Prepares web automation test code in the identified browser editor, captures existing text, verifies replacements, and pauses for review before execution or state-changing actions.
---

# Edit, verify, and request review

1. Identify and report the current target using `active-browser-context`. Analyze the application and test requirements using `web-page-analysis`.
2. Editing tools require an editing request; desktop capture focuses the editor and temporarily uses the clipboard. Capture current code before designing a replacement:

   ```powershell
   powershell.exe -NoProfile -STA -File scripts/Get-BrowserEditor.ps1 -ExpectedUrl '<URL>' -ExpectedWindowHandle <handle> -EditorName '<exact accessible editor name>'
   ```

   If the name is unknown, inspect `Editors` from `Read-BrowserPage.ps1`. Multiple matching editors are an error, never "take first".
3. Explain the intended test scenarios, preconditions, and assertions. Keep existing useful work. Put the intended test code in a UTF-8 file outside tracked source, such as `artifacts/login-validation.spec.js`. Confirm the intended test framework and target environment rather than assuming the page provides a runner. Never include credentials.
4. Write using an exact URL, window handle, accessible name, and a SHA-256 precondition from the capture result:

   ```powershell
   powershell.exe -NoProfile -STA -File scripts/Set-BrowserEditor.ps1 -ExpectedUrl '<URL>' -ExpectedWindowHandle <handle> -EditorName '<exact name>' -ExpectedContentSha256 '<capture ContentSha256>' -CodePath artifacts/login-validation.spec.js
   ```

5. Check `Verified`, `ContentSha256`, `PreviousContentSha256`, and `ClipboardRestored`. A failed readback is a failure, not a completed edit. Do not blindly retry after failure; inspect current state first. Preserve `PreviousText` locally only as needed; never commit it.
6. Show the test code and explain its assertions. State explicitly that it has **not been run**. Ask for approval if execution would submit a form, save application data, finalize a workflow, or has unknown effects.

## Execution policy

- The bundled tooling has no execution/submit entry point. There is no automatic Ctrl+Enter.
- User approval applies to the current test code/action plan, environment, and page only. Any later edit invalidates it.
- Test steps that submit forms, save records, or finalize workflows require explicit approval of their effects on the identified application.
- Run is allowed without approval only with affirmative evidence that it does not submit forms, change persistent application data, or finalize a workflow. A label or guessed keyboard shortcut is insufficient.
- After approval, use a verified same-page transport if available. If the transport cannot do this without opening a connection page, explain the limitation.

## Adapter limitations

The initial adapter supports one uniquely named, enabled, visible UI Automation Edit control with reliable Ctrl+A/C/V behavior. It validates focus and clipboard readback. It is not a universal Monaco/CodeMirror adapter. Stop on unsupported behavior. Do not select hidden textareas, send keys to the address bar, or use SetValue success as proof of an edit.
