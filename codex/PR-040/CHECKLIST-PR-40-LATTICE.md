# PR 40 Checklist: Lattice v0 + v0.1 + vector flagged

## 0) PR structure
- [x] Create bundle dir: infra-docs/codex/PR-040/ — receipts: codex/PR-040/README.md
- [x] Add: INPUT-PR-40-LATTICE.md, CHECKLIST-PR-40-LATTICE.md, FIXLOG-PR-40-LATTICE.md — receipts: codex/PR-040/INPUT-PR-40-LATTICE.md; codex/PR-040/CHECKLIST-PR-40-LATTICE.md; codex/PR-040/FIXLOG-PR-40-LATTICE.md
- [ ] Link these in the PR body

## 1) infra-docs changes
ADR and docs
- [x] Update ADR-030:
  - [x] Add always-on meta.lattice decision (IDs-only, content-minimized) — receipts: decisions/ADR-030-lattice-gate-v0.1-retrieval-policy-capsules-storage.md:D7a
  - [x] Add explicit note: critical constraints must not rely on Lattice retrieval (Driver Blocks / Mounted Law) — receipts: decisions/ADR-030-lattice-gate-v0.1-retrieval-policy-capsules-storage.md:D5
  - [x] Clarify lexical vs vector scoring semantics (separate thresholds, no shared min_score) — receipts: decisions/ADR-030-lattice-gate-v0.1-retrieval-policy-capsules-storage.md:D7
- [x] Update Lattice v0 doc (if needed) to include:
  - [x] Memory list + detail endpoints — receipts: architecture/solserver/message-processing-gates-v0.md#Lattice-v0-v0.1-notes
  - [x] meta.lattice always present — receipts: architecture/solserver/message-processing-gates-v0.md#Lattice-v0-v0.1-notes
  - [x] vector queries behind flag (default lex) — receipts: architecture/solserver/message-processing-gates-v0.md#Lattice-v0-v0.1-notes
