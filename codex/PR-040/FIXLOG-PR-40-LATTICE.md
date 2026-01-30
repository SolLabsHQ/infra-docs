# PR 40 Fixlog: Lattice v0 + v0.1 + vector flagged

## Summary
- Implemented SolServer memory span save + list/detail endpoints, lattice retrieval with caps + policy trigger rules, meta.lattice always-on, sqlite-vec packaging + CI smoke test, and env flag docs. Added SolMobile memory cache/vault + citations, ghost card accept + auto-accept settings, and lattice meta ingestion. Removed user-derived query terms from trace, shipped policy bundle into image + Fly env, enforced memento-aware lattice status, and reran local + staging lattice smoke (score telemetry verified).

## infra-docs changes
- [x] ADR-030 updated (decisions/ADR-030-lattice-gate-v0.1-retrieval-policy-capsules-storage.md):
  - [x] meta.lattice always present
  - [x] critical constraints not dependent on lattice retrieval
  - [x] scoring semantics separated for lexical vs vector
  - [x] policy capsule IDs + offline bundle note
- [x] Lattice v0 doc updated (architecture/solserver/message-processing-gates-v0.md)
- [x] Smoke runbook updated to require canonical /v1/chat anchors, memory save required fields, and transmission id from header/body (codex/PR-040/SMOKE-PR-40-LATTICE.md)

## solserver changes
Memory API
- [x] POST /v1/memories span save (anchor span resolution, evidence_message_ids, summary/snippet) — solserver/src/routes/memories.ts
- [x] GET /v1/memories list (lifecycle_state default pinned, thread scope, cursor) — solserver/src/routes/memories.ts
- [x] GET /v1/memories/:id detail (includes archived + evidence ids) — solserver/src/routes/memories.ts
- [x] memory lifecycle_state + memory_kind + supersedes_memory_id + evidence_message_ids_json columns and filters — solserver/src/store/sqlite_control_plane_store.ts; solserver/src/store/control_plane_store.ts
- [x] adaptive span selection + LLM distill with fallback + distill_model/distill_attempts stored — solserver/src/routes/memories.ts; solserver/src/memory/memory_distiller.ts; solserver/src/store/sqlite_control_plane_store.ts
- [x] distill output typing narrowed for build (DistillCheck union) — solserver/src/memory/memory_distiller.ts

Lattice gate
- [x] hybrid trigger rules (memory always, policy on risk/intent/keywords) — solserver/src/control-plane/orchestrator.ts
- [x] caps enforcement (memories 6, ADR 4, policy 4, 8KB total) — solserver/src/control-plane/orchestrator.ts
- [x] strict byte-cap ordering (stop on first cap hit) — solserver/src/control-plane/orchestrator.ts
- [x] injection into PromptPack retrieval section only with Governance subsection — solserver/src/control-plane/prompt_pack.ts
- [x] retrieval packing prioritizes memory before policy/ADR under byte cap — solserver/src/control-plane/orchestrator.ts

meta.lattice + trace
- [x] meta.lattice always present (IDs + counts + timings + warnings) — solserver/src/control-plane/orchestrator.ts; solserver/src/contracts/output_envelope.ts
- [x] gate_lattice trace event emitted — solserver/src/control-plane/orchestrator.ts
- [x] query terms removed from trace; emit count only — solserver/src/control-plane/orchestrator.ts
- [x] explicit timings added (db, lattice total, model total, request total) — solserver/src/control-plane/orchestrator.ts

sqlite-vec
- [x] vec0.so packaged in image (Docker build step) — solserver/Dockerfile
- [x] loadExtension wired behind LATTICE_VEC_ENABLED — solserver/src/store/sqlite_control_plane_store.ts
- [x] vector queries behind LATTICE_VEC_QUERY_ENABLED — solserver/src/control-plane/orchestrator.ts
- [x] CI smoke test added — solserver/.github/workflows/ci-solserver.yml
- [x] fail-open behavior handled in code/tests — solserver/src/control-plane/orchestrator.ts; solserver/test/lattice_retrieval.test.ts
- [x] Integration test: POST /v1/memories then next chat retrieves memory — solserver/test/lattice_retrieval.test.ts
- [x] Integration test: saved name memory used next turn — solserver/test/lattice_retrieval.test.ts
- [x] meta.lattice.scores telemetry (fts5_bm25 + vec_distance keyed by retrieval IDs) — solserver/src/control-plane/orchestrator.ts; solserver/src/contracts/output_envelope.ts
- [x] Smoke scripts capture transmission id from header/body — solserver/scripts/smoke_lattice_local.sh; solserver/scripts/smoke_lattice_staging.sh
- [x] policy capsule bundle shipped in image + Fly env set — solserver/policy/policy_capsules.json; solserver/Dockerfile; solserver/fly.toml; solserver/fly.prod.toml
- [x] Docker smoke checks bundle presence + non-empty capsules — solserver/.github/workflows/ci-solserver.yml

