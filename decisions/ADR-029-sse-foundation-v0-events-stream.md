# ADR-029: SSE Foundation v0: Authenticated Real-Time Events Stream

- Status: Proposed
- Date: 2026-01-28
- Owners: SolServer / SolMobile
- Domains: transport, realtime, trust, observability, agentic readiness

## Context

SolOS v0 currently relies on request-response delivery (and, when needed, polling) for user-visible updates. This creates perceptible lag for:
- transmission lifecycle feedback (accepted, started, completed, failed)
- future agentic flows (tool request/approval/progress)
- future “System 2” signals (Ghost Deck, evidence extraction notifications)

We need a server-to-client push channel that:
- reduces perceived latency
- stays optional (offline-first posture remains valid)
- does not bypass SolServer’s gates and enforcement pipeline

## Decision

### D1) Add an authenticated SSE endpoint (`GET /v1/events`) on SolServer
- Implement a single authenticated SSE stream for each logged-in client.
- Primary purpose in v0: establish the pipe, heartbeat, and minimal chat lifecycle status.
- This endpoint is additive. Existing REST endpoints and polling semantics remain correct.

### D2) Use `fastify-sse-v2` v4.2.2 on SolServer, behind an interface boundary
- SolServer will implement an `SSEHub` interface (and `EventBus` or equivalent) that hides the concrete plugin.
- v0 implementation uses an in-memory connection registry.
- v0.1 swaps to a shared broker-backed implementation without changing call-sites.

### D3) Use LaunchDarkly `swift-eventsource` on SolMobile, behind an interface boundary
- `swift-eventsource` requires Swift 5.1+. SolMobile is currently pinned to Swift 5.0, so we will upgrade to Swift 6.0 (ADR-028).
- SolMobile will implement:
  - `SSEClient` (connection lifecycle)
  - `SSEDispatcher` (decode + routing)
- The concrete EventSource library is wrapped so we can swap later if needed.
- SolMobile will upgrade to Swift 6.0 as part of enabling this client (see ADR-028).

### D4) Define an event contract that is Envelope-first
All events follow standard SSE framing:

```
id: <event_id>
event: <event_name>
data: <json>
```

**Contract rule:** the SSE `event:` name MUST match the JSON envelope `kind`.

The `data` JSON MUST be a single canonical envelope shape:

```json
{
  "v": 1,
  "ts": "2026-01-28T00:00:00Z",
  "kind": "ping",
  "subject": { "type": "none" },
  "trace": { "trace_run_id": null },
  "payload": {}
}
```

Where:
- `v`: schema version
- `ts`: ISO-8601 timestamp (server)
- `kind`: stable event kind
- `subject`: the thing the event is about (kept consistent across kinds)
- `trace`: correlation identifiers (optional in v0)
- `payload`: event-specific data (kept small)

#### Subject shapes (v0)

**`none`** (heartbeat, connection health)
```json
{ "type": "none" }
```

**`transmission`** (chat lifecycle)
```json
{
  "type": "transmission",
  "transmission_id": "tx_123",
  "thread_id": "th_456",
  "client_request_id": "cr_789"
}
```

Rules:
- `transmission_id` is required.
- `thread_id` is optional.
- `client_request_id` is optional.

#### v0 minimum kinds
- `ping` (server heartbeat)
- `tx_accepted` (chat request accepted; transmission created/located)
- `run_started` (provider/model work started)
- `assistant_final_ready` (final OutputEnvelope has passed gates and is persisted)
- `assistant_failed` (terminal failure after enforcement and retries)

#### v0 payload shapes
- `ping`: `{}`
- `tx_accepted`: `{}` (all correlation fields live in `subject` + `trace`)
- `run_started`: `{}`
- `assistant_final_ready`: `{}`
- `assistant_failed`:

```json
{
  "code": "PROVIDER_TIMEOUT",
  "detail": "The model request timed out. Please try again.",
  "retryable": true,
  "retry_after_ms": 2000
}
```

### D5) Connection registry supports multiple devices
Store connections as:
- `user_id -> set<connection>` (not a single connection)
- Each connection has its own lifecycle and cleanup.

### D6) Reconnect behavior: backoff with jitter, bounded by UI state
- Client uses truncated exponential backoff with jitter.
- If disconnected for a prolonged period, client transitions UI to a degraded state (“Sync Pending”) and relies on REST refresh.

### D7) Catch-up: `Last-Event-ID` is accepted, replay is deferred
- v0: client may send `Last-Event-ID` when reconnecting; server may log it but does not guarantee replay.
- v0.1: implement catch-up/replay for “must not miss” event classes.

## v0, v0.1, v1 plan

### v0 (PR #39)
- `/v1/events` endpoint, authenticated
- in-memory connection registry
- `ping` event every ~30s
- chat lifecycle status events for v0 UX:
  - `tx_accepted`
  - `run_started`
  - `assistant_final_ready`
  - `assistant_failed`
- minimal observability (open/close, active connection count)
- interfaces (`SSEHub`, `EventBus`, `SSEClient`, `SSEDispatcher`) created and used

### v0.1 (scale + continuity)
- Redis (or equivalent) pub/sub for multi-instance broadcast
- optional replay for selected kinds (ex: Ghost Deck signals)
- `resync_required` mechanism for cases where replay is unavailable
- richer correlation (`trace_run_id`, `transmission_id`) for debugging

### v1 (trust-grade realtime)
- explicit delivery semantics (at-least-once with idempotent client handling)
- stronger ordering per stream
- push integration for background wake (APNs), SSE for foreground continuity
- operational hardening: resource caps, abuse controls, per-connection limits

## 4B

### Bounds
- SSE is optional and must not be required for correctness.
- REST + polling remains the source of truth.
- v0 does not provide replay guarantees.

### Buffer
- If SSE fails, SolMobile falls back to REST refresh and/or existing polling.
- Reconnect uses backoff with jitter to protect SolServer during restarts.

### Breakpoints
- Connect established
- Heartbeat observed (or missed)
- Reconnect attempt started
- Degraded state entered (“Sync Pending”)
- Connection closed + cleaned up

### Beat
- v0: pipe + heartbeat + interfaces
- v0.1: shared broker + catch-up for selected event classes
- v1: reliability semantics + background story

## Alternatives Considered
- WebSockets: more complexity, bi-directional protocol, higher operational surface for v0.
- Long-polling: still client-driven, worse perceived latency.
- No streaming: acceptable but blocks agentic “alive” feel.

## Consequences

### Benefits
- Removes “dead air” with low engineering overhead.
- Provides a stable channel for future agentic UX.
- Keeps enforcement boundaries intact by keeping SSE optional and envelope-first.

### Costs / Risks
- Adds long-lived connections (need cleanup + observability).
- Multi-instance broadcast is not solved in v0 (addressed in v0.1).

## Acceptance Criteria (v0)
- `/v1/events` exists and requires authentication.
- SolMobile connects after login and disconnects on logout.
- Client receives periodic `ping` events.
- For a `POST /v1/chat` request:
  - server emits `tx_accepted` quickly (includes `subject.transmission_id`)
  - server emits `run_started` when the provider call begins
  - after gates pass and the transmission is persisted, server emits `assistant_final_ready`
  - on terminal failure, server emits `assistant_failed` with a stable `{ code, detail, retryable, retry_after_ms? }` payload
- Connections are removed on close (no unbounded growth in registry).
- Interfaces exist and the concrete libraries are not referenced from app-wide call-sites.
