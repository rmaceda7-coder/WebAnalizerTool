# Roadmap

The primary objective is web test automation: application inspection, test scenario/assertion design, automation code preparation, and evidence-based reporting. The current runtime supports passive inspection and guarded editor transfers; form interaction and test execution are extension work.

## Initial foundation (0.1.x)

- Primary-monitor Chrome discovery and accessible page analysis.
- Explicit editor capture, guarded replacement, and verified readback.
- Project-local OpenCode agent/skills and review-before-submit contract.
- Windows PowerShell 5.1/7 verification and documentation.

## Next candidates

1. Record opt-in live editor compatibility results using the shipped local fixture; deterministic clipboard failure/focus-loss transfer tests are now included.
2. Stable tab/document identity through a passive attachment mechanism verified not to open connection pages.
3. Dedicated Monaco/CodeMirror adapters, with accurate capability detection.
4. Explicitly requested secondary-monitor targeting using monitor identity, never global-focus fallback.
5. Edge/Firefox adapters with separate compatibility evidence.
6. Verified web interaction and test-runner integrations, with environment/revision-scoped approval, explicit action effects, and actual assertion-result reporting.
7. Optional global OpenCode installation tooling that preserves existing user configuration.

Each item needs tests and documented side effects before becoming supported. Broader browser support is not implied by the initial implementation.
