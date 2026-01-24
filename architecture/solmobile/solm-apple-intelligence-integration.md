# SolM Apple Intelligence Integration (v0)

- Status: Draft
- Date: 2026-01-23
- Owners: SolMobile / SolServer

## Context
Apple Intelligence can provide optional, device-native signals that complement SolServer signals. It must remain privacy-minimal and never include raw user content.

## Scope (v0)
- Non-blocking device-side analysis.
- Mechanism-only hints surfaced as DeviceMuseObservation events.
- No gating of journal offers or server decisions in v0.

## Data flow
1) SolMobile requests Apple Intelligence analysis for message N-1 (best effort).
2) Device produces a DeviceMuseObservation (mechanism-only).
3) SolMobile sends the observation to `POST /v1/trace/events`.
4) SolServer stores trace events for inspection and tuning only.

## Privacy constraints
- Do not send raw message text, context windows, evidence spans, or extracted entities.
- Allowed fields are mechanism signals only (detected_type, intensity, confidence, optional phase_hint) plus IDs and timestamps.
- The system inspects the mechanism, not the thought.

## PR10 integration
- Apple Intelligence runs non-blocking.
- Emits DeviceMuseObservation for message N-1.
- Uploads to `POST /v1/trace/events`.
- Does not affect offer eligibility in v0.
