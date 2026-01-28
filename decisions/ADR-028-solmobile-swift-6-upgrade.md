# ADR-028: SolMobile Swift 6 Upgrade

## Status
Proposed

## Date
2026-01-28

## Owners
SolMobile

## Domains
toolchain baseline, concurrency safety, SSE client enablement

## Context

SolMobile’s Xcode project is currently pinned to `SWIFT_VERSION = 5.0`. This blocks:
- adopting Swift ecosystem packages that require Swift 5.1+
- leveraging Swift 6’s concurrency safety improvements for long-lived networking (SSE)

We are adopting LaunchDarkly `swift-eventsource` for SSE v0 behind a wrapper interface, and we want a single, explicit toolchain baseline to reduce drift.

## Decision

### D1) Upgrade SolMobile to Swift 6.0
- Set `SWIFT_VERSION = 6.0` for all SolMobile targets and build configurations:
  - SolMobile
  - SolMobileTests
  - SolMobileUITests

### D2) Start with a permissive concurrency checking posture, then tighten
- v0: use a permissive strict concurrency configuration to get the build green while we address errors incrementally.
- v0.1: tighten strict concurrency checking (and fix remaining warnings/errors).
- v1: consider “strict everywhere” and treating key concurrency warnings as build failures.

### D3) Toolchain baseline
- Require an Xcode toolchain that supports Swift 6.
- Document this in the repo (DEV-SETUP or equivalent) so onboarding is deterministic.

### D4) Migration approach (pragmatic)
Expected hotspots:
- `Sendable` conformance on types crossing concurrency domains
- `@MainActor` annotations for UI-bound state
- actor isolation violations
- captured mutable state in async closures

We will resolve issues with minimal refactors first, then follow with cleanup PRs.

## v0, v0.1, v1 plan

### v0 (paired with SSE foundation)
- bump `SWIFT_VERSION` to 6.0
- compile and run app + tests
- keep concurrency checking permissive enough to ship without large refactors

### v0.1
- address remaining concurrency warnings systematically
- tighten strict concurrency checking
- add basic concurrency regression tests around SSE lifecycle (foreground/background)

### v1
- adopt stricter concurrency checking defaults
- consider warnings-as-errors for concurrency in key targets
- finalize long-lived networking patterns (actors where appropriate)

## 4B

### Bounds
- This ADR changes the toolchain baseline, not product behavior.
- Avoid large refactors during the initial upgrade unless required to compile.

### Buffer
- If Swift 6 upgrade blocks unrelated work, isolate fixes into focused follow-up PRs.
- Keep SSE client behind an interface to reduce coupling during the migration.

### Breakpoints
- Project builds under Swift 6
- App launches and core flows work
- Tests pass (or known failures are documented with fixes queued)
- Concurrency tightening milestone achieved (v0.1)

### Beat
- v0: baseline upgrade + compile green
- v0.1: tighten and clean up
- v1: harden and enforce

## Alternatives Considered
- Stay on Swift 5.0: blocks required libraries and defers concurrency safety.
- Upgrade only to Swift 5.1/5.9: reduces immediate churn, but still postpones Swift 6 benefits and future alignment.

## Consequences

### Benefits
- Enables modern Swift libraries and tooling.
- Improves concurrency safety for realtime networking.
- Establishes a deterministic team toolchain baseline.

### Costs / Risks
- Initial compile failures due to stricter rules.
- Requires alignment on Xcode version across the team.

## Acceptance Criteria
- `SWIFT_VERSION = 6.0` applied across all targets/configs.
- SolMobile builds locally and core flows run.
- SSE client wrapper compiles (even if SSE is feature-flagged).
- Toolchain requirement is documented.
