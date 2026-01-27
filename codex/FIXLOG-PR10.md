# FIXLOG PR10: Journal Support Delta

## Delta Summary
- Journal donation on iOS is stubbed; Ascend always fails.
- Journal-specific artifacts are not emitted server-side (ghost_kind always memory_artifact).
- Journal draft/entry/offer/CPB schemas are defined but have no routes or UI flows.
- Ascend haptics and fidelity gating diverge from ADR-024.
- ghost_type is treated as a validation error in server contracts despite doc aliasing.

## Evidence (key files)
- solmobile/ios/SolMobile/SolMobile/Services/JournalDonationService.swift
- solmobile/ios/SolMobile/SolMobile/Views/Chat/GhostCardComponent.swift
- solserver/src/worker.ts
- solserver/src/routes/memories.ts
- solserver/src/contracts/output_envelope.ts
- infra-docs/schema/v0/journal_draft_request.schema.json
- infra-docs/schema/v0/journal_draft_envelope.schema.json
- infra-docs/schema/v0/journal_entry.schema.json
- infra-docs/schema/v0/journal_offer_event.schema.json
- infra-docs/schema/v0/cpb_journal_style.schema.json

