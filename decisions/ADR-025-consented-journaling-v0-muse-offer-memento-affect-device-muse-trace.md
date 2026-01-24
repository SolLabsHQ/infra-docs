# ADR-025: Consented Journaling v0 - Synaptic Muse Offer + ThreadMemento Affect + DeviceMuse Trace

- Status: Proposed
- Date: 2026-01-23
- Owners: SolServer / SolMobile
- Domains: trust, consent, journaling, thread state, trace, privacy

## Context
SolMobile v0 is local-first and explicit-memory-only. Users must not experience passive or hidden persistence.

Journaling is distinct from memory:
- Journaling transforms a bounded conversation span into a draft.
- The transformation requires a model step referencing prior conversation content.
- Journaling must remain explicitly consented and inspectable.

We also need respectful timing:
- Overwhelm can be journal-worthy, but prompting during peak escalation can feel intrusive.
- The system needs thread-level emotional velocity (phase) to decide offer eligibility.

Finally, we want to experiment with Apple Intelligence as a secondary voice:
- It must be optional (hardware, availability, cross-platform parity).
- It must be privacy-minimal: mechanism insight only, no raw content.

## Decision
### D1) Muse Offer pattern
SolServer may emit a journal offer as inspiration only.
- Offers are suggestions, not persistence.
- Draft generation occurs only after explicit user consent.
- SolServer attaches the offer as `OutputEnvelope.meta.journal_offer` (not as a saved artifact).

### D2) Deterministic JournalOfferClassifier v0 (Synaptic gate)
For v0, journal offer detection is deterministic and runs inside Synaptic gate, using:
- Sentinel mood label + intensity
- Sentinel risk signal
- ThreadMemento affect rollup phase (rising, peak, downshift, settled)

No extra model call is used to decide whether a moment exists. Drafting uses a model call only after user acceptance.

Classifier rules (v0):
- If risk is elevated: emit no offer.
- Overwhelm + phase != settled: emit no offer.
- Insight + intensity > threshold: offer immediately.
- Gratitude: wait during rising/peak, offer on downshift/settled.
- Resolve/Decision: offer only when settled.
- Curiosity: mute (not a journaling trigger).

### D3) ThreadMemento v0.1 includes affect rollup (P0)
ThreadMemento is extended to include `affect`:
- points[] (max 5) with per-message intensity and label
- rollup with phase (rising, peak, downshift, settled) and an intensity bucket

This rollup is required to compute offer eligibility safely.

ThreadMemento remains a thread-level state object (not a durable knowledge record).

### D4) Journal draft endpoint (sync)
Add `POST /v1/journal/drafts`:
- Request: `JournalDraftRequest` (required: request_id, thread_id, mode, evidence_span)
- Response: `JournalDraftEnvelope` with evidence binding metadata including `non_invention`

Draft mode:
- `verbatim`: preserve user words, minimal shaping
- `assist`: apply CPB journalStyle (tone + max lines) and return structured draft

### D5) Journal entry endpoints (explicit persistence)
Add CRUD for `JournalEntry` as an explicitly user-initiated action.
- JournalEntry requires `draft_meta.mode`; draft_id is optional.

### D6) Trace ingestion endpoint + privacy constraints
Add `POST /v1/trace/events` for client-originated events:
- JournalOfferEvent (offer lifecycle and tuning)
- DeviceMuseObservation (Apple Intelligence hint events)

Privacy rule (DeviceMuseObservation):
- Mechanism-only trace signals:
  - detected_type, intensity, confidence, optional phase_hint
  - ids: local_user_uuid, thread_id, message_id, ts
- Must not include raw message text, context spans, evidence spans, or extracted entities.
- The system inspects the mechanism, not the thought.

### D7) Client responsibilities (pilot)
SolMobile:
- Uses CPB journalStyle to apply cooldowns and timing preferences (avoid peak overwhelm, cooldown minutes).
- Renders offers and captures explicit consent selection (verbatim/assist).
- Label-only fidelity gate for Ascend:
  - Client must not compute fidelity/directness.
  - Ascend is shown only when server labels `ghost_kind == journal_moment`.

Apple Intelligence (optional):
- Runs non-blocking.
- Produces DeviceMuseObservation for message N-1 and sends to trace.
- Does not gate or suppress offers in v0.

## 4B
### Bounds
- No auto-save journaling.
- No drafting without explicit consent.
- DeviceMuseObservation is mechanism-only; no raw content.

### Buffer
- Offers respect avoid-peak preference and cooldown.
- Apple Intelligence is optional; server behavior does not depend on it in v0.

### Breakpoints
- Offer emitted (server)
- Offer shown (client)
- Offer accepted/declined/tuned (client to trace)
- Draft generated (server)
- Entry saved (explicit user action)

### Beat
- v0.1: deterministic classifier + ThreadMemento affect rollup + drafts endpoint + trace ingestion
- v0.2: optional device hints can influence classifier as tie-break only (still no content)

## Consequences
### Benefits
- Predictable, testable offer behavior (deterministic matrix).
- Respectful timing based on emotional velocity.
- Strong consent boundary for drafting and persistence.
- Apple Intelligence experimentation is safe and optional.

### Costs / Risks
- Requires ThreadMemento v0.1 schema and compatibility handling.
- Needs trace ingestion route and schema enforcement.
- Must keep client label-only gating aligned (no drift into local fidelity computation).

## Acceptance Criteria
- Overwhelm rising/peak/downshift produces no journal offer; settled may offer.
- Insight above threshold offers regardless of phase.
- Gratitude offers only after downshift/settled.
- POST /v1/journal/drafts returns schema-valid JournalDraftEnvelope and sets evidence_binding.non_invention.
- DeviceMuseObservation trace events are rejected if any content fields appear.
