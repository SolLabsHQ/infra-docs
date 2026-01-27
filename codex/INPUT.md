## **INPUT**

\# Codex Input — Muse Overlay \+ Starlight Protocol (v0.2)

\#\# Objective

Implement a spatial contract that respects focus:

\- \*\*Pilot (Bottom):\*\* composer \+ starlight wait tether \+ recovery pill

\- \*\*Muse (Top-Left):\*\* ghost card overlay (no layout push) with handle-only gestures

Waiting should feel alive (starlight). Arrival should be unmistakable (haptic \+ flash). Saved truths should leave the room (receipt window → evaporate). Manual-entry prompts stay recoverable (dismiss → pill → restore).

\#\# Naming rules

\- Do not name things “202” or “200” in enums/types.

\- Use semantic terms like \`pending\`, \`flash\`, \`idle\`, \`dismissed\`, \`hidden\`.

\- No numeric gate language anywhere.

\---

\#\# Pilot Domain: Starlight Pulse (wait tether \+ landed flash)

\#\#\# Location

Leading edge of the composer input.

\#\#\# State model

\`\`\`swift

` enum StarlightState { case idle, pending, flash } 
`
\`\`\`

### **Behavior**

* When a request is accepted (HTTP 202): pending  
  * 2s breathing loop (alpha 0.2 → 0.7) in brandGold  
* When the assistant response becomes visible: flash  
  * quick brighten/expand \+ dissolve (\~0.35s)  
  * then return to idle (pulse ends)

### **Visual scaffold**

Use StarlightPulseView (pending breath \+ flash dissolve). Keep behavior identical even if refactoring.

---

## **Haptics: Velocity (Pilot speed vs Muse speed)**

### **Rule**

We always give *something* on assistant arrival (user may be thinking/looking elsewhere).

* Fast (Pilot speed): delta \< 1.2s since pending began  
  * single soft impact  
* Slow (Muse speed): delta ≥ 1.2s  
  * full Heartbeat: 0.6 → 120ms → 0.9

### **Director refinement**

For slow arrivals only, scale heartbeat intensity slightly with wait duration, capped at \+20%.

---

## **Muse Domain: Ghost Card Overlay (top-left)**

### **Placement**

* ZStack overlay pinned top-left safe area (no List insertion, no layout push)  
* Card body does not steal scroll gestures

### **Handle-only interaction**

* Only a 24pt circular handle is swipeable (not the whole card)  
* Gestures:  
  * Swipe up on handle: Ascend/Accept (only if applicable)  
  * Swipe left on handle: Dismiss (NOT delete)  
* No swipe down

### **Handle “Echo Pulse”**

On overlay appear, handle performs a one-shot echo ring \+ ghost bounce to create “visual travel” from bottom starlight to top muse.

---

## **Linger Paradox (policy)**

### **Saved memory (memory\_id exists, fact\_null false)**

* Receipt window then auto-evaporate in place (alpha fade 0.8s)  
* Window: normal 3s, high-rigor 5s  
* Receipt glow during the window (brandGold stroke \+ shadow)  
* No chip for saved memories

### **Manual entry (fact\_null true)**

* Stays until action or explicit dismiss  
* If user starts typing: hide overlay and show recovery pill (quiet, leading-aligned)

### **Pending (memory\_id nil, fact\_null false)**

* Stays visible until saved transition, then follows saved policy

---

## **Visual vocabulary (reusable)**

Use the same glassmorphism family across:

* starlight pulse  
* handle echo pulse  
* receipt glow  
* recovery pill

### **Receipt glow**

During receipt window only:

* thin brandGold stroke  
* soft brandGold shadow

### **High-rigor pulse**

If high-rigor, glow pulses subtly at 0.5Hz during its 5s window.

---

## **Recovery Pill (quiet, leading-aligned)**

### **Placement \+ material**

* .ultraThinMaterial  
* pinned directly above composer leading edge (aligned with starlight)  
* 3–5s lifetime  
* tappable to restore muse overlay  
* translucent, ignorable, never blocks typing

---

## **Muse symbol v0.1: 👻 (locked)**

We use 👻 as v0.1 Muse symbol, styled “spectral,” not sticker-y.

| Context | Visual styling | Logic |
| ----- | ----- | ----- |
| Muse Handle | 24pt ghost, 60% opacity | only swipeable target |
| Recovery Pill | 14pt ghost \+ brandGold | signals restorable truth |
| Vault | 16pt ghost (solid) | row icon for “distilled by Muse” |

### **Spectral styling rules**

* subtle brandGold shadow on arrival  
* handle performs echo ring \+ bounce (1.0 → 1.4 → 1.0)

---

## **Deliverables**

1. StarlightPulseView wired at composer leading edge (pending \+ flash \+ idle)  
2. MuseOverlayHost pinned top-left, handle-only gestures, no layout push  
3. MuseHandleView 👻 echo pulse, spectral styling  
4. Recovery pill (ultraThinMaterial), leading-aligned above composer, 3–5s, tappable  
5. Haptics policy on assistant arrival (soft vs heartbeat \+ mild scaling)  
6. Saved receipt window behavior (3s/5s) \+ evaporate in place  
7. Single stubbed UI smoke test (no local server) proving Save to Memory wiring and ghost appears

---

## **Acceptance criteria (must verify)**

* No layout jump on muse arrival.  
* Starlight pulses while waiting, flashes on assistant arrival, then stops.  
* Assistant arrival always produces a haptic (soft if fast, heartbeat if slow \+ scaling).  
* Muse overlay handle-only gestures work (up=ascend, left=dismiss).  
* Dismiss shows recovery pill; tap restores.  
* Saved memory glows briefly then evaporates (3/5s).  
* Manual entry never auto-deletes; typing hides it and shows recovery pill.  
* High-rigor glow pulses subtly at 0.5Hz during its window.

\---