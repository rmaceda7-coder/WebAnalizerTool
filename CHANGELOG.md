# Changelog

Notable changes are recorded here. Versions follow Semantic Versioning once releases are published.

## 0.2.0 — Unreleased

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
- Persistent review-before-submit rules, including SQL Practice Online behavior.
- PowerShell 5.1/7 checks and GitHub Actions workflow.
- Installation, architecture, contributor, attribution, and verification documentation.
