## Code Review: solmobile PR #39

### Verdict
- [ ] Approve
- [x] Approve with nits
- [ ] Block

### High-risk areas in this PR
- Swift 6 migration correctness (MainActor isolation, Sendable issues)
- SSE lifecycle (login/logout, background/foreground)
- UI state machine correctness (banner transitions)
- Header injection consistency (`x-sol-user-id` on REST + SSE)

### Contract + invariants (block if violated)
- [x] Client uses SSE only for **status**; no assistant text streaming from SSE.
- [x] Final content always fetched via `GET /v1/transmissions/:id`.
- [x] Polling fallback still functions when SSE is unavailable.

### Swift 6 upgrade checks
- [x] Build succeeds under Swift 6 (see FIXLOG entry 2026-01-28 08:45).
- [x] MainActor isolation is applied where SwiftData/UI requires it (no cross-actor crashes).
- [x] Remaining warnings are documented and not hiding correctness issues.

### SSE lifecycle checks
- [x] Connect SSE on login (token available).
- [x] Disconnect SSE on logout.
- [x] Background/foreground behavior is deterministic (reconnect with backoff+jitter).
- [x] No duplicate SSE connections created on repeated foreground events.

### UI state checks
- [x] Banner transitions:
  - Sending → Sent/Queued on tx_accepted
  - Sent/Queued → Thinking on run_started
  - Thinking → Final on assistant_final_ready + fetch
  - Any → Failed on assistant_failed (shows code/detail appropriately)
- [x] State is keyed by transmission_id to avoid misrouting.

### Header injection checks
- [x] `x-sol-user-id` is consistent across:
  - `/v1/events` SSE
  - `/v1/chat` POST
  - `/v1/transmissions/:id` GET
- [x] `Authorization: Bearer …` is used and not confused with user id.

### Nits / Improvements
- [ ] Persist Last-Event-ID is explicitly deferred (or implemented minimally).
- [ ] Consider adding a lightweight debug overlay/logging toggle for SSE events (dev-only).

### Notes
- SSE event routing and status store are keyed by transmission_id; final fetch remains the source of truth.
- Client correctness still depends on server fanout; inline staging solved server-side delivery.
