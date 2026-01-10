# SolM Trace UI Spec v0 — Idea Lot Draft
> Purpose: capture Manus-grade operator tracing as a **SolM-native** capability: user-legible transparency + governance-as-actions + OS-first portability + prompting telemetry.

---

## Why this exists
Agentic systems live or die on trust. Trust comes from **observable behavior**, not vibes.

Manus showed a strong pattern:
- Explicit passes (Plan → Evidence → Synthesis)
- Visible workstream (“opened 5/12 pages”, “editing CSS”, “creating files”)
- A “deliverable” endpoint (published artifact)

SolM should steal the **trace exposure** while keeping our core difference:
- **Device-first truth**
- **Governance as actions** (writes must stop at Breakpoints)
- **OS-first exports** (Notes/Markdown) vs “web-first publishing”

---

## Design principles
1. **Legibility in 10 seconds**  
   User should quickly answer: *What is it doing? Why? What will change?*

2. **Governance is not “theme” — it is control points**  
   Governance only counts when it blocks or gates actions.

3. **OS-first portability**  
   Outputs must be easy to copy/export into Notes/Markdown (and later PDF), with citations.

4. **Trace as UI AND telemetry**  
   Even if mostly hidden, the trace must exist as structured events for prompt iteration, audit, and debugging.

5. **Privacy-by-default**  
   Store summaries and citations, not raw page dumps. Avoid capturing secrets by default.

---

## Scope
### v0 Goals
- Trace Drawer (collapsed by default)
- Run Timeline (step cards)
- Evidence panel + citations
- Breakpoint modal (write safety handshake)
- Export: Save to Notes + Export Markdown + Share
- Telemetry event stream (client + server)

### v0 Non-goals
- Full “agent IDE” inside SolM
- Fancy animation/polish
- Full observability dashboard (SolServer later)
- Long-running orchestration UI (async tracking later)

---

## Core mental model
### A Run
A Run is a single “job” with an intent: *summarize*, *schedule*, *draft*, *research*, *park open loop*, etc.

Runs consist of Steps.

### Lanes (execution surface)
- **Local Tools (SolM)**: OS truth (Calendar/Reminders/Journal/Notes)
- **Server Tools (SolServer)**: network fetch, secrets, governance checks, audit write-log
- **Model**: structured proposals + summaries (no raw chain-of-thought exposure)

---

## 4B Primitive (must be explicit in UI)
SolM Trace uses 4B as the operator contract surfaced to the user.

- **Bounds**: hard constraints (e.g., “public web only”, “no logins”, “max 12 pages”, “no writes without approval”)
- **Buffer**: pause behavior (“if ambiguous or risky, stop and ask”)
- **Breakpoints**: required stop points for writes / risky actions
- **Beat**: pacing / pass structure (“Plan → Evidence → Synthesis”)

> Hard rule: 4B must be visible in every non-trivial run.

---

## User stories
- **User trust:** “Show me what you’re doing without making me read logs.”
- **Write safety:** “Before you change anything in my life (events/reminders/messages), ask me.”
- **Builder debugging:** “Show me where the prompt or tool shape drifted.”
- **Prompt iteration:** “Give me telemetry I can tune against.”

---

## UI Components (v0)

### 1) Trace Drawer (collapsed by default)
Entry control:
- **Trace** pill/button + status dot: `idle | running | paused | complete | needs-review`

Expanded view shows:
- Run title (auto): “Create reminders”, “Summarize doc”, “Plan trip”
- Outcome badge: ✅ Complete / ⏸ Paused / ⚠ Needs review
- 4B Budget Strip
- Export actions (OS-first)

### 2) 4B Budget Strip (always visible when trace open)
Compact display:
- **Bounds:** list of constraints (short)
- **Buffer:** “Pause on ambiguity” ON/OFF (default ON)
- **Breakpoints:** `0 pending` / `1 pending` + tap for queue
- **Beat:** pass indicator with current step highlighted

### 3) Run Timeline (the heart)
Vertical list of Step cards. Each card has:
- Step type icon + label
- 1-line summary (human)
- Time + elapsed
- Expand affordance for details

Step types:
1. **Plan**
2. **Evidence**
3. **Tool Call**
4. **Breakpoint**
5. **Synthesis**

Expanded details (User View):
- Inputs: short summary
- Outputs: short summary
- “Show sources” (if applicable)

Expanded details (Dev View):
- Tool payloads (redacted)
- Normalized errors + codes
- Evidence anchors (which sources fed which claims)

