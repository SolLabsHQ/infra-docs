# Container View

This document describes the major containers that make up the SolMobile v0 system, including their responsibilities and communication paths.

This is a C4 Model Level 2 view. It intentionally avoids component-level detail.

---

## Containers

### 1. SolMobile (iOS Client)

**Type:** Native iOS application  
**Primary responsibilities:**
- Capture user input (text-first in v0)
- Display model responses
- Maintain local threads and message history
- Enforce thread lifecycle rules (TTL cleanup, pinning)
- Provide explicit user actions to save memory
- Display usage and cost metrics

**Persistence:**
- Local-only thread storage by default
- Threads expire and are deleted after a defined TTL unless pinned
- No implicit long-term memory persisted from threads

---

### 2. SolServer (API + Policy Runtime)

**Type:** Containerized backend service  
**Hosting:** Fly.io  
**Primary responsibilities:**
- Accept chat requests from SolMobile
- Validate request schemas and enforce budgets
- Apply policy constraints (explicit memory model, drift controls)
- Perform retrieval and context shaping based on domain scope
- Route inference calls to the LLM provider
- Write explicit memories to persistent storage
- Emit usage metrics and audit fields per request

**Key characteristics:**
- Stateless by default
- Persistent writes occur only for explicit memory and auditing metadata
- Designed to be provider-agnostic for inference

---

### 3. Inference Provider (LLM)

**Type:** External managed service  
**Primary responsibilities:**
- Perform reasoning and text generation based on provided bounded context

**Constraints:**
- Receives only scoped context for each request
- Treated as stateless within SolLabs system boundaries
- No SolLabs-controlled long-term memory is stored at the provider

---

### 4. Memory Store (Explicit Memory Persistence)

**Type:** Managed database  
**Initial choice:** Fly Postgres (jsonb/text payloads)  
**Primary responsibilities:**
- Persist user-explicitly saved memory objects
- Support listing, filtering, and retrieval injection as summaries
- Support deletion and auditability

**Notes:**
- Stores only what the user explicitly saved
- Retrieval injects summaries only, with caps enforced by SolServer

---

### 5. Object Store (Attachments and Large Objects)

**Type:** Object storage  
**Initial choice:** Not required for v0  
**Future choice:** Cloudflare R2 when needed

**Primary responsibilities (future):**
- Store attachments (audio, images, exports)
- Provide a stable, cost-effective blob store

---

### 6. Observability (Errors and Tracing)

**Type:** External monitoring services  
**Primary tools:**
- Sentry for client and server errors
- Optional OpenTelemetry tracing with low sampling by default

**Primary responsibilities:**
- Capture runtime errors and crashes
- Provide request correlation and debugging support
- Maintain low overhead and cost discipline at v0

---

## Communication Paths

### SolMobile → SolServer
**Protocol:** HTTPS  
**Calls:**
- `POST /v1/chat` for inference
- `POST /v1/memories` for explicit save
- `GET /v1/memories` for listing and retrieval support
- `GET /v1/usage/daily` for cost meter and usage reporting

**Security posture:**
- Auth strategy is v0-minimal but must support user isolation
- Requests include budget caps to enforce predictable cost

---

### SolServer → Inference Provider
**Protocol:** HTTPS  
**Behavior:**
- Sends only bounded context: pinned context reference, capsule summary, capped short history, and capped retrieval summaries
- Enforces strict max tokens per request

---

### SolServer → Memory Store
**Protocol:** Database connection  
**Behavior:**
- Writes explicit memory records only
- Reads memory summaries for retrieval injection
- Supports pagination and domain filtering

---

### SolServer → Observability
**Behavior:**
- Emits error events and request metadata
- Tracing is optional and must remain low-cost by default

---

## Trust Boundaries (Container-Level)

- SolMobile is trusted for local storage and user intent capture
- SolServer is trusted to enforce policy and persistence rules
- Inference provider is treated as a stateless external engine
- Memory store is trusted only for explicit saved records

No container may silently expand persistence beyond explicit rules.

---

## Constraints and Guardrails

- Explicit memory only (see ADR-003)
- Documentation-first changes (see ADR-002)
- Container-first hosting strategy (see ADR-004)
- Drift control via bounded context and retrieval caps
- Cost visibility and budget caps are first-class requirements

---

## Status

This container view represents the v0 architecture baseline.

Lower-level views will be added only when justified by operational complexity or scale.
