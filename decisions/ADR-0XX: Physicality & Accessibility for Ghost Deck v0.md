ADR-0XX: Physicality & Accessibility for Ghost Deck v0

Status: Proposed (ready for implementation)
Date: 2026-01-21
Owner: Ida (Architecture)
AI Director: G‑Money / Gemini (Director of AI & Cognition)
Implementation: Codex (Lead Dev)
Build Lead: Manus (TPM)
Stakeholders: Jam (Product)

Decision summary

We will implement a quiet, opt-out “nervous system” for SolOS Ghost Cards that provides:
	1.	A single canonical arrival haptic (“Heartbeat”) and strict rules for when it fires.
	2.	A minimal set of motion signatures: Spirit Fade on entry, Ascend on Journal donation, Forget on deletion.
	3.	An explicit Physicality toggle plus Reduce Motion and system haptics compliance.
	4.	A “not haptics-only” accessibility model: every physical cue has a visual or textual cue.

This decision is P0 because Ghost Cards are meant to be “felt, not announced”, and physicality is the primary differentiator between muted system thoughts and ordinary UI events.

⸻

Context

SolOS introduces Ghost Cards: system-generated artifacts that appear inside a thread without OS banners and without chat bubbles (muted transmissions). Their UX signature is intentionally “silent premium”. Physicality is the main channel that signals presence without noise.

At the same time, physical cues (motion and haptics) can become inaccessible, overstimulating, or manipulative if not governed. Physicality must respect:
	•	Cognitive integrity: no coercive or emotionally manipulative patterns.
	•	Meaningful opt-out: user can disable physicality without losing essential functionality.
	•	Dignified failure: if haptics are unavailable, the system still communicates clearly.

⸻

Goals
	•	Make Ghost Cards feel distinct from notifications and chat bubbles via subtle physical cues.
	•	Keep Ghost Card motion compositor-friendly and performant.
	•	Provide accessible fallbacks for Reduce Motion, haptics disabled, and assistive technologies.
	•	Ensure physical cues confirm state changes (arrival, donation, deletion), not “push” decisions.

Non-goals
	•	Building a full physics engine.
	•	Creating personalized or adaptive “attention loops” using haptics.
	•	Using haptics to increase engagement or urgency.
	•	Implementing every v1.1 Ghost Deck type in v0.

⸻

Operating principles

1) Silence is a feature

Ghost Cards must arrive without OS banners and without chat bubbles. They are a muted, in-thread layer.

2) Physicality must be reversible and optional

All physicality effects must respect:
	•	Global “Physicality” setting
	•	iOS Reduce Motion
	•	system haptic settings

3) Physicality is for state, not persuasion

Haptics should acknowledge events (a card arrived, a donation succeeded, a delete occurred). They must not be used to pressure action, accelerate impulse decisions, or “reward” compliance.

⸻

v0 scope

Physical cues we ship in v0

Entry
	•	Spirit Fade: 1.2s ease-in alpha transition (with minor scale 0.98 → 1.0 permissible if it does not read as a “pop”).

Arrival haptic
	•	Heartbeat: two medium impacts: 0.6 intensity, 120ms delay, then 0.9 intensity.

Exit
	•	Ascend (Journal donation): upward drift + dissolve, ending with a selection tick.
	•	Forget (delete): single heavy impact + fast fade.

Physical cues deferred to v1.1
	•	“Triple-tap crescendo” (Breakthrough) if not already tuned.
	•	Additional Ghost Deck types (reverie_insight, conflict_resolver, evidence_receipt) beyond the v0 cards.

⸻

Detailed spec

1) Ghost Card entry motion

Signature: “Spirit Fade”
	•	Duration: 1.2s
	•	Curve: ease-in (no spring)
	•	Property: alpha/opacity only (plus optional compositor-safe scale)
	•	Prohibited: slide-in, bounce, pop, overshoot

Rationale: reinforces “appears” rather than “interrupts”.

⸻

