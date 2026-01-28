# SolServer SSE v0: Implementation Spec (SSEHub + Chat Status Events)

- Status: Draft (Task 2)
- Date: 2026-01-28
- Owners: SolServer
- Related docs:
  - PR #39: SSE-01 foundation write-up
  - SSE v0 contract: `SSE-v0.md`
  - Evidence-bound gates + regen: `evidence-gates-offline-critic-v0.md`

## 0. What we are building

In v0, SolServer adds a **single authenticated SSE endpoint** (`GET /v1/events`) and a minimal set of **chat lifecycle status events** to eliminate polling dead air:

- `tx_accepted`
- `run_started`
- `assistant_final_ready`
- `assistant_failed`
- `ping` (keepalive)

SSE does not become the system of record. It is a push notification layer over existing transmission persistence and fetch endpoints.

## 1. Constraints we must not violate

### 1.1 Offline-first compatibility
SolMobile must remain functional without a live SSE connection. Polling + REST fetch semantics remain correct.

### 1.2 Gates stay sovereign
SolServer gates can reject outputs and force regen. Streaming raw assistant text before gates pass would bypass enforcement. Therefore:
- v0 streams status only.
- Final content is only available via committed transmission reads.

This is aligned with the “server rejects + regen” enforcement model.

### 1.3 Multi-device by default
A user may have multiple active clients. In v0, we broadcast events to all active connections for the user.

### 1.4 Single-instance operational posture (v0 demo safety)
In-memory connection state implies we should run SolServer as a single instance for demo and early v0 unless we have sticky routing. v0.1 introduces Redis for true horizontal scaling.

## 2. Architecture

### 2.1 Components

1. **SSE Route** (`GET /v1/events`)
   - Authenticated route that upgrades the response to SSE and registers the connection.

2. **ConnectionRegistry (in-memory, v0)**
   - Stores active connections keyed by `user_id`.
   - Supports multiple concurrent connections per user.

3. **SSEHub (interface)**
   - Primary API used by services to emit events.
   - Hides implementation details of `fastify-sse-v2`.

4. **EventBus (internal)**
   - Decouples event creation from delivery to sockets.
   - In v0 it can be a thin layer; in v0.1 it becomes the seam for Redis pub/sub.

5. **Chat Orchestrator Integration**
   - Emits the chat lifecycle events at well-defined breakpoints.

### 2.2 Data flow (high-level)

**Connect**
- Client calls `/v1/events` with auth.
- Server authenticates, registers connection in registry, starts ping schedule.

**Chat request**
- Client `POST /v1/chat` (existing behavior).
- Server emits `tx_accepted` quickly after transmission id is known.
- When model call starts: emit `run_started`.
- After gates pass and transmission is committed: emit `assistant_final_ready`.
- If terminal failure: emit `assistant_failed`.

Client still fetches the final transmission via REST.

## 3. Interfaces

### 3.1 `SSEHub` (v0)

```ts
type UserId = string;

type SSEEventEnvelopeV1 = {
  v: 1;
  ts: string;
  kind: "ping" | "tx_accepted" | "run_started" | "assistant_final_ready" | "assistant_failed";
  subject: Record<string, unknown>;
  trace?: { trace_run_id?: string | null };
  payload: Record<string, unknown>;
};

interface SSEHub {
  // Broadcast to all active connections for a user
  publishToUser(userId: UserId, event: SSEEventEnvelopeV1): void;

  // Admin/ops
  activeConnectionCount(): number;
  activeConnectionCountForUser(userId: UserId): number;
}
```

### 3.2 `ConnectionRegistry` (v0)

```ts
type ConnectionId = string;

type SSEConnection = {
  id: ConnectionId;
  userId: string;
  createdAtMs: number;
  // plugin-specific stream handle; opaque to callers
  stream: unknown;
};

interface ConnectionRegistry {
  add(conn: SSEConnection): void;
  remove(userId: string, connId: ConnectionId): void;
  list(userId: string): SSEConnection[];
  countAll(): number;
  countUser(userId: string): number;
}
```

Design note:
- Do **not** store a single connection per user. Store a set.

### 3.3 Event ID generation

