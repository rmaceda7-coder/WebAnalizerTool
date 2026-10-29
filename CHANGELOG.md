# Changelog

Notable changes are recorded here. Versions follow Semantic Versioning once releases are published.

## 0.2.0 — Unreleased

- Replaced blanket Playwright/Selenium startup bans with passive current-page and disclosed tool-driven test-session modes. Added connected-MCP capability routing, server prerequisites, scoped approval/artifact rules, orchestration skill, and automated policy-regression checks. No global configuration, credentials, host permissions, or server implementations were changed; live connectivity remains separately verified.
- Reframed project purpose, agent/skill guidance, examples, and fixture terminology around web test automation, including smoke/regression scenarios, validation assertions, and expected-versus-observed reporting. Documented the current inspection/editor-transfer capability boundary separately from future interaction and test-runner integrations.
- Standardized documentation in English: translated README example prompts and creator labels, replaced non-English operating-contract examples with English guidance, and established an English-only documentation requirement.
- Private injectable desktop operations and deterministic editor-transfer tests for guards, clipboard/focus failures, empty editors, Unicode, delayed copy, and readback mismatch.
- Disposable local HTML editor, loopback-only opt-in fixture server, server tests, and a documented manual desktop procedure.
- Expanded operating-contract guidance for passive attachment, connection-page limitations, and current-revision approval before submission/completion-triggering execution.
- Dated implementation history with source/test links and verification evidence; contributor and agent instructions require traceability documentation for future changes and align authorized publication with `main`.
- Project-local read-only `browser_vision` MCP with direct PNG image content for visible browser tables, charts, and diagrams.
- Bound, DPI-aware `PrintWindow` capture cropped to the page viewport, in-memory encoding, blank-image detection, and target/bounds rechecks.
- UTF-8 discovery/read CLI output for the Node bridge; no image-file read permission round trip.
- Visual reasoning workflow, MCP transport tests, blank-image tests, and Windows CI coverage.

## 0.1.0 — Initial implementation

- Primary-monitor Chrome discovery using Win32 Z-order and monitor identity.
- Passive selected-document reading using Windows UI Automation.
- Guarded editor capture/write with URL, handle, and content preconditions.
- Clipboard-based Unicode-safe paste and readback verification; no automatic execution.
- OpenCode primary agent and three workflow skills.
- Persistent review-before-submit rules for actions with state-changing or unknown effects.
- PowerShell 5.1/7 checks and GitHub Actions workflow.
- Installation, architecture, contributor, attribution, and verification documentation.
