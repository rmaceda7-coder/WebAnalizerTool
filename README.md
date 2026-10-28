# Web Analyzer and Acting Tool

Analyze the existing Chrome page on the **primary Windows monitor**, edit browser code editors, and keep the user in control of submission.

[![Verify](https://github.com/rmaceda7-coder/web-analyzer-and-acting-tool/actions/workflows/verify.yml/badge.svg)](https://github.com/rmaceda7-coder/web-analyzer-and-acting-tool/actions/workflows/verify.yml)

## What it does

- Identifies the foremost eligible Chrome window on the primary monitor, even when a terminal on another monitor has keyboard focus.
- Reads the selected page through Windows UI Automation without opening a browser, welcome tab, or connection page.
- Captures existing editor text, checks its fingerprint before replacing it, and verifies the resulting code by clipboard readback.
- Provides an OpenCode primary agent and three focused workflow skills.
- Leaves the code for review. **No bundled command executes code or submits an exercise.**

**Initial support:** Windows 10/11, an existing Chrome session, and accessible code editors that implement Ctrl+A/C/V reliably. Other browsers, secondary-display targeting, remote desktops, and arbitrary editors are not yet supported adapters. See [limitations](docs/architecture.md#limitations).

## Quick start

### Requirements

- Git; Windows PowerShell 5.1 (included in Windows) or PowerShell 7.
- Chrome already open on the primary Windows monitor.
- An interactive, unlocked desktop; browser and shell at the same elevation level.
- [OpenCode](https://opencode.ai) for the agent workflow. No Python, Node package, Selenium driver, or Playwright connection is needed by these scripts.

### Install

```powershell
git clone https://github.com/rmaceda7-coder/web-analyzer-and-acting-tool.git
```

Open a terminal in the cloned folder and run:

```powershell
powershell.exe -NoProfile -STA -File tests/Run-Tests.ps1
opencode
```

The project config selects `web-analyzer` as the default agent. If OpenCode was already running before installation or configuration changes, **quit and restart it** from this folder. Existing sessions do not reload agents/configuration automatically.

This is a project-local installation. It does not modify your global OpenCode config or make the agent available from unrelated directories. Existing global tools remain inherited; no MCP connections are initiated by the project configuration.

### Ask the agent

> Analiza la pagina activa de Chrome en el monitor principal.

> Lee el enunciado y deja una consulta en el editor para mi revision. No la ejecutes.

The agent reports the page identity, inspects requirements, captures existing code, writes and verifies a solution, then pauses when approval is required. See [the walkthrough](docs/usage.md).

## Submission rules

| Action | Behavior |
|---|---|
| Identify/read primary-display page | Passive; no navigation, focus change, or clipboard access |
| Capture or edit browser code after an editing request | May focus Chrome and temporarily use clipboard; attempts restoration |
| Run proven independent of submission/completion | Agent may run if a verified same-page transport is available |
| Submit, completion-triggering Run, or unknown Run | Ask for explicit approval of the current code first |
| Change code after approval | Request new approval before submission |

**SQL Practice Online:** Run was observed to complete exercises, so approval is required. A button named Run is not proof of a non-submitting operation.

## CLI commands

All commands run from the project root. Use `-STA -NoProfile` for desktop operations.

```powershell
# Passive discovery; returns current handle, exact URL, and primary monitor device.
powershell.exe -NoProfile -STA -File scripts/Get-PrimaryBrowserContext.ps1

# Use the exact values returned above, not these example placeholders.
powershell.exe -NoProfile -STA -File scripts/Read-BrowserPage.ps1 `
  -ExpectedUrl 'https://example.test/exercise' -ExpectedWindowHandle 12345
```

For editor capture and guarded writes, see [usage](docs/usage.md). Output is JSON. Failures terminate with a nonzero script exit. Browser/page output may contain private data; keep it out of Git.

## Project layout

```text
.opencode/agents/       OpenCode primary agent
.opencode/skills/       Target discovery, page analysis, editor workflow
src/                   Windows UI Automation module and Win32 adapter
scripts/               JSON CLI entry points
tests/                 Dependency-free policy, fingerprint, syntax, and config checks
docs/                  Architecture, usage, manual verification, and roadmap
.github/               CI, issue template, pull request template
AGENTS.md              Persistent operating contract
AUTHORS.md             Creator signature and contact publication status
```

## Documentation

- [Installation and usage](docs/usage.md)
- [Architecture and extension points](docs/architecture.md)
- [Verification scenarios](docs/verification-scenarios.md)
- [Roadmap](docs/roadmap.md)
- [Contributing](CONTRIBUTING.md)
- [Security reporting](SECURITY.md)
- [Changelog](CHANGELOG.md)

## Creator / Creador

**Ramiro Maceda**

**Senior Software Quality Assurance Engineer**

- Phone / Telefono: [+591 60356760](tel:+59160356760)
- LinkedIn: [Ramiro Maceda Toranzos](https://www.linkedin.com/in/ramiro-maceda-toranzos-928746214)
- Email / Correo: [rmaceda7@gmail.com](mailto:rmaceda7@gmail.com)
- GitHub: [rmaceda7-coder](https://github.com/rmaceda7-coder)
- Repository: [web-analyzer-and-acting-tool](https://github.com/rmaceda7-coder/web-analyzer-and-acting-tool)

See [AUTHORS.md](AUTHORS.md). Contact details were provided by the creator for publication.

## License

Copyright (c) 2026 Ramiro Maceda. All rights reserved. See [LICENSE](LICENSE). No open-source redistribution license has been selected yet.
