\# FIXLOG PR10: Consented Journaling v0 \+ ThreadMemento \+ Apple Intelligence Trace Hints

\#\# Delta Summary  
\- iOS Journal export (“Ascend”) is stubbed; donateMoment returns false, so export never succeeds.  
\- Ascend availability gating (OS support \+ fidelity/directness) is incomplete.  
\- Ascend success haptic is not aligned with v0 physicality spec (release tick on completion; heartbeat only on arrival).  
\- SolServer does not implement the “Muse Offer” pattern (Synaptic gate journal\_offer emission).  
\- SolServer does not provide journal APIs:  
  \- POST /v1/journal/drafts (JournalDraftRequest → JournalDraftEnvelope)  
  \- CRUD for JournalEntry (explicit, user-initiated)  
\- SolServer strict contract handling rejects legacy ghost\_type in some paths; needs normalization to ghost\_kind.  
\- Trace ingestion path is missing for:  
  \- JournalOfferEvent (offer shown/accepted/declined/draft\_generated/entry\_saved)  
  \- Apple Intelligence device hint events (message N-1 observation)  
\- ThreadMemento exists but lacks:  
  \- infra-docs contract entry  
  \- thread-level affect/mood roll-up (needed for phase inference)  
  \- (optional) simplified acceptance mode (auto/manual/off) for SolMobile.

\#\# Evidence (key files)  
SolMobile  
\- solmobile/ios/SolMobile/SolMobile/Services/JournalDonationService.swift  
\- solmobile/ios/SolMobile/SolMobile/Views/Chat/GhostCardComponent.swift  
\- solmobile/ios/SolMobile/SolMobile/Views/Chat/CaptureSuggestionCard.swift

SolServer  
\- solserver/src/routes/chat.ts  
\- solserver/src/routes/memories.ts  
\- solserver/src/contracts/output\_envelope.ts  
\- solserver/src/worker.ts  
\- solserver/src/orchestrator.ts  
\- solserver/src/retrieval.ts  
\- solserver/src/prompt\_pack.ts

Infra-docs (schemas / ADRs)  
\- infra-docs/schema/v0/journal\_draft\_request.schema.json  
\- infra-docs/schema/v0/journal\_draft\_envelope.schema.json  
\- infra-docs/schema/v0/journal\_entry.schema.json  
\- infra-docs/schema/v0/journal\_offer\_event.schema.json  
\- infra-docs/schema/v0/cpb\_journal\_style.schema.json  
\- infra-docs/decisions/ADR-021 — Consented Journaling \+ Conversation.md  
\- infra-docs/decisions/ADR-023-ghost-deck-delivery-physics-v0.md  
\- infra-docs/decisions/ADR-024-ghost-deck-physicality-accessibility-v0.md  
\- infra-docs/schema/v0/api-contracts.md  
