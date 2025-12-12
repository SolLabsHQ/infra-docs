# ADR-003 — Explicit Memory Model

## Status
Accepted

## Context
Many AI-driven systems accumulate state implicitly through conversation history, background logging, or behavioral inference.

This creates ambiguity around what is remembered, why it is remembered, and how long it persists, eroding user trust and making systems difficult to reason about or audit.

SolLabs systems require a clear and inspectable memory model.

---

## Decision
SolLabs systems adopt an **explicit memory model**.

Memory is created, persisted, and retained **only** through deliberate user action or explicitly defined system behavior.

There is no silent or implicit long-term memory.

---

## Definitions

### Thread
- Ephemeral interaction context
- Stored locally by default
- Time-bounded (TTL-based)
- Not treated as memory

### Memory
- A discrete, explicitly saved object
- Created only by user intent
- Persisted with clear lifecycle rules
- Inspectable and removable

Threads and memory are distinct concepts.

---

## Rules

- No automatic promotion of threads to memory
- No background or inferred memory capture
- Local thread storage is disposable
- Server-side persistence occurs only for explicit memory
- All memory objects have clear ownership and lifecycle

If a feature blurs these boundaries, it violates this decision.

---

## Implications

- Clients must provide explicit save actions
- Servers must reject ambiguous persistence
- Retrieval systems operate only over explicit memory
- Cost and storage remain bounded and predictable

---

## Consequences

### Positive
- User trust and clarity
- Inspectable system behavior
- Reduced data risk
- Easier compliance and auditing

### Tradeoffs
- Reduced convenience compared to implicit systems
- Requires intentional UX design

These tradeoffs are accepted.

---

## Date
2025-12-12
