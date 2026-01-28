# SSE v0: Real-Time Status Events for SolMobile ⇄ SolServer

- Status: Draft (Task 2)
- Date: 2026-01-28
- Owners: SolServer / SolMobile
- Related ADRs:
  - ADR-029: SSE Foundation v0
  - ADR-026: SSE Chat Status v0
  - ADR-028: SolMobile Swift 6 Upgrade
- Related PR: PR #39 (SSE-01)

## 0. Purpose

SSE (Server-Sent Events) provides a **server → client** push channel so SolMobile can feel responsive without polling-induced dead air.

In v0, SSE is **not** the system of record. It is a notification pipe that tells the client “something changed,” and the client uses existing REST reads (e.g., `GET /v1/transmissions/:id`) as truth.

This document defines the v0 event contract, lifecycle, and the minimum implementation needed to support:

- `tx_accepted`
- `run_started`
- `assistant_final_ready`
- `assistant_failed`
- `ping` (keepalive)

It also outlines the planned evolution to v0.1 and v1.

## 1. Non-goals for v0

v0 explicitly does **not** attempt to do the following:

- Stream assistant text deltas (token streaming).
- Provide durable replay guarantees (“exactly once”, strict ordering as truth).
- Solve multi-instance fanout (Redis comes in v0.1).
- Introduce client → server messaging via SSE (SSE remains one-way).

This aligns with the server gates and enforcement posture: canonical assistant content is only delivered after the OutputEnvelope has passed gates and been committed. (See the evidence-bound gates doc for why partial output is dangerous as a truth boundary.)

## 2. Glossary

- **SSE**: HTTP response that stays open and emits newline-delimited events (`event`, `id`, `data`).
- **Event ID**: the `id:` field in SSE framing. Clients may persist this as `Last-Event-ID` on reconnect.
- **Last-Event-ID**: a client header used to request replay/catch-up. v0 logs it; replay is v0.1+.
- **Status event**: a small signal that references a transmission/run and helps UI state.
- **Gates**: server-side enforcement that validates and may regen model output until it conforms.

## 3. Version plan

### v0 (this PR series)
- `/v1/events` endpoint exists and is authenticated.
- In-memory connection registry.
- Heartbeat `ping` every ~30s.
- Chat lifecycle status events emitted by SolServer.
- No assistant text streaming.

### v0.1
- Shared broker (Redis) to support horizontal scaling.
- Selective catch-up (replay) for “must-not-miss” event classes.
- `resync_required` event when replay is unavailable.

### v1
- Explicit delivery semantics (typically at-least-once + idempotent client handling).
- Better ordering guarantees per logical stream.
- Background story (push wake) + foreground SSE continuity.
- Hardening: abuse controls, caps, deeper observability.

## 4. API surface

### 4.1 Endpoint

`GET /v1/events`

- Auth: required (same auth middleware as other `/v1/*` endpoints).
- Transport: SSE (HTTP/1.1 compatible).
- One-way: server → client only.

### 4.2 Required headers (server response)

Typical SSE headers (implementation detail may vary by framework/plugin):

- `Content-Type: text/event-stream`
- `Cache-Control: no-cache`
- `Connection: keep-alive`

### 4.3 Authentication header (client request)

SolMobile sends the same auth it uses for REST (e.g., `Authorization: Bearer <token>`), and the server binds the connection to `user_id` after auth.

### 4.4 Connection scoping

v0 scoping is **by user**: events are broadcast to all active connections for a user (multi-device support).

v0.1 may add optional device scoping if needed, but the default remains “all devices see the same truth”.

## 5. Event framing and contract

### 5.1 SSE framing

Each event uses standard SSE framing:

```
id: <event_id>
event: <event_name>
data: <json>
```

Rules:
- The JSON in `data:` is a single-line JSON object (no multi-line formatting).
- `event:` MUST match the JSON `kind` field (see below). This keeps filtering simple.

### 5.2 Canonical envelope: `SSEEventEnvelope v1`

All events share a common JSON envelope. This is intentionally small and stable.

TypeScript shape:

