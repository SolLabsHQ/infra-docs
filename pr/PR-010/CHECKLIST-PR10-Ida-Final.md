\# PR10 Checklist: Consented Journaling v0 (Synaptic Muse Offer \+ Drafts \+ iOS Export) \+ ThreadMemento \+ Apple Intelligence Trace Hints

\#\# SolMobile (iOS)

\#\#\# Ascend export completion (Apple Journal)  
\- \[ \] Implement JournalingSuggestions donation and return success/failure.  
  \- solmobile/ios/SolMobile/SolMobile/Services/JournalDonationService.swift  
\- \[ \] Ensure first Ascend triggers native iOS permission prompt (requestAuthorization).  
  \- solmobile/ios/SolMobile/SolMobile/Services/JournalDonationService.swift  
\- \[ \] Fallback for unsupported iOS versions: use share sheet export (title/body) instead of JournalingSuggestions.  
  \- solmobile/ios/SolMobile/SolMobile/Views/Chat/GhostCardComponent.swift  
  \- solmobile/ios/SolMobile/SolMobile/Views/Chat/CaptureSuggestionCard.swift

\#\#\# Ascend gating \+ physicality compliance  
\- \[ \] Gate Ascend availability by OS support \+ memory fidelity/directness.The "Gate" is simply checking: `if (artifact.ghost_kind == .journalMoment)`.  
  \- solmobile/ios/SolMobile/SolMobile/Views/Chat/GhostCardComponent.swift  
\- \[ \] Align Ascend haptics:  
  \- Heartbeat only on arrival (idempotent per card instance)  
  \- Release tick (selectionChanged) on Ascend completion  
  \- Respect Physicality toggle \+ Reduce Motion  
  \- solmobile/ios/SolMobile/SolMobile/Views/Chat/GhostCardComponent.swift

\#\#\# Journal Offer UI (server-driven)  
\- \[ \] Render Journal Offer card when server returns meta.journal\_offer (offer\_eligible=true).  
  \- solmobile/ios/SolMobile/SolMobile/Views/Chat/ThreadDetailView.swift (or new JournalOfferCard.swift)  
\- \[ \] Offer actions:  
  \- Save my words (verbatim)  
  \- Help me shape it (assist)  
  \- Not now  
  \- Don’t ask like this (tuning)  
  \- solmobile/ios/SolMobile/SolMobile/Views/Chat/JournalOfferCard.swift (new)

\#\#\# Journal Draft flow (assist mode)  
\- \[ \] On “Help me shape it”, call POST /v1/journal/drafts with JournalDraftRequest.  
  \- solmobile/ios/SolMobile/SolMobile/Networking/SolServerClient.swift  
\- \[ \] Render JournalDraftEnvelope in an inline editor (title/body/tags\_suggested).  
  \- solmobile/ios/SolMobile/SolMobile/Views/Journal/JournalDraftEditorView.swift (new)  
\- \[ \] Export draft via share sheet and/or Ascend (journal donation) depending on OS.  
  \- solmobile/ios/SolMobile/SolMobile/Views/Journal/JournalDraftEditorView.swift

\#\#\# Identity plumbing (pseudonymous)  
\- \[ \] Generate stable local\_user\_uuid on first launch and include with every /v1/chat and journal/trace call.  
  \- solmobile/ios/SolMobile/SolMobile/Services/LocalIdentity.swift (new)  
  \- solmobile/ios/SolMobile/SolMobile/Networking/SolServerClient.swift

\#\#\# ThreadMemento client posture (simplify)  
\- \[ \] Add a high-level setting: Thread state updates \= auto/manual/off (default auto for internal builds).  
  \- solmobile/ios/SolMobile/SolMobile/Views/Settings/SettingsView.swift  
\- \[ \] In auto mode: accept ThreadMemento drafts automatically (no per-memento UI prompt).  
  \- solmobile/ios/SolMobile/SolMobile/Views/Chat/ThreadDetailView.swift  
  \- solmobile/ios/SolMobile/SolMobile/Networking/SolServerClient.swift

\#\#\# Apple Intelligence (trace-only, non-blocking)  
\- \[ \] Add background observation for message N-1:  
  \- mood\_intensity (0..1)  
  \- candidate moment\_type (optional)  
  \- confidence  
  \- optional phase\_hint  
\- \[ \] Send observation to SolServer trace ingestion (do not block chat; do not gate offers in v0).  
  \- solmobile/ios/SolMobile/SolMobile/Services/AppleIntelligenceObserver.swift (new)  
  \- solmobile/ios/SolMobile/SolMobile/Networking/SolServerClient.swift  
\- \[ \] Store the observation locally too (debug only) for side-by-side review.  
  \- solmobile/ios/SolMobile/SolMobile/Models/DeviceMuseObservation.swift (new)

\---

\#\# SolServer

