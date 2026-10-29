---
name: mcp-tool-orchestration
description: Selects connected MCP servers for requested testing or development, verifies session and capability boundaries, and applies scoped approval and evidence requirements.
---

# Route work to verified connected tools

1. Read `docs/mcp-capabilities.md` and follow `AGENTS.md`. Determine the user's task, target, current-session versus managed-session requirement, and artifact constraints. For current-page tasks, load `active-browser-context` first and discover/report the real Windows target passively.
2. Select the most suitable exposed tool, preferring the requested server. Read its schema and required instructions/resources. Do not invoke unrelated servers, inspect global secrets, or equate tool availability with a working/authenticated connection.
3. Do not apply the Windows adapter's inspection-only limitation to Playwright, Selenium, or other MCP servers. For requested browser testing, follow the contract's tool-driven setup rules: announce connection-page/new-browser/focus/session effects before setup, ask about unknown effects or conflicting constraints, and never substitute a session silently.
4. Verify target identity after connection. Existing-page interactions require an unambiguous mapping to the discovered desktop page; URL equality alone is insufficient. A separate runner session must be identified as separate. Never use an extension welcome page as the application or bypass user consent.
5. Announce a bounded action/test plan. Routine non-persistent functional checks may proceed within a testing request after effect verification. Submissions, persistent writes, workflow completion, publishing, destructive operations, load generation, and unknown-effect execution require explicit scoped approval. Review collection/test scripts and evaluated code before running.
6. Honor no-file instructions across screenshots, logs, traces, reports, downloads, and runner defaults. Do not bypass a denied tool with another transport. A technical limitation may justify a disclosed authorized alternative, not a guessed success.
7. Inspect real postconditions and output. Report prepared versus executed work, actual assertions, blocked/skipped cases, target/session differences, artifacts, and pending approval. AI-generated analyses or scripts do not establish execution.

## Server-specific prerequisites

- Postman: fetch the required `postman://instructions` resource before API work, resolve identity/workspace/environment scope, and inspect requests/scripts before execution.
- Serena: read initial instructions before coding; use the correct active project/session and follow memory rules.
- GitHub: follow this environment's `gh` requirement and explicit publication approval; inspect repository/branch/history/diff.
- JMeter: separate result analysis from load execution; approve target, traffic limits, duration, side effects, outputs, and stop conditions before generating load.
- Other servers: follow their actual tool/resource instructions and host permissions. Missing interfaces or authentication are limitations to report.

Changing guidance does not change installed server implementations or override higher-priority instructions. Restart OpenCode to load changed agents/skills; live capability checks remain separate from documentation tests.
