# INPUT.md — PR #39 (SSE-01) Working Set

*Purpose:* single source of truth for what this PR is doing, why, and what it must not break.

## What we are building (v0)

We are adding **Server-Sent Events (SSE)** as an authenticated, server→client push channel so SolMobile can feel “alive” without relying on polling.

### v0 scope (this PR)
- SolServer exposes **`GET /v1/events`** (authenticated) using **`fastify-sse-v2` v4.2.2**, wrapped behind an interface.
- SolServer **migrates OpenAI provider integration to the Responses API** (ADR-027) so we can support provider-side SSE later, while keeping v0 delivery semantics unchanged.
- SolMobile connects using **LaunchDarkly `swift-eventsource`** behind a wrapper interface.
- SolMobile upgrades toolchain to **Swift 6.0** (required to comfortably adopt the SSE client and to standardize concurrency posture).
- SolServer sends:
  - `ping` heartbeat (every ~30s)
  - minimal **chat lifecycle** status events:
    - `tx_accepted`
    - `run_started`
    - `assistant_final_ready`
    - `assistant_failed` (includes user-visible failure detail so UI can react)

### Hard boundary (do not violate)
- **No assistant text streaming in v0.**
- SSE is **not** the system of record.
- Canonical assistant content remains the committed Transmission/OutputEnvelope produced **after gates pass** (and after any regen loops).

## Why
- Polling creates “dead air” on mobile.
- SSE provides instant feedback for:
  - request acceptance
  - work started
  - success/failure completion
- Responses API migration reduces future rework for streaming and newer models, without changing v0 UX.

## Libraries / versions (locked for this PR)
- **Server:** `fastify-sse-v2` **v4.2.2**
- **Client:** LaunchDarkly `swift-eventsource` (requires **Swift 5.1+**)
- **SolMobile toolchain:** upgrade to **Swift 6.0** across all targets/configs

## Implementation decisions (v0)
- **Library choice:** keep `fastify-sse-v2` + LaunchDarkly `swift-eventsource` (both stable and match ADRs).
- **Connection storage:** in-memory `user_id -> Set<connection>` for v0; plan Redis pub/sub or stream-backed hub in v0.1 for multi-instance fanout.
- **Connection caps:** default **3** connections per user; drop oldest on over-cap (deterministic).
- **Ping cadence:** ~30s heartbeat.
- **Client backoff:** exponential with base **~1s** + jitter (±20%), cap **~30s** + jitter (±20%), reset after **60s** idle; configured via `reconnectTime`, `maxReconnectTime`, `backoffResetThreshold` in `swift-eventsource`.
- **Responses format:** default `text.format=json_schema` strict; allow fallback via `OPENAI_TEXT_FORMAT=json_object`.

## OpenAI provider posture (v0)
- Use **Responses API** (`POST /v1/responses`).
- Use structured outputs via `text.format` (prefer `json_schema` strict for OutputEnvelope v0-min).
- `store: false` by default.
- **No provider streaming yet** (`stream: false`) to preserve gates + regen.

## SolServer SSE v0: Event emission points (Codex execution driver)

Goal: make SolMobile feel “alive” via `/v1/events` without bypassing gates. SSE is a notification pipe; canonical results remain `GET /v1/transmissions/:id`.

### Invariant (do not break)
- **Do NOT stream assistant text** in v0.
- Emit only lifecycle status events.
- Emit `assistant_final_ready` **only after** OutputEnvelope passes gates and final result is committed to persistence.
- Polling remains correct and supported.

---

## v0 event kinds (required)
- `ping` (keepalive)
- `tx_accepted`
- `run_started`
- `assistant_final_ready`
- `assistant_failed`

### Required correlation fields (per event)
- `transmission_id` (required)
- `thread_id` (optional)
- `client_request_id` (optional but recommended)
- `trace_run_id` (optional but recommended)

### `assistant_failed` payload (UI-usable)
- `code` (enum)
- `detail` (short safe string)
- `retryable` (boolean)
- `retry_after_ms` (optional)
- `category` (optional: provider|gates|network|internal)

v0 failure codes (minimal):
- `PROVIDER_TIMEOUT`
- `PROVIDER_ERROR`
- `GATE_REGEN_EXHAUSTED`
- `OUTPUT_ENVELOPE_INVALID`
- `INTERNAL_ERROR`

