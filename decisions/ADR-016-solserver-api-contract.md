# ADR-016: SolServer API Contract and Minimal Surface Area

## Status
Accepted

## Context
SolServer exists to augment SolMobile, not replace it.
Without a clearly constrained API contract, server capabilities tend to expand,
leading to increased cost, tighter coupling, and erosion of offline-first guarantees.

A minimal, explicit API surface ensures:
- predictable behavior
- easier reasoning about data flow
- stronger enforcement of client–server boundaries

## Decision
SolServer will expose a deliberately minimal and explicit API contract.

### Core API Responsibilities
SolServer APIs are limited to:
- AI inference requests
- Explicit memory persistence
- Cost and usage reporting
- Policy enforcement feedback
- Optional sync endpoints (future, explicit)

All APIs are invoked intentionally by SolMobile.

### Prohibited API Patterns
SolServer must not expose APIs that:
- Implicitly fetch conversational history
- Auto-save or infer memory state
- Reconstruct user context without client input
- Perform background inference without a client request

### API Design Principles
- Stateless by default
- Request-scoped context only
- Explicit inputs and outputs
- Idempotent where possible
- Versioned from first release
 
### Error and Policy Signaling
Responses may include:
- Policy decisions (allowed, degraded, blocked)
- Cost warnings or budget states
- Enforcement reasons in machine- and human-readable form

Errors must be explainable and actionable by the client.

## Consequences
- Smaller, more maintainable server surface area.
- Easier evolution and refactoring.
- Stronger alignment with privacy and cost constraints.
- More responsibility on the client for orchestration.

## Notes
This decision reinforces:
- Client–server responsibility boundary (ADR-011)
- Cost visibility and enforcement (ADR-012)
- Observability discipline (ADR-009)

SolServer is an API, not a memory oracle.