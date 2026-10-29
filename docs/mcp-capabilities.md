# Connected MCP capabilities and execution policy

## Purpose and limits

Use the best relevant connected tool for the user's task, including inherited global MCP servers. The bundled Windows adapter's passive inspection/editor-transfer boundary does not prohibit capabilities supplied by another server. This guide is routing and approval policy, not a new adapter, a sandbox, proof of authentication, or a guarantee that every listed server is installed.

Follow higher-priority instructions, host permissions, and each server's instructions. Project edits cannot override restrictions already loaded in a running session. Quit and restart OpenCode after agent/skill/config changes. Do not use an alternative transport to bypass a permission denial.

## Select and verify a capability

1. Determine the task, target/environment, expected behavior, session requirements, and artifact constraints. Respect instructions such as current-session-only, no new tabs, no files, or report-only.
2. Read the exposed tool descriptions and relevant server instructions/resources. Inventory only tools needed for this task; do not call every connected server or dump global configuration/secrets.
3. Prefer an explicitly requested server. Verify its connection mode, target identity, side effects, and required permissions before consequential calls. A visible tool definition establishes an available interface, not a working connection or successful action.
4. State a short test/action plan. Separate passive reads, routine UI checks, persistent changes, code execution, publication, and load generation. Resolve unknown effects before acting.
5. Execute only authorized steps. Read actual output and postconditions. Rebind after navigation or session changes; stop when scope, consent, or identity becomes uncertain.
6. Report observed evidence, executed steps, assertion outcomes, skipped/blocked tests, artifacts, environment/session differences, and any approval still needed. A successful tool response is not automatically a passed assertion.

Do not change global MCP configuration, install drivers/extensions, expose debugging ports, add credentials, or blanket-allow tool permissions merely to remove a blocker. Propose the smallest setup change separately. Preserve inherited server definitions; do not duplicate them in the project config with guessed commands or versions.

## Browser session modes

### Passive current-page discovery

For "this page", "current website", or the existing primary-monitor session, load `active-browser-context` first. Use `browser_vision.get_primary_browser_context` or the corresponding Windows script. Report monitor device, native window handle, title, and exact URL before reading content. Discovery must not focus Chrome, launch browsers, navigate, or open extension connection tabs.

An MCP-selected tab is not proof of the desktop target. Before interactions, establish that the runner controls the discovered page/session, using available stable target/session identifiers or a documented, unambiguous attachment mapping. URL/title equality alone cannot distinguish duplicate pages or browser profiles. If the installed transport cannot establish that mapping, do not claim same-page attachment; offer a separate test session and explain session/cookie differences.

### Requested tool-driven session

An explicit request to use Playwright or Selenium for testing permits its ordinary connection or managed-browser setup if no existing-session-only or no-new-page constraint conflicts. Before the first call, announce known startup effects: an extension connection/consent page, changed focus, a new managed browser, or separate authentication state. If effects are unknown or conflict with constraints, ask for setup approval first. This is intentional setup, not passive discovery.

A URL-only functional-test request permits visiting that URL in a verified session. It does not alone authorize a new browser or extension setup; ask to select that mode if needed. Never silently replace the current session with Selenium or another managed browser.

User-controlled extension consent must remain with the user. Do not bypass it, auto-approve it, or use the connection page as the application under test. After setup, inspect the runner's selected page/session, report the actual target, then perform the planned checks. Expected navigation/popups can be part of the plan; unexpected origins, login boundaries, or ambiguous targets require review. A managed/headless session has no verified primary-monitor identity unless separately established.

## Capability routing matrix

The names below describe server roles observed in this environment, not an exhaustive or permanent tool inventory. Use actual tool schemas at runtime.

