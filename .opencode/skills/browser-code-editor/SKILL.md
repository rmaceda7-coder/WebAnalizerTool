---
name: browser-code-editor
description: Reads and edits code in the identified browser editor, verifies text, and pauses for user review before submit or completion-triggering execution.
---

# Edit, verify, and request review

1. Identify and report the current target using `active-browser-context`. Analyze the statement using `web-page-analysis`.
2. Editing tools require an editing request; desktop capture focuses the editor and temporarily uses the clipboard. Capture current code before designing a replacement:

   ```powershell
   powershell.exe -NoProfile -STA -File scripts/Get-BrowserEditor.ps1 -ExpectedUrl '<URL>' -ExpectedWindowHandle <handle> -EditorName '<exact accessible editor name>'
   ```

   If the name is unknown, inspect `Editors` from `Read-BrowserPage.ps1`. Multiple matching editors are an error, never "take first".
3. Explain the intended change. Keep existing useful work. Put the intended code in a UTF-8 file outside tracked source, such as `artifacts/query.sql`. Never include credentials.
4. Write using an exact URL, window handle, accessible name, and a SHA-256 precondition from the capture result:

   ```powershell
   powershell.exe -NoProfile -STA -File scripts/Set-BrowserEditor.ps1 -ExpectedUrl '<URL>' -ExpectedWindowHandle <handle> -EditorName '<exact name>' -ExpectedContentSha256 '<capture ContentSha256>' -CodePath artifacts/query.sql
   ```

5. Check `Verified`, `ContentSha256`, `PreviousContentSha256`, and `ClipboardRestored`. A failed readback is a failure, not a completed edit. Do not blindly retry after failure; inspect current state first. Preserve `PreviousText` locally only as needed; never commit it.
6. Show the code and the reasoning. State explicitly that it has **not been run or submitted**. Ask for approval if execution would submit, grade-as-delivery, complete the exercise, or has unknown semantics.

## Execution policy

- The bundled tooling has no execution/submit entry point. There is no automatic Ctrl+Enter.
- User approval applies to the current code, exercise, and page only. Any later edit invalidates it.
- SQL Practice Online Run is known to mark exercises complete. Ask first, even if the exercise was already completed.
- Run is allowed without approval only with affirmative evidence that it does not submit or complete an exercise. A label or guessed keyboard shortcut is insufficient.
- After approval, use a verified same-page transport if available. If the transport cannot do this without opening a connection page, explain the limitation.

## Adapter limitations

The initial adapter supports one uniquely named, enabled, visible UI Automation Edit control with reliable Ctrl+A/C/V behavior. It validates focus and clipboard readback. It is not a universal Monaco/CodeMirror adapter. Stop on unsupported behavior. Do not select hidden textareas, send keys to the address bar, or use SetValue success as proof of an edit.