## solmobile changes
- [x] cache memory_ids and dereference — ios/SolMobile/SolMobile/Actions/TransmissionAction.swift; ios/SolMobile/SolMobile/Views/Chat/ThreadDetailView.swift
- [x] memory list + detail UI wiring — ios/SolMobile/SolMobile/Views/Memory/MemoryVaultView.swift; ios/SolMobile/SolMobile/Views/Memory/MemoryDetailView.swift
- [x] ghost card 👍 accept + receipt — ios/SolMobile/SolMobile/Views/Chat/GhostCardComponent.swift; ios/SolMobile/SolMobile/Views/Chat/ThreadDetailView.swift
- [x] auto-accept setting (safe_only default) — ios/SolMobile/SolMobile/Services/MemoryOfferSettings.swift; ios/SolMobile/SolMobile/Views/SettingsView.swift
- [x] OutputEnvelope meta.lattice DTO + Message storage for lattice ids — ios/SolMobile/SolMobile/Models/OutputEnvelope.swift; ios/SolMobile/SolMobile/Models/Message.swift
- [x] LATTICE_OFFLINE badge (dev/staging gated by LATTICE_DEV_BADGE + status=fail) — ios/SolMobile/SolMobile/Views/Chat/ThreadDetailView.swift; ios/SolMobile/SolMobile/Info-Debug.plist; ios/SolMobile/SolMobile/Info-Release.plist
- [x] UI test stubs for ghost accept + memory detail/undo — ios/SolMobile/SolMobile/Services/UITestNetworkStub.swift
- [x] UI smoke tests for ghost accept + local memory vault/citations — ios/SolMobile/SolMobileUITests/SolMobileUITests.swift
- [x] SSE reconnect on base URL change (prevents /v1/events stale localhost) — ios/SolMobile/SolMobile/Views/SettingsView.swift
- [x] Starlight pending covers queued/sending transmissions — ios/SolMobile/SolMobile/Views/Chat/ThreadDetailView.swift
- [x] Outbox failure banners differentiate chat vs memory + retry per kind — ios/SolMobile/SolMobile/Views/Chat/ThreadDetailView.swift; ios/SolMobile/SolMobile/Services/OutboxService.swift; ios/SolMobile/SolMobile/Actions/TransmissionAction.swift
- [x] Memory receipt dismiss (X), swipe-to-dismiss, auto-dismiss window — ios/SolMobile/SolMobile/Views/Chat/ThreadDetailView.swift

## Tests run
- solserver: `bash -lc 'source ~/.nvm/nvm.sh && nvm use 20 >/dev/null && pnpm vitest run test/memory_routes.test.ts'`
- solserver: `bash -lc 'source ~/.nvm/nvm.sh && nvm use 20 >/dev/null && pnpm vitest run test/lattice_retrieval.test.ts'`
- solserver: `pnpm vitest run test/output_envelope.test.ts`
- solserver: `pnpm vitest run test/gates.pipeline.test.ts --testTimeout 300000`
- solserver: `pnpm run build`
- solmobile UI: `xcodebuild test -project ios/SolMobile/SolMobile.xcodeproj -scheme SolMobile -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' -only-testing SolMobileUITests/testGhostCardAcceptShowsReceipt -only-testing SolMobileUITests/testMemoryVaultAndCitationsLocal`

## Smoke runbook
- Local (solserver/scripts/smoke_lattice_local.sh):
  - BASE_URL=http://localhost:3333
  - Flags: LATTICE_ENABLED=1, LATTICE_VEC_ENABLED=0, LATTICE_VEC_QUERY_ENABLED=0, SOL_INLINE_PROCESSING=1, CONTROL_PLANE_DB_PATH=./data/control_plane_smoke_<ts>.db
  - POST /v1/chat returned transmission ids (anchors); POST /v1/memories succeeded with evidence_message_ids length > 1.
  - GET /v1/memories/:id and GET /v1/memories returned the created memory.
  - Chat retrieval (outputEnvelope.meta.lattice): status=hit; scores methods fts5_bm25; bytes_total=141; counts.memories=0; counts.mementos=1
- Staging deploy: `pnpm deploy:staging` succeeded (solserver-staging)
- Staging smoke (solserver/scripts/smoke_lattice_staging.sh + chat retrieval):
  - Case A flags: LATTICE_ENABLED=1, LATTICE_VEC_ENABLED=0, LATTICE_VEC_QUERY_ENABLED=0
    - meta.lattice: status=hit; scores methods fts5_bm25 only; bytes_total=1932; counts.memories=6
  - Case B flags: LATTICE_ENABLED=1, LATTICE_VEC_ENABLED=1, LATTICE_VEC_QUERY_ENABLED=0
    - meta.lattice: status=hit; scores methods fts5_bm25 only; bytes_total=2030; counts.memories=6
  - Case C flags: LATTICE_ENABLED=1, LATTICE_VEC_ENABLED=1, LATTICE_VEC_QUERY_ENABLED=1
    - meta.lattice: status=hit; scores methods vec_distance; bytes_total=2049; counts.memories=6
- Staging flags reset to Case B (default): LATTICE_ENABLED=1, LATTICE_VEC_ENABLED=1, LATTICE_VEC_QUERY_ENABLED=0

## Known issues / deferred
- None