---

## Emission points (single responsibility per stage)

### 1) `tx_accepted`
**When:** immediately after the server has accepted the chat request and a `transmission_id` is known (new or idempotent replay).
**Where:** `/v1/chat` handler (after auth + idempotency, after transmission record exists/loaded).
**Why:** removes “dead air” immediately.

### 2) `run_started`
**When:** immediately before the OpenAI provider call begins.
**Where:** the orchestration function that calls OpenAI (single place).
**Why:** lets UI switch from “sent” to “thinking”.

### 3) `assistant_final_ready`
**When:** after OutputEnvelope is schema-valid, gates pass (including any regen), and the final result is committed.
**Where:** commit/persist function or the orchestrator right after DB commit succeeds.
**Why:** client can safely fetch final result without race.

### 4) `assistant_failed`
**When:** on terminal failure (provider terminal, timeout, regen exhausted, unexpected error).
**Where:** centralized error handler at the same orchestration layer that owns retries/regen.
**Rule:** persist failure state first, then emit.

---

## File-level TODO map (search/apply to repo structure)

### A) `/v1/events` route (SolServer)
- Ensure SSE endpoint exists and is auth-protected.
- Connection registry supports **multiple connections per user**: `user_id -> Set<conn>`.
- Send `ping` every ~30s.
- Provide internal publish API:
  - `publishToUser(userId, envelope)`
  - (optional) `publishToConnection(connId, envelope)`
- Cleanup on `close` to avoid leaks.

### B) `/v1/chat` route handler
- After idempotency resolution + `transmission_id` known: emit `tx_accepted`.
- Ensure you can pass `client_request_id` through if present.

### C) Chat orchestration / runner (provider call + gates)
- Emit `run_started` right before provider call.
- Keep OpenAI **Responses API call non-streaming** for v0 (`stream: false`) so gates validate a full OutputEnvelope.
- On success commit: emit `assistant_final_ready`.
- On terminal fail: emit `assistant_failed`.

### D) OpenAI provider migration (SolServer)
- Migrate from Chat Completions to **Responses API** (`POST /v1/responses`).
- Use `text.format` to enforce OutputEnvelope JSON.
- Set `store: false` (privacy).
- Keep `stream: false` in v0.

---

## Verification (minimal)
- With a chat request:
  - Client receives: `tx_accepted` then `run_started`.
  - After completion: `assistant_final_ready`.
  - Client fetches final via `GET /v1/transmissions/:id` and renders it.
- With forced error (e.g., provider failure):
  - Client receives `assistant_failed` with usable code/detail.
- With SSE disabled/offline:
  - Polling flow still works end-to-end.


## Event contract (v0)
- SSE framing uses:
  - `id: <event_id>`
  - `event: <event_name>`
  - `data: <json>`
- `data` MUST be a single **SSEEventEnvelope** JSON (schema versioned).
- `event` must match `kind`.

Minimum v0 kinds:
- `ping`
- `tx_accepted`
- `run_started`
- `assistant_final_ready`
- `assistant_failed`

`assistant_failed` must include:
- `code` (stable, UI-usable)
- `detail` (short human-readable string suitable for UI)
- `retryable` (boolean)
- `retry_after_ms` (optional)

## Constraints we must preserve
- Offline-first posture: app must still function without SSE by falling back to existing polling (`GET /v1/transmissions/:id`).
- Gates/enforcement: server rejects + regen remains the enforcement mechanism; SSE must not bypass it.

## Docs that define the plan
- ADR-029 — SSE foundation v0
- ADR-026 — SSE chat status v0
- ADR-027 — OpenAI Responses API migration
- ADR-028 — SolMobile Swift 6 upgrade
- SSE-v0.md — cross-cutting SSE contract (this repo)
- SolServer-SSE-v0.md — implementation spec (server-focused)
- PR #39 write-up (updated in this PR)

## Out of scope for this PR (explicit punts)
- Redis / shared broker for multi-instance fanout
- True replay/catch-up of missed events using `Last-Event-ID`
- Token-by-token assistant text deltas (preview streaming)
- Tool events (`tool_request`, `tool_progress`, etc.)
- Evidence extraction events (LATTICE-01)