\#\#\# Muse Offer (Synaptic gate)  
\- \[ \] Implement JournalOfferClassifier in Synaptic gate path (NOT worker).  
  \- Inputs: history window \+ sentinel mood metadata \+ optional CPB journalStyle \+ optional device hints  
  \- Output: meta.journal\_offer in OutputEnvelope  
  \- solserver/src/gates/synaptic.ts (or existing synaptic gate module)  
\- \[ \] Phase inference (per-thread):  
  \- compute intensity trend over sliding window  
  \- label phase: rising|peak|downshift|settled  
  \- optional ephemeral cache keyed by (local\_user\_uuid, thread\_id) with TTL (runtime-only)  
\- \[ \] Apply CPB rule:  
  \- if avoid\_peak\_overwhelm=true, offer\_eligible=false when phase rising/peak; true on downshift/settled  
  \- allow explicit user request override  
  \- cpb\_journal\_style.schema.json

\#\#\# JournalOfferClassifier v0 (Deterministic Heuristic Matrix)

\#\#\#\# AC-SVR-JO-01: Deterministic classifier (no extra LLM call)  
\- \[ \] JournalOfferClassifier runs inside Synaptic gate as a pure function of:  
  \- Sentinel mood label \+ intensity  
  \- ThreadMemento affect rollup phase  
  \- risk level gate (from Sentinel)  
\- \[ \] No additional model call is used to \*decide\* whether to offer.  
\- \[ \] Drafting model call happens only after explicit user consent (accept offer).

\#\#\#\# AC-SVR-JO-02: Risk safety gate  
\- \[ \] If risk is elevated (riskLevel \>= 0.5 or Sentinel risk classification \>= medium), classifier emits \*\*no\*\* journal\_offer.

\#\#\#\# AC-SVR-JO-03: Overwhelm circuit breaker (quiet confidence)  
\- \[ \] If mood.label \== "overwhelm" AND phase ∈ {rising, peak, downshift}, classifier emits \*\*no\*\* journal\_offer.  
\- \[ \] If mood.label \== "overwhelm" AND phase \== "settled", classifier may emit a journal\_offer with moment\_type \== "vent" (or mapped overwhelm type) and confidence \>= "med".

\#\#\#\# AC-SVR-JO-04: Insight fast lane  
\- \[ \] If mood.label \== "insight" AND intensity \> 0.7, classifier emits journal\_offer:  
  \- moment\_type \== "insight"  
  \- confidence \== "high"  
  \- offer\_eligible \== true  
  \- regardless of phase.

\#\#\#\# AC-SVR-JO-05: Gratitude downshift rule  
\- \[ \] If mood.label \== "gratitude" AND phase ∈ {rising, peak}, classifier emits \*\*no\*\* journal\_offer.  
\- \[ \] If mood.label \== "gratitude" AND phase ∈ {downshift, settled}, classifier emits journal\_offer:  
  \- moment\_type \== "gratitude"  
  \- confidence \>= "med"  
  \- offer\_eligible \== true.

\#\#\#\# AC-SVR-JO-06: Resolve / Decision settled rule  
\- \[ \] If mood.label \== "resolve" AND phase \== "settled", classifier emits journal\_offer:  
  \- moment\_type \== "decision" (or "resolve" mapped to decision)  
  \- confidence \>= "med"  
  \- offer\_eligible \== true.  
\- \[ \] If mood.label \== "resolve" AND phase \!= "settled", classifier emits \*\*no\*\* journal\_offer.

\#\#\#\# AC-SVR-JO-07: Curiosity is not journaling  
\- \[ \] If mood.label \== "curiosity", classifier emits \*\*no\*\* journal\_offer (curiosity routes to Lattice/Search patterns, not journaling).

\#\#\#\# AC-SVR-JO-08: Offer payload completeness  
\- \[ \] When journal\_offer is emitted, OutputEnvelope.meta.journal\_offer includes:  
  \- moment\_id (uuid)  
  \- moment\_type  
  \- phase (from ThreadMemento rollup)  
  \- confidence  
  \- evidence\_span {start\_message\_id, end\_message\_id}  
  \- why\[\] (bounded list)  
  \- offer\_eligible (boolean)

\#\#\#\# AC-SVR-JO-09: Unit test coverage (minimum set)  
\- \[ \] Unit tests cover at least:  
  1\) Overwhelm Rising/Peak/Downshift \=\> no offer  
  2\) Overwhelm Settled \=\> offer (vent)  
  3\) Insight intensity \> 0.7 \=\> offer regardless of phase  
  4\) Gratitude Rising/Peak \=\> no offer; Downshift/Settled \=\> offer  
  5\) Risk elevated \=\> no offer

\#\#\# Journal Drafts API  
\- \[ \] Add POST /v1/journal/drafts endpoint:  
  \- Request validates against journal\_draft\_request.schema.json  
  \- Response validates against journal\_draft\_envelope.schema.json  
  \- solserver/src/routes/journal.ts (new)  
