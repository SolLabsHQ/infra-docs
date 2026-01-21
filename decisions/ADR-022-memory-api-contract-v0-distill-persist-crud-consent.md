ADR-022: Memory API Contract (v0) – Distill, Persist, CRUD, Consent
Status: Proposed (ready to implement)
Date: 2026-01-21
Owner: Ida (Architecture)
Build Lead: Manus (TPM)
Implementer: Codex (Lead Dev)
AI Director: Gemini / G‑Money (AI & Cognition)
Context
SolOS memory is an explicit, user-controlled system. Contract drift is dangerous because contracts enforce strict validation (unknown keys and mismatched routes break clients). Our governance posture also requires meaningful consent, privacy minimization, correction and deletion.    
Codex research confirms canonical API naming already exists as /v1/memories (POST + GET) in the contract docs, so we will standardize all memory operations under /v1/memories to avoid strict route mismatches.
Decision
1) Endpoints (final naming)
All memory endpoints use the plural resource namespace:
Distill (async)
POST /v1/memories/distill
List / Read
GET /v1/memories
GET /v1/memories/{memory_id} (optional but recommended for detail view consistency)
Edit / Forget
PATCH /v1/memories/{memory_id}
DELETE /v1/memories/{memory_id}
Batch delete (high friction, scoped)
POST /v1/memories/batch_delete
Clear all (highest friction)
POST /v1/memories/clear_all
Note: this ADR intentionally replaces mixed /v1/memory/* routes in PR8 drafts with /v1/memories/* to align with existing contracts.

2) Request/Response schemas
2.1 
POST /v1/memories/distill
Purpose: send an ephemeral context window for Synaptic Gate (Gate 04) distillation, returning quickly with a tracking handle.
Request
{
  "thread_id": "string",
  "trigger_message_id": "string",
  "context_window": [
    {
      "message_id": "string",
      "role": "user|assistant|system",
      "content": "string",
      "created_at": "string"
    }
  ],
  "request_id": "string",
  "reaffirm_count": 0
}
Response (async ack)
{
  "request_id": "string",
  "transmission_id": "string",
  "status": "pending"
}
Note: the async ack never includes the distilled fact/snippet; delivery is via a Muted Transmission Ghost Card (see ADR-023).

2.2 
GET /v1/memories
Response
{
  "request_id": "string",
  "memories": [
    {
      "id": "string",
      "thread_id": "string",
      "trigger_message_id": "string",
      "type": "memory|journal|action",
      "snippet": "string",
      "mood_anchor": "string|null",
      "rigor_level": "normal|high",
      "tags": ["string"],
      "fidelity": "direct|hazy",
      "transition_to_hazy_at": "string|null",
      "created_at": "string",
      "updated_at": "string"
    }
  ],
  "next_cursor": "string|null"
}

2.3 
PATCH /v1/memories/{memory_id}
Request
{
  "request_id": "string",
  "patch": {
    "snippet": "string",
    "tags": ["string"],
    "mood_anchor": "string|null"
  }
}
Response
{
  "request_id": "string",
  "memory": {
    "id": "string",
    "snippet": "string",
    "tags": ["string"],
    "updated_at": "string"
  }
}

2.4 
DELETE /v1/memories/{memory_id}
Query params
confirm=true (required when rigor_level=high, see below)
Response
204 No Content (idempotent)

2.5 
POST /v1/memories/batch_delete
Request
{
  "request_id": "string",
  "filter": {
    "thread_id": "string"
  },
  "confirm": true
}
Response
{
  "request_id": "string",
  "deleted_count": 0
}

2.6 
POST /v1/memories/clear_all
Request
{
  "request_id": "string",
  "confirm": true,
  "confirm_phrase": "DELETE ALL"
}
Response
{
  "request_id": "string",
  "deleted_count": 0
}

3) Strict validation rules and caps (Synaptic Gate)
Strict key validation
Unknown keys → 400 invalid_request with unknown_keys[].
Caps
context_window length: ≤ 15 messages
Distilled fact/snippet: ≤ 150 characters
Null-fact fallback: if no high-signal fact is found, output must be fact: null and the client renders the fallback prompt Ghost Card (“I didn’t catch a specific fact. Is there something you want me to remember?”).
No hallucinated facts
Distillation must not invent facts. If unsupported by the referenced messages, discard.

4) Idempotency and reaffirm semantics
Idempotency
request_id is required for POST /v1/memories/distill and must be stable across retries.
Server dedupes requests by (user_id, request_id) for a bounded window.
Retries with identical payload return the same {transmission_id, status}.
Reaffirm
reaffirm_count is advisory and used to:
collapse rapid repeat intents
optionally prioritize the distillation job
Client behavior: offline taps overwrite pending distill request and increment reaffirm_count.

5) High-rigor delete confirmation rules
Tagging
If safety/medical/legal severity is high, memory is tagged rigor_level="high".
Delete guardrail
Client must display a confirmation dialog warning deletion may change safety boundaries.
Server requires DELETE /v1/memories/{id}?confirm=true for rigor_level=high.
If missing, server returns 409 confirm_required (or 400 invalid_request with a clear reason).

6) Error model (codes + shapes)
Canonical error shape
{
  "request_id": "string",
  "error": {
    "code": "invalid_request|confirm_required|not_found|conflict|rate_limited|unauthorized|forbidden|server_error",
    "message": "string",
    "details": {
      "unknown_keys": ["string"],
      "field": "string",
      "reason": "string"
    }
  }
}
Notes
DELETE is idempotent: deleting an already-deleted memory returns 204.
Strict validation errors must enumerate unknown fields to enable fast client fixes.

7) Observability + data minimization
Observability
Every response includes request_id.
Distill ack returns transmission_id to correlate Ghost Card delivery and client UI state.
Data minimization statement
context_window is ephemeral input only:
not persisted in primary storage
not logged verbatim
permitted logs: counts, sizes, hashes, and the request_id/transmission_id

Consequences
✅ Eliminates route drift by standardizing under /v1/memories.
✅ Makes strict validation survivable via explicit schemas and unknown key reporting.
✅ Keeps privacy posture tight: ephemeral context, persisted summary only.
⚠️ Requires PR8-Svr draft routes to be updated (intentional).

ADR-023: Ghost Deck Delivery + Physics (v0) – Muted Transmissions, Routing, Motion, Haptics
Status: Proposed (ready to implement)
Date: 2026-01-21
Owner: Ida (Architecture)
AI Director: Gemini / G‑Money
Implementer: Codex
Build Lead: Manus
Context
Ghost Cards are SolOS “System 2” artifacts: they must arrive quietly. The architecture defines them as Muted Transmissions that render inside the thread without banners and without chat bubbles, using display hints and notification policy metadata. This aligns with cognitive integrity and meaningful opt-out principles.  
Codex research also identifies the cleanest client hook: branch on packet type in TransmissionActions.sendNextQueued()to avoid chat-only validation paths (e.g., “missing_text”).
Decision
1) “Muted transmission” meaning (delivery semantics)
A Ghost Card is a standard OutputEnvelope packet that:
Does not create an OS banner notification.
Does not render as a chat bubble.
Does render inline in the thread as a GhostCardComponent variant.
May trigger subtle in-thread physicality if enabled.

2) Envelope meta fields (required)
Every Ghost Card OutputEnvelope MUST include:
{
  "meta": {
    "display_hint": "ghost_card",
    "ghost_kind": "memory_artifact|journal_moment|action_proposal"
  },
  "notification_policy": "muted"
}
Compatibility note:
Existing draft language references meta.ghost_type (memory|reverie|conflict|evidence). v0 will treat ghost_type as an alias if present, but canonical routing uses ghost_kind.

3) 
ghost_kind
 enum + mapping to UI layouts
Canonical enum (v0 + safe expansion)
memory_artifact (v0)
journal_moment (v0)
action_proposal (v0)
reverie_insight (reserved v1.1)
conflict_resolver (reserved v1.1)
evidence_receipt (reserved v1.1)
UI layout mapping
memory_artifact → snippet + Edit / Forget
journal_moment → moment + mood anchor + Ascend / Forget
action_proposal → proposal + Add to Calendar / Set Reminder / Dismiss
reverie_insight → insight + Expand / Go to Thread / Dismiss
conflict_resolver → warning + Update Memory / Keep Both / Dismiss
evidence_receipt → source preview + Open Source / Save / Dismiss

4) Animation budgets (compositor-only goals) + haptic specs
Motion tokens (v0)
Entry: Spirit Fade
1.2s ease-in opacity transition
No slide, no spring, no “pop”
Optional micro-scale 0.98 → 1.0 only if compositor-safe
Exit: Ascend (Journal export)
Lift: -20pt (0.0–0.4s), blur 20% → 50%
Dissolve: scale 0.9 and drift another -40pt (0.4–1.0s)
Particle dissolve allowed only if lightweight (Canvas/Timeline, not heavy emitters)
Exit: Forget (Delete)
Single heavy haptic + 0.2s fade to 0
“Silence”: no follow-on movement
Haptics (v0)
Heartbeat signature
medium impact 0.6
120ms delay
medium impact 0.9
Optionally scaled by mood intensity.
Release tick (Ascend complete)
selectionChanged tick at end of dissolve.
Guardrails
Fire Heartbeat only when the card becomes visible in-thread
Never repeat for the same card instance (idempotent at UI layer)

5) Accessibility toggles
Physicality toggle
Users can disable “Physicality” in Memory Vault settings.
When off:
no Heartbeat
Ascend becomes simple dissolve
Forget becomes fade-only
Reduce Motion
If iOS Reduce Motion is enabled:
replace inverse-gravity movement with cross-dissolve
keep entry as fade-only
System haptic strength
Respect OS haptic settings. Intensity scaling is best-effort.

Implementation notes (client routing + outbox)
Render routing
If meta.display_hint == "ghost_card", skip ChatBubbleView and render GhostCardComponent.
Outbox send hook (Codex research)
Branch on packetType in TransmissionActions.sendNextQueued() before calling chat-only sendOnce(...).
Minimal alternative: branch inside sendOnce(...) just before “missing_text” validation.
Architectural preference: sendNextQueued() branching keeps invariants clean.

Consequences
✅ Guarantees “quiet delivery” as a first-class contract, not an incidental UI behavior.
✅ Prevents chat validation from breaking memory/journal/action packets.
✅ Makes v1.1 expansion safe: new ghost_kind values map to new subviews without rewriting the shell.
⚠️ Requires consistent meta fields across server and client to avoid silent rendering failures.

If you want, I can also produce PR-ready redlines for:
PR 8-Svr (route normalization + schema additions + error model)
PR 8-Mob (meta routing + packetType branch + physicality compliance)