v0 requirement:
- Each event MUST set an SSE `id:` field so clients can persist `Last-Event-ID`.

Implementation guidance:
- Use ULID or similar time-sortable IDs, OR
- Use `${transmission_id}:${monotonic_seq}` for transmission-scoped ordering.
- Do not block v0 on strict ordering semantics; it is sufficient that IDs are unique and stable.

## 4. Event emission breakpoints in the chat pipeline

This section is the “no hand-waving” part: where we emit, and why.

### 4.1 `tx_accepted`

Emit when:
- The request has passed basic validation and auth, and
- A transmission exists (created or reused via idempotency).

Minimum correlation:
- `transmission_id` (required)
- `thread_id` (if available)
- `client_request_id` (if provided)

Reason:
- This is the key UX unlock: it flips the UI from “sending…” to “queued/accepted” immediately.

### 4.2 `run_started`

Emit when:
- The server begins the provider call (OpenAI/other).

Reason:
- This aligns UI “thinking” state with actual work start, not just request receipt.

### 4.3 `assistant_final_ready`

Emit when:
- OutputEnvelope is fully generated, passed gates, and persisted to the transmission record.

Reason:
- Client can now fetch and render canonical content.

### 4.4 `assistant_failed`

Emit when:
- Terminal failure (provider retries exhausted, gate regen exhausted, server internal error).

Payload requirements:
- `code` (stable UI code)
- `detail` (safe, short)
- `retryable` (boolean)
- optional `retry_after_ms`
- optional `category`

Important:
- The transmission record should also reflect terminal failure so polling clients converge.

## 5. Connection lifecycle and ping

### 5.1 Registering connections
On connect:
- Add connection to registry under the authenticated `user_id`.
- Subscribe the connection to hub publishing.

On close:
- Remove connection from registry.
- Ensure ping timers are cleared (no leaks).

### 5.2 Ping schedule
- Send `ping` event every ~30s to each active connection.
- Prefer a real event (`event: ping`) over comment-only pings.

## 6. Delivery behavior and backpressure

### 6.1 Best-effort writes
If writing to a connection fails:
- Log it with `user_id`, `conn_id`, and a reason if available.
- Remove the connection from registry.

### 6.2 Connection caps (v0)
Add conservative caps to avoid a runaway memory footprint:
- Max connections per user (example: 3–5).
- If cap is exceeded, close the oldest connection (or reject the new one).
Exact number is a tuning knob; v0 can start with 3.

## 7. Security and privacy

- `/v1/events` requires auth.
- Events are emitted only to the authenticated user’s connections.
- v0 events should contain IDs and small status fields only.
- Avoid putting assistant content into SSE in v0.

## 8. v0.1: Redis seam

The registry and hub must be coded so we can swap the underlying bus:

- v0: `InMemoryHub` + local registry
- v0.1: `RedisHub` (pub/sub) + per-instance registry for socket handles

Key requirement:
- Event publishing call-sites do not change.

## 9. Testing plan

### 9.1 Server unit tests
- Registry add/remove and per-user fanout.
- Publish to user with multiple connections.
- Remove connection on write failure.

### 9.2 Integration test
- Start server.
- Connect SSE client with auth.
- Trigger a chat request.
- Assert event order contains at least:
  - `tx_accepted` then `run_started` then terminal (`assistant_final_ready` or `assistant_failed`)
- Disconnect and assert registry count returns to baseline.

## 10. 4B

### Bounds
- SSE is additive. REST remains truth.
- v0 does not implement replay/catch-up.
- v0 does not stream assistant text deltas.

### Buffer
- If SSE is down, polling clients still converge.
- Write failures remove connections to avoid leak buildup.

### Breakpoints
- Connection open/close
- Ping sent
- tx_accepted emitted
- run_started emitted
- terminal event emitted (final or failed)
- connection removed on write error

### Beat
- v0: in-memory hub + status events
- v0.1: Redis hub + selective replay/resync
- v1: reliability semantics + background story

## 11. Open questions (parked)
- Should we include “regen_attempt” status for long gate loops (likely v0.1)?
- Should we add device-scoped targeting (likely not needed early)?
- Do we want sticky routing as a hard requirement until Redis (ops decision)?
