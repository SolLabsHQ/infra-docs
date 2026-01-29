# PR 40: LATTICE (v0 + v0.1) Memory Vault + Lattice Gate + Vector (flagged)

Owner
- Jam (final approval)
- Codex (implementation)

Scope
This PR implements:
A) LATTICE-01 (v0): explicit Save-to-Memory span save, persistence, and lexical retrieval injection
B) Lattice Gate v0.1: bounded enrichment retrieval (memory always; governance/policy gated by sentinel risk and intent)
C) sqlite-vec packaging + vector queries behind a flag (default is lexical)
D) Always-on meta.lattice in OutputEnvelope meta (IDs, counts, timings, warnings only)
E) Memory list and detail endpoints for UI citation and caching
F) Policy capsules remain offline and bundled, no server fetch endpoint required
G) Trace logging: explicit DB-read timing and model timing so we can compare, no guessing

Non-goals
- No RRF fusion (lex + vec rank fusion) in this PR
- No multi-hop traversal or typed-edge graph traversal (v1)
- No UI rendering of policy text from server
- No enforcement in Lattice gate (still enrichment-only)
- No “critical constraints” enforcement via Lattice (belongs to Driver Blocks / Mounted Law)

Decisions locked
1) Retrieval mode
- Default: lexical (FTS5 / BM25)
- Vector queries: behind flag
- No RRF

2) meta.lattice
- Always present in production response meta
- Content-minimized: IDs + counts + bytes + timings + warning codes
- UI can dereference memory content via Memory API endpoints

3) Policies
- Policy capsule content is bundled offline (in app and server build artifact as needed)
- meta.lattice references capsules by stable IDs only (ex: ADR-030#D6)
- UI uses local bundle to display policy details (no network call)

4) Memory lifecycle
- Implement lifecycle_state on memory artifacts with default pinned
- Default retrieval pulls pinned only
- Archived returned only via explicit ID dereference (GET by id) or explicit list filter

Repos in play
- infra-docs
  - Update ADR-030 with the new meta.lattice and critical constraints notes (minimal edit)
  - Add/refresh Lattice v0 and PR-40 artifacts bundle docs if needed
  - Add policy capsule bundle source artifacts if infra-docs is the canonical generator

- solserver
  - Implement memory endpoints (POST span save, GET list, GET detail)
  - Implement retrieval provider: lexical always; governance gated; vector query behind flag
  - Package sqlite-vec (vec0.so) in Docker build and load it behind env flag
  - Emit meta.lattice always
  - Emit explicit timings: lattice_db_ms, lattice_total_ms, model_total_ms, request_total_ms
  - Add tests: caps, fail-open, lifecycle filters, meta.lattice shape, vec flag behavior

- solmobile
  - Cache memory IDs and dereference via GET /v1/memories/:id for citation UI
  - Add Ghost Card thumbs-up accept action for memory offers (safe-only default)
  - Add setting: auto_accept_memory_offers (off | safe_only | always)
  - Optional: dev-only debug HUD badge when lattice status=fail/offline

API changes (SolServer)
1) POST /v1/memories
- Accept: thread_id, anchor_message_id, optional window {before, after}
- Server resolves span (user + assistant messages), stores evidence_message_ids
- Distills summary + snippet
- Persists memory row + FTS index + optional embedding row (if configured)
- Returns {memory_id, snippet, summary, evidence_message_ids, lifecycle_state}

2) GET /v1/memories
- Query: scope=user|thread, thread_id, lifecycle_state (default pinned), limit, cursor
- Returns list of memory summaries suitable for Vault UI

3) GET /v1/memories/:memory_id
- Returns memory detail (snippet, summary, evidence_message_ids, lifecycle_state, tags, timestamps)

Lattice retrieval behavior (SolServer)
- Always attempt memory retrieval (cheap)
- Attempt governance/policy retrieval only when:
  - sentinel risk in {med, high}, OR
  - intent/signals indicate governance, constraints, safety, journaling, “we decided this before”
- Caps:
  - max_memories: 6
  - max_adr_snips: 4
  - max_policy_capsules: 4
  - max_total_bytes: 8KB combined injection
- Fail-open:
  - retrieval failure or index unavailable yields empty bundles + warnings
  - chat proceeds normally

Scoring semantics
Lexical (FTS5 / BM25):
- rank order by bm25 or rank column
- gating: prefer relative gating (best + margin) or top-K only with strict caps
- store score in meta.lattice.scores with method=fts5_bm25 and value

Vector (sqlite-vec):
- query by distance (lower is better), return top-K
- gating: use max_distance or min_similarity (explicit config)
- store score in meta.lattice.scores with method=vec_distance and value

Do not share a single min_score across lexical and vector.

Flags and config
Required:
- LATTICE_ENABLED=1 (default 0 until enabled)
- LATTICE_VEC_ENABLED=0|1 (default 0)
- LATTICE_VEC_QUERY_ENABLED=0|1 (default 0)  # option 2: vector queries behind flag
- LATTICE_POLICY_BUNDLE_PATH=/app/policy/policy_capsules.json (or similar)

Optional:
- LATTICE_DEV_BADGE=1 (client debug HUD)
- LATTICE_BUSY_TIMEOUT_MS=200 (tight, fail-open fast)

Deliverables
- Working Save-to-Memory span flow + retrieval injection
- Always-on meta.lattice in responses
- Memory list + detail endpoints
- sqlite-vec packaged and loadable in runtime image
- Vector query path behind flag with fail-open fallback
- Trace and metrics: lattice db read time + model time (direct comparisons)

Acceptance Criteria
- Save-to-Memory stores evidence_message_ids length > 1 (span, not single line)
- Next chat turn retrieves and injects memory summaries in PromptPack retrieval section
- Governance/policy injection happens only under trigger rules
- Total injected bytes capped at 8KB
- Lattice failures do not fail chat
- sqlite-vec loads in CI smoke test when enabled, and chat still works when disabled
- meta.lattice always present with retrieval IDs and timings
- Memory GET list and GET detail work and match IDs emitted in meta.lattice
