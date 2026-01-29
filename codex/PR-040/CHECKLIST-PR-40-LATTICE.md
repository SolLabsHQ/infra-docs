# PR 40 Checklist: Lattice v0 + v0.1 + vector flagged

## 0) PR structure
- [ ] Create bundle dir: infra-docs/codex/PR-040/
- [ ] Add: INPUT-PR-40-LATTICE.md, CHECKLIST-PR-40-LATTICE.md, FIXLOG-PR-40-LATTICE.md
- [ ] Link these in the PR body

## 1) infra-docs changes
ADR and docs
- [ ] Update ADR-030:
  - [ ] Add always-on meta.lattice decision (IDs-only, content-minimized)
  - [ ] Add explicit note: critical constraints must not rely on Lattice retrieval (Driver Blocks / Mounted Law)
  - [ ] Clarify lexical vs vector scoring semantics (separate thresholds, no shared min_score)
- [ ] Update Lattice v0 doc (if needed) to include:
  - [ ] Memory list + detail endpoints
  - [ ] meta.lattice always present
  - [ ] vector queries behind flag (default lex)
- [ ] Policy capsule bundle decision:
  - [ ] Document policy capsule ID format (ex: ADR-030#D6)
  - [ ] Document “policies are bundled offline in app” for UI use

## 2) solserver implementation
Memory API
- [ ] POST /v1/memories supports span save:
  - [ ] Accept anchor_message_id + window
  - [ ] Resolve span includes user + assistant messages
  - [ ] Persist evidence_message_ids
  - [ ] Distill summary + snippet (strict JSON)
- [ ] Add GET /v1/memories list:
  - [ ] Supports lifecycle_state filter (default pinned)
  - [ ] Supports thread scope filter
  - [ ] Cursor pagination (or documented offset if simpler)
- [ ] Add GET /v1/memories/:id detail:
  - [ ] Returns evidence_message_ids, lifecycle_state, timestamps

Memory lifecycle
- [ ] Add lifecycle_state column to memory artifacts with default pinned
- [ ] Default retrieval filters pinned only
- [ ] Allow archived only by explicit ID deref or explicit list filter

Lattice gate and retrieval
- [ ] Wire lattice after sentinel and before model call (as specified in ADR-030)
- [ ] Implement hybrid triggering:
  - [ ] Always attempt memory retrieval
  - [ ] Governance/policy retrieval only on risk in {med, high} or intent/signal triggers
- [ ] Inject into PromptPack retrieval section only (no Driver Blocks)
- [ ] Enforce caps:
  - [ ] max_memories 6
  - [ ] max_adr_snips 4
  - [ ] max_policy_capsules 4
  - [ ] max_total_bytes 8KB

meta.lattice always present
- [ ] Add OutputEnvelope.meta.lattice:
  - [ ] status: hit|miss|fail
  - [ ] retrieval_trace: memory_ids, memento_ids, policy_capsule_ids
  - [ ] counts, bytes_total
  - [ ] timings_ms: lattice_total, lattice_db, model_total, request_total
  - [ ] warnings: codes only
- [ ] Ensure response always includes meta.lattice even when lattice disabled (status=miss or off)

Trace and latency logging
- [ ] Add explicit timing for:
  - [ ] lattice_db_ms
  - [ ] lattice_total_ms
  - [ ] model_total_ms
  - [ ] request_total_ms
- [ ] Add trace event phase gate_lattice with counts and bytes and safe query terms only

sqlite-vec packaging + vector query lane (Option 2)
- [ ] Docker build: include vec0.so in /app/extensions
- [ ] Add CI smoke test that loads vec0.so in the built image
- [ ] Runtime: loadExtension behind LATTICE_VEC_ENABLED=1
- [ ] Vector queries behind LATTICE_VEC_QUERY_ENABLED=1
- [ ] Default retrieval remains lexical
- [ ] Fail-open if vec load fails:
  - [ ] disable vector search
  - [ ] emit warning code
  - [ ] continue lexical retrieval
- [ ] Store vector scores in meta.lattice with method=vec_distance

Scoring
- [ ] Lexical scoring:
  - [ ] sort by bm25/rank
  - [ ] strict caps, conservative gating
- [ ] Vector scoring:
  - [ ] sort by distance
  - [ ] optional max_distance threshold
- [ ] No shared min_score across lexical/vector

## 3) solmobile implementation
Caching + citation
- [ ] Cache memories locally by memory_id
- [ ] When meta.lattice contains memory_ids:
  - [ ] deref missing ids via GET /v1/memories/:id
  - [ ] store in cache for inspector / vault
- [ ] Add Memory Vault list view backed by GET /v1/memories

Ghost cards accept UX
- [ ] Add 👍 Accept action to memory offer ghost cards
- [ ] Add setting: auto_accept_memory_offers (off | safe_only | always)
  - [ ] default safe_only or off (Jam preference)
  - [ ] safe_only applies only to non-constraint memory kinds
- [ ] Optional: dev + staging badge ⚠ LATTICE_OFFLINE when meta.lattice.status=fail

## 4) tests
SolServer
- [ ] Unit: span resolution includes both roles and evidence_message_ids length > 1
- [ ] Unit: memory lifecycle filters pinned by default
- [ ] Unit: meta.lattice always present and schema-valid
- [ ] Unit: caps enforced (8KB total)
- [ ] Unit: governance retrieval triggered only under rules
- [ ] Unit: vec load fail-open does not break chat
- [ ] Integration: POST save then next chat retrieves injected memory

SolMobile
- [ ] Manual: save memory from message, appears in vault
- [ ] Manual: meta.lattice ids trigger deref and cache
- [ ] Manual: ghost card accept is 1 tap

## 5) release and ops
- [ ] Document env flags in README or config doc
- [ ] Confirm Fly /data volume usage for SQLite paths
- [ ] Confirm busy_timeout is bounded (no hidden latency)
