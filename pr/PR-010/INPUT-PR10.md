\#\# \*\*INPUT\*\*

\# Codex Input — PR10 Consented Journaling v0 \+ ThreadMemento Affect \+ Apple Intelligence Trace (v0.1)

\#\# Objective

Ship PR10 as two clean PRs with contracts-first discipline:

1\) \*\*PR10-Svr (solserver \+ infra-docs)\*\*    
   \- Contracts updated in \`infra-docs\` \*\*before\*\* code changes  
   \- Synaptic Gate emits \`meta.journal\_offer\` (Muse Offer pattern)  
   \- \`ThreadMemento\` upgraded to include \*\*affect rollup\*\* (P0)  
   \- \`POST /v1/journal/drafts\` returns \`JournalDraftEnvelope\`  
   \- JournalEntry endpoints exist (explicit user action)  
   \- Trace ingestion exists for JournalOfferEvent \+ DeviceMuseObservation (Apple Intelligence hint)  
   \- Deterministic v0 JournalOfferClassifier (no extra LLM call)

2\) \*\*PR10-Mob (solmobile-ios)\*\*    
   \- Ascend export (Apple Journal donation) works \+ fallback share sheet  
   \- Fidelity gate is \*\*label-only\*\*: client checks \`ghost\_kind \== journal\_moment\` (no recompute)  
   \- Journal Offer UI consumes server \`meta.journal\_offer\`  
   \- Assist path calls \`/v1/journal/drafts\`  
   \- Apple Intelligence runs \*\*non-blocking\*\* and sends \*\*mechanism-only\*\* hints to trace

\#\# Branch Names  
infra-docs (contracts \+ schemas \+ PR10 artifacts)  
	**•	codex/pr10-contracts-and-schemas**  
	•	Updates: api-contracts.md, new schemas (thread\_memento v0.1, device\_muse\_observation), and infra-docs/pr/PR-010/\* artifacts.

solserver (Synaptic Muse Offer \+ drafts \+ entries \+ trace ingestion \+ memento affect)  
	**•	codex/pr10-svr-muse-offer-drafts-trace**  
	•	Implements: Synaptic classifier, ThreadMemento v0.1 affect, /v1/journal/drafts, /v1/journal/entries CRUD, /v1/trace/events, legacy alias normalization.

solmobile (Ascend export \+ offer UI \+ server drafts \+ Apple AI trace-only)  
	**•	codex/pr10-mob-offer-ui-ascend-apple-hints**  
	•	Implements: Ascend donation \+ fallback, label-only fidelity gate, offer card, assist draft editor, DeviceMuseObservation background upload.

\#\# Naming rules

\- Do not invent new schema fields without updating infra-docs first.  
\- Use explicit terms: \`journal\_offer\`, \`offer\_eligible\`, \`phase\`, \`moment\_type\`.  
\- Apple Intelligence events are \*\*DeviceMuseObservation\*\* (trace-only). No “telemetry” wording in code or docs.

\---

\#\# Governance rules (hard)

\#\#\# Contracts-first gate (hard stop)  
\- \*\*Do not write application code\*\* until:  
  1\) \`infra-docs/schema/v0/api-contracts.md\` is updated for PR10 endpoints \+ ThreadMemento v0.1  
  2\) Any new schemas are added (thread\_memento.schema.json v0.1, device\_muse\_observation.schema.json)

\*\*BREAKPOINT A:\*\* After infra-docs updates, print:  
\- files changed  
\- key contract diffs  
\- schema additions  
Then STOP for review.

\#\#\# Fidelity gate clarification (SolMobile)  
\- \*\*Do not compute fidelity/directness on client.\*\*  
\- The “gate” is strictly:  
  \- show Ascend only if the server labeled the artifact \`ghost\_kind \== journal\_moment\`  
  \- otherwise hide/disable

\#\#\# Apple Intelligence trace privacy (strict)  
\- DeviceMuseObservation is \*\*mechanism-only\*\*:  
  \- ok: detected\_type, intensity, confidence, phase\_hint, thread\_id, message\_id, local\_user\_uuid, ts  
  \- NOT ok: raw user text, context window, evidence spans, extracted entities  
\- Principle: inspect the mechanism, not the thought.

\#\#\# ThreadMemento affect rollup is P0  
\- \`offer\_eligible\` depends on phase, and phase depends on affect velocity.  
\- Must land in PR10-Svr.

\---

\#\# PR split rules

\- Create two PRs:  
  \- \`pr10-svr-consented-journaling-muse-offer\`  
  \- \`pr10-mob-consented-journaling-offer-ui\`  
\- Implement and merge PR10-Svr first.  
\- PR10-Mob depends on PR10-Svr contracts and endpoints.

\---

\#\# Domain A — infra-docs (Contracts \+ Schemas) \[PR10-Svr\]

\#\#\# Required placements  
Add the PR10 artifacts into infra-docs for permanence:  
\- \`infra-docs/pr/PR-010/REVIEW-PR10-Ida-Final.md\`  
\- \`infra-docs/pr/PR-010/FIXLOG-PR10-Ida-Final.md\`  
\- \`infra-docs/pr/PR-010/CHECKLIST-PR10-Ida-Final.md\`  
\- \`infra-docs/pr/PR-010/INPUT-PR10.md\` (this file)

Update \`infra-docs/schema/v0/api-contracts.md\` to include:  
\- ThreadMemento endpoints \+ schema ref (v0.1)  
\- Journal drafts endpoint:  
  \- \`POST /v1/journal/drafts\` (JournalDraftRequest → JournalDraftEnvelope)  
\- Journal entries endpoints (explicit persistence):  
  \- \`POST /v1/journal/entries\`  
  \- \`GET /v1/journal/entries\`  
  \- \`PATCH /v1/journal/entries/:entry\_id\`  
  \- \`DELETE /v1/journal/entries/:entry\_id\`  
\- Trace ingestion endpoint:  
  \- \`POST /v1/trace/events\` (JournalOfferEvent \+ DeviceMuseObservation)

Add missing schemas:  
\- \`infra-docs/schema/v0/thread\_memento.schema.json\` (v0.1, includes affect rollup)  
\- \`infra-docs/schema/v0/device\_muse\_observation.schema.json\` (trace-only, no text)

\*\*BREAKPOINT A\*\* applies here: STOP after contracts and schemas are done.

\---

\#\# Domain B — SolServer (Muse Offer \+ Drafts \+ Trace) \[PR10-Svr\]

\#\#\# B1) ThreadMemento v0.1 (Affect Rollup)  
\- Upgrade ThreadMemento version to \`memento-v0.1\`  
\- Add \`affect\`:  
  \- \`points\[\]\` max 5 (end\_message\_id, intensity 0..1, label, confidence, source)  
  \- \`rollup\` (phase: rising|peak|downshift|settled, intensity bucket, updated\_at)  
\- Store and inject as retrieval item kind \`memento\` (keep existing injection behavior)

\#\#\# B2) Phase inference (per-thread)  
\- Compute phase from affect points:  
  \- rising: slope up  
  \- peak: intensity high and not falling  
  \- downshift: falling after high  
  \- settled: low/stable after downshift  
\- Optional: ephemeral runtime cache keyed by (local\_user\_uuid, thread\_id) for smoothing (TTL). Not durable memory.

\#\#\# B3) JournalOfferClassifier v0 (Deterministic Heuristic Matrix)  
Location: Synaptic gate (NOT worker)

Rules:  
\- Risk gate: if elevated risk \=\> no offer  
\- Overwhelm circuit breaker: overwhelm \+ not settled \=\> no offer  
\- Insight fast lane: insight \+ intensity \> 0.7 \=\> offer now  
\- Gratitude: wait during rising/peak, offer on downshift/settled  
\- Resolve: offer decision only when settled  
\- Curiosity: mute (not journaling)

Emit:  
\- \`OutputEnvelope.meta.journal\_offer\` object with moment\_id, moment\_type, phase, confidence, evidence\_span, why\[\], offer\_eligible.

\#\#\# B4) Journal Drafts API  
Add \`POST /v1/journal/drafts\`:  
\- Validate request against \`journal\_draft\_request.schema.json\`  
\- Fetch bounded evidence\_span from thread store  
\- Generate draft using the existing model call (no new model to “decide”)  
\- Validate response against \`journal\_draft\_envelope.schema.json\`  
\- Enforce evidence binding:  
  \- set \`meta.evidence\_binding.non\_invention\` true/false  
  \- populate \`meta.assumptions\[\]\` and \`meta.unknowns\[\]\` as needed

\#\#\# B5) Journal Entries API (explicit persistence)  
Add CRUD endpoints using \`journal\_entry.schema.json\`.  
\- Explicit user action only (no background save).  
\- Store entries server-side for cross-platform parity (Android), but keep creation explicit and inspectable.

\#\#\# B6) Trace ingestion (server)  
Add \`POST /v1/trace/events\`:  
\- Accept \`JournalOfferEvent\` objects  
\- Accept \`DeviceMuseObservation\` objects  
\- Store keyed by (local\_user\_uuid, thread\_id, message\_id) with timestamps  
\- Ensure DeviceMuseObservation is rejected if it contains text/context fields (schema enforcement).

\#\#\# B7) Identity plumbing  
\- Accept \`local\_user\_uuid\` in every request (header or body)  
\- Use it for trace correlation and ephemeral caches  
\- Do not treat it as login identity (pseudonymous)

\---

\#\# Domain C — SolMobile (Offer UI \+ Ascend \+ Apple Intelligence) \[PR10-Mob\]

\#\#\# C1) Ascend export completion  
\- Implement JournalingSuggestions donation for supported OS  
\- Ensure permission prompt flows correctly  
\- Fallback to share sheet for unsupported OS versions

\#\#\# C2) Fidelity gate is label-only  
\- Do NOT compute fidelity on device.  
\- Gate Ascend by server label only:  
  \- show Ascend if \`ghost\_kind \== journal\_moment\`  
  \- otherwise do not show

\#\#\# C3) Journal Offer UI (server-driven)  
\- Render a JournalOfferCard when \`meta.journal\_offer.offer\_eligible \== true\`  
\- Actions priority:  
  1\) Help me shape it (primary)  
  2\) Save my words (secondary)  
  3\) Not now  
  4\) Don’t ask like this (tuning)

\#\#\# C4) Assist path (draft)  
\- On accept assist:  
  \- POST /v1/journal/drafts with JournalDraftRequest (mode=assist, evidence\_span, cpb\_refs, preferences.max\_lines)  
\- Render draft editor, allow edits, then export via share sheet or Ascend

\#\#\# C5) Verbatim path (no draft API required)  
\- Build title/body locally from evidence span  
\- Export via share sheet (and optionally Ascend where available)  
\- No server draft call needed for verbatim

\#\#\# C6) Apple Intelligence observer (trace-only, non-blocking)  
\- Run in background for message N-1 after send/receive  
\- Produce DeviceMuseObservation (mechanism-only)  
\- POST to /v1/trace/events asynchronously  
\- Never block chat UI and never gate journaling offers in v0

\---

\#\# Deliverables

\#\#\# PR10-Svr (infra-docs \+ solserver)  
1\) infra-docs: api-contracts.md updated \+ schemas added (thread\_memento v0.1, device\_muse\_observation)  
2\) solserver: ThreadMemento v0.1 affect rollup  
3\) solserver: Synaptic JournalOfferClassifier v0 deterministic  
4\) solserver: POST /v1/journal/drafts implemented (schema-valid JournalDraftEnvelope)  
5\) solserver: JournalEntry CRUD endpoints (explicit)  
6\) solserver: POST /v1/trace/events ingestion with strict schema enforcement (no text allowed for device hints)

\#\#\# PR10-Mob (solmobile-ios)  
1\) Ascend donation works \+ fallback share sheet  
2\) Fidelity gate is label-only based on ghost\_kind  
3\) JournalOfferCard UI consumes meta.journal\_offer  
4\) Assist draft editor calls /v1/journal/drafts  
5\) Apple Intelligence observer sends trace-only hints (no content)

\---

\#\# Acceptance criteria (must verify)

\#\#\# Contracts-first (hard)  
\- Contracts \+ schemas are merged before server implementation begins (BREAKPOINT A).

\#\#\# ThreadMemento affect (P0)  
\- ThreadMemento v0.1 contains affect points (max 5\) \+ rollup phase.  
\- Phase labels match rising|peak|downshift|settled.

\#\#\# JournalOfferClassifier (deterministic)  
\- No extra LLM call used to decide offers.  
\- Overwhelm rising/peak/downshift emits no offer.  
\- Insight intensity \> 0.7 emits offer regardless of phase.  
\- Gratitude rising/peak waits; downshift/settled offers.  
\- Risk elevated emits no offer.

\#\#\# Journal drafts  
\- POST /v1/journal/drafts returns schema-valid JournalDraftEnvelope.  
\- meta.evidence\_binding.source\_span matches source\_span.  
\- meta.evidence\_binding.non\_invention is set and meaningful.

\#\#\# Fidelity gate (mobile)  
\- Ascend button appears only when server labeled ghost\_kind \== journal\_moment.

\#\#\# Apple Intelligence trace privacy  
\- DeviceMuseObservation payload contains no text/context fields (schema rejects).  
\- Upload is async and never blocks chat.  
\- Device hint never changes offer behavior in v0.

\---  
