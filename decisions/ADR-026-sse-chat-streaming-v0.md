# ADR-026: SSE Chat Status v0: Status Stream + Final Commit

- Status: Proposed
- Date: 2026-01-28
- Owners: SolServer / SolMobile
- Domains: chat delivery, realtime UX, trust enforcement, transport, offline-first

## Context

SolServer currently delivers chat via `POST /v1/chat` with either:
- 200 (completed response), or
- 202 (pending), followed by client polling `GET /v1/transmissions/:id`.

OutputEnvelope is the canonical success payload and is validated through SolServer’s gates. The gates may reject and force regeneration when outputs violate schema or evidence constraints.

We want SSE-based “snappiness” and agentic readiness, but we must not bypass gates by streaming unvalidated assistant content.

## Decision

### D1) Preserve `/v1/chat` semantics and offline-first correctness
- `/v1/chat` remains the canonical request endpoint.
- 200/202 behavior remains valid and stable for existing clients.
- Polling remains supported and correct even when SSE is unavailable.

### D2) Stream chat status events over `/v1/events`, not assistant text (v0)
SolServer will use `/v1/events` (ADR-029) to emit a minimal set of lifecycle status events for chat.

These events are notifications. They are not a source of truth. The committed transmission remains the source of truth via REST fetch.

**v0 status kinds**
- `tx_accepted` (server accepted request; transmission created or located)
- `run_started` (provider/model work started)
- `assistant_final_ready` (final OutputEnvelope passed gates and is persisted)
- `assistant_failed` (terminal failure after enforcement and retries)

### D3) Minimum fields on every chat status event
Every chat status event MUST include the following identifiers so SolMobile can correlate UI state:

**In the SSE envelope**
- `subject.type = "transmission"`
- `subject.transmission_id` (required)
- `subject.thread_id` (optional)
- `subject.client_request_id` (optional)

**In the SSE envelope trace block**
- `trace.trace_run_id` (optional)

### D4) Failure details are user-presentable and UI-useful
`assistant_failed` MUST include a failure payload that is safe to show to users and can drive UI messaging.

**Failure payload fields**
- `code` (stable string enum)
- `detail` (short, user-presentable explanation; no secrets, no stack traces)
- `retryable` (boolean)
- `retry_after_ms` (optional integer)

**v0 failure code set**
- `PROVIDER_TIMEOUT`
- `PROVIDER_RATE_LIMITED`
- `PROVIDER_UNAVAILABLE`
- `GATE_SCHEMA_INVALID`
- `GATE_EVIDENCE_VIOLATION`
- `GATE_REGEN_EXHAUSTED`
- `INTERNAL_ERROR`

### D5) Gates remain the enforcement boundary for canonical assistant content
- v0 does not stream assistant text deltas.
- The only user-visible assistant content is the final OutputEnvelope that has passed gates and has been committed.
- If gates fail and regeneration occurs, no partial assistant content is streamed.

### D6) SSE does not become required for correctness
- If the SSE stream is down, SolMobile continues to function via existing polling and fetch semantics.
- SSE events are treated as a fast path for UI responsiveness.

## v0, v0.1, v1 plan

### v0 (PR #39 scope)
- `/v1/events` exists and is stable (auth, connection lifecycle, heartbeat)
- emit `tx_accepted`, `run_started`, `assistant_final_ready`, `assistant_failed` for chat requests
- final delivery stays via existing transmission fetch paths (OutputEnvelope after gates)
- simple client UI states: accepted, thinking, syncing, completed, failed

### v0.1
One of the following may be added behind a feature flag:
- Two-phase preview stream (ephemeral preview deltas, followed by commit/reject), OR
- A dedicated `/v1/chat/stream` endpoint if it proves cleaner than using `/v1/events`.

Rules for any preview:
- preview is never persisted as canonical memory
- preview is never eligible for tool execution
- commit happens only after final OutputEnvelope passes gates

### v1
- richer agentic events (tool_request/tool_started/tool_result)
- optional partial text streaming with explicit commit semantics
- stronger continuity and ordering (especially for System 2 signals)

## 4B

### Bounds
- Gates remain the enforcement boundary for user-visible assistant content.
- v0 streams status only.
- Polling remains correct and supported.

### Buffer
- If streaming fails, the system degrades to polling with no correctness loss.
- UI indicates degraded state when needed.

### Breakpoints
- `tx_accepted` emitted
- `run_started` emitted
- gates passed and OutputEnvelope committed
- `assistant_final_ready` emitted
- terminal failure emitted (and client sync path invoked)

### Beat
- v0: status streaming + final commit
- v0.1: optional preview semantics behind a flag
- v1: agentic event expansion and reliability hardening

## Alternatives Considered
- Full token delta streaming in v0: conflicts with post-gate enforcement.
- Incremental linting for chunked streaming: complex and easy to get wrong.
- WebSockets: higher operational surface than needed for v0.

## Consequences

### Benefits
- “Alive” feel without compromising gates.
- Keeps offline-first behavior intact.
- Clear separation: SSE notifies, REST persists.

### Costs / Risks
- No token-by-token “typing” feel in v0.
- Requires careful client UI to make “thinking” feel responsive.

## Acceptance Criteria (v0)
- `/v1/events` works end-to-end and clients receive `ping`.
- A `/v1/chat` request produces:
  - `tx_accepted` quickly (includes `transmission_id`)
  - `run_started` when the provider call begins
  - after gates pass and the transmission is persisted, `assistant_final_ready`
  - on terminal failure, `assistant_failed` with `{ code, detail, retryable, retry_after_ms? }`
- The client never displays assistant content that did not pass gates.
- When SSE is unavailable, polling behavior remains correct and user-visible.
