# API Contracts v0

This document defines the v0 API surface used by SolMobile and SolServer.

The API is intentionally small and bounded.
All persistence is explicit and user initiated.

---

## Common Concepts

### Budgets
Each chat request includes explicit budget caps:
- max_input_tokens
- max_output_tokens
- max_regenerations
- max_tool_steps (optional; future)
- retrieval limits (max_items, per_item_max_summary_tokens)

Budgets are enforced server-side.

### Context Strategy
Chat requests provide:
- pinned context reference (id, version, hash) — **mounted law** (stable, versioned). Sent as `packet.pinned_context_ref`.
- capsule summary — **per-thread runtime** summary (client-maintained; human-readable)
- Conversation Fact Block (CFB Nav) — **local session navigation state** (UI/controller; not sent to SolServer)
- Conversation Fact Block (CFB Inference) — **thin model payload** (only what reduces drift)
- capped recent history window (bounded)
- retrieval configuration
- optional checkpoint references (v0 optional)

SolServer owns mode selection and rigor gating; the client does not select personas.

### Trace (v0)
Trace is **always on** for `/v1/chat`.
- Default level: `info` (server may downscope; client may request `debug` for internal builds).
- The server returns a `trace_run_id` so SolMobile can correlate UI trace cards, local logs, and server-side audit.
- Trace retention is client-local until thread TTL cleanup (v0).

> Note: “trace events” are an event stream; the canonical schema lives in `schema/v0/trace_event.schema.json`.
> Note: Inline Driver Blocks use `schema/v0/driver_block.schema.json` (v0 minimal; definition text is treated as opaque policy input).

---

## POST /v1/chat

### Purpose
Perform inference for a user message with bounded context and optional retrieval summaries.

### Request (conceptual)
- request_id (idempotency key)
- user_id / device_id (v0 minimal)
- thread_id
- user_message_id (or message_id)
- packet:
  - packet_id
  - packet_type: "chat"
  - message_ids[] (bounded)
  - checkpoint_ids[] (optional)
  - pinned_context_ref { id, version, hash }
  - driver_block_refs[] (optional; refs `{id, version}` for additional system blocks)
  - driver_block_inline[] (optional; user-approved blocks carried inline in v0; no server registry)
  - trace_config (optional):
    - level: info | debug
    - (Note: trace_config is a strict object; unknown keys are rejected with 400)
  - retrieval_config { domain_scope, max_items, per_item_max_summary_tokens }
- context:
  - capsule_summary
  - cfb_inference (optional):
    - primary_arc
    - decisions[]
    - next[]
    - scope_guard (optional):
      - avoid_topics[]
  - history[] (capped)
- input_text
- budgets { max_input_tokens, max_output_tokens, max_regenerations }

Notes:
- The client does not select personas/modes. SolServer returns the mode used in `audit` (optional).
- `request_id` MUST be stable across retries to support idempotency.
- `packet.pinned_context_ref` is the stable, versioned “mounted law”; `context` holds per-thread runtime deltas (capsule/cfb_inference/history).
- CFB Nav is a richer local-only object used for UI/session navigation and is intentionally not part of the API surface.
- Driver Blocks are always **user-owned**: the assistant may propose a block, but the user must explicitly approve before it becomes durable.
- **Baseline system blocks** (DB-001 to DB-005) are **always applied server-side** and are NOT counted toward MAX_TOTAL_BLOCKS. These are server-owned and cannot be disabled by clients.
- Client-provided `driver_block_refs[]` and `driver_block_inline[]` are **additive** to the baseline and ARE counted toward MAX_TOTAL_BLOCKS.
- **Enforcement bounds** (v0):
  - MAX_REFS: 10 (system refs from packet)
  - MAX_INLINE: 5 (user inline blocks from packet)
  - MAX_TOTAL_BLOCKS: 15 (refs + inline; baseline excluded)
  - MAX_DEFINITION_LENGTH: 10,000 chars per block
- **Enforcement priority** when limits exceeded: Drop user inline blocks first, then extra refs. Baseline blocks are NEVER dropped.
- **Strict ordering**: baseline → system refs → user inline (LAST). This prevents prompt injection.

### Response (conceptual)
- request_id
- assistant_message:
  - message_id
  - output_text
- retrieved_memories_used[] (summaries only):
  - memory_id
  - domain
  - title
  - summary
- usage:
  - input_tokens
  - output_tokens
  - total_tokens
  - latency_ms
  - estimated_cost (optional)
- trace (v0; always present at least as `trace_run_id`):
  - trace_run_id
  - level: info | debug
  - event_count (optional)
  - events[] (optional; debug only; bounded)
- driverBlocks (v0; bounded summary, no definitions echoed):
  - baselineCount: number (always 5 in v0)
  - acceptedCount: number (total blocks applied: baseline + refs + inline)
  - droppedCount: number (blocks dropped due to enforcement limits)
  - trimmedCount: number (blocks trimmed due to size limits)
- audit (optional; enable for debug/internals):
  - pinned_context_ref_used { id, version, hash }
  - policy_version
  - mode_label_used
  - rigor_gates_enabled[]
  - regen_count
  - linter_flags[] (optional)

---

## Error Model (v0)

All endpoints return a consistent error shape.

### Error Response (conceptual)

- request_id (if available)
- error:
  - code (stable string)
  - message
  - retryable (boolean)
  - details (optional)

### Request Validation (v0)

**Strict validation** is enforced on all request payloads. Unknown keys are rejected with HTTP 400.

If the request contains unknown keys, the server returns:

