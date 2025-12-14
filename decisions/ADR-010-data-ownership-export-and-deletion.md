# ADR-010: Data Ownership, Export, and Deletion Semantics

## Status
Accepted

## Context
SolMobile and SolServer handle personal, identity-aware data that may include
thoughts, memories, reflections, and decision artifacts. By design, this data
has high personal sensitivity and long-term meaning.

Trust requires clear guarantees around:
- Who owns the data
- How it can be exported
- How it can be deleted
- What “deletion” actually means across systems

Ambiguity in these areas leads to fear, misuse, or silent retention.

## Decision
User data is owned by the user and governed by explicit, inspectable rules.

### Ownership
- All user-generated content belongs to the user.
- SolLabsHQ does not claim ownership of user data.
- Server-side storage exists only to support user-initiated features.

### Export
- Users may export their data at any time.
- Export formats prioritize:
  - Human readability (JSON, Markdown, plain text)
  - Structural completeness (threads, metadata, timestamps)
- Exports must not require special tooling to interpret.

### Deletion
Deletion is explicit and user-initiated.

#### Local deletion (SolMobile)
- Removing content deletes it from on-device storage.
- TTL-based cleanup applies to non-pinned, non-exported content.
- Deleted local content is not silently re-synced.

#### Server deletion (SolServer)
- Deleting server-side memory removes it from primary persistence.
- Backups are time-bounded and age out automatically.
- No “soft delete” or hidden retention for analytics.

### Guarantees
- No undeclared retention of deleted data.
- No shadow copies created for observability or training.
- No resurrection of deleted memories via sync or cache.

## Consequences
- Strong user trust posture.
- Higher implementation discipline around storage boundaries.
- Clear answers to “where does my data live?” and “can I get it back?”

## Notes
This decision complements:
- Explicit memory (ADR-003)
- Offline-first client design (ADR-008)
- Observability data minimization (ADR-009)

Deletion must be explainable in plain language, not just technically correct.