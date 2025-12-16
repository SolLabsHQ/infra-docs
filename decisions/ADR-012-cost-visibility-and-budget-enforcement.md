# ADR-012: Cost Visibility, Budgets, and Enforcement

## Status
Accepted

## Context
SolMobile and SolServer rely on paid infrastructure and AI inference.
Unbounded usage, hidden costs, or opaque token consumption undermines trust
and discourages experimentation.

As a personal-scale system, SolOS must:
- Remain economically predictable
- Make costs visible to the user
- Prevent runaway usage by default

Cost control is a product feature, not an afterthought.
 
## Decision
SolOS will implement explicit cost visibility and budget enforcement from v0.

### Cost Visibility Principles
- Users should understand *where* cost is incurred.
- Cost information should be available without inspecting logs or invoices.
- Precision is less important than directional clarity and trust.

### What Is Tracked
Server-side (SolServer):
- Token counts per request (input, output)
- Estimated cost per request
- Aggregated daily and monthly cost
- Model selection and pricing tier
- Budget enforcement actions (warn, degrade, block)

Client-side (SolMobile):
- Request counts
- Approximate token usage summaries
- Feature-level attribution (chat, memory save, regeneration)
- Local-only cost estimates (non-authoritative)

### Budget Model
- A monthly budget is defined (default conservative).
- Budget states:
  - Green: normal operation
  - Yellow: warning and UI notice
  - Red: enforced degradation or blocking
- Enforcement is explicit and explainable.

### Enforcement Behavior
When budgets are exceeded:
- Prefer graceful degradation over hard failure.
- Reduce model quality or frequency before blocking entirely.
- Always explain why a request was limited or blocked.

No silent throttling.

## Consequences
- Predictable operating costs.
- Increased user confidence in experimentation.
- Slightly more implementation complexity.
- Clear boundary between “capability” and “affordability.”

## Notes
This decision complements:
- Client–server responsibility boundaries (ADR-011)
- Observability and data minimization (ADR-009)

Cost awareness is part of respecting user agency.