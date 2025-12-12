# System Context

This document describes the system context for SolLabsHQ projects, focusing on the relationships between the core system, its users, and external services.

The purpose of this document is to establish clear boundaries, trust zones, and responsibilities at the system level.

---

## Primary System

**SolMobile v0**  
A personal-scale AI-assisted system designed to support intentional thinking, explicit memory, and drift-controlled interactions.

SolMobile is not a general-purpose assistant. It is a user-owned system that prioritizes clarity, consent, and auditability over convenience.

---

## Primary User

**Individual User (Owner)**

- Uses SolMobile as a personal thinking and organization tool
- Explicitly controls what information is saved or discarded
- Initiates all long-term memory persistence
- Reviews outputs and decisions rather than delegating agency

The user is the system’s highest-trust actor.

---

## External Systems

### Large Language Model Provider

- Provides inference capabilities for natural language understanding and generation
- Receives only scoped, bounded context per request
- Does not retain long-term memory on behalf of the user
- Is treated as a stateless reasoning engine

LLM providers are interchangeable and abstracted behind the server runtime.

---

### SolServer (Backend Runtime)

- Acts as the policy and orchestration layer
- Enforces memory consent rules and retrieval limits
- Manages request shaping, context injection, and budget caps
- Handles audit logging and decision traceability

SolServer is a trusted system component but does not autonomously persist user memory.

---

### Memory Storage

- Stores only user-explicitly saved memory entries
- Does not infer or construct long-term behavioral profiles
- Is domain-scoped and retrieval-limited
- Supports auditability and deletion

Memory storage is treated as a controlled extension of user intent, not an intelligence layer.

---

### Device Platform (iOS)

- Hosts the SolMobile client
- Stores ephemeral threads and local state
- Enforces thread expiration and cleanup policies
- Provides native capabilities such as reminders, widgets, and shortcuts

The device is considered a trusted execution environment for user interaction.

---

## Trust Boundaries

The system defines clear trust boundaries:

- User ↔ SolMobile: Full trust
- SolMobile ↔ SolServer: High trust with policy enforcement
- SolServer ↔ LLM Provider: Limited trust, stateless interaction
- SolServer ↔ Storage: Controlled, explicit writes only

No external system is permitted to independently infer user intent or memory.

---

## Constraints

- Long-term memory must be explicitly initiated by the user
- Context windows are intentionally bounded
- Retrieval limits are enforced to prevent drift and overfitting
- Cost visibility is maintained as a first-class concern

These constraints are considered architectural features, not limitations.

---

## Out of Scope

The following are explicitly out of scope for this system:

- Autonomous agents
- Implicit personality modeling
- Background learning without consent
- Behavioral prediction or nudging
- Cross-user data aggregation

---

## Status

This context reflects the initial architectural baseline for SolMobile v0.

All changes to system boundaries or trust relationships must be accompanied by an Architecture Decision Record (ADR).
