# PR #39: SSE-01 — SSE Foundation + Chat Status Events (v0)

## 1. Summary

This PR introduces Server-Sent Events (SSE) to enable real-time, low-latency updates from SolServer to SolMobile.

**v0 outcome:** SolMobile feels responsive (no “dead air”) by receiving **chat lifecycle status events** and a heartbeat, while keeping SolServer’s **gates + regen** as the enforcement boundary for all assistant content.

## 2. Motivation

The current request/response model plus polling creates perceptible delay between:
- user sending a message
- server accepting it
- server starting model work
- server producing a final committed result

SSE allows SolServer to push **immediate state transitions** to SolMobile, improving trust and responsiveness and preparing the transport lane for future agentic signals.

## 3. Scope

### In scope (this PR)

#### SolServer
- Authenticated SSE endpoint: **`GET /v1/events`**
- **`fastify-sse-v2` v4.2.2** for SSE handling (wrapped behind an interface)
- In-memory connection registry (v0), supporting **multiple connections per user**
- Heartbeat: `ping` event every ~30 seconds
- Minimal chat status events:
  - `tx_accepted`
  - `run_started`
  - `assistant_final_ready`
  - `assistant_failed` (UI-usable failure detail)

#### SolMobile
- Upgrade toolchain: **Swift 6.0** (required for adopting the SSE client library and standardizing concurrency posture)
- SSE client wrapper using LaunchDarkly **`swift-eventsource`**
- Reconnect behavior with backoff + jitter (bounded; shows degraded state when needed)
- Dispatcher to decode events and route them to UI + watchers

### Out of scope (explicit punts)
- Token-by-token assistant text streaming
- True replay/catch-up using `Last-Event-ID` (server-side replay)
- Redis/shared broker for multi-instance fanout
- Feature-specific events (LATTICE-01 evidence events, MCP tool events)
- Complex channels/groups broadcasting (beyond user-targeted delivery)

## 4. Hard boundary: gates stay sovereign

SolServer’s output is enforced by:
- strict OutputEnvelope parsing
- evidence binding + other gates
- server reject + regen loops

**This PR does not stream assistant text.** SSE is used only for status transitions and failure reporting. Canonical content remains available via `GET /v1/transmissions/:id` once committed.

## 5. Technical design

### 5.1 SolServer

1) **Endpoint:** `GET /v1/events` (authenticated)
2) **Connection registry:** in-memory map
   - `user_id -> set<connection>`
   - each connection has a `connection_id`
   - cap connections per user (default 3), evict oldest on overflow
3) **Emitter / hub:** internal `SSEHub` interface
   - v0 implementation: `InMemorySSEHub`
   - v0.1: swap to Redis-backed hub without changing call-sites
4) **Heartbeat:** emit `ping` every ~30s to keep the stream alive and to measure connection health

### 5.2 Event contract (v0)

SSE framing:

```
id: <event_id>
event: <kind>
data: <SSEEventEnvelope JSON>
```

Rules:
- `event` MUST match JSON `kind`.
- `data` is always the same envelope type:

```json
{
  "v": 1,
  "ts": "2026-01-28T00:00:00Z",
  "kind": "run_started",
  "subject": {
    "type": "transmission",
    "transmission_id": "tx_123",
    "thread_id": "th_456",
    "client_request_id": "cr_789"
  },
  "trace": { "trace_run_id": "tr_abc" },
  "payload": {}
}
```

### 5.3 Chat lifecycle emission points (v0)

- `tx_accepted`: when `/v1/chat` is accepted and `transmission_id` is known
- `run_started`: immediately before provider/model call begins
- `assistant_final_ready`: only after gates pass and the transmission is persisted for fetch
- `assistant_failed`: terminal failure after enforcement/retry policy is exhausted

`assistant_failed` payload fields:
- `code` (stable code for UI)
- `detail` (human-readable short text for UI)
- `retryable` (boolean)
- `retry_after_ms` (optional)
- optional `category` for grouping (network/provider/gates/internal)

### 5.4 SolMobile

- Create `SSEClient` protocol and a LaunchDarkly `EventSource` adapter implementation.
- Connection lifecycle:
  - connect after login
  - disconnect on logout
  - reconnect on drop with backoff + jitter
- Dispatch:
  - `tx_accepted` / `run_started`: update in-flight state
  - `assistant_final_ready`: trigger fetch and render final response
  - `assistant_failed`: show error state with UI messaging informed by `code` + `detail`
- Fallback: if SSE is unavailable, polling watchers remain correct and supported.

## 6. Testing strategy

### Unit tests
- SolServer: connection add/remove, event routing, envelope serializer
- SolMobile: envelope decoding, basic dispatcher behavior

### Integration tests
- connect → receive ping → disconnect cleanup
- `/v1/chat` lifecycle triggers status events (happy path + failure path)

### Manual checks
- background/foreground transitions
- WiFi ↔ cell switching
- airplane mode reconnect

## 7. Rollout plan

- Merge to `main` and deploy to staging
- Verify:
  - ping frequency
  - status events emitted on chat requests
  - memory remains stable during repeated connect/disconnect

## 8. Acceptance criteria

- `/v1/events` exists, requires auth, and streams `ping`
- SolMobile connects after login and reconnects on drop
- `/v1/chat` produces:
  - `tx_accepted`
  - `run_started`
  - `assistant_final_ready` (after gates pass)
  - `assistant_failed` (with UI-ready detail)
- No assistant text is streamed in v0
- Polling remains correct when SSE is unavailable

## 9. References
- ADR-029: SSE foundation v0
- ADR-026: SSE chat status v0
- ADR-028: SolMobile Swift 6 upgrade
- SSE-v0.md (contract)
- SolServer-SSE-v0.md (implementation spec)

## 10. Follow-ups
- None pending for lockfile; `pnpm install` was run under Node 24 via nvm/corepack.
