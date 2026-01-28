# ADR-027 — OpenAI Responses API Migration (SolServer)

## Status
Proposed

## Context
- SolServer currently calls OpenAI using **Chat Completions** (`POST /v1/chat/completions`).
- SSE work (ADR-029, ADR-026) is about *server → client* streaming, but we also want to be ready for:
  - provider-side streaming (OpenAI SSE) when we eventually choose to stream more than statuses
  - newer models and “agentic primitives” that are first-class in the Responses API
- Responses API changes two key surfaces that matter for SolOS:
  - **structured output config** moves from `response_format` → `text.format`
  - **streaming** is explicitly supported via `stream: true` (SSE)

## Decision
SolServer will migrate its OpenAI provider integration from **Chat Completions** to the **Responses API**.

### D1) Endpoint + storage posture
- Use `POST /v1/responses`.
- Set `store: false` by default (SolOS prefers server-side persistence only for *our* artifacts: Transmissions, OutputEnvelope, traces).

### D2) Structured output enforcement
- Replace `response_format: { type: "json_object" }` with `text.format`.
- v0 will use **Structured Outputs** (`type: "json_schema"`, `strict: true`) for the **OutputEnvelope v0-min** schema.
  - If we ever need to support a model that does not support `json_schema`, we can fall back to JSON mode (`type: "json_object"`) behind a feature flag.

### D3) Streaming posture
- v0: `stream: false` (buffered response), because our gates require a full candidate OutputEnvelope before validation + regen.
- v0.1+: we may enable `stream: true` server-side (buffer deltas; do not expose un-gated content to clients) as a preparatory step toward chat streaming.

### D4) v0 does not require OpenAI streaming for correctness
- v0 SSE is primarily status + commit (ADR-026).
- Provider calls may remain non-streaming in v0 to keep the gating pipeline simple and deterministic.

## v0, v0.1, v1 plan

### v0
- Migrate SolServer OpenAI calls to `/v1/responses`.
- Keep response delivery semantics unchanged:
  - `/v1/chat` still returns 200 or 202, and polling via `GET /v1/transmissions/:id` remains correct.
- SSE remains **status-only** (no token deltas).

### v0.1
- Optional: enable provider streaming (`stream: true`) for earlier server-side progress signals.
- Implement an internal OpenAI stream parser behind an interface boundary.
- Still buffer until the full OutputEnvelope candidate is complete, then run gates.

### v1
- If we decide to stream assistant text:
  - introduce an explicit streaming surface (`/v1/chat/stream` or content negotiation)
  - define “preview vs committed” semantics (un-gated deltas must never be confused with committed OutputEnvelope)

## Alternatives considered
- Keep Chat Completions and only add SSE for client status events.
- Use JSON mode (`json_object`) only (simpler, but weaker guarantees).
- Adopt OpenAI streaming immediately and forward deltas to clients (rejected for v0 due to gates + regen + trust).

## Consequences
### Benefits
- Aligns SolServer with OpenAI’s recommended API primitive.
- Puts structured outputs and streaming on the same API surface we’ll build on long-term.
- Reduces future rework when we add richer realtime features.

### Costs / risks
- Provider response shape changes (Responses `output[]` items vs Chat Completions `choices[]`).
- New failure modes to handle explicitly (e.g., incomplete generations, refusals).

## References
- OpenAI: “Migrate to the Responses API”
- OpenAI: Responses API reference (`/v1/responses`)
- OpenAI: Structured model outputs (Structured Outputs + JSON mode)
- OpenAI: Streaming API responses (SSE)

## Date
2026-01-28
