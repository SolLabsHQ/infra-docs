# API Contracts v0

This document defines the v0 API surface used by SolMobile and SolServer.

The API is intentionally small and bounded.
All persistence is explicit and user initiated.

---

## Common Concepts

### Budgets
Each chat request includes explicit budget caps:
- max input tokens
- max output tokens
- retrieval item limits

Budgets are enforced server-side.

### Context Strategy
Chat requests provide:
- pinned context reference (id, version, hash)
- capsule summary (client-maintained)
- capped recent history
- retrieval configuration

---

## POST /v1/chat

### Purpose
Perform inference for a user message with bounded context and optional retrieval summaries.

### Request (conceptual)
- request_id
- user/device identifiers (v0 minimal)
- thread_id, message_id
- mode (sole/sherlock/watson or equivalent)
- context:
  - pinned_context_ref { id, version, hash }
  - domain_scope
  - capsule_summary
  - history[] (capped)
  - retrieval_config { max_items, max_summary_tokens }
- input_text
- budgets { max_input_tokens, max_output_tokens }

### Response (conceptual)
- request_id
- output_text
- retrieved_memories_used[]:
  - memory_id
  - domain
  - title
  - summary
- usage:
  - input_tokens
  - output_tokens
  - total_tokens
  - estimated_cost (optional)
- audit:
  - pinned_context_hash
  - policy_version (optional)

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
