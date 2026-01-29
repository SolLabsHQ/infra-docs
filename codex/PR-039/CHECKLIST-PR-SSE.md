# CHECKLIST.md — PR #39 (SSE-01)

## Docs + Governance
- [ ] ADR-029 (SSE foundation) is present and referenced from PR description
- [ ] ADR-026 (SSE chat status) is present and referenced
- [ ] ADR-027 (OpenAI Responses API migration) is present and referenced
- [ ] ADR-028 (Swift 6 upgrade) is present and referenced
- [ ] SSE-v0.md is present and referenced
- [ ] SolServer-SSE-v0.md is present and referenced
- [ ] PR description reflects **chat status events are in-scope** (Change Proposal applied)
- [ ] PR description reflects **OpenAI Responses API migration is in-scope** (Change Proposal applied)

## SolServer
### Endpoint + auth
- [x] Add `GET /v1/events` route
- [x] Route is protected by existing auth middleware
- [x] Response headers and framing are correct for SSE (`text/event-stream`, no caching, flush behavior)

### Library + interfaces
- [x] Use `fastify-sse-v2` v4.2.2 (wrapped)
- [x] Implement `SSEHub` interface
- [x] Implement `InMemorySSEHub` (v0)
- [x] Connection registry supports **multiple connections per user** (`user_id -> set<connection>`)

### Heartbeat + cleanup
- [x] Emit `ping` every ~30s to active connections
- [x] On disconnect/close: remove connection from registry
- [x] Guard against unbounded growth (basic caps + logs)

### Chat status events (v0)
- [x] Define `SSEEventEnvelope` JSON and server serializer
- [x] Emit `tx_accepted` when SolServer accepts `/v1/chat` and has a `transmission_id`
- [x] Emit `run_started` when provider work begins
- [x] Emit `assistant_final_ready` only after:
  - OutputEnvelope schema validated
  - gates pass (including regen loops if needed)
  - transmission is persisted and fetchable via `GET /v1/transmissions/:id`
- [x] Emit `assistant_failed` on terminal failure with:
  - code + detail + retryable (+ retry_after_ms when relevant)
- [x] Ensure **no assistant text deltas** are emitted in v0

### OpenAI provider (Responses API migration)
- [x] Migrate provider endpoint from `POST /v1/chat/completions` → `POST /v1/responses`
- [x] Map existing “messages” prompting into Responses `input` shape (string or list of role/content items)
- [x] Replace `response_format` with `text.format`:
  - Prefer `type: "json_schema"` + `strict: true` for OutputEnvelope v0-min
  - Allow fallback to `type: "json_object"` behind a flag if needed
- [x] Set `store: false` by default
- [x] Keep `stream: false` in v0 (buffered) to preserve gates + regen
- [x] Parse Responses output into:
  - `assistant_text` (from the output message item’s `output_text` blocks)
  - `OutputEnvelope` JSON (from structured output / parsed JSON)
- [ ] Handle and surface provider terminal states:
  - refusal / safety
  - incomplete generations
  - network / timeout
  - provider 4xx/5xx
- [ ] Ensure `/v1/chat` behavior remains identical to clients (200/202 semantics + idempotency)

### Observability
- [ ] Log connect/disconnect with user_id + connection_id (redacted as needed)
- [ ] Track active connection count
- [ ] Track events emitted per kind (basic counters)
- [ ] Provider logs include OpenAI `response_id` when available

### Tests
- [ ] Unit tests: connection add/remove; event emission routing
- [ ] Unit tests: envelope serialization
- [ ] Unit tests: Responses parsing (output_text extraction + structured JSON parse)
- [ ] Integration test: connect → receive ping → disconnect cleanup
- [ ] Integration test: `/v1/chat` lifecycle emits expected status events (happy path + failure path)
- [ ] Integration test: `/v1/chat` still returns correct 200/202 + polling behavior

## SolMobile
### Toolchain baseline
- [x] Update `SWIFT_VERSION = 6.0` across all targets/configs (app + tests)
- [ ] Set initial concurrency checking posture (per ADR-028)
- [x] App builds and launches

### Client + wrapper
- [x] Add `SSEClient` protocol (wrapper boundary)
- [x] Implement `LaunchDarklyEventSourceClient` (concrete adapter)
- [x] Connect on login, disconnect on logout
- [x] Pass auth token/headers correctly
- [x] Use `x-sol-user-id` from `UserIdentity.resolvedId()` for REST + SSE (same UUID)
- [x] Reconnect with backoff + jitter
- [ ] Persist last event id locally (even if replay is not implemented yet)

### Dispatcher + routing
- [x] Decode `SSEEventEnvelope`
- [x] Route:
  - `ping` -> update connection health
  - `tx_accepted` / `run_started` -> update UI state for the transmission
  - `assistant_final_ready` -> trigger fetch `GET /v1/transmissions/:id` and render final OutputEnvelope
  - `assistant_failed` -> surface user-facing status with code + detail, and determine next action (retry vs wait)
