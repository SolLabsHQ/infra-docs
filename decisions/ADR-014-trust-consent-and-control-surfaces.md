# ADR-014: Trust, Consent, and User-Facing Control Surfaces

## Status
Accepted

## Context
SolOS handles personal, reflective, and identity-aware information.
Even with strong backend guarantees (privacy, deletion, ownership),
users cannot trust a system unless those guarantees are visible,
understandable, and controllable from the interface.

Trust is not implicit. It must be earned repeatedly through clear signals.

## Decision
SolMobile will surface trust, consent, and control explicitly in the UI.

### Core Principles
- No silent persistence
- No ambiguous states
- No irreversible actions without clarity
- Control should be understandable without documentation

### Required Trust Surfaces

#### Memory Actions
- Clear distinction between:
  - Draft (local, temporary)
  - Pinned (durable, server-stored)
  - Archived
  - Deleted
- Promotion to durable memory requires an explicit user action.
- UI language must describe *what will happen* before it happens.

#### Consent Signals
- Any action that writes to the server is labeled as such.
- Any action that incurs cost is explainable.
- Any action that changes lifecycle state is reversible when possible.

#### Visibility
- Users can see:
  - What is stored locally
  - What is stored server-side
  - What is scheduled for cleanup
- System state is inspectable, not hidden.

#### Deletion and Undo
- Deletion actions clearly state scope (local vs server).
- Short-window undo may exist for user error.
- Permanent deletion is clearly communicated.

### Language and Tone
- UI copy prioritizes clarity over cleverness.
- No dark patterns, nudges, or misleading defaults.
- Calm, grounded language over urgency or fear.

## Consequences
- Increased UI and design effort.
- Slower feature rollout.
- Stronger user trust and long-term adoption.

## Notes
This ADR operationalizes:
- Ownership and deletion semantics (ADR-010)
- Memory lifecycle states (ADR-013)
- Cost visibility (ADR-012)

Trust is a product feature.