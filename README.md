# WebAnalizerTool — Web Analyzer and Acting Tool

An automation foundation for **web application testing**: inspect the existing Chrome page on the **primary Windows monitor**, compare observed UI behavior with test expectations, and prepare test code with verified editor transfers.

[![Verify](https://github.com/rmaceda7-coder/WebAnalizerTool/actions/workflows/verify.yml/badge.svg?branch=main)](https://github.com/rmaceda7-coder/WebAnalizerTool/actions/workflows/verify.yml)

## What it does

- Supports QA workflows: analyze application UI, identify smoke/regression scenarios, draft assertions, and report expected versus observed behavior.
- Identifies the foremost eligible Chrome window on the primary monitor, even when a terminal on another monitor has keyboard focus.
- Reads the selected page through Windows UI Automation without opening a browser, welcome tab, or connection page.
- Analyzes visible image-based tables and diagrams through a project-local MCP that returns the page viewport directly as PNG image content, without intermediate screenshot files.
- Captures existing editor text, checks its fingerprint before replacing it, and verifies the resulting code by clipboard readback.
- Provides an OpenCode primary agent and three focused workflow skills.
- Leaves prepared test code for review. **Bundled commands expose no test runner, form-submit action, or record-saving action.**

The current adapter provides page discovery, accessibility reading, viewport capture, and guarded code-editor transfers. General clicking, form filling, navigation, and end-to-end test execution require separately implemented and verified capabilities. Proposed test scenarios and generated scripts are not evidence that a test has run.

**Initial support:** Windows 10/11, an existing Chrome session, and accessible code editors that implement Ctrl+A/C/V reliably. Other browsers, secondary-display targeting, remote desktops, and arbitrary editors are not yet supported adapters. See [limitations](docs/architecture.md#limitations).

## Quick start

### Requirements

- Git; Windows PowerShell 5.1 (included in Windows) or PowerShell 7.
- Chrome already open on the primary Windows monitor.
- An interactive, unlocked desktop; browser and shell at the same elevation level.
- [OpenCode](https://opencode.ai) for the agent workflow. No Python, Node package, Selenium driver, or Playwright connection is needed by these scripts.
- Node.js 22+ for the direct-image MCP bridge (standard library only; no `npm install` needed). The PowerShell CLI remains usable without Node.js.

### Install

```powershell
git clone https://github.com/rmaceda7-coder/WebAnalizerTool.git
```

Open a terminal in the cloned folder and run:

```powershell
powershell.exe -NoProfile -STA -File tests/Run-Tests.ps1
opencode
```

The project config selects `web-analyzer` as the default agent. If OpenCode was already running before installation or configuration changes, **quit and restart it** from this folder. Existing sessions do not reload agents/configuration automatically.

This is a project-local installation. It does not modify your global OpenCode config or make the agent available from unrelated directories. Existing global tools remain inherited. The config starts only the bundled `browser_vision` stdio MCP; that server does not attach to or inspect Chrome until a tool is called.

### Ask the agent

> Inspect the login page on the primary monitor and identify validation, accessibility, and smoke-test scenarios.

> Compare the visible dashboard status indicators with the expected behavior and report any discrepancies with supporting evidence.

> Prepare a Playwright test for required-field validation on the login form and leave the test code in the identified editor for my review. Do not run it.

The agent reports the page identity, inspects the application against test requirements, identifies assertions and defects, and prepares requested test code with readback verification. It distinguishes proposed tests, observed results, and actual execution. See [the walkthrough](docs/usage.md).

## Test actions and execution controls

| Action | Behavior |
|---|---|
| Identify/read primary-display page | Passive; no navigation, focus change, or clipboard access |
| Capture or edit browser code after an editing request | May focus Chrome and temporarily use clipboard; attempts restoration |
| Run verified as independent of form submission, persistent changes, and workflow completion | Agent may run if a verified same-page transport is available |
| Submit forms, save application data, complete a workflow, or use Run with unknown effects | Ask for explicit approval of the current test code/action plan first |
| Change test code, action plan, or target after approval | Request new approval before the affected action |

A button named Run or Test does not establish its effects. Verify the operation and target environment before execution; the bundled adapter does not provide a test runner.

## CLI commands

All commands run from the project root. Use `-STA -NoProfile` for desktop operations.

```powershell
# Passive discovery; returns current handle, exact URL, and primary monitor device.
powershell.exe -NoProfile -STA -File scripts/Get-PrimaryBrowserContext.ps1

# Use the exact values returned above, not these example placeholders.
powershell.exe -NoProfile -STA -File scripts/Read-BrowserPage.ps1 `
  -ExpectedUrl 'https://example.test/login' -ExpectedWindowHandle 12345
```

For editor capture and guarded writes, see [usage](docs/usage.md). Output is JSON. Failures terminate with a nonzero script exit. Browser/page output may contain private data; keep it out of Git.

## Direct image analysis

After restarting OpenCode from this folder, the `browser_vision` MCP exposes:

| Tool | Output |
|---|---|
| `get_primary_browser_context` | Window, monitor, title, and exact URL |
| `read_browser_page` | Accessibility text and editor metadata |
| `capture_browser_page` | PNG image content plus capture metadata |

The last two require `expectedUrl` and `expectedWindowHandle` returned by discovery. The agent reports the target, then reads/captures it as needed. You do not have to upload screenshots or copy image links. Capture uses Chrome's own window rendering, crops to the page viewport, and rechecks the target. It does not navigate, scroll, change focus, access the clipboard, or save screenshots. The image is sent through OpenCode to the configured model, so use an image-capable model; session storage/provider retention still follows your OpenCode/provider settings.

Only visible content is captured. Uniform/black output is rejected; partially missing GPU-rendered content is not always detectable. See [architecture](docs/architecture.md#visual-capture). If OpenCode reports a missing Node executable, install Node.js 22+ and restart. If a local permission rule asks about the tool, grant the specific `browser_vision` read/capture operation as desired; broader filesystem/shell permission changes are unnecessary.

The bridge launches PowerShell with a **process-only** execution-policy bypass so it works with the default restricted Windows script policy; it does not change machine/user policy. Organizational policy can still prevent execution.

Verification:

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File tests/Run-Tests.ps1
pwsh.exe -NoProfile -STA -File tests/Run-Tests.ps1
node --test tests/browser-vision-mcp.test.mjs tests/editor-fixture.test.mjs
```

## Project layout

```text
.opencode/agents/       OpenCode primary agent
.opencode/skills/       Target discovery, page analysis, editor workflow
src/                   Windows UI Automation module and Win32 adapter
scripts/               JSON CLI entry points
tests/                 Policy/transfer checks, MCP tests, and opt-in local editor fixture
docs/                  Architecture, usage, manual verification, and roadmap
.github/               CI, issue template, pull request template
AGENTS.md              Persistent operating contract
AUTHORS.md             Creator signature and contact publication status
```

## Documentation

All project documentation and guidelines are maintained in English.

- [Installation and usage](docs/usage.md)
- [Architecture and extension points](docs/architecture.md)
- [Verification scenarios](docs/verification-scenarios.md)
- [Roadmap](docs/roadmap.md)
- [Contributing](CONTRIBUTING.md)
- [Security reporting](SECURITY.md)
- [Changelog](CHANGELOG.md)
- [Implementation history and verification traceability](docs/implementation-history.md)

## Creator

**Ramiro Maceda**

**Senior Software Quality Assurance Engineer**

- Phone: [+591 60356760](tel:+59160356760)
- LinkedIn: [Ramiro Maceda Toranzos](https://www.linkedin.com/in/ramiro-maceda-toranzos-928746214)
- Email: [rmaceda7@gmail.com](mailto:rmaceda7@gmail.com)
- GitHub: [rmaceda7-coder](https://github.com/rmaceda7-coder)
- Repository: [WebAnalizerTool](https://github.com/rmaceda7-coder/WebAnalizerTool)

See [AUTHORS.md](AUTHORS.md). Contact details were provided by the creator for publication.

## License

Copyright (c) 2026 Ramiro Maceda. All rights reserved. See [LICENSE](LICENSE). No open-source redistribution license has been selected yet.
