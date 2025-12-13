# ADR-005 — C4 Model Adoption

## Status
Accepted

## Context
SolLabsHQ requires a lightweight, repeatable way to document architecture that:
- remains readable over time
- avoids premature detail
- supports clear boundaries and trust relationships
- can evolve incrementally as the system grows

A consistent modeling approach reduces drift and prevents architecture docs from becoming ad hoc or tool-specific.

---

## Decision
SolLabsHQ adopts the **C4 Model** as the primary architectural documentation framework.

At v0, documentation is limited to:
- **Level 1: System Context**
- **Level 2: Container View**

Levels 3 and 4 are intentionally deferred.

---

## Rationale
The C4 Model provides:
- a clear hierarchy of views
- a shared vocabulary for system structure
- a practical stopping point to prevent over-architecture

Focusing on Levels 1 and 2 preserves clarity while the system is still small and fast-moving.

---

## Scope
This decision applies to architecture documentation in:
- `infra-docs/architecture/`

Repository-level documentation may include additional diagrams, but must not contradict the canonical C4 views.

---

## Constraints
- Markdown architecture documents remain the canonical narrative source.
- stated boundaries and trust relationships must be consistent across views.
- deeper diagrams (Level 3+) require justification by scale, risk, or operational complexity.

---

## Consequences

### Positive
- Consistent, legible architecture across systems
- Easier onboarding and review
- Reduced drift through a stable documentation pattern

### Tradeoffs
- Some implementation detail will remain undocumented until needed
- Requires discipline to keep diagrams aligned with written docs

These tradeoffs are accepted.

---

## Date
2025-12-12
