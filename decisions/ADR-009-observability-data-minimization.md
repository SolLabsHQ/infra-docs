# ADR-009: Observability and Data Minimization

## Status
Accepted

## Context
SolMobile and SolServer require basic observability to support debugging, reliability, and cost monitoring.
At the same time, SolOS is explicitly identity-aware and can handle sensitive personal content.
Logging and telemetry can easily become an unintended data hoard.

We want enough signal to debug without storing user content by default.

## Decision
Observability will follow a data-minimization posture by default.

### Default logging rules
- Do not log raw message content (prompts or responses) by default.
- Do not log explicit memory content by default.
- Prefer structured metadata and hashes over content.
- Logs should be useful for debugging, not for replaying user conversations.

### What we do capture
Client (SolMobile):
- app version, device model family, OS version
- request id and correlation ids
- latency (network and total), error codes, retry counts
- feature flags and mode (Sole, Sherlock, Watson)
- local-only telemetry counts (optional and user-controlled): dwell time, regenerate taps, copy events, prompt shown and tap path

Server (SolServer):
- request id, user id surrogate, device id surrogate
- route and model selection
- token counts (input, output), estimated cost, budgets and enforcement decisions
- Rigor Gate applied and regen counts
- constraint linter flags and Wisdom Gate posture
- high-level domain classification (non-sensitive tags)

### What requires explicit opt-in
- Any upload of user content for troubleshooting
- Any persistent storage of full prompts and responses
- Any sensitive diagnostics bundles

## Consequences
- Debugging relies more on correlation ids, structured events, and reproducible cases.
- Lower privacy risk and lower storage costs.
- Clear user trust posture from day one.

## Notes
This decision pairs with explicit memory and offline-first.
When deeper debugging is needed, use time-bounded, user-initiated diagnostic capture that is clearly labeled and reversible.