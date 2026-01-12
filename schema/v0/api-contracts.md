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
Persist a user-explicit memory object.

### Request (conceptual)
- memory:
  - domain
  - title (optional)
  - tags[] (optional)
  - importance (optional)
  - content (text)
- source:
  - thread_id
  - message_id
  - created_at
- consent:
  - explicit_user_consent: true

### Response (conceptual)
- memory_id
- created_at
- domain
- title
- summary (server-generated optional)

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
- items[]:
  - memory_id
  - domain
  - title
  - summary
  - created_at
  - tags[]
- next_cursor (optional)

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
