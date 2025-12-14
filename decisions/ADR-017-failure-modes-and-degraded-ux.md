# ADR-017: Failure Modes and Degraded User Experience

## Status
Accepted

## Context
SolOS operates across device, network, and server boundaries.
Failures are inevitable: connectivity loss, budget exhaustion, policy blocks,
API errors, or background task limits.

Poorly handled failures erode trust more than failures themselves.
A system that degrades clearly and calmly preserves user confidence.

## Decision
SolMobile and SolServer will explicitly model failure modes and provide
graceful, explainable degraded experiences.

### Failure Categories

#### Network Unavailable
- SolMobile operates in local-only mode.
- Reading, searching, and drafting remain available.
- Server-dependent actions are deferred or disabled with explanation.

#### Server Unavailable
- Requests fail fast with clear messaging.
- No silent retries that drain battery or cost.
- Local work continues uninterrupted.

#### Policy or Constraint Block
- Requests may be degraded or halted.
- Reason is surfaced in human-readable form.
- User understands *why* and *what to do next*.

#### Budget Exhaustion
- Progressive degradation preferred over hard stops.
- Clear indication of budget state.
- No surprise failures without warning.

#### Background Execution Limits
- BackgroundTasks failures are non-fatal.
- Cleanup, sync, or uploads retry opportunistically.
- User is not blamed for OS-imposed limits.

### UX Principles for Degraded States
- Explain, don’t obscure.
- Maintain calm tone.
- Preserve user work.
- Avoid panic language or urgency.
- Never imply user error when system constraints apply.

### Logging and Recovery
- Failures are logged with minimal metadata.
- Recovery paths are explicit and testable.
- No automatic escalation without user awareness.

## Consequences
- More deliberate UX design effort.
- Fewer “mysterious” behaviors.
- Stronger long-term trust and system resilience.

## Notes
This decision complements:
- Offline-first design (ADR-008)
- Cost enforcement (ADR-012)
- Trust and consent surfaces (ADR-014)

Failure is a first-class system state, not an exception.