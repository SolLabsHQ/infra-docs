# FIXLOG.md — PR #39 (SSE-01)

*Purpose:* lightweight running log of issues found and fixed while implementing SSE + Swift 6 upgrade. Keep entries small and concrete.

---

## Format

### YYYY-MM-DD HH:MM (local)
- **Area:** SolServer | SolMobile | Docs | Tests
- **Issue:** what broke (one sentence)
- **Impact:** user-visible vs internal
- **Root cause:** what actually caused it
- **Fix:** what changed
- **Verification:** how we proved it
- **Notes:** anything to remember later (follow-up ticket, v0.1 punt, etc.)

---

## Entries

### 2026-01-28 19:45
- **Area:** SolMobile
- **Issue:** Needed to confirm consistent user id header for SSE + REST.
- **Impact:** Potential SSE/REST mismatch if headers diverged.
- **Root cause:** Verification request during staging prep.
- **Fix:** Confirmed `x-sol-user-id` is set via shared `UserIdentity.resolvedId()` for both REST (`SolServerClient.applyUserIdHeader`) and SSE (`SSEClient.makeHeaders`).
- **Verification:** `rg "x-sol-user-id"` + code review in `SolServerClient.swift` and `SSEClient.swift`.
- **Notes:** No code changes required.

### 2026-01-28 14:20
- **Area:** SolMobile
- **Issue:** SSE client referenced `UserIdentity` that was private to `SolServerClient` (compile error).
- **Impact:** Build failure.
- **Root cause:** User id helper lived as a private enum inside `SolServerClient`.
- **Fix:** Extracted shared `UserIdentity` into `Services/UserIdentity.swift` and removed the private enum.
- **Verification:** Static review; no build run yet.
- **Notes:** None.

### 2026-01-28 14:35
- **Area:** SolServer
- **Issue:** Responses API parsing could miss `output_text` fallback.
- **Impact:** Potential provider success treated as failure if output is only in `output_text`.
- **Root cause:** Parser only walked `output[*].content[*].text`.
- **Fix:** Added `output_text` fallback when content blocks are absent.
- **Verification:** Static review.
- **Notes:** Keep an eye on Responses schema changes.

### 2026-01-28 14:50
- **Area:** SolMobile
- **Issue:** Reconnect jitter not explicit in SSE client.
- **Impact:** Possible reconnect thundering herd.
- **Root cause:** `swift-eventsource` config supports backoff but no jitter knob.
- **Fix:** Added small randomized jitter to base and max reconnect delays.
- **Verification:** Static review.
- **Notes:** Consider explicit jitter control if library adds support later.

### 2026-01-28 16:10
- **Area:** SolMobile
- **Issue:** SSE status events were logged but did not drive UI state (no “Sent/Thinking” transitions).
- **Impact:** Users still saw “dead air” despite SSE.
- **Root cause:** Dispatcher lacked published state updates for tx_accepted/run_started.
- **Fix:** Added SSEStatusStore stage tracking and updated ThreadDetailView banner to reflect Sending → Sent/Queued → Thinking, plus failure detail.
- **Verification:** Static review.
- **Notes:** Failure banner uses SSE detail until polling updates local status.

### 2026-01-28 16:20
- **Area:** SolMobile
- **Issue:** SSE lifecycle didn’t explicitly follow auth/app lifecycle.
- **Impact:** Streams could linger across background/logout.
- **Root cause:** SSEService only started at app init and didn’t observe app lifecycle.
- **Fix:** Added app lifecycle observers to disconnect on background and reconnect on foreground; refreshConnection now starts service if needed.
- **Verification:** Static review.
- **Notes:** Auth token save/clear already triggers refresh/stop in Settings.

### 2026-01-28 16:35
- **Area:** SolServer
- **Issue:** Responses API text.format needed a fallback mode for environments lacking json_schema.
- **Impact:** Potential provider errors if strict schema not supported.
- **Root cause:** format was hardcoded to json_schema.
- **Fix:** Added `OPENAI_TEXT_FORMAT=json_object` fallback while defaulting to json_schema strict.
- **Verification:** Static review.
- **Notes:** Keep schema strict as default for gate enforcement.

### 2026-01-28 16:45
- **Area:** Tooling
- **Issue:** `pnpm` unavailable in the current environment, so lockfile can’t be updated here.
- **Impact:** `pnpm-lock.yaml` still missing fastify-sse-v2 changes.
- **Root cause:** Node/npm version lacks pnpm and corepack.
- **Fix:** Documented for follow-up; requires a dev environment with pnpm.
- **Verification:** `pnpm --version` returned “command not found”.
- **Notes:** Must run `pnpm install` and commit lockfile before merge.

### 2026-01-28 16:55
- **Area:** Tooling
- **Issue:** `pnpm` needed to update lockfile.
- **Impact:** None (resolved).
- **Root cause:** Node 8 environment lacked corepack/pnpm.
- **Fix:** Switched to Node 24 via nvm, enabled corepack, ran `pnpm install` in `solserver`.
- **Verification:** `pnpm install` completed with pnpm v10.28.2.
- **Notes:** Lockfile now updated in repo status.

### 2026-01-28 17:05
- **Area:** SolServer
- **Issue:** Run test suite after SSE/Responses changes.
- **Impact:** Verification.
- **Root cause:** N/A (verification step).
- **Fix:** Ran `pnpm test` under Node 24.
- **Verification:** 38 test files passed; 1 OpenAI integration test skipped.
- **Notes:** SSE endpoint smoke + SolMobile build still pending.

### 2026-01-28 08:45
- **Area:** SolMobile
- **Issue:** Swift 6 concurrency errors in model helpers (main-actor isolation).
- **Impact:** Build failure.
- **Root cause:** Default main-actor isolation conflicted with nonisolated DTO helpers and enums.
- **Fix:** Marked pure data types and helpers as `nonisolated` (EvidenceBounds, GhostKind, JournalOffer models, EvidencePayload DTOs), added `@MainActor` to deprecated `toEvidencePayload`.
- **Verification:** `xcodebuild` for iPhone 17 simulator succeeded.
- **Notes:** Several Swift 6 warnings remain in `SolServerClient` about captured vars.

### 2026-01-28 08:45
- **Area:** SolMobile
- **Issue:** Outbox concurrency errors when hopping to MainActor for model updates.
- **Impact:** Build failure.
- **Root cause:** `TransmissionActions` used MainActor-only operations from nonisolated contexts.
- **Fix:** Made `TransmissionActions` `@MainActor`, adjusted `OutboxWorkerActor` to create/await on MainActor, and moved memento Tasks to `@MainActor` in `ThreadDetailView`.
- **Verification:** `xcodebuild` for iPhone 17 simulator succeeded.
- **Notes:** Consider re-evaluating main-actor workload if outbox performance regresses.
