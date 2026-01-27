\# PR10 Review: Consented Journaling v0 (SolMobile \+ SolServer) \+ ThreadMemento \+ Apple Intelligence Trace Hints

\#\# Scope  
Scan SolMobile iOS and SolServer implementations for:  
\- Journal export (“Ascend”) completion and physicality compliance.  
\- Server-side journaling support: Synaptic Muse Offer \+ drafts/entries APIs \+ trace ingestion.  
\- ThreadMemento: usage, storage model, docs gaps, and planned “affect” (thread mood) extension.  
\- Apple Intelligence: optional, non-blocking, trace-only hint lane.

Compare to:  
\- ADR-021 (Consented Journaling \+ CPB journalStyle)  
\- ADR-022 (memory distill contract patterns)  
\- ADR-023/024 (Ghost Deck delivery \+ physicality \+ haptics)  
\- v0 schemas: journal\_offer\_event, journal\_draft\_request/envelope, journal\_entry, cpb\_journal\_style

\---

\#\# Findings (Documented vs Implemented)

\#\#\# Implemented (matches docs / already present)  
SolMobile  
\- Ghost card physicality \+ Reduce Motion \+ Physicality toggle are implemented.  
  \- solmobile/ios/SolMobile/SolMobile/Views/Chat/GhostCardComponent.swift  
  \- solmobile/ios/SolMobile/SolMobile/Services/PhysicalityManager.swift  
\- Ghost card routing uses meta.display\_hint \+ ghost\_kind with legacy ghost\_type mapping.  
  \- solmobile/ios/SolMobile/SolMobile/Models/GhostCardMetadata.swift  
\- CaptureSuggestion journal entry export via share sheet exists and is functional (journal\_entry suggestion type).  
  \- solmobile/ios/SolMobile/SolMobile/Views/Chat/CaptureSuggestionCard.swift  
\- Journal location sampling on arrival (ghost ledger) exists.  
  \- solmobile/ios/SolMobile/SolMobile/Services/LocationSampler.swift

SolServer  
\- Memory distill \+ CRUD endpoints exist (memory artifacts).  
  \- solserver/src/routes/memories.ts  
\- ThreadMemento endpoints exist (draft \+ decision \+ read latest), and is injected as a retrieval item (kind: "memento").  
  \- solserver/src/routes/chat.ts  
  \- solserver/src/retrieval.ts  
  \- solserver/src/prompt\_pack.ts  
  \- solserver/src/orchestrator.ts

\---

\#\#\# Missing or Partial (doc/impl delta)

\#\#\#\# A) SolMobile: Ascend export is stubbed  
\- JournalingSuggestions.donateMoment() is TODO and returns false, so Ascend never succeeds.  
  \- solmobile/ios/SolMobile/SolMobile/Services/JournalDonationService.swift

\#\#\#\# B) SolMobile: Ascend gating \+ haptics drift  
\- Ascend availability is not gated by OS support \+ fidelity/directness.  
\- Success haptic behavior diverges from ADR-024 / haptics spec (release tick on completion; heartbeat on arrival only).  
  \- solmobile/ios/SolMobile/SolMobile/Views/Chat/GhostCardComponent.swift

\#\#\#\# C) SolServer: Journaling support not implemented end-to-end  
\- Journal draft/entry/offer/CPB schemas exist but no wired routes or runtime logic is active:  
  \- infra-docs/schema/v0/journal\_draft\_request.schema.json  
  \- infra-docs/schema/v0/journal\_draft\_envelope.schema.json  
  \- infra-docs/schema/v0/journal\_entry.schema.json  
  \- infra-docs/schema/v0/journal\_offer\_event.schema.json  
  \- infra-docs/schema/v0/cpb\_journal\_style.schema.json  
\- Server does not currently emit journal offers from Synaptic gate (Muse Offer pattern).  
\- Server does not currently provide /v1/journal/drafts or /v1/journal/entries endpoints.

\#\#\#\# D) SolServer: ghost\_type alias handling mismatch  
\- ghost\_type is documented as alias, but strict validation errors can occur if ghost\_type is present without ghost\_kind.  
  \- solserver/src/contracts/output\_envelope.ts

\#\#\#\# E) Trace: client-to-server trace ingestion does not exist (needed for offers \+ Apple hints)  
\- /v1/chat returns trace\_run\_id, but there is no client API path to submit JournalOfferEvent or Apple Intelligence hint events to server trace DB.  
\- Requirement: add a small trace ingestion endpoint (or equivalent).

\#\#\#\# F) ThreadMemento: gaps \+ planned extension  
Current  
\- ThreadMemento exists in SolServer \+ SolMobile; it is user-surfaced with accept/decline/undo today.

Gaps  
\- No infra-docs contract entry for ThreadMemento in api-contracts.md.  
\- SolServer storage is in-memory only (no audit/persistence); behavior depends on process lifetime.  
\- No “affect” / mood roll-up exists in memento; phase inference for journaling needs a home.

Planned (PR10 scope)  
\- Extend ThreadMemento to include thread-level affect roll-up:  
  \- N=5 recent intensity points \+ rollup phase (rising/peak/downshift/settled)  
\- Option: add a high-level SolMobile setting for memento acceptance (auto/manual/off), default auto for internal builds.

\#\#\#\# G) Apple Intelligence: optional “second voice” is not present  
\- Add an on-device background observation that computes mood/intensity \+ candidate moment type for message N-1.  
\- Do not block UX, do not gate behavior in v0.  
\- Send to SolServer trace for review only.

\---

\#\# Notes  
\- PR10 spans both repos; recommend two PRs in sequence:  
  1\) solserver \+ infra-docs (contracts/endpoints/trace ingestion/memento docs)  
  2\) solmobile-ios (consume offer/export/haptics/Apple hints)  
