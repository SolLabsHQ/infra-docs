# ADR-030: Lattice Gate v0.1 - Retrieval Enrichment (Memory + Governance) + PolicyCapsules + Storage

- Status: Proposed
- Date: 2026-01-24
- Owners: SolServer
- Domains: retrieval, memory, governance, safety, budgets, trace, ops

## Context
SolServer implements a deterministic gates pipeline with strict output validation and post-output enforcement. The pre-model pipeline includes a `gate_lattice` slot that is currently a stub.

We want Lattice v0.1 for two reasons:
1) Continuity: restore relevant user memory and thread mementos so the model does not regress on prior decisions, preferences, and constraints.
2) Governance reload: inject relevant excerpts of ADRs and governance rules to reduce drift and prevent repeated re-litigation.

Lattice is enrichment only. It supplies context for PromptPack.
Enforcement remains with output gates and post-output linter. Sentinel classifies risk and urgency.

## Decision

### D1) PolicyCapsule is an architecture entity (v0.1)
A PolicyCapsule is a bounded excerpt used for prompt enrichment.

- Policy capsules are derived from ADRs and governance docs.
- Policy capsules are not ADRs.
- Policy capsules are small by design so they can be injected without bloating prompts.

PolicyCapsule schema (minimum):
- id (stable, example: ADR-025#D2)
- title
- snippet (bounded)
- tags[]
- max_bytes
- source_path
- source_anchor (optional)

### D2) PolicyCapsule derivation and storage (v0.1)
- Default: build-time compilation from ADRs and governance docs into a capsule bundle (JSON or SQLite table).
- Capsules are excerpt-sized and intentionally short.
- Capsules preserve traceability via source_path and id.
- Policy capsule IDs use stable ADR anchors (example: ADR-030#D6).
- Policy capsules are bundled offline in the app; the server emits capsule IDs only.

### D3) Lattice v0.1 retrieval sources (planned v0.1; stub today)
Lattice v0.1 pulls from two sources (C = both):

1) Memory index:
- user memory
- thread mementos

2) Governance index:
- ADR snippets
- governance docs
- policy capsules

### D4) Triggering behavior (planned v0.1; stub today)
Lattice runs after sentinel and before model call. Triggering is hybrid:

- Always attempt memory retrieval (cheap, user-specific).
- Attempt governance and policy retrieval only when:
  - sentinel risk is `med` or `high`, OR
  - intent or signals indicate governance, constraints, journaling, safety, or “we decided this before”.
- Feature gate: Lattice runs only when `LATTICE_ENABLED=1` (default `0` until enabled).

### D5) PromptPack injection placement (planned v0.1; stub today)
PromptPack already has a retrieval section.

In v0.1:
- Lattice output is injected into the existing retrieval section.
- Governance snippets appear as a labeled subsection inside retrieval in v0 (no new PromptSectionId).
- Lattice output must not be inserted as Driver Blocks to avoid enforcement confusion.
- Critical constraints must not rely on Lattice retrieval; enforce via Driver Blocks / Mounted Law.

### D6) Lattice v0.1 limits and fail-open posture (planned v0.1; stub today)
Default caps:
- max_memories: 6
- max_adr_snips: 4
- max_policy_capsules: 4
- max_total_bytes: 8KB (combined injected snippets)

Fail-open:
- If retrieval fails or indexes are unavailable, Lattice returns an empty enrichment bundle plus warnings.
- The chat request proceeds with normal PromptPack assembly.
- No request is blocked by Lattice failures.
- Warning surface (v0): trace-only; optional debug meta flag can surface warnings in the future.

### D7) Observability (content-minimized, planned v0.1; stub today)
Trace phase naming:
- Lattice uses trace phase `gate_lattice`.
- Lattice trace metadata lives under the lattice gate result metadata (not as raw content).

Emit a Lattice trace event with:
- memory_hits, adr_hits, policy_hits
- bytes_total
- query_terms (safe terms only, no content)
- lexical and vector scoring are tracked separately (no shared min_score)

No raw content is logged.

### D7a) meta.lattice (planned v0.1; stub today)
- `OutputEnvelope.meta.lattice` is always present in production responses (even when lattice is disabled).
- Content-minimized: IDs only (memory_ids, memento_ids, policy_capsule_ids), counts, bytes_total, timings_ms, warning codes.

