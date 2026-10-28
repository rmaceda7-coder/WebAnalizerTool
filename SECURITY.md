# Security and private data

This tool reads existing authenticated browser pages and can replace editor text after an editing request. Treat returned JSON, clipboard snapshots, and error diagnostics as potentially private.

- Do not attach browser profiles, authentication tokens, private URLs, page dumps, or clipboard contents to issues or pull requests.
- Keep temporary evidence in the ignored `artifacts/` folder or outside the repository.
- Discovery does not attach a debugging port, open connection tabs, or launch browsers.
- Editor operations attempt to restore the clipboard; complex delayed/custom clipboard formats may not round-trip. See the documented limitations.
- Approval policy is an agent instruction, not an operating-system sandbox. Existing global tools are inherited by OpenCode. The shipped scripts expose no Run/Submit operation, but custom tools must honor the same contract.

## Reporting

For non-sensitive bugs use a GitHub issue. For security-sensitive reports, email the maintainer at [rmaceda7@gmail.com](mailto:rmaceda7@gmail.com). Do not publish exploit details or private evidence in public issues.

The initial 0.1.x series is the only maintained version line. Fixes are delivered on the main development line.