### 4) Evidence Panel
Evidence list with:
- Title + domain
- Why it was used (one line)
- Citation anchors used in output
Actions:
- **Copy citations** (Markdown)
- **Open sources** (if allowed)

### 5) Breakpoint Modal (governance handshake)
Trigger on any write or risky move.

Modal shows:
- **Proposed action** (plain language)
- **What changes** (diff-style if possible)
- **Why** (one line)
- **Reversible?** yes/no + how
Actions:
- **Approve**
- **Edit**
- **Deny**
Secondary:
- “Show details” (Dev View only)

### 6) Export / Save (OS-first)
Primary actions:
- **Save to Notes** (single note: summary + timeline + citations)
- **Export Markdown**
- **Share**
Later options:
- Export PDF
- Create “Recheck:” reminder (Open Loops template)

---

## Speaker differentiation (style requirement)
We must avoid the “looks like user input” failure mode.

Four distinct visual roles (not just color):
- **User**
- **Operator**
- **Evidence**
- **System**

Primary differentiation tools:
- Left-rail role labels + icons
- Typography + spacing
- Subtle color accents (do not rely on strong blocks that mimic chat bubbles)

> A lightly faded blue accent can frame “Operator” callouts without confusing voice attribution.

---

## Telemetry (prompting + audit)
Trace must exist as structured events even if UI is minimized.

### Event types
- `run.started`
- `step.created`
- `tool.requested`
- `tool.completed`
- `breakpoint.raised`
- `breakpoint.resolved` (approve/deny/edit)
- `run.completed`
- `run.aborted`

### Required fields (minimum)
- IDs: `run_id`, `step_id`, `parent_step_id`
- Lane: `local | server | model`
- Step type: `plan | evidence | tool | breakpoint | synthesis`
- Timing: `start_ts`, `end_ts`, `elapsed_ms`
- Redaction: `none | masked | summary_only`
- Citations: `[ {title, url, snippet<=N} ]`
- Governance: `{ consequence_weight, confidence_level, required_breakpoint }`
- Outcome: `success | partial | fail` + `error_code`

### Privacy defaults
- Do **not** store raw page text by default.
- Do **not** store secrets or credentials ever.
- Prefer: summary + citation pointer + minimal snippet.

---

## Prompt injection & hostile-web posture (OWASP-aligned)
Prompt injection is “instruction smuggling” into content, caused by weak separation between “data” and “instructions.”

SolM posture (product-level mitigations):
- Prefer **structured tools** over freeform page interpretation.
- Default to **read-only web fetch** tools (server lane) with constrained parsing.
- Any web action beyond read-only fetch hits a **Breakpoint**.
- Keep “tool write” permissions minimal and explicit.

This is where governance becomes an action surface, not a policy paragraph.

---

## Governance hooks (Council alignment)
Governance is enforced by behavior:

- **Thurgood**: blocks writes without Breakpoint; ensures clear “what changes” diff.
- **Obama**: ensures user autonomy and comprehension; prevents authority laundering.
- **Cassandra**: when a Breakpoint is raised, enumerates 2–3 plausible downside paths (no fear theater).
- **Skeptic**: flags missing citations, weak sources, or shaky inference.
- **Decision Auditor**: records why a gated action was approved/denied.

---

## MVP: the first screen to ship
**Trace Drawer + Timeline + Breakpoint Modal + Export Markdown/Notes**

This yields:
- Manus-level visibility (trust)
- SolM-level safety (Breakpoints)
- Real telemetry for prompting (iteration)

---

## Microcopy: Breakpoint modal (starter)
Title: **Approval required**
Body:
- Proposed: “Create reminder ‘Pay rent’ for Jan 1 at 9:00 AM”
- Changes: “Adds 1 reminder in ‘Open Loops’”
- Why: “You asked me to capture next steps from this thread”
- Reversible: “Yes — delete reminder”
Buttons: **Approve** | **Edit** | **Deny**

---

## Open questions (parked)
- Should Trace be pinned per thread or per run?
- How do we represent async runs (server continues, client shows status)?
- How do we compress long timelines for human readability?
- What’s the default retention window for trace telemetry?

---

## Arc | Active | Parked | Decisions | Next
**Arc:** Bring operator trace visibility into SolM as UI + telemetry.
**Active:** Trace Drawer, Run Timeline, Evidence Panel, Breakpoint modal, Export, telemetry schema.
**Parked:** SolServer dashboard view; async orchestration UX; long-run compression; retention policy.
**Decisions:** Governance must be visible as Breakpoints; OS-first export is a primary feature; privacy defaults favor summaries/citations.
**Next:** Draft the Markdown export template + Notes layout, then mock one example run end-to-end.