\- \[ \] Draft generation rules:  
  \- mode=verbatim: minimal shaping, preserve words  
  \- mode=assist: apply CPB tone\_notes \+ preferences.max\_lines  
  \- enforce evidence span binding; set meta.evidence\_binding.non\_invention true/false  
  \- journal\_draft\_envelope.schema.json

\#\#\# Journal Entries API (explicit persistence)  
\- \[ \] Add JournalEntry endpoints (explicit, user-initiated):  
  \- POST /v1/journal/entries (create)  
  \- GET /v1/journal/entries (list)  
  \- PATCH /v1/journal/entries/:entry\_id (edit)  
  \- journal\_entry.schema.json  
  \- solserver/src/routes/journal.ts (new)  
\- \[ \] Store entries in server persistence layer (same pattern as memories, but type="journal").  
  \- solserver/src/storage/\* (existing storage module)

\#\#\# Trace ingestion (server-side DB)  
\- \[ \] Add minimal trace ingestion endpoint for client events:  
  \- POST /v1/trace/events (accept JournalOfferEvent \+ DeviceMuseObservation)  
  \- store keyed by (trace\_run\_id?, local\_user\_uuid, thread\_id, message\_id?)  
  \- solserver/src/routes/trace.ts (new)  
\- \[ \] Store JournalOfferEvent rows to trace DB:  
  \- shown/accepted/declined/muted\_or\_tuned/draft\_generated/entry\_saved/edited\_before\_save  
  \- journal\_offer\_event.schema.json  
\- \[ \] Store Apple Intelligence observation rows to trace DB (trace-only; no gating in v0).  
  \- device\_muse\_observation.schema.json (add in infra-docs) OR embed as generic trace event payload

\#\#\# Contract normalization  
\- \[ \] Normalize/accept legacy ghost\_type before validation; map to ghost\_kind when ghost\_kind missing.  
  \- solserver/src/contracts/output\_envelope.ts

\#\#\# ThreadMemento (docs \+ affect extension)  
\- \[ \] Extend ThreadMemento to include thread-level affect rollup:  
  \- N=5 recent intensity points  
  \- rollup phase: rising|peak|downshift|settled  
  \- bump version to memento-v0.1  
  \- solserver/src/memento/\* (existing)  
  \- solmobile DTO: SolServerClient.swift  
\- \[ \] Keep storage model clear: in-memory registry today; document limitation.  
  \- solserver/src/retrieval.ts (comments \+ behavior)

\---

\#\# Docs / Contracts (infra-docs)

\#\#\# Journal endpoints  
\- \[ \] Update api-contracts.md:  
  \- add /v1/journal/drafts (request/response \+ async vs sync decision)  
  \- add /v1/journal/entries CRUD (explicit persistence)  
  \- add /v1/trace/events ingestion (client → server trace)  
  \- infra-docs/schema/v0/api-contracts.md

\#\#\# JournalOfferEvent \+ journalStyle CPB  
\- \[ \] Document offer lifecycle and tuning controls (cooldown\_minutes, avoid\_peak\_overwhelm).  
  \- journal\_offer\_event.schema.json  
  \- cpb\_journal\_style.schema.json

\#\#\# ThreadMemento contract  
\- \[ \] Add ThreadMemento section to api-contracts.md:  
  \- GET /v1/memento (latest)  
  \- POST /v1/memento (create draft)  
  \- POST /v1/memento/decision (accept/decline/revoke)  
  \- Include schema fields \+ versioning \+ new affect block (memento-v0.1)  
  \- infra-docs/schema/v0/api-contracts.md

\#\#\# Apple Intelligence device hint schema (trace-only)  
\- \[ \] Add device\_muse\_observation.schema.json (minimal) OR document payload under trace event contract.  
  \- infra-docs/schema/v0/device\_muse\_observation.schema.json (new)

\---

\#\# Acceptance Criteria

\#\#\# SolServer  
1\) After high intensity and subsequent downshift/settled, server emits meta.journal\_offer with offer\_eligible=true.  
2\) When avoid\_peak\_overwhelm=true and phase is rising or peak, offer\_eligible=false (unless explicit user request).  
3\) POST /v1/journal/drafts returns schema-valid JournalDraftEnvelope with correct source\_span \+ meta.evidence\_binding.  
4\) Trace ingestion stores JournalOfferEvent and DeviceMuseObservation keyed to thread/message.  
5\) ThreadMemento v0.1 includes affect rollup and remains injectable as retrieval kind "memento".

\#\#\# SolMobile  
1\) First Ascend triggers native permission prompt; successful donation shows confirmation; denied shows actionable message.  
2\) Ascend gated by OS support \+ fidelity/directness; haptics match spec (heartbeat arrival only; release tick on completion).  
3\) Journal Offer card appears only when server offers and client cooldown allows.  
4\) Assist path calls /v1/journal/drafts, shows editor, exports; emits trace events.  
5\) Apple Intelligence observation runs non-blocking and is uploaded to trace without affecting offers in v0.  
