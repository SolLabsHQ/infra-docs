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