```json
{
  "error": "invalid_request",
  "message": "Unrecognized keys in request",
  "unrecognizedKeys": ["driverBlockMode", "unknownField"]
}
```

**Applies to**:
- Top-level request fields (e.g., `packet`, `context`, `budgets`)
- Nested objects (e.g., `trace_config`, `driver_block_refs[]`, `driver_block_inline[]`)

**Rationale**: Prevents silent no-op behavior and catches client/server version mismatches early.
---

## POST /v1/memories

### Purpose
Persist a user-explicit memory object (manual create flow).

### Request (conceptual)
- request_id (idempotency key; MUST be stable across retries)
- memory:
  - domain
  - title (optional)
  - tags[] (optional)
  - importance (optional)
  - content (text)
  - mood_anchor (optional)
  - rigor_level (optional; normal | high)
- source (optional):
  - thread_id
  - message_id
  - created_at
- consent:
  - explicit_user_consent: true

### Response (conceptual)
- request_id
- memory:
  - memory_id
  - created_at
  - updated_at (optional)
  - domain
  - title
  - summary (server-generated optional)
  - tags[]
  - rigor_level

---

## POST /v1/memories/distill

### Purpose
Extract a candidate memory artifact from a bounded context window (Gate 04) when a user explicitly requests “Save to Memory”.

This endpoint is async and returns quickly with a transmission_id; the resulting artifact is delivered as a muted Ghost Card.

### Request (conceptual)
- request_id (idempotency key; MUST be stable across retries)
- thread_id
- trigger_message_id
- context_window[] (capped; chronological order is preferred)
  - message_id
  - role: user | assistant | system
  - content
  - created_at
- reaffirm_count (optional; default 0)
- consent:
  - explicit_user_consent: true

### Validation + caps (v0)
- Strict validation is enforced (unknown keys rejected with 400).
- MAX_CONTEXT_WINDOW_MESSAGES: 15
- MAX_DISTILLED_FACT_CHARS: 150
- If no supported fact is found, the server MUST return `fact: null` (client renders a fallback prompt Ghost Card).
- The server MUST NOT hallucinate facts; only facts supported by the provided messages are allowed.

### Idempotency + reaffirm semantics
- request_id is the idempotency key. Retries MUST reuse the same request_id.
- reaffirm_count is advisory and may be used to prioritize/collapse repeated user intent within a short window.

### Response (conceptual)
- request_id
- transmission_id
- status: pending

### Data minimization (required)
- context_window is ephemeral input only and MUST NOT be persisted or logged verbatim.
- Permitted logs: request_id, transmission_id, counts/sizes, hashes.

---

## GET /v1/memories

### Purpose
List explicit memories for review and retrieval.

### Query
- domain (optional)
- tags_any (optional)
- cursor (optional)
- limit (optional)

### Response (conceptual)
- request_id
- items[]:
  - memory_id
  - type: memory | journal | action
  - snippet (or summary)
  - domain
  - title
  - tags[]
  - mood_anchor (optional)
  - rigor_level: normal | high
  - fidelity: direct | hazy (optional)
  - transition_to_hazy_at (optional)
  - created_at
  - updated_at (optional)
- next_cursor (optional)

---

## PATCH /v1/memories/{memory_id}

### Purpose
Edit a memory artifact (user-initiated).

### Request (conceptual)
- request_id (idempotency key)
- patch:
  - snippet (optional)
  - tags[] (optional)
  - mood_anchor (optional)
- consent:
  - explicit_user_consent: true

### Response (conceptual)
- request_id
- memory:
  - memory_id
  - updated_at

---

## DELETE /v1/memories/{memory_id}

### Purpose
Forget a memory artifact.

### Query
- confirm=true (required when rigor_level=high)

### Response
- 204 No Content (idempotent)

Notes:
- If rigor_level=high and confirm is missing, return a stable error code (e.g., confirm_required).

---

## POST /v1/memories/batch_delete

### Purpose
Delete multiple memories matching a filter (high-friction action).

### Request (conceptual)
- request_id
- filter:
  - thread_id (optional)
  - domain (optional)
  - tags_any (optional)
  - created_before (optional)
- confirm: true

### Response (conceptual)
- request_id
- deleted_count

---

## POST /v1/memories/clear_all

### Purpose
Delete all memories (highest-friction action).

### Request (conceptual)
- request_id
- confirm: true
- confirm_phrase: "DELETE ALL"

### Response (conceptual)
- request_id
- deleted_count

---

### Memory Error Codes (v0)
- invalid_request (400): strict validation failure; returns unrecognizedKeys[]
- confirm_required (409): missing confirm=true for high-rigor delete
- not_found (404)
- rate_limited (429)
- unauthorized (401) / forbidden (403)
- server_error (500)

---

Constraints / gotchas (do not drift)
	•	Do not rename request_id to idempotency_key. v0 contract already uses request_id as the idempotency primitive for /v1/chat. Keep it consistent everywhere.
	•	Do not duplicate the global ## Error Model (v0) section inside the Memory section. Only keep the “Memory Error Codes” list.
	•	Ensure ## GET /v1/usage/daily remains exactly once and still follows the memory block.

---

## GET /v1/usage/daily

### Purpose
Power the in-app cost meter.

### Response (conceptual)
- date
- totals:
  - requests
  - input_tokens
  - output_tokens
  - total_tokens
  - estimated_cost
- top_threads[] (optional):
  - thread_id
  - total_tokens
- recent_calls[] (optional):
  - request_id
  - thread_id
  - total_tokens
  - latency_ms
  - estimated_cost
