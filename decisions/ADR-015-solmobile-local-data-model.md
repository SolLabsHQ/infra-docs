# ADR-015: SolMobile Local Data Model and Persistence Strategy

## Status
Accepted

## Context
SolMobile is an offline-first system where the client is the primary locus of
interaction, context, and working memory.

A clear local data model is required to:
- Support memory lifecycle states
- Enable fast local search and retrieval
- Enforce TTL cleanup
- Maintain explainable boundaries between local and server data

The persistence strategy must favor clarity, durability, and future evolution.

## Decision
SolMobile will use a structured local persistence layer as the system of record
for all non-server memory.

### Data Model Principles
- Local storage is authoritative for Draft and Archived states.
- Pinned memory exists locally and may be mirrored server-side.
- No implicit writes to the server occur from local persistence alone.
- All lifecycle transitions are explicit.

### Storage Technology
- Use native Apple persistence (SwiftData preferred; CoreData acceptable).
- Schema is versioned and migration-aware.
- Data is encrypted at rest using OS-provided facilities.

### Core Entities (Conceptual)
- Thread
- Message
- MemoryItem
- LifecycleState
- Metadata (timestamps, origin, cost hints)

### Retention and Cleanup
- Draft data is subject to TTL cleanup.
- Archived data is retained until explicit deletion.
- Cleanup jobs run opportunistically via BackgroundTasks.

## Consequences
- Predictable and inspectable local behavior.
- Slightly higher upfront modeling effort.
- Strong alignment with offline-first and explicit memory principles.

## Notes
This decision operationalizes:
- Memory lifecycle states (ADR-013)
- Client–server boundary (ADR-011)
- Trust and control surfaces (ADR-014)