# Roadmap

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
6. An execution adapter with revision-scoped approval and explicit per-platform Run semantics.
7. Optional global OpenCode installation tooling that preserves existing user configuration.

Each item needs tests and documented side effects before becoming supported. Broader browser support is not implied by the initial implementation.
