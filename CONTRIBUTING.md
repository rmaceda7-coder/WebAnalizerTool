# Contributing

## Development setup

Clone the repository, open a PowerShell terminal in its root, and run:

```powershell
powershell.exe -NoProfile -STA -File tests/Run-Tests.ps1
pwsh -NoProfile -STA -File tests/Run-Tests.ps1
node --test tests/browser-vision-mcp.test.mjs tests/editor-fixture.test.mjs
```

No third-party test packages are required. Node.js 22+ is needed for the MCP and fixture-server tests. CI runs both Node suites and checks under Windows PowerShell and PowerShell 7. Hosted runners do not validate a real Chrome UI or clipboard.

## Changes

All project documentation and guidelines must be written in English. Use English for headings, explanatory text, example prompts, templates, agent/skill instructions, changelog entries, and implementation records.

Frame examples and feature proposals around web test automation: smoke/regression coverage, form validation, accessibility observations, and user-workflow tests. Document whether a capability inspects state, prepares code, performs an interaction, or executes assertions; do not imply a test ran from generated code alone.

1. Use `main` for this project's work and authorized GitHub updates. Create or publish another branch only when explicitly requested by the user. Inspect local and remote history before publishing.
2. Keep pure selection/context/hash logic testable without a desktop.
3. Keep OS interop separate from agent instructions and CLI wrappers.
4. Update `CHANGELOG.md`, relevant usage/architecture documentation, and the [implementation history](docs/implementation-history.md) for every implementation or behavior/policy change.
5. Verify desktop changes using the opt-in [manual scenarios](docs/verification-scenarios.md).
6. Inspect `git status` and `git diff`. Never include captured page contents, personal browser profiles, clipboard data, tokens, or private test drafts.
7. Ask for GitHub synchronization approval after verification. Commit and push only when authorized; create a pull request only when explicitly requested. Publish the implementation and its traceability documentation together.

Use concise imperative commit subjects with optional conventional prefixes (`feat:`, `fix:`, `docs:`, `test:`). Keep changes scoped.

## Implementation traceability

Add a dated entry with a stable identifier to `docs/implementation-history.md`. Record:

- The requirement or problem and the implemented behavior.
- Affected source, tests, configuration, and documentation, linked with repository-relative paths.
- Exact verification commands, observed results, and any side effects or limitations.
- Manual checks still pending, clearly separated from completed automated checks.
- GitHub commit/PR links for already published changes. For the entry being committed, a GitHub file-history link provides traceability without needing to embed a commit's own hash in itself.

Keep `CHANGELOG.md` as the concise release summary and the implementation history as the detailed evidence index. Never include real browser content, clipboard data, credentials, or private URLs as evidence.

## Attribution

Retain Ramiro Maceda's creator signature and copyright. Do not invent contact fields. Consult the current LICENSE before redistributing the project.