```ts
type ISO8601 = string;

type SSESubject =
  | { type: "none" }
  | { type: "transmission"; transmission_id: string; thread_id?: string; client_request_id?: string }
  | { type: "thread"; thread_id: string }
  | { type: "user"; user_id: string };

type SSETrace = {
  trace_run_id?: string | null;
};

type NotificationPolicy = "normal" | "muted";
type DisplayHint = "system1" | "system2";

type SSEEventEnvelopeV1 = {
  v: 1;
  ts: ISO8601;
  kind: "ping" | "tx_accepted" | "run_started" | "assistant_final_ready" | "assistant_failed";
  subject: SSESubject;
  trace?: SSETrace;
  // Event-specific payload; kept intentionally small
  payload: Record<string, unknown>;
};
```

Notes:
- `subject` is the primary correlation surface.
- `trace.trace_run_id` is included when available (helpful for debugging and logs).
- Event payload fields should avoid duplicating data that the client can fetch via REST. Prefer IDs + small status bits.

## 6. v0 event kinds

### 6.1 `ping`

Purpose: keep the stream alive and allow the client to detect stale connections.

Payload: empty.

Example:

```
id: 01J2...PING
event: ping
data: {"v":1,"ts":"2026-01-28T00:00:00Z","kind":"ping","subject":{"type":"none"},"payload":{}}
```

### 6.2 `tx_accepted`

Meaning: SolServer accepted the user request and created (or reused) a transmission.

When emitted:
- As soon as the server has a `transmission_id` and has decided to proceed.

Payload:

```ts
{
  transmission_status: "pending" | "queued";
  notification_policy?: NotificationPolicy;
  display_hint?: DisplayHint;
}
```

Example:

```
id: 01J2...A
event: tx_accepted
data: {"v":1,"ts":"2026-01-28T00:00:01Z","kind":"tx_accepted","subject":{"type":"transmission","transmission_id":"tx_123","thread_id":"th_456","client_request_id":"cr_789"},"trace":{"trace_run_id":"run_abc"},"payload":{"transmission_status":"queued","notification_policy":"normal","display_hint":"system1"}}
```

### 6.3 `run_started`

Meaning: the model run began (provider call started).

When emitted:
- Immediately before initiating the model/provider call (after preflight validation and routing).

Payload:

```ts
{
  provider?: "openai" | "other";
  model?: string;
}
```

Example:

```
id: 01J2...B
event: run_started
data: {"v":1,"ts":"2026-01-28T00:00:02Z","kind":"run_started","subject":{"type":"transmission","transmission_id":"tx_123","thread_id":"th_456","client_request_id":"cr_789"},"trace":{"trace_run_id":"run_abc"},"payload":{"provider":"openai","model":"gpt-5-nano"}}
```

### 6.4 `assistant_final_ready`

Meaning: the final assistant result has passed gates and is committed (persisted). The client can now fetch the transmission and render final OutputEnvelope content.

When emitted:
- After gates pass and persistence is complete.

Payload:

```ts
{
  transmission_status: "completed";
}
```

Example:

```
id: 01J2...C
event: assistant_final_ready
data: {"v":1,"ts":"2026-01-28T00:00:05Z","kind":"assistant_final_ready","subject":{"type":"transmission","transmission_id":"tx_123","thread_id":"th_456","client_request_id":"cr_789"},"trace":{"trace_run_id":"run_abc"},"payload":{"transmission_status":"completed"}}
```

Client behavior on receipt:
- Fetch `GET /v1/transmissions/tx_123` (or existing equivalent) and render the committed result.

### 6.5 `assistant_failed`

Meaning: a terminal failure occurred. The client should reflect failure state and allow user retry/resume (depending on code).

When emitted:
- When the server cannot produce a committed final response (provider failure that exhausted retry policy, gates failing after capped regens, or other terminal errors).

Payload:

```ts
type FailurePayload = {
  code: string;                 // stable code used for UI decisions
  detail: string;               // short human-readable detail (safe to show)
  retryable: boolean;           // can client offer a retry action?
  retry_after_ms?: number;      // optional suggestion (esp rate-limit)
  category?: "provider" | "gate" | "auth" | "validation" | "server";
};
```

Example:

```
id: 01J2...D
event: assistant_failed
data: {"v":1,"ts":"2026-01-28T00:00:06Z","kind":"assistant_failed","subject":{"type":"transmission","transmission_id":"tx_123","thread_id":"th_456","client_request_id":"cr_789"},"trace":{"trace_run_id":"run_abc"},"payload":{"code":"PROVIDER_TIMEOUT","detail":"Model request timed out.","retryable":true,"category":"provider"}}
```

#### v0 failure codes (initial set)