- [x] Policy capsule bundle decision:
  - [x] Document policy capsule ID format (ex: ADR-030#D6) — receipts: decisions/ADR-030-lattice-gate-v0.1-retrieval-policy-capsules-storage.md:D2
  - [x] Document “policies are bundled offline in app” for UI use — receipts: decisions/ADR-030-lattice-gate-v0.1-retrieval-policy-capsules-storage.md:D2

## 2) solserver implementation
Memory API
- [x] POST /v1/memories supports span save — receipts: solserver/src/routes/memories.ts:43-588
  - [x] Accept anchor_message_id + window — receipts: solserver/src/routes/memories.ts:43-51
  - [x] Resolve span includes user + assistant messages — receipts: solserver/src/routes/memories.ts:503-539
  - [x] Persist evidence_message_ids — receipts: solserver/src/routes/memories.ts:553-573
  - [x] Distill summary + snippet (strict JSON) — receipts: solserver/src/routes/memories.ts:549-573
- [x] Add GET /v1/memories list — receipts: solserver/src/routes/memories.ts:591-691
  - [x] Supports lifecycle_state filter (default pinned) — receipts: solserver/src/routes/memories.ts:630-666
  - [x] Supports thread scope filter — receipts: solserver/src/routes/memories.ts:591-666
  - [x] Cursor pagination (or documented offset if simpler) — receipts: solserver/src/routes/memories.ts:606-691
- [x] Add GET /v1/memories/:id detail — receipts: solserver/src/routes/memories.ts:694-721
  - [x] Returns evidence_message_ids, lifecycle_state, timestamps — receipts: solserver/src/routes/memories.ts:704-721

Memory lifecycle
- [x] Add lifecycle_state column to memory artifacts with default pinned — receipts: solserver/src/store/sqlite_control_plane_store.ts:340-365,492-509
- [x] Default retrieval filters pinned only — receipts: solserver/src/control-plane/orchestrator.ts:1932-1937; solserver/src/routes/memories.ts:630-635
- [x] Allow archived only by explicit ID deref or explicit list filter — receipts: solserver/src/routes/memories.ts:630-666,694-721
- [x] Add memory classification fields used by client settings:
  - [x] memory_kind (preference | fact | workflow | relationship | constraint | project | other) OR canonical tags that encode this — receipts: solserver/src/routes/memories.ts:28-60,565-586
  - [x] is_safe_for_auto_accept (server-computed or derived from memory_kind) — receipts: solserver/src/routes/memories.ts:197-198,685-686
- [x] Implement memory edit semantics as new record creation:
  - [x] Editing a memory creates a new memory_id (new record) — receipts: solserver/src/routes/memories.ts:785-821
  - [x] Old record is archived, not deleted — receipts: solserver/src/routes/memories.ts:809-813
  - [x] New record stores supersedes_memory_id = <old_id> — receipts: solserver/src/routes/memories.ts:803-805
  - [x] Old record remains dereferenceable by ID forever (for citations) — receipts: solserver/src/routes/memories.ts:694-721
- [x] Ensure GET /v1/memories/:id returns archived records too (so meta.lattice citations never 404) — receipts: solserver/src/routes/memories.ts:694-721
- [x] Ensure memory list endpoint can filter:
  - [x] lifecycle_state (default pinned) — receipts: solserver/src/routes/memories.ts:630-666
  - [x] memory_kind or tags (for Vault filtering and auto-accept audits) — receipts: solserver/src/routes/memories.ts:598-666

Lattice gate and retrieval
- [x] Wire lattice after sentinel and before model call (as specified in ADR-030) — receipts: solserver/src/control-plane/orchestrator.ts:1768-1776,1874-1883
- [x] Implement hybrid triggering:
  - [x] Always attempt memory retrieval — receipts: solserver/src/control-plane/orchestrator.ts:1932-1937
  - [x] Governance/policy retrieval only on risk in {med, high} or intent/signal triggers — receipts: solserver/src/control-plane/orchestrator.ts:1991-2004; solserver/src/control-plane/orchestrator.ts:160-188
- [x] Inject into PromptPack retrieval section only (no Driver Blocks) — receipts: solserver/src/control-plane/prompt_pack.ts:16-116
- [x] Enforce caps:
  - [x] max_memories 6 — receipts: solserver/src/control-plane/orchestrator.ts:1916-1919,2040-2044
  - [x] max_adr_snips 4 — receipts: solserver/src/control-plane/orchestrator.ts:1916-1919,2036-2037
  - [x] max_policy_capsules 4 — receipts: solserver/src/control-plane/orchestrator.ts:1916-1919,2037-2038
  - [x] max_total_bytes 8KB — receipts: solserver/src/control-plane/orchestrator.ts:1916-1919,2062-2071

meta.lattice always present
- [x] Add OutputEnvelope.meta.lattice:
  - [x] status: hit|miss|fail — receipts: solserver/src/contracts/output_envelope.ts:110-125; solserver/src/control-plane/orchestrator.ts:2094-2112
  - [x] retrieval_trace: memory_ids, memento_ids, policy_capsule_ids — receipts: solserver/src/control-plane/orchestrator.ts:2098-2104
  - [x] counts, bytes_total — receipts: solserver/src/control-plane/orchestrator.ts:2105-2111
  - [x] timings_ms: lattice_total, lattice_db, model_total, request_total — receipts: solserver/src/contracts/output_envelope.ts:115-123; solserver/src/control-plane/orchestrator.ts:3782-3793
  - [x] warnings: codes only — receipts: solserver/src/contracts/output_envelope.ts:124-125; solserver/src/control-plane/orchestrator.ts:2111-2112
- [x] Ensure response always includes meta.lattice even when lattice disabled (status=miss or off) — receipts: solserver/src/control-plane/orchestrator.ts:1921-1937,2094-2112,3782-3793

Trace and latency logging
- [x] Add explicit timing for:
  - [x] lattice_db_ms — receipts: solserver/src/control-plane/orchestrator.ts:1930-1939,1968-1969,3782-3786
  - [x] lattice_total_ms — receipts: solserver/src/control-plane/orchestrator.ts:2081-2082,3782-3784
  - [x] model_total_ms — receipts: solserver/src/control-plane/orchestrator.ts:3782-3786
  - [x] request_total_ms — receipts: solserver/src/control-plane/orchestrator.ts:3782-3787
- [x] Add trace event phase gate_lattice with counts and bytes and safe query terms only — receipts: solserver/src/control-plane/orchestrator.ts:2114-2127

sqlite-vec packaging + vector query lane (Option 2)
- [x] Docker build: include vec0.so in /app/extensions — receipts: solserver/Dockerfile:19-41
- [x] Add CI smoke test that loads vec0.so in the built image — receipts: solserver/.github/workflows/ci-solserver.yml:88-99
- [x] Runtime: loadExtension behind LATTICE_VEC_ENABLED=1 — receipts: solserver/src/store/sqlite_control_plane_store.ts:515-529
- [x] Vector queries behind LATTICE_VEC_QUERY_ENABLED=1 — receipts: solserver/src/control-plane/orchestrator.ts:1952-1988
- [x] Default retrieval remains lexical — receipts: solserver/src/control-plane/orchestrator.ts:1930-1946
- [x] Fail-open if vec load fails:
  - [x] disable vector search — receipts: solserver/src/store/sqlite_control_plane_store.ts:515-529
  - [x] emit warning code — receipts: solserver/src/control-plane/orchestrator.ts:1978-1982
  - [x] continue lexical retrieval — receipts: solserver/src/control-plane/orchestrator.ts:1930-1946,1970-1977
- [x] Store vector scores in meta.lattice with method=vec_distance — receipts: solserver/src/control-plane/orchestrator.ts:2098-2120; solserver/src/contracts/output_envelope.ts:105-129

Scoring
- [x] Lexical scoring:
  - [x] sort by bm25/rank — receipts: solserver/src/store/sqlite_control_plane_store.ts:1915-1931
  - [x] strict caps, conservative gating — receipts: solserver/src/control-plane/orchestrator.ts:1916-1919,2040-2071
- [x] Vector scoring:
  - [x] sort by distance — receipts: solserver/src/store/sqlite_control_plane_store.ts:1956-1980
  - [x] optional max_distance threshold — receipts: solserver/src/store/sqlite_control_plane_store.ts:1968-1977
- [x] No shared min_score across lexical/vector — receipts: solserver/src/control-plane/orchestrator.ts:1930-1988



## 3) solmobile implementation
Caching + citation
- [x] Cache memories locally by memory_id — receipts: solmobile/ios/SolMobile/SolMobile/Models/MemoryArtifact.swift:MemoryArtifact; solmobile/ios/SolMobile/SolMobile/Actions/TransmissionAction.swift:upsertMemoryArtifact
- [x] When meta.lattice contains memory_ids:
  - [x] deref missing ids via GET /v1/memories/:id — receipts: solmobile/ios/SolMobile/SolMobile/Actions/TransmissionAction.swift:prefetchLatticeMemoriesIfNeeded
  - [x] store in cache for inspector / vault — receipts: solmobile/ios/SolMobile/SolMobile/Actions/TransmissionAction.swift:upsertMemoryArtifact
- [x] Add Memory Vault list view backed by GET /v1/memories — receipts: solmobile/ios/SolMobile/SolMobile/Views/Memory/MemoryVaultView.swift:refreshMemories; solmobile/ios/SolMobile/SolMobile/Connectivity/SolServerClient.swift:listMemories
- [x] Vault UI is User Memory only:
  - [x] Memory list view calls GET /v1/memories (default pinned) — receipts: solmobile/ios/SolMobile/SolMobile/Views/Memory/MemoryVaultView.swift:refreshMemories; solmobile/ios/SolMobile/SolMobile/Views/Memory/MemoryVaultView.swift:pinnedMemories
  - [x] Memory detail view calls GET /v1/memories/:id — receipts: solmobile/ios/SolMobile/SolMobile/Views/Memory/MemoryDetailView.swift:fetchMemoryDetailIfNeeded
- [x] Citation deep-link:
  - [x] When meta.lattice includes memory_ids, the inspector can open a cited memory detail view — receipts: solmobile/ios/SolMobile/SolMobile/Views/Chat/ThreadDetailView.swift:MemoryCitationsSheet; solmobile/ios/SolMobile/SolMobile/Views/Chat/ThreadDetailView.swift:MemoryCitationDetailSheet
  - [x] If not cached, deref via GET /v1/memories/:id, then cache — receipts: solmobile/ios/SolMobile/SolMobile/Views/Chat/ThreadDetailView.swift:MemoryCitationDetailSheet.fetchMemoryIfNeeded

Ghost cards accept UX
- [x] Add 👍 Accept action to memory offer ghost cards — receipts: solmobile/ios/SolMobile/SolMobile/Views/Chat/GhostCardComponent.swift:actionRow
- [x] Add setting: auto_accept_memory_offers (off | safe_only | always) — receipts: solmobile/ios/SolMobile/SolMobile/Services/MemoryOfferSettings.swift:AutoAcceptMode; solmobile/ios/SolMobile/SolMobile/Views/SettingsView.swift:Memory offers
  - [x] default safe_only or off (Jam preference) — receipts: solmobile/ios/SolMobile/SolMobile/Services/MemoryOfferSettings.swift:autoAcceptMode; solmobile/ios/SolMobile/SolMobile/Views/SettingsView.swift:autoAcceptMemoryOffers
  - [x] safe_only applies only to non-constraint memory kinds — receipts: solmobile/ios/SolMobile/SolMobile/Views/Chat/GhostCardComponent.swift:autoAcceptIfNeeded
- [x] Required: dev + staging badge ⚠ LATTICE_OFFLINE when meta.lattice.status=fail — receipts: solmobile/ios/SolMobile/SolMobile/Views/Chat/ThreadDetailView.swift:shouldShowLatticeOfflineBadge; solmobile/ios/SolMobile/SolMobile/Info-Debug.plist:LATTICE_DEV_BADGE; solmobile/ios/SolMobile/SolMobile/Info-Release.plist:LATTICE_DEV_BADGE
- [x] Ghost Card 👍 accept (one tap):
  - [x] Accept action supports memory offers (and driver_block offers if present) — receipts: solmobile/ios/SolMobile/SolMobile/Views/Chat/ThreadDetailView.swift:acceptMemoryOffer; solmobile/ios/SolMobile/SolMobile/Views/Chat/GhostCardComponent.swift:actionRow
  - [x] After accept, show an in-app receipt (toast or notification) with:
    - [x] View (deep-links to memory detail) — receipts: solmobile/ios/SolMobile/SolMobile/Views/Chat/ThreadDetailView.swift:memoryReceiptCard; solmobile/ios/SolMobile/SolMobile/Views/Chat/ThreadDetailView.swift:MemoryDetailRoute
    - [x] Undo (reverts acceptance, archives or unpins the created record) — receipts: solmobile/ios/SolMobile/SolMobile/Views/Chat/ThreadDetailView.swift:undoMemoryAccept
- [x] Auto-accept settings behavior:
  - [x] auto_accept_memory_offers supports: off | safe_only | always — receipts: solmobile/ios/SolMobile/SolMobile/Services/MemoryOfferSettings.swift:AutoAcceptMode
  - [x] safe_only uses memory_kind/is_safe_for_auto_accept — receipts: solmobile/ios/SolMobile/SolMobile/Views/Chat/GhostCardComponent.swift:autoAcceptIfNeeded; solmobile/ios/SolMobile/SolMobile/Models/MemoryArtifact.swift:isSafeForAutoAccept
  - [x] If auto-accept includes driver_block offers, still emit the receipt notification with View + Undo — receipts: solmobile/ios/SolMobile/SolMobile/Views/Chat/GhostCardComponent.swift:autoAcceptIfNeeded; solmobile/ios/SolMobile/SolMobile/Views/Chat/ThreadDetailView.swift:presentMemoryReceipt

## 4) tests
SolServer
- [x] Unit: span resolution includes both roles and evidence_message_ids length > 1 — receipts: solserver/test/memory_routes.test.ts:it("saves a memory span and includes evidence_message_ids")
- [x] Unit: memory lifecycle filters pinned by default — receipts: solserver/test/memory_routes.test.ts:it("filters memory list by lifecycle_state and returns archived by id"); solserver/test/lattice_retrieval.test.ts:it("retrieves pinned memories only")
- [x] Unit: meta.lattice always present and schema-valid — receipts: solserver/test/output_envelope.test.ts:it("returns outputEnvelope on success and matches assistant")
- [x] Unit: caps enforced (8KB total) — receipts: solserver/test/lattice_retrieval.test.ts:it("always includes meta.lattice and respects byte caps")
- [x] Unit: governance retrieval triggered only under rules — receipts: solserver/test/lattice_retrieval.test.ts:it("retrieves policy capsules only when triggered")
- [x] Unit: vec load fail-open does not break chat — receipts: solserver/test/lattice_retrieval.test.ts:it("fails open when vec extension cannot load")
- [x] Integration: POST save then next chat retrieves injected memory — receipts: solserver/test/lattice_retrieval.test.ts:it("retrieves memories saved via the API on the next chat turn")
- [x] Integration test: edit memory creates new record; old record is archived but still GET-able by ID — receipts: solserver/test/memory_routes.test.ts:it("patch creates new memory id and archives old record")

SolMobile
- [x] Manual: save memory from message, appears in vault — receipts: solmobile/ios/SolMobile/SolMobileUITests/SolMobileUITests.swift:testMemoryVaultAndCitationsLocal
- [x] Manual: meta.lattice ids trigger deref and cache — receipts: solmobile/ios/SolMobile/SolMobileUITests/SolMobileUITests.swift:testMemoryVaultAndCitationsLocal
- [x] Manual: ghost card accept is 1 tap — receipts: solmobile/ios/SolMobile/SolMobileUITests/SolMobileUITests.swift:testGhostCardAcceptShowsReceipt
- [x] Manual test: receipt notification deep-links to memory detail and Undo works — receipts: solmobile/ios/SolMobile/SolMobileUITests/SolMobileUITests.swift:testGhostCardAcceptShowsReceipt

## 5) release and ops
- [x] Document env flags in README or config doc — receipts: solserver/docs/dev.md:33-49
- [x] Confirm Fly /data volume usage for SQLite paths — receipts: solserver/docs/dev.md:23-31
- [x] Confirm busy_timeout is bounded (no hidden latency) — receipts: solserver/src/store/sqlite_control_plane_store.ts:139-146; solserver/docs/dev.md:33-45
