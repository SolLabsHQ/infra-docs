# ADR-013: Memory Lifecycle States

## Status
Accepted

## Context
SolOS handles multiple classes of information:
- transient conversational context
- working thoughts and drafts
- explicitly saved memories
- archived or historical material

Without a formal lifecycle, memory systems tend to:
- accumulate unintentionally
- blur temporary vs durable data
- violate user expectations around persistence

Explicit memory requires explicit states.

## Decision
All memory in SolOS follows a defined lifecycle with clear state transitions.
No memory is durable by default.

### Memory States

#### Draft
- Default state for all new content.
- Exists locally on device.
- Subject to TTL cleanup.
- Never written to the server.

Examples:
- Ongoing chat threads
- Partial thoughts
- Temporary notes

#### Pinned
- Explicitly promoted by the user.
- Written to server-side memory storage.
- Indexed and retrievable.
- Included in exports unless excluded.

Pinning is a deliberate act.

#### Archived
- No longer active but intentionally retained.
- Read-only by default.
- Excluded from active context unless explicitly referenced.
- May exist locally, server-side, or both.

Archiving preserves history without polluting present context.

#### Deleted
- Removed by explicit user action.
- Deleted locally and server-side.
- Not eligible for sync or regeneration.
- Backups age out per retention policy.

Deletion is final within declared guarantees.

### Transitions
- Draft → Pinned (explicit user action)
- Pinned → Archived (explicit user action)
- Any → Deleted (explicit user action)
- Draft → Deleted (automatic TTL cleanup)

Implicit transitions are forbidden.

## Consequences
- Predictable memory behavior.
- Reduced risk of silent accumulation.
- Clear mental model for users.
- Simplifies enforcement of privacy and deletion guarantees.

## Notes
This lifecycle complements:
- Explicit memory (ADR-003)
- Offline-first design (ADR-008)
- Ownership and deletion semantics (ADR-010)

Memory should feel intentional, not haunted.