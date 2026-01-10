## Driver Blocks (SolMobile v0)

### Purpose
Driver Blocks are user-owned micro-protocols that reduce cognitive carry and tighten assistant compliance without repeated user prompting. They compile into:
- prompt constraints (tightening)
- output contract requirements (required sections/fields)
- validators (must-have + must-not)
- action expectations (e.g., offload artifacts like Anchors/Checkpoints/OpenLoops)

Driver Blocks are policy inputs for SolServer’s Policy Engine. SolMobile’s job is to:
- store user Driver Blocks locally
- select which blocks are active for a given Thread
- include them in the chat Packet (refs + optional inline definitions)

### Types of Driver Blocks (v0 framing)
- **System defaults** (shipped baseline): referenced by `{id, version}`
- **User-created offline** (local-first): stored locally; may be carried inline per request
- **Runtime-created** (assistant proposes; user approves): stored locally once approved

> v0 does not require a server-side Driver Block registry. Custom blocks can be carried inline in the Packet.

---

## Decisions

### D7 — Driver Blocks are local-first and thread-activatable
- Driver Blocks live in a local `DriverBlockStore`.
- Threads may activate a small subset (0..N) of Driver Blocks.
- A global default set may be applied via Preferences.

### D8 — Packet carries Driver Block inputs
- For each remote chat request, SolMobile includes:
  - `driver_block_refs[]` for system defaults (id + version)
  - `driver_block_inline[]?` for user-approved blocks that must be carried inline in v0 (no server registry)
  - `driver_block_mode?` for audit clarity (`default | custom`)

### D9 — Driver Blocks do not require a new UI surface in v0
- v0 defaults to “system baseline blocks” with zero user configuration required.
- Optional v0.1: a minimal per-thread “Controls” sheet to enable/disable a small list.

---

## Domain Model Additions

### DriverBlock
User-owned policy artifact stored locally.
- `driverBlockId`
- `title`
- `version`
- `scope`: `system | user`
- `enabledByDefault` (bool)
- `createdAt`, `updatedAt`
- `definition` (opaque text blob; schema not enforced in v0)
- `tags[]?` (optional: decision, offload, rigor, tone, etc.)

> v0 treats `definition` as opaque. SolServer interprets compiled behavior; SolMobile just stores/selects/transmits.

### Preferences (additions)
- `activeDriverBlockRefs[]` (default enabled blocks by id/version)

### Thread (additions)
- `driverBlockMode`: `default | custom` (optional)
- `driverBlockOverrides[]?`:
  - `enableRefs[]?` (add to defaults)
  - `disableRefs[]?` (remove from defaults)
  - `inlineBlocks[]?` (custom blocks to include for this thread)

### Packet (chat additions)
- `driver_block_mode?`
- `driver_block_refs[]?`
- `driver_block_inline[]?`

---

## v0 Flow Updates

### Flow A — Typed message (with Driver Blocks)
1. user types
2. submit → `Message(user)` created immediately
3. Transmission(chat) created with Packet:
   - messageIds[]
   - budgets?
   - pinnedContextRef?
   - **driver_block_refs[]** from Preferences + Thread overrides
   - **driver_block_inline[]?** if thread uses local-only blocks
4. SolServer applies Driver Blocks in Policy Engine and returns assistant message (+ optional action hints)
5. SolMobile appends `Message(assistant)` locally

### Flow D — Remote chat request (SolServer) (updated)
1. create `Transmission(chat)` with `Packet` describing thread + message ids + checkpoint/facts refs (if any)
2. include `driver_block_refs[]` and optional `driver_block_inline[]`
3. attempts recorded in `DeliveryAttempt[]`
4. on success → append `Message(assistant)` with usage metadata
5. optional: interpret action hints (Anchor/Checkpoint suggestions) as UI prompts (v0.1)

---

## Implementation Components (additions)
- `DriverBlockStore` (local persistence)
- `DriverBlockSelector` (merge Preferences defaults + Thread overrides → Packet fields)
- (optional v0.1) `DriverBlockControlsSheet` (per-thread toggles)

---

## Notes (v0 stance)
- Start with a small system baseline (no UI configuration required).
- Defer schema formalization; treat Driver Block definitions as opaque blobs until v0 usage proves what needs structure.
Keep the interaction model simple: “defaults work; customization is optional.”

