# Domain: solmobile

## Purpose
The solmobile domain governs the native iOS client and its local-first interaction model.

## In Scope
- UI interaction patterns and constraints
- Local thread and message storage
- TTL cleanup behavior and pinning
- Explicit memory save actions
- Cost meter presentation (usage visibility)
- Client-side capsule summary behavior (if used)

## Out of Scope
- Server persistence logic
- Retrieval policy and injection rules
- LLM provider behaviors
- Long-term memory inference or automatic saving

## Persistence Rules
- Threads are stored locally by default.
- Threads expire after a defined TTL unless pinned.
- No automatic promotion of thread content into long-term memory.
- All long-term persistence requires explicit user action through a save flow.

## Retrieval Expectations
- Retrieval is requested by the client only as part of a chat request.
- The client does not independently retrieve or inject memory.
- The client displays which retrieved items were used (summaries only).

## PR10 delta
- Label-only fidelity gate: Ascend is shown only when `ghost_kind == journal_moment` (see `decisions/ADR-024-ghost-deck-physicality-accessibility-v0.md` and `decisions/ADR-025-consented-journaling-v0-muse-offer-memento-affect-device-muse-trace.md`).
- Trace ingestion: SolMobile emits JournalOfferEvent and DeviceMuseObservation to `POST /v1/trace/events` (see `architecture/solmobile/trace-ui-v0.md` and `schema/v0/trace_events_request.schema.json`).