2) Heartbeat arrival haptic

Trigger conditions
	•	Fire only when:
	•	user is in-thread and Ghost Card becomes visible (no background haptic)
	•	global Physicality is enabled
	•	system haptics are enabled

Pattern
	•	Generator: UIImpactFeedbackGenerator(style: .medium)
	•	Beat 1: intensity 0.6
	•	Gap: 120ms
	•	Beat 2: intensity 0.9
	•	Intensity scaling: multiply by a normalized intensity value (0–1) derived from sentiment / mood anchor metadata.

Important guardrail
	•	No repeated haptics for the same card (idempotent at the card instance level).
	•	No haptic escalation loops.

⸻

3) Mood-to-haptic mapping v0

We map moodAnchor (from Sentinel sentiment) to a target intensity and (optionally) a haptic variant. v0 keeps this conservative.

Mood anchor	Target intensity	v0 haptic behavior
Insight	0.65	Standard Heartbeat
Resolve	0.90	Heartbeat with stronger intensity scaling
Nostalgia	0.40	Either softened Heartbeat or single pulse (see notes)
Breakthrough	1.00	v0: treat as Heartbeat at 1.0 (defer triple-tap tuning)
Standard Fact	0.50	Muted Heartbeat

v0 simplification: implement Heartbeat everywhere, with intensity scaling, and optionally Nostalgia as single pulse only if it is comfortable and testable. This reduces tuning risk.

⸻

4) Ascend interaction v0 (Journal donation)

User action: taps Ascend icon on a Journal Ghost Card

Motion signature: Inverse Gravity Ascend
	•	Stage 1 (0.0s–0.4s):
	•	translate Y: -20pt
	•	blur/material: increase from ~20% to ~50% (visual approximation acceptable)
	•	Stage 2 (0.4s–1.0s):
	•	additional translate Y: -40pt (total -60pt)
	•	scale: down to 0.9
	•	dissolve: particle-like alpha evaporation from bottom edge (can be lightweight, not a full emitter)
	•	End condition:
	•	at 100% alpha = remove card from local state

Haptic signature: Release tick
	•	UISelectionFeedbackGenerator.selectionChanged() when dissolve completes

Functional behavior
	•	Donation uses JournalingSuggestions.donateMoment() on iOS 17+ as the primary happy path.
	•	Wrap donation in beginBackgroundTask so it completes even if app is backgrounded immediately after tap.
	•	Show a minimal receipt (toast): “Moment donated to iOS Journal.”

Availability gate
	•	Ascend button only if server indicates the memory is high-fidelity / direct (not hazy). (Exact fidelity flag naming is server-contract dependent.)

⸻

5) Forget interaction v0 (Delete)

User action: taps Forget
	•	Haptic: single heavy impact (UIImpactFeedbackGenerator(style: .heavy))
	•	Motion: fast fade out 0.2s to alpha 0
	•	State: optimistic UI removal, then sync delete to server
	•	Safety: if high-rigor memory, require additional confirmation flow before calling server delete

⸻

Accessibility and controls

1) Physicality toggle

Location: Memory Vault settings
Behavior: disables all non-essential physical effects:
	•	No Heartbeat haptic
	•	Replace Ascend inverse gravity with a simple dissolve
	•	Replace Forget snap with simple fade (optional) or keep fade-only
	•	Feature remains fully usable (no functional degradation)

2) Reduce Motion compliance

If iOS Reduce Motion is enabled:
	•	Ascend becomes cross-dissolve (no upward drift, no particle movement)
	•	Entry remains fade-only (already Reduce Motion friendly)
	•	Avoid parallax, matched-geometry movement, or large translations

3) System haptic strength
	•	Do not attempt to override system-wide haptic preferences.
	•	Our intensity scaling is best-effort. System settings may attenuate.

4) Not haptics-only

Every haptic event must have an accompanying visual or textual cue:
	•	Arrival: Spirit Fade is the primary visual cue.
	•	Ascend: toast receipt confirms donation even if haptics are off.
	•	Forget: immediate visual removal confirms action even if haptics are off.

