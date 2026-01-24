# Domain: solserver

## Purpose
The solserver domain governs the backend runtime that enforces policy, validation, budgets, and retrieval constraints for SolMobile.

## In Scope
- API contracts and schema validation
- Policy enforcement (explicit memory model, drift controls)
- Retrieval selection and injection (summaries only)
- Token and cost accounting per request
- Audit fields and request correlation
- Hosting/runtime constraints (Fly.io baseline)

## Out of Scope
- Client UI behavior
- Local thread storage and TTL cleanup
- Implicit memory accumulation

## Persistence Rules
- Server persists only explicit memory objects and minimal audit metadata.
- No silent persistence of conversation history.
- Retrieval operates only over explicit memory.

## Observability
- Errors and key request metadata are captured.
- Tracing is optional and low sampling by default.

## PR10 delta
- Journal drafts/entries endpoints are part of the minimal API surface (see `schema/v0/api-contracts.md` and `decisions/ADR-025-consented-journaling-v0-muse-offer-memento-affect-device-muse-trace.md`).
- Trace ingestion via `POST /v1/trace/events` accepts JournalOfferEvent and DeviceMuseObservation (mechanism-only; see `schema/v0/trace_events_request.schema.json` and `architecture/solmobile/solm-apple-intelligence-integration.md`).