| Server / tool family | Appropriate work | Verification and approval boundary |
|---|---|---|
| `browser_vision` and bundled Windows scripts | Passive existing-page discovery, accessibility text, in-memory viewport images; guarded editor transfers via scripts | Bind exact URL/window. Desktop writes capture old text, check its hash, verify readback, and attempt clipboard restoration. No general clicks/navigation/runner are supplied. |
| Playwright MCP | Accessibility/DOM inspection, navigation, locators, clicks, fields, keyboard, responsive checks, console/network evidence, functional assertions | Establish session mode before connection. Inspect elements before actions. Classify action effects, including autosave. Scripts/evaluate/run-code can have arbitrary effects; review them, not just their names. Screenshot tools may save files even without a filename. |
| Selenium MCP | Managed browser tests, DOM/element state, mouse/keyboard, frames/windows, diagnostics, scripts, screenshots | Browser startup normally creates a separate session; disclose this. Follow required accessibility resources when exposed. Verify current window/frame and URL. Cookie changes, uploads, and script execution require their own effects review. Do not copy authenticated profile data into another session without permission. |
| Postman MCP | Workspace/spec/collection discovery, request preparation, mocks/environments, collection execution and assertion reporting | Read `postman://instructions` via the resource interface before API-related work; if unavailable, report the initialization gap. Resolve user identity for "my" requests, explicit workspace/collection/environment IDs, and supported tool set. Inspect collection scripts/requests, external targets, and resolved environment before running. Runs may write data even when labeled tests. Cloud resource creation/replacement/publication needs scoped authorization. |
| JMeter MCP | Analyze existing results, identify bottlenecks, prepare visualizations/reports; execute approved performance plans | Inspect plan, targets, credentials sources, threads/rate/ramp/duration, write effects, and output paths first. Obtain explicit load authorization, limits, and a stop/abort plan. Do not run load against a public or production site merely because a functional test was requested. Execution/visualization usually writes files. |
| GitHub MCP / `gh` | Repository/issue/PR/check discovery and explicitly requested repository changes | Verify repository, branch/base, visibility, and diff. Follow this project's requirement to use `gh` for GitHub tasks. Do not commit, push, create/merge PRs, publish comments, or create repositories without authorization. Follow `main` and history-review requirements. Tool availability is not publication approval. |
| Filesystem / local editing tools | Read project material, prepare authorized code/config/docs, inspect evidence | Stay within allowed directories; use `apply_patch` for edits in this environment. Preserve unrelated work. Honor no-file/report-only constraints. Broad read access is not permission to copy secrets or capture private browser profiles. |
| Serena MCP | Semantic code exploration, references, diagnostics, refactoring, project memories | Call initial instructions before coding; use the correct project/session. Refactoring is a write. Memory creation/deletion must follow server/user rules, and sensitive browser data must not be stored as memory. |
| OpenAI assistance MCP | Draft tests/data/assertions/reports; review code or analyze supplied logs/results | Generated output is advice/code, not executed evidence. Review before use. Avoid forwarding credentials/private page data; disclose external processing or costs not already covered by the user's task. Never fabricate results. |
| Other connected servers / resource providers | Task-relevant capabilities actually exposed by that server | Read their instructions and schemas, identify the target and effects, then apply the same approval/evidence rules. Missing capabilities remain blockers, not reasons to invent commands or success. |

## Approval matrix

| Action | Required scope |
|---|---|
| Passive inspection and analysis of an authorized target | May proceed within the request, subject to host permissions. |
| Ordinary navigation, scrolling, menus, viewport changes, local UI controls in a functional test | Announce the plan and verify non-persistent effects first. Check for autosave, data submission, external destinations, or hidden side effects; do not rely on labels or HTTP methods. |
| Browser connection/managed-session setup | Explicit Playwright/Selenium testing request covers ordinary disclosed setup unless constraints conflict. Otherwise obtain setup approval. Unknown startup behavior requires clarification. |
| Prepare code or transfer it into an editor | Requires an editing request, capture/preservation of existing work, stale-content protection, and readback. Preparation alone does not authorize execution. |
| Independently verified non-persistent test execution | May run when requested or allowed by the operating contract, after reviewing current code/effects and verifying session identity. Preparation-only instructions still prohibit execution. |
| Submit forms, save/delete records, finalize workflows, execute write requests, or run with unknown effects | Explicit approval tied to the current plan/code, environment, data, and effects. A broad "test the website" or "go" is not enough for undisclosed effects. |
| Create/replace remote collections/environments/mocks, publish comments/code, merge or release | Explicit resource/action authorization. Confirm visibility and preserve unrelated remote data. Secrets are not ordinary shared environment variables. |
| Generate load or execute performance plans | Explicit target authorization, traffic limits/duration, environment, side-effect review, and stop conditions. |
| Files, screenshots, traces, downloads, generated reports, or logs when user says no files | Do not create them. Prefer verified in-memory results. If a runner necessarily creates artifacts, explain the conflict and ask before execution. Host-managed session history/retention is separate and must not be promised absent. |

Approval covers the disclosed plan and its expected route transitions, not unrelated websites, changed environments, or materially changed code/effects. Reassess on changes. Host permission prompts remain independent of user task approval.

## Functional testing and evidence

For a basic website test, announce a bounded smoke plan: load the specified route, inspect key navigation, exercise verified non-persistent controls, check expected destinations and visible state transitions, and inspect available console/network errors. Add validation, keyboard, responsive, and regression checks when relevant and supported. Do not submit a contact/login/order form merely to improve coverage without the required approval.

For each executed case record its precondition, action, expected result, observed result, and assertion evidence. Separate product failures from tool/connection failures, blocked checks, and unexecuted proposals. A screenshot proves visible pixels, not link destinations, accessible names, or successful business operations. A weak accessibility extraction is a limitation until DOM/accessibility evidence confirms a defect.

Report test counts only for cases actually executed; include blocked/skipped cases separately. State whether output belongs to the existing user session or a managed test session. Do not turn old page output or an AI-generated report into fresh execution evidence.

## Verification after policy changes

Automated policy checks can verify documented routing and retained safety boundaries. They do not establish live transport compatibility. After restarting OpenCode, manually verify the chosen browser setup with consent, correct target/session mapping, safe interactions and actual assertions, artifact behavior, and any relevant authenticated server. Do not connect every server, launch browsers, run collections/load plans, or publish remote resources as an unattended policy test.