## Wire format vs local model
- **Wire format** fields in the Packet use **snake_case** (e.g., `driver_block_refs`) to match the API contract.
- SolMobile may use camelCase for local Swift types, but must map to the wire keys when constructing the Packet.

## v0 Bounds
- Max active **user** Driver Blocks per request: **3** (`driver_block_inline` items).
- Max size per inline block (recommended): **4 KB** of UTF-8 text.
- Application order: **system defaults** → **user saved (offline)** → **runtime proposed + approved**.

## Baseline System Driver Blocks (v0)

These are **system-default** Driver Blocks shipped as the baseline behavior. They require **no UI configuration** in v0; SolMobile simply includes their `{id, version}` refs by default in the chat Packet as `driver_block_refs[]`.

### DB-001 — NoAuthorityDrift (v0)
**Intent:** Prevent capability/authority laundering and maintain trust boundaries.  
**Triggers:** Always-on.  
**Contract effects:**
- Forbid claims of actions not actually performed (e.g., “I already sent/added/checked…”).
- If an external action is desired, output a proposed action artifact instead (e.g., “Here’s the reminder template,” “Here’s the message draft,” “Here’s what to click”).  
**Validators (examples):**
- Must-not: “I sent…”, “I added…”, “I checked your account…”, unless explicitly supported by the current tool boundary.

---

### DB-002 — ShapeFirst (Topology-First Output) (v0)
**Intent:** Preserve usability under load by leading with the “shape” before depth.  
**Triggers:** Any non-trivial response (multi-step, multi-domain, or > ~8 lines of content).  
**Contract effects:**
- Require a short 3–6 bullet “shape” before details.
- Keep prose tight; avoid wall-of-text.  
**Validators (examples):**
- Must-have: initial bullet “shape” section when response is complex.

---

### DB-003 — DecisionClosure (Receipt → Release) (v0)
**Intent:** Provide decision relief and stop re-litigation loops.  
**Triggers (examples):**
- user expresses scanning/rumination: “I can’t relax until…”, “I’m worried about…”, “I keep thinking…”
- user requests closure: “lock it”, “what’s decided?”, “wrap this up”  
**Contract effects:**
- Require an explicit **Receipt**: what is true/decided/confirmed.
- Require an explicit **Release**: permission to stop carrying/stop scanning until the next breakpoint.
- Require a **Next step** (single concrete action or check-in point).  
**Validators (examples):**
- Must-have: “Receipt:” + “Release:” (or equivalent semantics) + “Next:”.

---

### DB-004 — OffloadWhenRemembering (v0)
**Intent:** Convert “remembering burden” into an artifact so the user doesn’t carry it mentally.  
**Triggers (examples):**
- “remind me…”, “don’t let me forget…”, “I need to remember…”, “follow up later…”  
**Contract effects:**
- Require an **offload artifact** suggestion in the response:
  - Anchor suggestion (message bookmark + title)
  - OpenLoop template (Need → Then)
  - (future) OS Reminder suggestion once SolM bridge is active  
**Validators (examples):**
- Must-not: “just remember / don’t forget / keep in mind” unless paired with an offload artifact.

---

### DB-005 — MissingFactsStopAsk (v0)
**Intent:** Avoid confident answers built on missing critical inputs; keep deterministic-first.  
**Triggers:**
- High-rigor domains or when required parameters are missing to proceed safely.  
**Contract effects:**
- If required facts are missing, the assistant must:
  1) state what’s missing (briefly),
  2) make a best-effort default **only if low risk**, and
  3) provide the smallest question set to proceed.  
**Validators (examples):**
- Must-have: “Assumption:” labels when defaults are used.
- Must-have: explicit request for missing inputs when needed.

---

### Default enablement
SolMobile v0 should include these baseline Driver Blocks by default via `Preferences.activeDriverBlockRefs[]`:
- DB-001 NoAuthorityDrift
- DB-002 ShapeFirst
- DB-003 DecisionClosure (Receipt → Release)
- DB-004 OffloadWhenRemembering
- DB-005 MissingFactsStopAsk

> Notes:
> - These blocks are intentionally general and non-controversial.
> - More specialized blocks (tone ladders, intimacy ladders, domain-specific rituals) are deferred to v0.1+ and should be opt-in per thread.