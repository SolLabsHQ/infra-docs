# ADR-004 — Infrastructure Hosting Strategy

## Status
Accepted

## Context
SolLabs systems require a lightweight, inspectable, and cost-disciplined runtime to support SolMobile and SolServer.

The infrastructure must:
- Support containerized services
- Remain simple at small scale
- Avoid premature vendor lock-in
- Align with a documentation-first and explicit-state philosophy

A heavy cloud platform would introduce unnecessary complexity and hidden defaults at v0.

---

## Decision
SolLabs adopts **Fly.io** as the initial hosting platform for SolServer and related runtime services.

Fly.io is used as a pragmatic v0 infrastructure choice, not a permanent commitment.

---

## Rationale

Fly.io was selected because it provides:

- Container-first deployment
- Minimal operational surface area
- Regional proximity to users
- Transparent pricing
- Low idle cost
- Simple rollback and redeploy semantics

This aligns with SolLabs’ preference for systems that are understandable and inspectable end-to-end.

---

## Scope
This decision applies to:
- SolServer runtime services
- Supporting APIs
- Internal tooling required for SolMobile v0

It does not mandate Fly.io for future systems or higher-scale deployments.

---

## Constraints

- Services must be stateless by default
- Persistent data must be explicitly modeled and justified
- Configuration should remain minimal and auditable
- Infrastructure complexity must not exceed application complexity
- This decision is constrained by ADR-002 (Documentation-First Architecture) and ADR-003 (Explicit Memory Model).

---

## Consequences

### Positive
- Fast iteration with low overhead
- Predictable costs
- Easy mental model
- Clean separation between runtime and state

### Tradeoffs
- Fewer managed services than large cloud providers
- Some operational tasks remain manual

These tradeoffs are acceptable at v0.

---

## Revisit Conditions
This decision should be revisited if:
- Scale requirements change materially
- Compliance constraints require a different provider
- Infrastructure complexity outgrows Fly.io’s model

---

## Date
2025-12-12
