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
- Explicit memory persistence (user-triggered only)
- Cost and usage reporting
- Policy enforcement feedback (degrade/block + reasons)
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

See Addendum (PR10) for minimal surface expansion.

---

## Contract

### 1) Chat / Inference
`POST /v1/chat`

Purpose:
- Primary inference endpoint for a single turn.

Normative requirements:
- Client provides context references (pinned context id/version/hash), not full pinned context text.
- Client provides a capsule summary and capped recent history.
- Client provides budgets/caps; server enforces client caps + server policy defaults.
- Requests are idempotent via `request_id`.

Request (shape):
- `request_id` (required, UUID)
- `user`: `{ user_id }`
- `device`: `{ device_id, client_version, platform }`
- `thread`: `{ thread_id, message_id? }`
- `mode` (optional; e.g., `normal`, `voice`, `coach`)
- `context`:
  - `pinned_context`: `{ id, version, hash }`
  - `domain_scope`: string | string[]
  - `capsule`: `{ summary, last_updated_at }`
  - `history`: array (last N messages; capped)
  - `retrieval`: `{ max_items, max_tokens_total, filters? }`
- `input`: `{ text }`
- `budgets`:
  - `max_input_tokens`
  - `max_output_tokens`
  - `max_retrieval_items`
  - `max_retrieval_tokens_total`
  - `max_regenerations`

Response (shape):
- `request_id` (echo)
- `thread_id`
- `assistant`: `{ text }`
- `retrieval_used`: array of `{ memory_id, domain, title, summary }` (summaries only)
- `policy` (optional): `{ decision: "allowed"|"degraded"|"blocked", reason_codes: string[], message? }`
- `usage`:
  - `tokens_in`
  - `tokens_out`
  - `tokens_total`
  - `latency_ms`
  - `estimated_cost_usd` (estimate)
  - `model`
- `audit`:
  - `pinned_context_id`
  - `pinned_context_version`
  - `pinned_context_hash`
  - `rigor_gate`: `{ applied, reason_codes, enforcement, regen_count }` (when relevant)

Notes:
- `estimated_cost_usd` is informational (ADR-012) and not billing-grade.
- Server may degrade output to satisfy budgets.

### 2) Explicit Memory Save
`POST /v1/memories`

Purpose:
- Creates a memory entry only when the user explicitly triggers save.

Requirements:
- No implicit saves.
- Server stores a summary for retrieval injection.

Request:
- `memory`: `{ domain, tags?, title, content, importance? }`
- `source`: `{ thread_id, message_id, created_at }`
- `consent`: `{ explicit: true }`

Response:
- `{ memory_id, domain, title, summary, created_at }`

### 3) Memory List (Summaries)
`GET /v1/memories?domain=...&tags_any=...&cursor=...`

Purpose:
- Lists memory summaries with pagination.

Response:
- `items`: `{ memory_id, domain, title, summary, created_at }[]`
- `next_cursor` (optional)

### 4) Usage Aggregates
`GET /v1/usage/daily?date=YYYY-MM-DD`

Purpose:
- Supports SolMobile Cost Meter (ADR-012).

Response:
- `date`
- `totals`: `{ tokens_in, tokens_out, tokens_total, estimated_cost_usd }`
- `top_threads`: `{ thread_id, tokens_total, estimated_cost_usd }[]`
- `recent_calls`: `{ request_id, thread_id, tokens_total, latency_ms, estimated_cost_usd, created_at }[]`

---

## Error Model
All errors must return:
- HTTP status code
- JSON body:
  - `error_code` (stable string)
  - `message` (human readable)
  - `remediation` (actionable hint)
  - `request_id` (echo when present)

Common codes:
- `BUDGET_EXCEEDED`
- `INVALID_REQUEST`
- `AUTH_REQUIRED`
- `RATE_LIMITED`
- `SERVER_BUSY`

## Idempotency
- `request_id` is required for `/v1/chat`.
- Duplicate `request_id` must be treated as idempotent where possible.

## Security and Privacy
- Auth mechanism is out of scope for this ADR, but endpoints assume authenticated access in production.
- No raw prompt/output persistence is required for the contract.
- Any additional logging/storage for drift/debugging must follow ADR-009 (data minimization) and related governance.  

## Addendum (PR10)
- Minimal surface expansion: journal drafts/entries and trace ingestion.

## Consequences
- Smaller, maintainable server surface area.
- Easier evolution and refactoring.
- Stronger alignment with privacy and cost constraints.
- More responsibility on the client for orchestration.

## Notes
This decision reinforces:
- Client–server responsibility boundary (ADR-011)
- Cost visibility and enforcement (ADR-012)
- Observability discipline (ADR-009)

SolServer is an API, not a memory oracle.