### D8) Storage decision for v0.1 on Fly (default + fallback + upgrade, planned v0.1)
#### v0.1 default (Fly)
- Single region deployment.
- SQLite DB file stored on Fly volume under `/data`.
- Lattice indexes are stored in the same SQLite database file as the control plane DB by default (unless explicitly separated later).
- Vector search enabled via sqlite-vec loadable extension (vec0.so) loaded by better-sqlite3.

#### v0.1 fallback (if sqlite-vec is unavailable)
- Plain SQLite lexical-only mode (FTS/BM25 or tag filtering) with the same Lattice contract.
- Governance retrieval still works via policy capsule bundle plus lexical or tag matching.

#### Upgrade breakpoint (switch to Turso/libSQL)
Switch to Turso/libSQL (optionally with embedded replicas on Fly) when any of these are true:
- multi-instance SolServer writes against the same logical DB
- multi-region retrieval read locality is required
- write contention or availability requirements exceed the single-writer posture
- operational burden of SQLite replication is no longer acceptable

LiteFS is not the v0.1 default because it increases operational complexity and introduces additional failure modes.

### D9) sqlite-vec enablement plan (better-sqlite3 + Fly image, planned v0.1)
SolServer uses better-sqlite3. sqlite-vec requires:
- shipping a loadable extension artifact (vec0.so) in the runtime image
- explicitly calling `db.loadExtension("/app/extensions/vec0.so")` after opening the DB
- gating the load behind an env flag (example: `LATTICE_VEC_ENABLED=1`, default `0`)

Note:
- better-sqlite3 enables loadable extensions at DB open, but we still treat sqlite-vec load as an explicit, gated step.
- Do not expose SQL-level load_extension to user-controlled inputs.
- If extension loading fails, disable vector search and emit a warning (fail-open).

CI and Fly runtime verification:
- add a smoke check in Docker build or CI that loads vec0.so and exits non-zero on failure
- validate inside the Docker image to avoid local host arch mismatch

Example smoke check:
- node -e "const Database=require('better-sqlite3'); const db=new Database(':memory:'); db.loadExtension('/app/extensions/vec0.so'); console.log('sqlite-vec load ok');"

Pinned binary sourcing (v0.1):
- Use a pinned sqlite-vec release artifact that matches the runtime architecture.
- Fly is commonly linux-x86_64, but the base image can be multi-arch. Make the artifact selection configurable via build arg or use per-arch selection logic.

### D10) Fly topology constraint for SQLite paths (planned v0.1)
If Lattice uses its own SQLite file (separate from control plane DB), it must:
- live under `/data` on Fly
- be covered by the same topology guard posture as the control plane DB

## 4B
### Bounds
- Lattice is enrichment only. No blocking and no rewriting.
- Injected text is bounded (8KB total by default).
- No raw content emitted into trace.
- Extension loading is gated and loads only a pinned local artifact.

### Buffer
- Memory retrieval is default and cheap.
- Governance retrieval is gated by sentinel and intent.
- Fail-open behavior prevents retrieval outages from breaking chat.

### Breakpoints
- sentinel risk `med` or `high` triggers governance retrieval.
- retrieval failures return warnings and an empty bundle (fail-open).
- upgrade breakpoint triggers move to Turso/libSQL.

### Beat
- v0.1: dual-source retrieval + policy capsules + trace metrics, SQLite single-region default.
- v0.2: tuning and scoring improvements, optional multi-region storage, still no enforcement in Lattice.

## Acceptance Criteria
- Lattice runs after sentinel and before model call.
- Memory hits are injected into PromptPack retrieval context when available.
- Governance and policy capsules are injected only under trigger rules.
- Total injected bytes are capped and enforced.
- Lattice failures do not fail the chat request.
- Trace includes counts and bytes and query terms with no content.
- sqlite-vec can be enabled by env flag, passes CI smoke check, and loads successfully in Fly runtime.

## Consequences
### Benefits
- Reduces repeated drift and re-litigation.
- Improves continuity for journaling and decision flows.
- Makes governance reload explicit and inspectable.
- Clear v0.1 storage posture with a clean upgrade breakpoint.

### Costs / Risks
- sqlite-vec requires explicit build and loader wiring and runtime validation.
- SQLite single-writer posture limits multi-instance scaling.
- Governance retrieval must remain bounded to avoid prompt bloat.
- Must keep trace content-minimized.
