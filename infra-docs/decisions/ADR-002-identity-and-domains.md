# ADR-004 — Identity and Domain Mapping

## Status
Accepted

## Context
As SolLabsHQ was established as a GitHub organization and documentation source, a clear distinction was needed between:

- The conceptual identity of the lab
- The technical handles used for infrastructure and publishing
- Domain ownership and intended usage

This decision clarifies naming, domains, and how they should be referenced going forward.

---

## Decision

### Identity
- **SolLabs** is the name of the lab.
- It is the human-facing and conceptual identity.

### Infrastructure Handle
- **SolLabsHQ** is the canonical infrastructure handle.
- It is used for:
  - GitHub organization
  - Repositories
  - Technical ownership
  - Source-of-record documentation

The “HQ” suffix is treated as an implementation detail, not a branding layer.

---

## Domain Mapping

### Canonical Domain
- **sollabshq.com**

This is the primary domain and source of truth.

Intended use:
- Documentation
- Architecture
- Governance artifacts
- System overviews

Future subdomains may include:
- `docs.sollabshq.com`
- `arch.sollabshq.com`
- `solmobile.sollabshq.com`
- `api.sollabshq.com` (internal/runtime)

---

### Supporting Domain
- **sollabshq.org**

Reserved for:
- Research-oriented material
- Essays or long-form documentation
- Non-commercial or governance framing

Usage is optional.

---

### Selective / Optional Domain
- **sollabs.ai**

Reserved for:
- AI-specific architecture explanations
- SolOS overviews
- Public-facing discussions of AI systems and governance

This domain is not the canonical home and should be used selectively.

---

## Naming Guidance

- Refer to the lab as **SolLabs** in prose.
- Reference **SolLabsHQ** only when describing infrastructure, repositories, or source control.
- Do not alternate naming without purpose.
- Do not center identity around domain names.

---

## Consequences

- Identity and infrastructure are clearly separated.
- Naming remains stable even if domains or platforms change.
- Documentation and authorship remain consistent and defensible.
- Future expansion does not require renaming or migration.

---

## Date
2025-12-12