- [x] If SSE is unavailable: fall back to existing polling watchers
- [x] Guard `Message.thread` inserts; skip insert + log if thread is unavailable (prevents CoreData 1570 orphans)

### Tests
- [ ] Unit test: envelope decoding
- [ ] Unit test: reconnection and state transitions (as feasible)
- [ ] Manual: airplane mode, WiFi↔cell, background/foreground transitions

## Product checks (v0)
- [ ] No “dead air”: message transitions quickly from “sent” -> “thinking”
- [ ] Failure UI is understandable and actionable (retry vs wait)
- [ ] No cases where the UI shows assistant text that failed gates

## Release checks
- [x] Deployed to staging
  - `flyctl secrets set SOL_INLINE_PROCESSING=1 -a solserver-staging`
  - `flyctl deploy -c fly.toml -a solserver-staging`
- [x] Verify ping every ~30s
  - `curl -sS -N -m 70 -H "Authorization: Bearer $SOLSERVER_STAGING_TOKEN" -H "x-sol-user-id: $SOL_TEST_USER_ID" "$SOLSERVER_STAGING_HOST/v1/events"` (`/tmp/sse-liveness-inline-1769634426.log`)
- [x] Verify chat status events in staging logs
  - `curl -sS -N -H "Authorization: Bearer $SOLSERVER_STAGING_TOKEN" -H "x-sol-user-id: $SOL_TEST_USER_ID" "$SOLSERVER_STAGING_HOST/v1/events"`
  - `curl -sS -H "Authorization: Bearer $SOLSERVER_STAGING_TOKEN" -H "Content-Type: application/json" -H "x-sol-user-id: $SOL_TEST_USER_ID" -X POST "$SOLSERVER_STAGING_HOST/v1/chat" -d '{"threadId":"TEST","message":"SSE staging check (inline)","clientRequestId":"sse-check-inline-001"}'`
  - Order observed: `tx_accepted → run_started → assistant_final_ready` (`/tmp/sse-happy-inline-1769634506.log`)
- [x] Verify Responses API migration works in staging (200/202 semantics unchanged)
  - `curl -sS -D /tmp/chat-status-inline-1769634692.hdr -o /tmp/chat-status-inline-1769634692.json -H "Authorization: Bearer $SOLSERVER_STAGING_TOKEN" -H "Content-Type: application/json" -H "x-sol-user-id: $SOL_TEST_USER_ID" -X POST "$SOLSERVER_STAGING_HOST/v1/chat" -d '{"threadId":"TEST","message":"SSE responses API staging check","clientRequestId":"sse-resp-inline-001"}'` (HTTP 200)
- [x] Verify failure flow emits `assistant_failed`
  - `curl -sS -N -H "Authorization: Bearer $SOLSERVER_STAGING_TOKEN" -H "x-sol-user-id: $SOL_TEST_USER_ID" "$SOLSERVER_STAGING_HOST/v1/events"`
  - `curl -sS -H "Authorization: Bearer $SOLSERVER_STAGING_TOKEN" -H "Content-Type: application/json" -H "x-sol-user-id: $SOL_TEST_USER_ID" -H "x-sol-simulate-status: 500" -X POST "$SOLSERVER_STAGING_HOST/v1/chat" -d '{"threadId":"TEST","message":"SSE staging failure check (inline)","clientRequestId":"sse-fail-inline-001"}'`
  - Observed: `tx_accepted → assistant_failed` (`/tmp/sse-fail-inline-1769634597.log`)
- [x] Polling fallback works with SSE disabled/unreachable
  - `curl -sS -H "Authorization: Bearer $SOLSERVER_STAGING_TOKEN" -H "Content-Type: application/json" -H "x-sol-user-id: $SOL_TEST_USER_ID" -X POST "$SOLSERVER_STAGING_HOST/v1/chat" -d '{"threadId":"TEST","message":"SSE polling fallback check (inline)","clientRequestId":"sse-poll-inline-001"}'`
  - `curl -sS -H "Authorization: Bearer $SOLSERVER_STAGING_TOKEN" -H "x-sol-user-id: $SOL_TEST_USER_ID" "$SOLSERVER_STAGING_HOST/v1/transmissions/<transmission_id>"` (`/tmp/transmission-poll-inline-dde1a88d-54ab-4111-b001-f4b49eb874a6.json`)
- [ ] Verify memory usage stable under repeated connect/disconnect

## SSE v0 + Responses API migration (PR #39) — CHECKLIST

### Docs / ADRs (must be in PR)
- [ ] ADR-026 (SSE chat status v0) present and reflects **status-only** streaming (no assistant text deltas).
- [ ] ADR-027 (OpenAI Responses API migration) present and reflects **stream:false** in v0, `store:false`, `text.format`.
- [ ] ADR-028 (Swift 6 upgrade) present and reflects toolchain baseline + migration posture.
- [ ] PR body updated to match scope: `/v1/events` + ping + chat status events + Responses migration.

