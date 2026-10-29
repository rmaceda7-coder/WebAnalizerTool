# Implementation history and traceability

This index records why changes were made, where they were implemented, and what verification supports them. The [changelog](../CHANGELOG.md) provides the release summary; [verification scenarios](verification-scenarios.md) contain commands, historical observations, and opt-in desktop procedures.

Every new implementation or behavior/policy change must add a dated entry here and update the relevant documentation. Link published commits/PRs or GitHub file history so the evidence remains traceable. An automated result does not establish live browser compatibility. GitHub Actions results belong to their exact commit and must be checked separately after publication.

## WAT-005 — Web test automation purpose and QA-focused examples

- **Date:** 2026-10-29
- **Release:** 0.2.0 (unreleased)
- **Baseline:** [0845b21](https://github.com/rmaceda7-coder/WebAnalizerTool/commit/0845b21787f0a149011bca21437ad50bb2ea50ba), with the accompanying English-only documentation update tracked in WAT-004.
- **Implementation history:** [agent history](https://github.com/rmaceda7-coder/WebAnalizerTool/commits/main/.opencode/agents/web-analyzer.md), [fixture history](https://github.com/rmaceda7-coder/WebAnalizerTool/commits/main/tests/fixtures/editor.html), and [this record's history](https://github.com/rmaceda7-coder/WebAnalizerTool/commits/main/docs/implementation-history.md)

### Requirement and changes

The user clarified that the primary objective is automated web testing. Reframed documentation and agent guidance around inspecting applications, designing smoke/regression/validation/accessibility scenarios, preparing automation code, and comparing expected versus observed behavior. Replaced answer-selection and academic-task examples with login validation, dashboard checks, data-grid scenarios, and Playwright assertions.

The capability boundary is explicit: the shipped runtime implements passive page inspection and guarded editor transfers. General web interaction and end-to-end test execution need separate verified capabilities. Prepared code and observed UI state do not establish an executed or passed test. State-changing action approval is scoped to the current test code/action plan, environment, and page.

Updated the disposable fixture to show test assertions and identify a test scenario through the `scenario` query parameter. The server's printed URL, HTTP test URL, synthetic MCP binding, PowerShell context tests, and manual procedure now use application/test-scenario terminology. Historical records retain their original verification results; their example terminology is aligned with the current project purpose.

### Affected files

| Area | Files |
|---|---|
| Purpose, action controls, and contributor guidance | [`README.md`](../README.md), [`AGENTS.md`](../AGENTS.md), [`CONTRIBUTING.md`](../CONTRIBUTING.md) |
| Agent and workflow instructions | [`.opencode/agents/web-analyzer.md`](../.opencode/agents/web-analyzer.md), [page-analysis skill](../.opencode/skills/web-page-analysis/SKILL.md), [code-editor skill](../.opencode/skills/browser-code-editor/SKILL.md) |
| QA walkthrough and capability boundaries | [`docs/usage.md`](usage.md), [`docs/architecture.md`](architecture.md), [`docs/roadmap.md`](roadmap.md), [`docs/verification-scenarios.md`](verification-scenarios.md) |
| Fixture and synthetic bindings | [`tests/fixtures/editor.html`](../tests/fixtures/editor.html), [`tests/Serve-EditorFixture.mjs`](../tests/Serve-EditorFixture.mjs), [`tests/editor-fixture.test.mjs`](../tests/editor-fixture.test.mjs), [`tests/browser-vision-mcp.test.mjs`](../tests/browser-vision-mcp.test.mjs), [`tests/Run-Tests.ps1`](../tests/Run-Tests.ps1) |
| Change evidence | [`CHANGELOG.md`](../CHANGELOG.md), this implementation record |

### Verification and pending checks

- `powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File tests/Run-Tests.ps1`: all 118 checks passed, including the renamed test-scenario URL bindings.
- `pwsh.exe -NoProfile -STA -File tests/Run-Tests.ps1`: all 118 checks passed.
- `node --test tests/browser-vision-mcp.test.mjs tests/editor-fixture.test.mjs`: all 6 tests passed with the updated fixture and MCP binding examples.
- `opencode agent list`: completed successfully and listed `web-analyzer (primary)` with the project-local skill directories.
- `git diff --check`: passed. A terminology review confirmed that examples now use web test scenarios; the targeted documentation-language scan returned no Spanish text.
- Restart OpenCode to load the updated agent and skill instructions. Live application interactions, test-runner execution, and the updated fixture's desktop scenarios have not been performed by this change.
- The user authorized committing and pushing WAT-005 together with WAT-004 to `main`. The file-history links identify the publication revision; hosted verification must be checked for that exact commit.

## WAT-004 — English-only documentation and guidelines

- **Date:** 2026-10-29
- **Release:** 0.2.0 (unreleased)
- **Baseline:** [0845b21](https://github.com/rmaceda7-coder/WebAnalizerTool/commit/0845b21787f0a149011bca21437ad50bb2ea50ba)
- **Implementation history:** [README history](https://github.com/rmaceda7-coder/WebAnalizerTool/commits/main/README.md) and [this record's history](https://github.com/rmaceda7-coder/WebAnalizerTool/commits/main/docs/implementation-history.md)

### Requirement and changes

The user identified Spanish text in the README and requested that all documentation and guidelines be in English. Reviewed the tracked Markdown documentation, including GitHub templates and project-local agent/skill instructions. Translated the remaining README example prompts and creator/contact labels. Replaced the operating contract's non-English example phrases with English guidance that applies regardless of the request language.

Established English as the required language for documentation and guidelines, including headings, explanatory text, example prompts, templates, agent/skill instructions, changelogs, and implementation records.

### Affected files

- [`README.md`](../README.md): English examples and attribution labels; explicit documentation-language statement.
- [`AGENTS.md`](../AGENTS.md): English-only documentation requirement and English wording for language-independent browser targeting.
- [`CONTRIBUTING.md`](../CONTRIBUTING.md): documentation-language requirement for contributors.
- [`CHANGELOG.md`](../CHANGELOG.md): release summary of the documentation update.
- This implementation record: requirement, scope, evidence, and publication traceability.

### Verification and publication

- Reviewed the tracked Markdown documentation, templates, and agent/skill instructions. A targeted search for the remaining Spanish labels, example phrases, and accented characters returned no matches after translation.
- `powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File tests/Run-Tests.ps1`: all 118 checks passed.
- `pwsh.exe -NoProfile -STA -File tests/Run-Tests.ps1`: all 118 checks passed.
- `node --test tests/browser-vision-mcp.test.mjs tests/editor-fixture.test.mjs`: all 6 tests passed.
- `git diff --check`: passed.
- No live browser/editor checks were performed for this documentation-only change; the pending desktop scenarios remain recorded in WAT-003.
- The user authorized publication together with WAT-005 on `main`. The file-history links identify the publication revision.

## WAT-003 — Editor-transfer reliability coverage and publication traceability

- **Date:** 2026-10-29
- **Release:** 0.2.0 (unreleased)
- **Baseline:** [4ceb144](https://github.com/rmaceda7-coder/WebAnalizerTool/commit/4ceb144)
- **Implementation commit:** [fc2dfcb](https://github.com/rmaceda7-coder/WebAnalizerTool/commit/fc2dfcb8204b46a656894c0f97cfcd78c4961a25)
- **Documentation/evidence updates:** [this record's history](https://github.com/rmaceda7-coder/WebAnalizerTool/commits/main/docs/implementation-history.md)

### Requirement and outcome

The project review identified a verification gap: clipboard- and focus-sensitive editor transfers lacked deterministic failure coverage. The user requested this improvement, followed by publication of all current updates and documentation of new implementations on GitHub for traceability.

Implemented:

- Private injectable desktop operations for binding, clipboard snapshot/restore, focus, keyboard input, polling, and accessibility confirmation of an empty editor. Public editor commands select the real operations; automated tests use an entirely simulated desktop.
- Transfer tests covering capture/replacement, changed fingerprints, stale target bindings before/after replacement, ambiguous editors, clipboard failures, refused/lost focus, unsupported/delayed copy, empty editor/replacement behavior, Unicode/multiline code, paste failure, and readback mismatch.
- Assertions that failures do not trigger blind retries/rollback and that clipboard restoration is attempted after a successful snapshot, with restoration failure reported distinctly.
- A disposable HTML editor and opt-in loopback server with simulations for duplicate editors, blocked copy, focus loss, changed URL binding, and corrupted paste. The server does not launch a browser and serves only the fixture route.
- CI coverage for the fixture server alongside existing MCP and PowerShell checks.
- Publication of the latest operating-contract clarifications: passive discovery must not open connection pages or launch a substitute browser, and writing code does not authorize submission/completion-triggering execution. These are agent policy clarifications, not a new execution adapter or sandbox.
- An ongoing requirement to document implementations, affected files, verification evidence, and pending checks with each authorized GitHub update. Contributor guidance now matches the project's `main` publication contract.

### Affected files

| Area | Files |
|---|---|
| Transfer implementation | [`src/WindowsBrowser.psm1`](../src/WindowsBrowser.psm1) |
| Deterministic tests and runner | [`tests/EditorTransfer.Tests.ps1`](../tests/EditorTransfer.Tests.ps1), [`tests/Run-Tests.ps1`](../tests/Run-Tests.ps1) |
| Disposable fixture and server | [`tests/fixtures/editor.html`](../tests/fixtures/editor.html), [`tests/Serve-EditorFixture.mjs`](../tests/Serve-EditorFixture.mjs), [`tests/editor-fixture.test.mjs`](../tests/editor-fixture.test.mjs) |
| Hosted verification | [`.github/workflows/verify.yml`](../.github/workflows/verify.yml) |
| Usage, boundaries, and evidence | [`README.md`](../README.md), [`docs/architecture.md`](architecture.md#transfer-verification-boundary), [`docs/verification-scenarios.md`](verification-scenarios.md#disposable-local-editor-fixture), [`docs/roadmap.md`](roadmap.md) |
| Policy and traceability | [`AGENTS.md`](../AGENTS.md), [`CONTRIBUTING.md`](../CONTRIBUTING.md), [`CHANGELOG.md`](../CHANGELOG.md), this record |

### Completed local verification

| Command | Observed result |
|---|---|
| `powershell.exe -NoProfile -STA -File tests/Run-Tests.ps1` | Blocked by the local execution policy before tests ran |
| `powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File tests/Run-Tests.ps1` | All 118 checks passed; bypass applied to that process only |
| `pwsh.exe -NoProfile -STA -File tests/Run-Tests.ps1` | All 118 checks passed |
| `node --test tests/browser-vision-mcp.test.mjs tests/editor-fixture.test.mjs` | All 6 tests passed on Node.js 24.20.0 |
| `git diff --check` | Passed |

The automated checks did not open Chrome, read browser content, change desktop focus, or access the real clipboard. The fixture-server test briefly listened on loopback. Node.js 22 is the configured hosted CI version; local Node.js 24 results are not a substitute for the hosted result. [Workflow runs](https://github.com/rmaceda7-coder/WebAnalizerTool/actions/workflows/verify.yml) identify the exact verified commit.

### Completed hosted verification

- The implementation and documentation were pushed to `main` in [fc2dfcb](https://github.com/rmaceda7-coder/WebAnalizerTool/commit/fc2dfcb8204b46a656894c0f97cfcd78c4961a25).
- [Verify run 40934112636](https://github.com/rmaceda7-coder/WebAnalizerTool/actions/runs/40934112636) completed successfully for that exact commit. The Windows job passed the Node.js 22 MCP/fixture-server tests, Windows PowerShell 5.1 tests, and PowerShell 7 tests.
- Observed with `gh run watch 40934112636 --exit-status --interval 10`; the command exited successfully. This evidence was recorded in a subsequent documentation-only commit; it describes the implementation commit above.

### Pending manual evidence and limitations

- Live Chrome/UI Automation tests against the disposable fixture have not been performed. Follow the [opt-in procedure](verification-scenarios.md#disposable-local-editor-fixture) and record actual observations before claiming editor compatibility.
- Simulation verifies orchestration, not Windows clipboard format fidelity, focus behavior, Chrome accessibility, or keyboard delivery. Real-desktop operations remain non-atomic.
- Stable same-URL tab/document identity and structured partial-write error reporting remain separate improvements; these tests do not establish those capabilities.

## WAT-002 — Direct browser image analysis

- **Date:** 2026-10-29
- **Release:** 0.2.0 (unreleased)
- **Implementation:** [933c688](https://github.com/rmaceda7-coder/WebAnalizerTool/commit/933c688)

- **Requirement:** inspect visible image-based tables, charts, and diagrams without screenshot-file round trips or navigation/focus changes.
- **Implementation:** the project-local MCP in [`scripts/browser-vision-mcp.mjs`](../scripts/browser-vision-mcp.mjs), bound capture entry point [`scripts/Get-BrowserPageImage.ps1`](../scripts/Get-BrowserPageImage.ps1), and Windows adapter return cropped PNG content in memory with target/bounds rechecks and uniform-image rejection.
- **Verification:** [`tests/browser-vision-mcp.test.mjs`](../tests/browser-vision-mcp.test.mjs) and synthetic image checks; the [historical verification record](verification-scenarios.md#verification-record) records 36 PowerShell checks per runtime, 5 Node tests, and a passive capture observation at that time.
- **Limitations:** visible viewport only, possible partially missing GPU content, and same-URL identity limitations. Historical capture evidence does not establish model interpretation or completion of mixed-DPI/overlap manual checks.

## WAT-001 — Primary-monitor browser analysis foundation

- **Date:** 2026-10-28
- **Release:** 0.1.0
- **Implementation:** [d617207](https://github.com/rmaceda7-coder/WebAnalizerTool/commit/d617207)

- **Requirement:** analyze the existing primary-monitor Chrome page and edit code with user review before submission.
- **Implementation:** [`src/NativeDesktop.cs`](../src/NativeDesktop.cs) for monitor/Z-order/focus interop; [`src/WindowsBrowser.psm1`](../src/WindowsBrowser.psm1) for passive discovery, bound reading, guarded capture/replacement, and clipboard readback; JSON CLI entry points, project-local OpenCode agent/skills, and an explicit approval contract.
- **Verification:** dependency-free selection/context/fingerprint/configuration checks and a passive discovery observation; the [historical record](verification-scenarios.md#verification-record) documents 31 checks per PowerShell runtime during initial setup.
- **Limitations:** Windows/Chrome, primary display, accessible editors with reliable clipboard behavior. Initial setup did not perform a live editor transfer; approval policy is not an operating-system sandbox.

Related publication history: [repository-link alignment](https://github.com/rmaceda7-coder/WebAnalizerTool/commit/dfc1bc0), [PowerShell workflow correction](https://github.com/rmaceda7-coder/WebAnalizerTool/commit/6ad693d), [hosted verification update](https://github.com/rmaceda7-coder/WebAnalizerTool/commit/df542f0), and [main-branch publication contract](https://github.com/rmaceda7-coder/WebAnalizerTool/commit/4ceb144).
