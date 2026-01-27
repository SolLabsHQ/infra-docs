# PR10 Checklist: Journal Support Delta

## SolMobile
- [ ] Implement JournalingSuggestions donation and return success/failure.
  - solmobile/ios/SolMobile/SolMobile/Services/JournalDonationService.swift
- [ ] Gate Ascend availability by OS support + memory fidelity/directness.
  - solmobile/ios/SolMobile/SolMobile/Views/Chat/GhostCardComponent.swift
- [ ] Align Ascend haptics with ADR (release tick on success; heartbeat on arrival only).
  - solmobile/ios/SolMobile/SolMobile/Views/Chat/GhostCardComponent.swift
- [ ] Add JournalOfferEvent telemetry emission for offer/accept/decline/save.
  - infra-docs/schema/v0/journal_offer_event.schema.json

## SolServer
- [ ] Add journal draft endpoint + worker to emit JournalDraftEnvelope.
  - infra-docs/schema/v0/journal_draft_request.schema.json
  - infra-docs/schema/v0/journal_draft_envelope.schema.json
- [ ] Add journal entry persistence endpoints (create/list/edit).
  - infra-docs/schema/v0/journal_entry.schema.json
- [ ] Produce journal_moment ghost_kind and type: "journal" artifacts where applicable.
  - solserver/src/worker.ts
  - solserver/src/routes/memories.ts
- [ ] Normalize/accept legacy ghost_type before validation.
  - solserver/src/contracts/output_envelope.ts

## Docs / Contracts
- [ ] Add Journal endpoints to API contracts doc.
  - infra-docs/schema/v0/api-contracts.md
- [ ] Document JournalOfferEvent flows and journalStyle CPB usage or defer explicitly.
  - infra-docs/schema/v0/journal_offer_event.schema.json
  - infra-docs/schema/v0/cpb_journal_style.schema.json
- [ ] Clarify journal_moment generation rules and memory type mapping.
  - infra-docs/decisions/ADR-022-memory-api-contract-v0-distill-persist-crud-consent.md
  - infra-docs/decisions/ADR-023-ghost-deck-delivery-physics-v0.md

