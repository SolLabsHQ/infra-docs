# PR10 Review: Journal Support (SolMobile + SolServer)

## Scope
Scan SolMobile and SolServer implementations for Journal support and compare to infra-docs specifications (ADR-021/022/023/024 + schema v0).

## Findings (Documented vs Implemented)

### Implemented (matches docs)
- Ghost card physicality + Reduce Motion + Physicality toggle are implemented in SolMobile.
  - solmobile/ios/SolMobile/SolMobile/Views/Chat/GhostCardComponent.swift
  - solmobile/ios/SolMobile/SolMobile/Services/PhysicalityManager.swift
  - solmobile/ios/SolMobile/SolMobile/Views/Memory/MemoryVaultView.swift
- Ghost card routing uses meta.display_hint + ghost_kind with ghost_type legacy mapping.
  - solmobile/ios/SolMobile/SolMobile/Models/GhostCardMetadata.swift
  - solserver/src/memory/ghost_envelope.ts
  - solserver/src/routes/chat.ts
- Journal location capture on arrival is implemented via LocationSampler.
  - solmobile/ios/SolMobile/SolMobile/Views/Chat/GhostCardComponent.swift
  - solmobile/ios/SolMobile/SolMobile/Models/GhostCardLedger.swift
  - solmobile/ios/SolMobile/SolMobile/Services/LocationSampler.swift
- Memory distill + CRUD endpoints exist on SolServer.
  - solserver/src/routes/memories.ts
- Composer draft persistence (long-form journaling reliability) is implemented.
  - solmobile/ios/SolMobile/SolMobile/Models/DraftRecord.swift
  - solmobile/ios/SolMobile/SolMobile/Views/Chat/ThreadDetailView.swift

### Missing or Partial (doc/impl delta)
- iOS Journal donation is stubbed; Ascend never succeeds.
  - solmobile/ios/SolMobile/SolMobile/Services/JournalDonationService.swift
- Journal ghost kind is supported in contracts but not produced server-side.
  - solserver/src/worker.ts (always ghostKind: memory_artifact)
  - solserver/src/routes/memories.ts (type: "memory" only)
- Journal draft/entry/offer/CPB schemas exist but no endpoints, models, or UI flows are implemented.
  - infra-docs/schema/v0/journal_draft_request.schema.json
  - infra-docs/schema/v0/journal_draft_envelope.schema.json
  - infra-docs/schema/v0/journal_entry.schema.json
  - infra-docs/schema/v0/journal_offer_event.schema.json
  - infra-docs/schema/v0/cpb_journal_style.schema.json
- Ascend haptics diverge from ADR: success uses heartbeat instead of release tick; fidelity gating not enforced.
  - solmobile/ios/SolMobile/SolMobile/Views/Chat/GhostCardComponent.swift
- ghost_type is documented as alias but server validation errors on it (strict contract).
  - solserver/src/contracts/output_envelope.ts

## Notes
- CaptureSuggestion journal entry export via share sheet exists and is functional.
  - solmobile/ios/SolMobile/SolMobile/Models/OutputEnvelope.swift
  - solmobile/ios/SolMobile/SolMobile/Views/Chat/CaptureSuggestionCard.swift

