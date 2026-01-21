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
    "ghost_kind": "memory_artifact|journal_moment|action_proposal|reverie_insight"
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