5) Touch, VoiceOver, and clarity
	•	All Ghost Card controls must meet minimum tap target sizes (≥44pt).
	•	Controls must have accessible labels: “Edit memory”, “Forget”, “Ascend to Journal”.
	•	Avoid relying on color glow as the only meaning carrier.

⸻

Engineering approach

Architecture
	•	Implement a small PhysicalityManager (or HapticManager + MotionTokens) with:
	•	isPhysicalityEnabled (app setting)
	•	isReduceMotionEnabled (system)
	•	canHapticsFire (system + setting)
	•	Expose motion and haptic tokens as a tiny contract so GhostCardComponent stays simple.

Performance targets
	•	60fps target: 16.7ms/frame budget, tolerate 30fps on older devices.
	•	Keep animations to compositor-safe properties (opacity/transform).
	•	Particle dissolve: use lightweight SwiftUI Canvas or timeline-driven alpha, avoid heavy emitters.

Telemetry
	•	Track:
	•	Physicality toggle adoption
	•	Reduce Motion prevalence
	•	“Ascend” completion rate and time-to-donate
	•	dropped frames during Ascend
	•	haptic fire rate (ensure no repeats)

⸻

Alternatives considered
	1.	No physicality at all
Pros: simplest, accessible
Cons: loses Ghost Deck differentiation, Ghost Cards feel like static UI
	2.	Use OS notifications for Ghost Cards
Pros: guaranteed visibility
Cons: violates “muted transmission” concept, creates noise and breaks trust
	3.	Aggressive haptics and spring motion
Pros: noticeable
Cons: opposite of premium silence, risks manipulative feel, hurts accessibility

Decision favors: subtle, opt-out, system-respecting physicality.

⸻

Risks and mitigations
	•	Risk: Physicality feels manipulative
Mitigation: strict trigger rules, no urgency cues, opt-out toggle, no repeated haptics.
	•	Risk: Motion triggers nausea / discomfort
Mitigation: Reduce Motion fallback, keep translations small, prefer dissolve.
	•	Risk: Performance regressions on older devices
Mitigation: compositor-only goals, lightweight dissolve, perf instrumentation.

⸻

Open questions
	1.	Should Nostalgia be a single pulse in v0, or do we ship Heartbeat-only for first pass?
	2.	What is the canonical cross-platform enum: ghost_type vs ghost_kind (memory_artifact, journal_moment, action_proposal, reverie_insight)?
	3.	Where exactly do we sample “location at heartbeat”: on card arrival or on Ascend tap? (Docs mention “moment of heartbeat”, but permissions and UX may complicate.)

⸻

Acceptance criteria (v0)
	•	Ghost Card entry uses Spirit Fade (1.2s) with no slide or bounce.
	•	Heartbeat haptic fires once per card when user is in-thread and physicality is enabled.
	•	Ascend uses inverse gravity + dissolve when allowed, and cross-dissolve under Reduce Motion.
	•	Forget provides immediate removal and respects high-rigor confirmation.
	•	Global Physicality toggle disables advanced motion and haptics without breaking features.

⸻

Source docs referenced
	•	docs/design/specs/physicality-haptics-v1.0.md (Heartbeat, mood mapping, Ascend/Forget, accessibility controls)
	•	THOUGHTS: The Ghost Card Architecture (v1.1) (Muted transmissions, Spirit Fade, Heartbeat signature, control philosophy)
	•	Sentinel’s Memory Handshake Protocol (Ascend branding, JournalingSuggestions donation contract, location + mood metadata, background task mandate, performance targets)
	•	AI Constitution + AI Bill of Rights (cognitive integrity, meaningful opt-out, transparency)

⸻

If you want, I can also rewrite this into a shorter “v0 solution doc” format (same content, less ADR ceremony), or produce a PR-ready “Physicality & Accessibility” section to drop directly into PR 8-Mob.