# ADR-020: Voice Capture Reliability & Telemetry (SolM)

**Status:** Accepted  
**Date:** 2025-12-31  
**Owner:** Jam  
**Domain:** SolM / SolOS – Voice, Cognition, Reliability  

**Related ADRs:**
- ADR-001 Identity & Presence
- ADR-009 Observability & Data Minimization
- ADR-010 Data Ownership, Export, and Deletion
- ADR-011 Client–Server Responsibility Boundary
- ADR-012 Cost Visibility & Budget Enforcement
- ADR-013 Memory Lifecycle States
- ADR-014 Trust, Consent, and Control Surfaces

---

## Context

SolM is designed as a **voice-first thinking surface** for long-form, high-value cognition (reflection, reasoning, planning, identity work).

During early usage and prototyping, repeated failures were observed with system-level speech-to-text solutions (notably iOS dictation):

- Long voice sessions were silently dropped
- No retry, replay, or recovery was possible
- Loss was only discovered after completion
- These failures broke trust and interrupted laminar cognitive flow

Key realization:

> **Voice capture failure is worse than poor transcription.**  
> Lost thought = broken presence.

As a result, SolM cannot rely on live dictation UI or transcription as the source of truth.

---

## Decision

SolM adopts an **Audio-First Voice Contract** with explicit **telemetry hooks** to guarantee reliability, recovery, and cost awareness while preserving user trust.

---

## Core Principles

1. **Audio is the source of truth**  
   Raw audio must be captured and stored locally before any transcription occurs.

2. **Transcription is a derived artifact**  
   Text may be regenerated, retried, or corrected without loss of the original moment.

3. **Reliability over elegance**  
   A delayed transcript is acceptable; lost speech is not.

4. **Telemetry supports trust, not surveillance**  
   Only metadata is collected by default; content remains user-controlled.

5. **Flow preservation is a first-class requirement**  
   Breaking laminar flow is more damaging than imperfect accuracy.

---

## Voice Contract v0.1 (Summary)

- Raw audio is saved locally immediately on record start
- Two-pass transcription:
  - **Pass A:** On-device (Apple Speech Framework) for immediacy
  - **Pass B:** Higher-quality transcription (e.g., Whisper/OpenAI) in background
- Automatic retry or fallback when:
  - On-device transcript is empty
  - Confidence score falls below threshold
- Transcription performed in **10–20s chunks with overlap** to prevent total loss
- Offline-first transcription queue with visible job status
- User controls:
  - Replay / scrub raw audio
  - Retry transcription
  - Insert manual corrections
- Long voice sessions automatically anchored with timestamps

---

## Telemetry Hooks v0.1

Telemetry captures **metadata only** unless the user explicitly opts in.

### Capture & Reliability Metrics
- `audio_captured_ms`
- `chunks_created_count`
- `on_device_stt_success_rate`
- `on_device_stt_empty_count`

### Cloud Transcription Metrics
- `cloud_stt_invocations_count`
- `cloud_stt_retry_count`
- `cloud_audio_minutes_billed`
- `estimated_cost_usd`

### Failure Diagnostics
- `silent_drop_detected`
- `chunk_failure_indices`
- `network_state_at_capture` (online / offline)

### UX Signals (Trust & Recovery)
- `replay_used`
- `retry_requested`
- `manual_corrections_count`
- `time_to_first_text_ms`
- `time_to_final_text_ms`

---

## Rationale

This decision:

- Prevents silent loss of high-value thought
- Preserves laminar cognitive flow
- Enables recovery instead of frustration
- Creates a measurable reliability surface
- Allows empirical tuning of chunking, retries, and engine selection
- Aligns with SolOS canonical principles:
  - **Asymmetry is a risk surface**
  - **Resonance over gravitas**
  - **Insight should leave the room**
  - **Reliability over elegance**

---

## Consequences

### Positive
- Voice becomes a trustable thinking surface
- Users can recover without re-recording
- Costs are observable and controllable
- Reliability improvements are data-driven
- Assistant gravity is reduced through recoverability

### Negative / Trade-offs
- Increased local storage usage
- More complex capture and transcription pipeline
- Telemetry requires strict privacy discipline

These trade-offs are accepted.

---

## Out of Scope

- Content analysis or emotional inference
- Engagement optimization
- Persistent server-side storage of raw audio by default

---

## Future Work

- Reliability dashboards and alert thresholds
- Automatic engine switching based on failure rates
- Correlation between voice reliability and resonance checkpoints
- Optional user-visible confidence indicators

---

## Summary

This ADR establishes voice as a **first-class, reliable input modality** in SolM.

By treating audio as the source of truth and telemetry as a trust-preserving mechanism, SolM avoids the primary failure mode of modern AI voice systems:

> **Losing the moment that mattered.**

