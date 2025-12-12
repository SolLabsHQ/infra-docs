# ADR-002 — Documentation-First Architecture

## Status
Accepted

## Context
SolLabs systems span multiple repositories and domains, including SolOS, SolMobile, and SolServer.

Without an explicit documentation-first posture, architectural intent risks being fragmented across code, commits, and informal discussion, leading to drift, re-litigation of decisions, and loss of provenance over time.

A clear rule is required to establish where architectural truth lives and how decisions are recorded.

---

## Decision
SolLabs adopts a **documentation-first architecture** model.

This means:
- Architectural intent is documented before or alongside implementation
- Material decisions are recorded as ADRs
- infra-docs is the canonical source of truth
- Code reflects documented decisions, not the other way around

Documentation is treated as a first-class artifact.

---

## Scope
This decision applies to:
- System boundaries and responsibilities
- Infrastructure and hosting choices
- Persistence and memory models
- API contracts and schemas
- Governance and constraint definitions

Minor implementation details do not require ADRs.

---

## Implications

- New repositories should include `/docs` where appropriate
- Architectural changes should reference existing ADRs or introduce new ones
- Code reviews may block changes that contradict documented intent
- Documentation may evolve, but changes must be intentional and recorded

---

## Consequences

### Positive
- Clear provenance and authorship
- Reduced architectural drift
- Easier onboarding (including future self)
- Strong audit and IP trail

### Tradeoffs
- Slight overhead when making changes
- Requires discipline to maintain

This overhead is intentional and accepted.

---

## Date
2025-12-12
