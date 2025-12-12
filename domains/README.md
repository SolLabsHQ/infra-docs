# Domains

This directory defines conceptual domains used within SolLabsHQ systems.

A domain is a boundary for:
- vocabulary and concepts
- allowed persistence and lifecycle rules
- retrieval scope for explicit memories
- documentation and ownership

Domains are used to reduce drift and prevent accidental coupling between unrelated areas of the system.

Domains are not implementations. They are constraints and organizing principles.

---

## Domain Rules

- Domains must be named consistently and used as stable identifiers.
- Memories are tagged with a domain.
- Retrieval is domain-scoped by default.
- Cross-domain retrieval requires explicit intent and must be justified.

---

## Current Domains

- `solos` — SolOS architecture, governance, and domain definitions
- `solmobile` — iOS client behaviors, local storage, UX constraints
- `solserver` — API/runtime policy, validation, observability, budgets
- `wealthos` — finance schemas and decision rules (future expansion)
- `sos` — State of Survival domain artifacts (if included in SolOS)
- `kincart` — separate system boundary (only referenced, not merged)
