---
name: active-browser-context
description: Identifies the selected page of the existing Chrome window on the primary Windows monitor for active-page analysis or editing without opening or navigating tabs.
---

# Identify the existing page

1. From the project root run:
    `powershell.exe -NoProfile -STA -File scripts/Get-PrimaryBrowserContext.ps1`
   When available, prefer `browser_vision` MCP's `get_primary_browser_context`, which calls the same adapter without a shell prompt or file artifact.
2. This enumerates monitors and eligible Chrome windows, selecting the primary-display Chrome window by Z-order. It does not use global foreground focus as the browser target.
3. Check the returned `Monitor.IsPrimary`, `Selection`, `WindowHandle`, `Title`, and `Url`. The URL must be HTTP(S), and exactly one exposed visible Document must identify it.
4. Tell the user which title and URL were identified, and that it is the primary monitor.
5. Bind later commands to the returned URL and handle. If either changes, stop, rediscover, and report the new target. Do not silently apply an edit to a new page.

## Constraints

- Discovery cannot focus Chrome or modify any page, tab, clipboard, or browser configuration.
- Do not fall back to secondary monitors, cached handles, the MCP tab, or the terminal's monitor.
- If the Windows primary display does not correspond to the display the user means by "1", ask them to resolve the mapping; do not assume a device suffix is a Settings number.
- Missing Chrome, inaccessible UI Automation, ambiguous documents, lock screens, and elevated-process mismatches are blockers to report.
- Other browsers/displays require an explicitly requested adapter extension; they are not supported by the initial release.
