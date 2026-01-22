\#\# \`CHECKLIST.md\`

\`\`\`md

\# Codex Checklist — Muse Overlay \+ Starlight v0.2

\#\# Wiring \+ placement

\- \[x] StarlightPulseView at composer leading edge.

\- \[x] StarlightState is semantic: idle / pending / flash.

\- \[x] Muse overlay is ZStack pinned top-left safe area (no List insertion).

\- \[x] Card body does not steal scroll gestures.

\- \[x] Only handle is swipeable (24pt circular target).

\#\# Starlight behavior

\- \[x] pending: 2s breathing loop (alpha 0.2 ↔ 0.7) in brandGold.

\- \[x] flash: brighten/expand \+ dissolve (\~0.35s) then idle.

\- \[x] pulse ends on assistant arrival.

\#\# Haptics (assistant arrival)

\- \[x] Always fires on assistant response visible.

\- \[x] delta \< 1.2s: single soft impact.

\- \[x] delta ≥ 1.2s: heartbeat 0.6 → 120ms → 0.9.

\- \[x] Mild scaling for slow arrivals capped at \+20%.

\- \[x] Gated by PhysicalityManager.canFireHaptics().

\#\# Muse overlay gestures \+ recovery

\- \[x] Swipe left on handle \= dismiss (not delete).

\- \[x] Swipe up on handle \= ascend/accept (only when applicable).

\- \[x] Dismiss shows recovery pill for 3–5s.

\- \[x] Recovery pill is ultraThinMaterial, leading-aligned above composer, tappable to restore.

\- \[x] Recovery pill never blocks typing.

\#\# Linger policy

\- \[x] Saved memory (memory\_id \!= nil && fact\_null false): receipt window then evaporate in place (0.8s fade).

\- \[x] Receipt window: 3s normal, 5s high-rigor.

\- \[x] Manual entry: stays until action; typing hides and shows recovery pill.

\- \[x] Pending stays full until saved transition.

\#\# Visual vocabulary

\- \[x] Receipt glow: thin brandGold stroke \+ soft shadow during receipt window only.

\- \[x] High-rigor glow pulses subtly at 0.5Hz during 5s window.

\- \[x] Handle echo pulse runs on appear (ring \+ ghost bounce).

\#\# 👻 Muse symbol v0.1

\- \[x] Handle: 👻 24pt, 60% opacity, brandGold shadow.

\- \[x] Recovery pill: 👻 14pt \+ brandGold styling.

\- \[x] Vault: 👻 16pt solid row icon.

\#\# Tests

\- \[x] Single stubbed UI smoke test (no local server):

  \- launch arg enables stub network

  \- tap Save to Memory

  \- assert ghost overlay (or equivalent placeholder) appears

\- \[ \] Existing unit tests still pass (CTA gating, confirm flow, etc.).
