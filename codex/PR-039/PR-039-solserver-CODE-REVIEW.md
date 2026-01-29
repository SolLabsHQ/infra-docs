## Code Review: solserver PR #39

### Verdict
- [ ] Approve
- [x] Approve with nits
- [ ] Block

### High-risk areas in this PR
- `/v1/events` SSE headers + buffering behavior on Fly/proxies
- Connection registry cleanup (leaks)
- Event emission ordering vs DB commit (race)
- OpenAI Responses API strict schema correctness (`additionalProperties:false` everywhere)
- Retryability classification (400 invalid schema must be non-retryable)

### Contract + invariants (block if violated)
- [x] SSE is **status-only** in v0 (no assistant text deltas over `/v1/events`).
- [x] `assistant_final_ready` emitted **after** final persistence commit (verify in code path).
- [x] Polling remains source of truth: `GET /v1/transmissions/:id` returns final after final_ready.
- [x] Failure events include UI-usable payload: code/detail/retryable/retry_after_ms.

### SSE endpoint correctness
- [x] Headers set explicitly:
  - Content-Type: text/event-stream
  - Cache-Control: no-cache
  - X-Accel-Buffering: no
  - flushHeaders called (or equivalent)
- [x] Ping cadence ~30s and timer is cleaned up on disconnect. (Idle timer cleared in `solserver/src/sse/sse_hub.ts`)
- [x] Connection registry is `user_id -> Set<conn>` not single conn.
- [x] Cleanup on close removes conn from registry (no unbounded growth).

### Event emission points (pressure-test)
- [x] `tx_accepted` emitted once transmission_id is known (after idempotency resolution).
- [x] `run_started` emitted only when orchestration actually begins provider work.
- [x] `assistant_failed` emitted after failure state persisted (payload safe, no secrets).
- [x] Simulated failure header short-circuits correctly (no run_started expected if it fails before provider).

### OpenAI Responses API migration (this bit burned us)
- [x] Default uses strict `json_schema` with recursive `additionalProperties:false`.
- [x] `OPENAI_TEXT_FORMAT=json_object` is explicitly a fallback (documented).
- [x] `store:false` set.
- [x] `stream:false` upstream in v0 (intentional).
- [x] 400 invalid_json_schema/invalid_request_error is mapped to retryable=false.

### Worker vs SSE process boundary (known constraint)
- [x] SOL_INLINE_PROCESSING gate is documented as staging-only workaround.
- [x] Without inline, worker emissions do not reach SSE clients (acknowledged).
- [x] v0.1 ticket exists for RedisHub fanout.

### Evidence (staging gate)
- [x] Liveness ping log attached (`sse-liveness-inline-1769634426.log`).
- [x] Happy path log shows tx_accepted → run_started → assistant_final_ready (`sse-happy-inline-1769634506.log`).
- [x] GET shows pending=false after final_ready (`transmission-inline-3afddef2-c9f6-45c0-b53d-aa2ccabe8823.json`).
- [x] Failure log shows assistant_failed payload (`sse-fail-inline-1769634597.log`).
- [x] Polling fallback log shows pending=false (`transmission-poll-inline-dde1a88d-54ab-4111-b001-f4b49eb874a6.json`).

### Nits / Improvements
- [ ] Add minimal metrics: active connections count, disconnect reasons (if trivial).
- [ ] Confirm no secrets/keys appear in logs or SSE payloads.

### Notes
- Ping timer now stops when the last connection closes (commit `1cf2672`).
- Inline processing was required to pass staging SSE order checks; cross-process fanout ticketed (issue #40).
- Failure simulate short-circuits before provider; absence of run_started in that flow is expected.
