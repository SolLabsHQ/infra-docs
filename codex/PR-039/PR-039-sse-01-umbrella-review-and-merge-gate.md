\#\# Umbrella Review: PR \#39 (SSE-01 Foundation) — infra-docs \+ solserver \+ solmobile

\#\#\# Why  
Staging is the merge gate for PR \#39. We needed to validate Fly integration (SSE stability, auth, reconnect behavior) and ensure the SSE status pipe does not bypass gates.

\#\#\# Connected PRs  
\- infra-docs: \<LINK\>  
\- solserver: \<LINK\>  
\- solmobile: \<LINK\>

\---

\#\# What changed (cross-repo)  
\- \*\*SolServer SSE:\*\* Added \`/v1/events\` SSE foundation \+ lifecycle status events (\`tx\_accepted\`, \`run\_started\`, \`assistant\_final\_ready\`, \`assistant\_failed\`) to eliminate “dead air” while keeping canonical content behind gates.  
\- \*\*SolMobile SSE \+ Swift 6:\*\* Upgraded to Swift 6 and wired LaunchDarkly EventSource behind interfaces. Outbox banner transitions Sending → Sent/Queued → Thinking → Final/Failed based on SSE status events.  
\- \*\*OpenAI Responses migration:\*\* SolServer provider moved to \`/v1/responses\` with structured output enforcement; upstream provider streaming remains off for v0 so gates validate a full OutputEnvelope.  
\- \*\*Docs/ADRs:\*\* ADR-026/027/028/029 \+ SSE-v0.md \+ SolServer-SSE-v0.md \+ INPUT/CHECKLIST/FIXLOG updated and reconciled against staging evidence.

\---

\#\# Staging Merge Gate: Evidence (PASS with inline processing enabled)  
\#\#\# SSE liveness (ping cadence)  
\- \`sse-liveness-inline-1769634426.log\`    
  pings observed at \~30s cadence (e.g. 21:07:06Z, 21:07:36Z, 21:08:06Z)

\#\#\# Happy path (SSE order \+ commit correctness)  
\- \`sse-happy-inline-1769634506.log\`    
  observed: \`tx\_accepted → run\_started → assistant\_final\_ready\`  
\- \`transmission-inline-3afddef2-c9f6-45c0-b53d-aa2ccabe8823.json\`    
  confirmed: \`pending=false\` after \`assistant\_final\_ready\` (commit is fetchable)

\#\#\# Failure path (SSE failure payload)  
\- \`sse-fail-inline-1769634597.log\`    
  observed: \`tx\_accepted → assistant\_failed\`    
  note: no \`run\_started\` is expected when \`x-sol-simulate-status\` short-circuits pre-provider; payload includes code/detail/retryable

\#\#\# Polling fallback (SSE disabled / unreachable)  
\- \`transmission-poll-inline-dde1a88d-54ab-4111-b001-f4b49eb874a6.json\`    
  confirmed: polling resolves to \`pending=false\`

\#\#\# Responses API sanity  
\- \`chat-status-inline-1769634692.hdr\` shows HTTP/2 200 on staging call

\---

\#\# Important constraint: why inline processing was used on staging  
Before enabling inline processing, staging only emitted \`tx\_accepted\` over SSE because the worker process could not publish to the in-memory SSE hub owned by the API process.

To satisfy the merge gate and validate Fly SSE behavior end-to-end, staging was run with:  
\- \`SOL\_INLINE\_PROCESSING=1\`

This is explicitly a \*\*staging verification posture\*\*, not the long-term production design.

\*\*Deferred to v0.1 (tracked):\*\*  
\- Cross-process/instance SSE fanout (RedisHub/pubsub) so worker events reach SSE connections without inline mode.  
\- Reconnect soak \+ memory profiling for long-run SSE stability.

\---

\#\# Risk  
\- Risk level: \*\*Medium\*\*  
\- Primary risks (known \+ mitigated):  
  \- \*\*Cross-process fanout\*\*: in-memory registry doesn’t work across worker/API processes (mitigated in staging via inline mode; v0.1 ticketed).  
  \- \*\*Proxy buffering / connection cleanup\*\*: explicit SSE headers added (\`X-Accel-Buffering: no\`, flush headers) and ping keepalive verified on Fly; soak test deferred.  
  \- \*\*Responses API schema strictness\*\*: strict json\_schema required recursive \`additionalProperties:false\`; fallback exists; verified no assistant text is streamed over SSE.

Rollback posture (if needed):  
\- Disable SSE client-side (fallback to polling)  
\- Revert \`/v1/events\` route  
\- Revert provider to Chat Completions (only if Responses integration proves unstable)  
\- Revert Swift 6 if toolchain stability becomes an issue (unlikely given build success)

\---

\#\# Merge plan  
\*\*Order:\*\*  
1\) infra-docs  
2\) solserver  
3\) solmobile

\*\*Post-merge staging hygiene (recommended):\*\*  
\- Unset staging inline flag and re-smoke:  
  \- \`flyctl secrets unset SOL\_INLINE\_PROCESSING \-a solserver-staging\` (or set to 0\)  
  \- re-run \`/v1/events\` liveness \+ one \`/v1/chat\` SSE order \+ GET confirm

\---

\#\# Remaining open item (non-blocking)  
\- “Verify memory usage stable under repeated connect/disconnect”    
  Suggested follow-up: reconnect soak \+ memory profile on Fly staging (ticketed).

\---

\#\# Review request  
Each repo PR has a repo-specific code review checklist comment. Please evaluate within that PR’s scope (server transport/provider correctness vs client lifecycle/UI vs docs/ADR accuracy).

\#\# Code Review: infra-docs PR \#39

\#\#\# Verdict  
\- \[ \] Approve  
\- \[ \] Approve with nits  
\- \[ \] Block

\#\#\# What I reviewed  
\- ADR-026/027/028/029: consistency \+ no contradictions  
\- SSE-v0.md \+ SolServer-SSE-v0.md: contract matches implementation intent (status-only)  
\- INPUT/CHECKLIST/FIXLOG: match actual staging evidence \+ no invented claims

\#\#\# Must-haves (blocking if missing)  
\- \[ \] The “status-only SSE” invariant is explicit everywhere (no assistant text deltas in v0).  
\- \[ \] \`assistant\_final\_ready\` is documented as \*\*post-commit\*\* and never pre-commit.  
\- \[ \] Staging gate evidence is recorded with file names \+ timestamps and clearly notes SOL\_INLINE\_PROCESSING=1 usage.  
\- \[ \] Cross-process fanout limitation is stated plainly \+ deferred to v0.1 with a tracking item.  
\- \[ \] Revert plan for staging env var is documented (when/how to unset).

\#\#\# Drift checks (common failure mode)  
\- \[ \] Docs match the current repo file names/paths (no “aspirational” sections).  
\- \[ \] Checklists mark only what’s proven; “PASS” items cite log evidence.

\#\#\# Nits / Improvements  
\- \[ \] Replace any vague terms (“works”, “stable”) with the exact check performed (curl commands, headers, log proof).  
\- \[ \] Add a one-liner explaining why \`stream:false\` upstream is intentional for v0 (gates require full OutputEnvelope).

\#\#\# Follow-ups  
\- \[ \] Ticket: RedisHub cross-process SSE fanout (worker → SSE)  
\- \[ \] Ticket: reconnect soak \+ memory profile (Fly staging)

—-

\#\# Code Review: solserver PR \#39

\#\#\# Verdict  
\- \[ \] Approve  
\- \[ \] Approve with nits  
\- \[ \] Block

\#\#\# High-risk areas in this PR  
\- \`/v1/events\` SSE headers \+ buffering behavior on Fly/proxies  
\- Connection registry cleanup (leaks)  
\- Event emission ordering vs DB commit (race)  
\- OpenAI Responses API strict schema correctness (\`additionalProperties:false\` everywhere)  
\- Retryability classification (400 invalid schema must be non-retryable)

\#\#\# Contract \+ invariants (block if violated)  
\- \[ \] SSE is \*\*status-only\*\* in v0 (no assistant text deltas over \`/v1/events\`).  
\- \[ \] \`assistant\_final\_ready\` emitted \*\*after\*\* final persistence commit (verify in code path).  
\- \[ \] Polling remains source of truth: \`GET /v1/transmissions/:id\` returns final after final\_ready.  
\- \[ \] Failure events include UI-usable payload: code/detail/retryable/retry\_after\_ms.

\#\#\# SSE endpoint correctness  
\- \[ \] Headers set explicitly:  
  \- Content-Type: text/event-stream  
  \- Cache-Control: no-cache  
  \- X-Accel-Buffering: no  
  \- flushHeaders called (or equivalent)  
\- \[ \] Ping cadence \~30s and timer is cleaned up on disconnect.  
\- \[ \] Connection registry is \`user\_id \-\> Set\<conn\>\` not single conn.  
\- \[ \] Cleanup on close removes conn from registry (no unbounded growth).

\#\#\# Event emission points (pressure-test)  
\- \[ \] \`tx\_accepted\` emitted once transmission\_id is known (after idempotency resolution).  
\- \[ \] \`run\_started\` emitted only when orchestration actually begins provider work.  
\- \[ \] \`assistant\_failed\` emitted after failure state persisted (payload safe, no secrets).  
\- \[ \] Simulated failure header short-circuits correctly (no run\_started expected if it fails before provider).

\#\#\# OpenAI Responses API migration (this bit burned us)  
\- \[ \] Default uses strict \`json\_schema\` with recursive \`additionalProperties:false\`.  
\- \[ \] \`OPENAI\_TEXT\_FORMAT=json\_object\` is explicitly a fallback (documented).  
\- \[ \] \`store:false\` set.  
\- \[ \] \`stream:false\` upstream in v0 (intentional).  
\- \[ \] 400 invalid\_json\_schema/invalid\_request\_error is mapped to retryable=false.

\#\#\# Worker vs SSE process boundary (known constraint)  
\- \[ \] SOL\_INLINE\_PROCESSING gate is documented as staging-only workaround.  
\- \[ \] Without inline, worker emissions do not reach SSE clients (acknowledged).  
\- \[ \] v0.1 ticket exists for RedisHub fanout.

\#\#\# Evidence (staging gate)  
\- \[ \] Liveness ping log attached  
\- \[ \] Happy path log shows tx\_accepted → run\_started → assistant\_final\_ready  
\- \[ \] GET shows pending=false after final\_ready  
\- \[ \] Failure log shows assistant\_failed payload  
\- \[ \] Polling fallback log shows pending=false

\#\#\# Nits / Improvements  
\- \[ \] Add minimal metrics: active connections count, disconnect reasons (if trivial).  
\- \[ \] Confirm no secrets/keys appear in logs or SSE payloads.

—-

\#\# Code Review: solmobile PR \#39

\#\#\# Verdict  
\- \[ \] Approve  
\- \[ \] Approve with nits  
\- \[ \] Block

\#\#\# High-risk areas in this PR  
\- Swift 6 migration correctness (MainActor isolation, Sendable issues)  
\- SSE lifecycle (login/logout, background/foreground)  
\- UI state machine correctness (banner transitions)  
\- Header injection consistency (\`x-sol-user-id\` on REST \+ SSE)

\#\#\# Contract \+ invariants (block if violated)  
\- \[ \] Client uses SSE only for \*\*status\*\*; no assistant text streaming from SSE.  
\- \[ \] Final content always fetched via \`GET /v1/transmissions/:id\`.  
\- \[ \] Polling fallback still functions when SSE is unavailable.

\#\#\# Swift 6 upgrade checks  
\- \[ \] Build succeeds under Swift 6 (include xcodebuild command/log).  
\- \[ \] MainActor isolation is applied where SwiftData/UI requires it (no cross-actor crashes).  
\- \[ \] Remaining warnings are documented and not hiding correctness issues.

\#\#\# SSE lifecycle checks  
\- \[ \] Connect SSE on login (token available).  
\- \[ \] Disconnect SSE on logout.  
\- \[ \] Background/foreground behavior is deterministic (reconnect with backoff+jitter).  
\- \[ \] No duplicate SSE connections created on repeated foreground events.

\#\#\# UI state checks  
\- \[ \] Banner transitions:  
  \- Sending → Sent/Queued on tx\_accepted  
  \- Sent/Queued → Thinking on run\_started  
  \- Thinking → Final on assistant\_final\_ready \+ fetch  
  \- Any → Failed on assistant\_failed (shows code/detail appropriately)  
\- \[ \] State is keyed by transmission\_id to avoid misrouting.

\#\#\# Header injection checks  
\- \[ \] \`x-sol-user-id\` is consistent across:  
  \- \`/v1/events\` SSE  
  \- \`/v1/chat\` POST  
  \- \`/v1/transmissions/:id\` GET  
\- \[ \] \`Authorization: Bearer …\` is used and not confused with user id.

\#\#\# Nits / Improvements  
\- \[ \] Persist Last-Event-ID is explicitly deferred (or implemented minimally).  
\- \[ \] Consider adding a lightweight debug overlay/logging toggle for SSE events (dev-only).