---

## SolServer: SSE `/v1/events`

### Endpoint + auth
- [x] `GET /v1/events` exists and requires auth.
- [x] Response headers correct for SSE (`Content-Type: text/event-stream`, keepalive-friendly).
- [ ] Endpoint is stable under reconnect.

### Connection registry
- [x] Registry supports **multiple connections per user**: `user_id -> Set<connection>`.
- [x] Connections are removed on close (no leak).
- [x] Connection cap enforced (default: 3 per user), with deterministic eviction or refusal behavior documented.

### Heartbeat
- [x] `ping` event emitted every ~30s to all active connections.
- [ ] Client detects missing pings and transitions to reconnect / degraded UI.

### Publish API
- [x] Internal publish function exists: `publishToUser(userId, envelope)`.
- [x] Event envelope includes `kind`, `ts`, `subject`, optional `trace`, and `payload`.
- [x] `event:` name matches `kind` (or is mapped deterministically).

---

## SolServer: Chat status events

### Event kinds (required)
- [x] `tx_accepted`
- [x] `run_started`
- [x] `assistant_final_ready`
- [x] `assistant_failed`

### Correlation fields
- [x] Each status event includes:
  - [x] `transmission_id` (required)
  - [x] `thread_id` (optional)
  - [x] `client_request_id` (optional but recommended)
  - [x] `trace_run_id` (optional but recommended)

### Emission points (verify single responsibility)
- [x] `tx_accepted` emitted in `/v1/chat` handler after auth+idempotency and `transmission_id` known.
- [x] `run_started` emitted immediately before provider call begins.
- [x] `assistant_final_ready` emitted **after** gates pass and final commit succeeds.
- [x] `assistant_failed` emitted on terminal failure **after** failure state is persisted.

### Failure payload (UI-usable)
- [x] `assistant_failed.payload` includes:
  - [x] `code` (enum)
  - [x] `detail` (safe string)
  - [x] `retryable` (boolean)
  - [x] `retry_after_ms` (optional)
  - [x] `category` (optional)
- [x] v0 failure codes implemented:
  - [x] `PROVIDER_TIMEOUT`
  - [x] `PROVIDER_ERROR`
  - [x] `GATE_REGEN_EXHAUSTED`
  - [x] `OUTPUT_ENVELOPE_INVALID`
  - [x] `INTERNAL_ERROR`

---

## SolServer: Gates boundary / invariants

- [x] **No assistant text is streamed** in v0 SSE (status-only).
- [ ] OutputEnvelope validation + post-linter enforcement remain unchanged: server rejects + regen still works.
- [x] `assistant_final_ready` is emitted only when `GET /v1/transmissions/:id` will return the committed final result (no race).

---

## SolServer: OpenAI Responses API migration (v0)

### Provider call shape
- [x] Replace `/v1/chat/completions` with `POST /v1/responses`.
- [x] Use `text.format` to enforce OutputEnvelope JSON.
- [x] Set `store: false`.
- [x] Set `stream: false` for v0.

### Parsing + contract
- [x] Provider response parsed into OutputEnvelope (same server contract as before).
- [ ] Gate/regen loop operates on the parsed OutputEnvelope.
- [ ] Integration tests updated for provider request/response mapping.

---

## SolMobile: Swift 6 + SSE client

### Swift 6 upgrade
- [x] `SWIFT_VERSION = 6.0` set for all targets/configs.
- [x] App compiles under Swift 6; minimal concurrency issues fixed or documented.
- [ ] Toolchain baseline documented (Xcode version required).

### SSE client wiring
- [x] LaunchDarkly `swift-eventsource` integrated behind `SSEClient` interface.
- [x] `SSEDispatcher` decodes event envelope and routes by `kind`.
- [x] Connection starts on login; stops on logout.
- [x] Reconnect uses backoff + jitter, with “Sync Pending” UI after prolonged disconnect.

### Routing behavior (v0)
- [x] `tx_accepted` updates UI to “Sent/Queued”.
- [x] `run_started` updates UI to “Thinking”.
- [x] `assistant_final_ready` triggers `GET /v1/transmissions/:id` fetch and renders final.
- [x] `assistant_failed` shows appropriate UI based on code/retryable.

---

## Verification (staging)

### Happy path
- [ ] Send chat:
  - [ ] Observe `tx_accepted`
  - [ ] Observe `run_started`
  - [ ] Observe `assistant_final_ready`
  - [ ] Client fetches final and renders it.
- [ ] Polling-only still works if SSE is disabled.

### Failure path
- [ ] Force a provider error:
  - [ ] Observe `assistant_failed` with code + detail + retryable.
  - [ ] UI displays failure appropriately; polling does not hang.

### Resource stability
- [ ] Connections do not leak on server.
- [ ] Multiple device connections behave correctly (no stomp).
- [ ] Server logs show stable open/close counts; no unbounded growth.
