# ADR-011: Client–Server Responsibility Boundary

## Status
Accepted

## Context
SolOS is designed around explicit memory, user agency, and offline-first operation.
As features expand, there is a natural risk of responsibility drift, where logic,
state, or decision-making silently migrates to the server for convenience.

Without a clear boundary, this leads to:
- Higher cost
- Reduced reliability
- Loss of user trust
- Implicit centralization of cognition

## Decision
SolMobile is the primary system of record for interaction and context.
SolServer is a policy, augmentation, and persistence service.

### SolMobile (Client) Responsibilities
SolMobile owns:
- User interaction and UX state
- Local thread storage and search
- Drafts, transient context, and working memory
- Explicit pinning and unpinning actions
- TTL cleanup of local-only data
- Offline operation and degraded-mode behavior
- OS-level integrations (Shortcuts, widgets, BackgroundTasks, notifications)
- Export initiation and local deletion semantics

SolMobile must remain functional without SolServer connectivity.

### SolServer (Server) Responsibilities
SolServer is responsible for:
- AI inference orchestration
- Policy enforcement (Rigor Gate, constraints, Wisdom Gate)
- Explicit memory persistence (only on user action)
- Cost tracking and budget enforcement
- Cross-device sync (optional, explicit, future)
- Audit metadata and drift telemetry (non-content)

SolServer must not assume continuous availability or exclusive authority.

### Explicit Non-Responsibilities (Server)
SolServer must not:
- Maintain implicit conversational state
- Store raw conversation history by default
- Make autonomous decisions on behalf of the user
- Perform long-term inference on user identity or psychology
- Retain deleted data outside declared backup windows

### Failure Modes
- If SolServer is unavailable, SolMobile continues in local-only mode.
- If policy enforcement fails, requests degrade or halt rather than bypass safeguards.

## Consequences
- Clear ownership of cognition and memory.
- Lower infrastructure costs and simpler scaling.
- Strong alignment with explicit memory and privacy principles.
- More complex client implementation, but greater system integrity.

## Notes
This boundary is intentional and architectural.
Violations of this boundary require a new ADR and explicit justification.