These codes are designed for stable UI messaging. They are intentionally small and coarse.

Provider failures
- `PROVIDER_TIMEOUT`
- `PROVIDER_RATE_LIMITED`
- `PROVIDER_UNAVAILABLE`
- `PROVIDER_BAD_RESPONSE`

Gate/enforcement failures
- `GATE_SCHEMA_INVALID`
- `GATE_EVIDENCE_BINDING_FAILED`
- `GATE_REGEN_EXHAUSTED`

Auth/validation/server
- `AUTH_EXPIRED`
- `REQUEST_INVALID`
- `SERVER_INTERNAL`

Rules:
- `detail` must be safe to show (no secrets, no raw prompt dumps).
- Server logs can include richer internal diagnostics keyed by `trace_run_id`.

## 7. Reconnect and “jitter”

### 7.1 Why jitter exists

When many clients reconnect at the same moment (app resumes, server restart, Wi-Fi switch), they can stampede the server. Jitter means “add a little randomness to reconnect delays” so reconnect attempts spread out.

### 7.2 v0 reconnect policy

Client reconnects with truncated exponential backoff and jitter.

Suggested v0 parameters:
- Initial delay: 2s
- Multiplier: 2x
- Cap: 30s
- Degraded UI threshold: 60s disconnected (client shows “Sync Pending” and relies on REST refresh)

Jitter approach:
- For a computed delay `d`, wait a randomized delay between `0` and `d` (full jitter), OR
- Wait a randomized delay around `d` (percent jitter). Either is acceptable as long as it spreads reconnect attempts.

Implementation note:
- If the chosen Swift library does not support jitter directly, implement jitter in the wrapper (the wrapper schedules reconnect attempts, not the library).

## 8. SolMobile responsibilities (v0)

### 8.1 Lifecycle
- Connect SSE after login.
- Disconnect on logout.
- Pause/Resume based on app foreground/background policy (battery-aware, but v0 can be simple).

### 8.2 `SSEClient` wrapper
- Wrap the concrete EventSource library so the app talks only to `SSEClient` protocol.
- The wrapper is where we enforce:
  - header injection (auth)
  - reconnect policy
  - last-event-id persistence

### 8.3 `SSEDispatcher`
- Parse `data` JSON into `SSEEventEnvelopeV1`.
- Route by:
  - `kind`
  - `payload.notification_policy` (e.g., `muted` routes to Ghost Deck)
  - `payload.display_hint` (system1 vs system2 UI routing)

### 8.4 Fallback
If SSE is not connected, SolMobile continues to function with existing polling watchers. SSE must not be required for correctness.

## 9. SolServer responsibilities (v0)

- Provide authenticated `/v1/events`.
- Maintain in-memory connection registry:
  - key: `user_id`
  - value: set of active connections
- Emit `ping` every ~30s to each active connection.
- Emit chat status events at well-defined points in the chat pipeline.
- Ensure isolation: a user never receives events for another user.

## 10. Observability (v0)

Minimum metrics/logs:
- Active SSE connections (global and per user).
- Connection opens/closes (with reason where possible).
- Events emitted per kind.
- Delivery failures (write errors to a connection).
- Reconnect counts (client-side logs).

## 11. Testing (v0)

Server
- Unit test: registry add/remove on connect/close.
- Unit test: broadcast to all connections for a user.
- Integration test: connect, receive `ping`, emit `tx_accepted` and verify receipt.

Client
- Unit test: decode envelope and route handler.
- Integration (local): connect to dev server, observe ping, then trigger chat and see status events.

## 12. 4B

### Bounds
- SSE is additive; REST remains truth.
- v0 does not provide replay guarantees.
- v0 does not stream assistant text deltas.

### Buffer
- If SSE fails, SolMobile falls back to existing polling and fetch flows.
- Reconnect uses backoff + jitter to protect SolServer during restarts.

### Breakpoints
- Connection established
- Heartbeat observed/missed
- Reconnect attempt started
- Degraded UI state entered
- Final ready received
- Failure received

### Beat
- v0: status streaming + final fetch
- v0.1: broker + selective replay/resync
- v1: reliability semantics + background story

## 13. Open questions (parked)
- Do we ever need device-scoped events (only send to one device)?
- How should we represent “regen in progress” in status events (if useful)?
- Should `assistant_failed` always imply transmission is terminal, or can it mean “retry scheduled”?
