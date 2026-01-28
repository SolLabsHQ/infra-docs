# ADR-027 — OpenAI Responses API Migration (SolServer)

## Status
Proposed

## Context
- SolServer’s OpenAI provider currently uses `POST /v1/chat/completions` with `response_format: { type: "json_object" }`.
- Streaming support and standardized structured outputs are required for SSE work (ADR-026).
- OpenAI’s Responses API is the recommended path and changes request/response shapes.

## Decision
TBD. This ADR will define:
- Use `POST /v1/responses` and `text.format` for OutputEnvelope JSON.
- Whether to stream from OpenAI and how to map provider events to SolServer SSE.
- Required request fields (model, input, system instructions) and `store: false` policy.
- Parsing/extraction logic for assistant text and OutputEnvelope meta.
- Error handling, retries, and integration test updates.

## Alternatives Considered
- Keep Chat Completions.
- Use OpenAI SDK vs raw fetch.
- Switch providers (non-OpenAI).

## Consequences
- Provider code and tests will change; OutputEnvelope parsing path updated.
- Requires careful mapping to existing gating/regen pipeline.

## Date
2026-01-28
