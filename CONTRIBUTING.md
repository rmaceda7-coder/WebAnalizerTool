# Contributing

## Development setup

Clone the repository, open a PowerShell terminal in its root, and run:

```powershell
powershell.exe -NoProfile -STA -File tests/Run-Tests.ps1
pwsh -NoProfile -STA -File tests/Run-Tests.ps1
```

No third-party test packages are required. CI runs checks under both Windows PowerShell and PowerShell 7. Hosted runners do not validate a real Chrome UI or clipboard.

## Changes

1. Create a descriptive branch, such as `feat/edge-adapter` or `fix/editor-readback`.
2. Keep pure selection/context/hash logic testable without a desktop.
3. Keep OS interop separate from agent instructions and CLI wrappers.
4. Update documentation and CHANGELOG.md when behavior changes.
5. Verify desktop changes using the opt-in [manual scenarios](docs/verification-scenarios.md).
6. Inspect `git status` and `git diff`. Never include captured page contents, personal browser profiles, clipboard data, tokens, or real exercise drafts.
7. Submit a pull request describing verification and any focus/navigation/submission effects.

Use concise imperative commit subjects with optional conventional prefixes (`feat:`, `fix:`, `docs:`, `test:`). Keep changes scoped.

## Attribution

Retain Ramiro Maceda's creator signature and copyright. Do not invent contact fields. Consult the current LICENSE before redistributing the project.
