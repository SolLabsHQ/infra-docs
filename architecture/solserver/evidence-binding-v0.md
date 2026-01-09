# SolM / SolSvr v0 — Evidence Acquisition, Normalization, Trust Tiers, and Claim↔Evidence Binding

**Status:** Draft Spec (v0)  
**Date:** 2026-01-03  
**Owners:** SolSvr (control plane), SolM (UX + local-first storage)  
**Motivation:** Perplexity shows that evidence UX matters; SolM must make evidence **auditable** and **policy-enforced** without token bloat or history mutation.

**One-liner #1:** **“Perplexity nails evidence presence. SolM must nail evidence binding.”**  
**One-liner #2:** **“Evidence UX is not enough; truth requires claim↔evidence binding.”**

---

## Table of Contents
1. Scope
2. Goals and Non-goals
3. Glossary
4. Principles
5. End-to-end Flow (L2/L3)
6. L1 Detail — Source Acquisition (Discovery → Fetch → Normalize → Spans)
7. L1 Detail — Python NormalizeService (sidecar)
8. Token Discipline (model context contract)
9. Trust Tiers + SourcePolicy
10. UserSourceOverride (domain demotion/block; optional topic scope)
11. EvidencePack + ClaimMap Binding
12. Gates (enforcement)
13. Background Completion + Notifications (No Silent Loss)
14. Storage (EvidenceStore + offsets)
15. Acceptance Criteria (v0)

---

## 1) Scope
This spec defines how SolSvr obtains external sources, normalizes them, assigns trust tiers, packages evidence for model consumption, and enforces claim↔evidence binding — with job durability for backgrounding.

---

## 2) Goals and Non-goals

### Goals
- **Reliable, fast** evidence acquisition (v0 shippable).
- **System-owned** trust tiers and policy enforcement.
- **Prompt-minimal** evidence: model gets IDs + short excerpts, not full docs.
- **Claim↔Evidence binding** via `claim_map[]`.
- **No Silent Loss**: backgrounded requests still complete and notify.
- **No history mutation**: no “edit old message to regenerate.”

### Non-goals (v0)
- Universal JS-rendered site support (headless browsing as rare fallback later).
- OCR for scanned PDFs/images (v1+).
- Perfect reputation adjudication (we provide defaults + user overrides).

---

## 3) Glossary
- **CFB:** Context Fact Block (authoritative internal facts within scope/TTL).
- **EvidenceItem:** Pack-level reference to a span plus metadata.
- **EvidenceSpan:** A bounded excerpt of normalized text with stable offsets.
- **EvidencePack:** The set of evidence items provided to the model for a run.
- **ClaimMap:** Model-produced binding: claims → CFB IDs / EvidenceSpan IDs / UNKNOWN.
- **SourcePolicy:** `official_only | reputable_only | anything`.
- **TrustTier:** `official | reputable | long_tail | social | unknown`.
- **UserSourceOverride:** User-defined domain tier override or block (optionally scoped).

---

## 4) Principles
1) **RetrievalService gets sources; model binds.**  
2) **Trust tiers are system-owned; model cannot upgrade them.**  
3) **No token waste:** do not send full documents to the model.  
4) **UNKNOWN beats bluffing** when policy cannot be satisfied.  
5) **No Silent Loss:** user leaving the app must not lose the result.  
6) **No history mutation:** copy/select-all/reuse-as-new-message only.

---

## 5) End-to-end Flow (L2/L3)
1) Packet received (thread + requestId + user message)
2) Router selects `mode_label` + `domain_hint` + `source_policy`
3) CFB lookup (local-first, optional server mirror)
4) Source discovery (web search and/or registries)
5) Fetch + normalize (Python sidecar)
6) Chunk into EvidenceSpans; persist to EvidenceStore
7) Rank/select spans → build EvidencePack
8) Main model call → OutputEnvelope with `claim_map[]`
9) Gates enforce schema + policy + binding
10) Persist answer to thread; notify if backgrounded
11) UI: thread + evidence chips + drill-in into spans

---

## 6) L1 Detail — Source Acquisition (Discovery → Fetch → Normalize → Spans)

### 6.1 Input
- `query_text`
- `source_policy`
- `domain_hint`
- `user_overrides[]`
- fetch budgets (timeouts, max bytes, max URLs)

### 6.2 Candidate discovery
- **official_only**
  - Pull candidates from **OfficialRegistry** (allowlisted domains/doc roots).
  - Optionally: domain-restricted web search across allowlisted domains.
- **reputable_only / anything**
  - Use `WebSearchAdapter` to get top N URLs + snippets.

### 6.3 Pre-flight safety + policy (before fetch)
- Allow `https://` only (v0).
- Block private network destinations (SSRF defense).
- Apply effective trust tier:
  - default tier for domain + user overrides → `effective_tier`
- Apply policy:
  - `official_only` rejects non-official domains up front.
  - `reputable_only` rejects domains below reputable (after overrides).

### 6.4 Fetch (bounded + cached)
FetchService:
- redirect cap
- connect/read timeout
- max bytes (per content-type)
- per-domain rate limit
- caching by `(url, policy_key)`

### 6.5 Normalize
Delegate normalization to Python sidecar (see §7).

### 6.6 Chunk → EvidenceSpans
- Chunk normalized text into bounded spans (size tuned for retrieval + quoting).
- For each span:
  - stable `evidence_span_id`
  - canonical offsets: `start_char`, `end_char`
  - short `excerpt` (prompt-safe)
  - provenance (url/domain/retrieved_at)
  - `trust_tier` + `policy_compliant`

---

## 7) L1 Detail — Python NormalizeService (sidecar)

### 7.1 Why Python sidecar
- Better extraction tooling; reduces reinvention.
- Improves reliability and time-to-correctness.
- Keeps SolSvr core lean.

### 7.2 Sidecar responsibilities
- Fetch and extract main content OR accept fetched bytes from SolSvr (v0 can be either; keep API stable).
- HTML: main-content extraction, cleanup, normalize to plain text.
- PDF: extract per page to plain text; insert page anchors (optional).
- Return `NormalizedDocument` with plain text (canonical offsets are on this text).

### 7.3 Normalization output contract
- Canonical locator: **character offsets** into `NormalizedDocument.text`.
- “Line numbers” are derived on demand by counting `\n` boundaries, not stored as primary data.

### 7.4 Suggested implementation notes (non-binding)
- HTML extraction: trafilatura (preferred) with fallback strategy.
- PDF extraction: PyMuPDF (fitz) for text extraction; embed page anchors.

---

## 8) Token Discipline (model context contract)
**Model receives:**
- EvidenceSpan IDs and short excerpts (1–3 sentences)
- trust tier labels + policy fields
- never full HTML/PDF text

**UI drill-in:**
- fetches stored `EvidenceSpan` and can show longer excerpt, provenance, and derived line markers.

This preserves budgets while enabling binding + audit.

---

## 9) Trust Tiers + SourcePolicy

### 9.1 TrustTier (system-owned)
- `official`: first-party docs, standards bodies, vendor docs
- `reputable`: vetted high-quality secondary sources
- `long_tail`: unknown/less reliable sites
- `social`: forums, reddit, user-generated
- `unknown`: cannot classify deterministically

### 9.2 SourcePolicy (per run)
- `official_only`: only `official` effective tier allowed
- `reputable_only`: `official` or `reputable` effective tier allowed
- `anything`: all tiers allowed; UI degrades chips for lower tiers

### 9.3 Effective tier calculation
`effective_tier = apply_user_overrides(default_tier(domain), overrides, topic_scope?)`

The model may **describe** a tier but cannot upgrade it.

---

## 10) UserSourceOverride (domain demotion/block; optional topic scope)

### 10.1 Purpose
Allow user-controlled trust judgments without requiring the model to adjudicate politics/ideology or “truth.”  
Example: “This domain is not reputable for politics.”

### 10.2 Behavior
- Overrides apply after default tiering.
- Overrides can:
  - block a domain entirely
  - demote a domain to a lower tier
- Optional topic scoping (v0 can store but not require full NLP classification).

### 10.3 Minimal JSON schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://sollabshq.com/schemas/user_source_override.schema.json",
  "title": "UserSourceOverride",
  "type": "object",
  "additionalProperties": false,
  "required": ["override_id", "domain", "action", "created_at"],
  "properties": {
    "override_id": { "type": "string", "minLength": 1 },

    "domain": { "type": "string", "minLength": 1 },

    "action": {
      "type": "string",
      "enum": ["block", "set_tier"]
    },

    "set_tier": {
      "type": "string",
      "enum": ["official", "reputable", "long_tail", "social", "unknown"]
    },

    "topic_scope": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "enabled": { "type": "boolean" },
        "topics": {
          "type": "array",
          "items": { "type": "string" }
        }
      }
    },

    "reason": { "type": "string" },

    "created_at": { "type": "string", "format": "date-time" }
  }
}

## 10.4 Where overrides apply
Overrides apply *after* default tiering and *before* any decision that would surface or rely on a source.

- **Source discovery filtering**
  - Remove blocked domains early.
  - Apply “effective_tier” to candidate lists (so ranking doesn’t waste time on disallowed stuff).

- **Fetch pre-flight**
  - Hard-stop blocked domains.
  - Enforce policy gates (e.g., `official_only` cannot fetch non-official).

- **Retrieval ranking/selection**
  - Rank within tier bands first (official/reputable above long_tail/social).
  - Allow demoted domains to remain selectable only when policy allows.

- **Policy gates (effective tier is authoritative)**
  - If claim support references a span whose *effective_tier* violates `source_policy`, fail gate → regen or UNKNOWN.

- **UI chip rendering**
  - Chip style is derived from `effective_tier` (not model language).
  - Any “tier explanation” text is optional and strictly descriptive.

---

## 11) EvidencePack + ClaimMap Binding

### 11.1 EvidencePack (model-facing, prompt-minimal)
EvidencePack is the **only** external-evidence payload the model sees for a run (besides any allowed CFBs).

**Contains:**
- `source_policy` (typed)
- `evidence_items[]` each referencing stored spans
- short excerpts only (budgeted)
- trust tier metadata (system-owned)

**Does NOT contain (v0):**
- full documents
- raw HTML/PDF bytes
- long quote dumps

**Intent:** make “proof” *ID-addressable* so the model can bind claims without dragging tokens.

---

### 11.2 ClaimMap (output binding contract)
Model output must include `claim_map[]` where each **claim** binds to **support**:

Support can point to:
- `cfb_ids[]` (internal facts)
- `evidence_span_ids[]` (external spans from EvidenceStore)
- OR `unknown_id` (explicit UNKNOWN for unsupported claims)

**Rules:**
- Model may not cite “a source” without using an ID.
- In high-rigor modes, every factual claim must bind to something or be UNKNOWN.

---

### 11.3 Minimal schemas (v0 JSON)

#### EvidencePack
```json
{
  "$id": "https://sollabshq.com/schemas/evidence_pack.schema.json",
  "title": "EvidencePack",
  "type": "object",
  "additionalProperties": false,
  "required": ["pack_id", "source_policy", "evidence_items", "created_at"],
  "properties": {
    "pack_id": { "type": "string", "minLength": 1 },
    "source_policy": { "type": "string", "enum": ["official_only", "reputable_only", "anything"] },
    "evidence_items": {
      "type": "array",
      "items": { "$ref": "https://sollabshq.com/schemas/evidence_item.schema.json" }
    },
    "created_at": { "type": "string", "format": "date-time" }
  }
}
### 11.4 EvidenceItem identity + storage model (span-first)
SolM treats evidence as **stored documents + stable spans**, not “whatever text happened to be in the prompt.”

**Key idea**
- The model sees *IDs* + short excerpts.
- The system stores the **canonical normalized text** and addresses support as:
  - `(doc_id, doc_version_hash, start_char, end_char)`

**Why**
- Prevents “citation chips near paragraphs” from becoming decorative.
- Makes support auditable and gate-checkable.
- Allows UI to render “lines X–Y” without sending line metadata to the model.

---

### 11.5 Evidence normalization (fetch → normalize → span)
Evidence normalization produces a **single canonical text** per fetched source, plus a **mapping back to provenance**.

**Normalization outputs**
- `NormalizedDoc` (canonical text + metadata)
- `EvidenceSpan` (start/end char offsets into `NormalizedDoc.text`)
- Optional derived display fields: `line_start`, `line_end` (computed at render time)

**Constraints**
- Normalize deterministically (same input → same output hash).
- Preserve quotes faithfully (no paraphrasing in normalization).
- Keep the model’s excerpt budget small; the store holds the rest.

---

### 11.6 Trust tiering (system-owned, model cannot upgrade)
Trust tier is assigned by the system, based on deterministic rules + allow/deny lists.

**Tier enum**
- `official` — first-party docs / vendor domains / standards bodies primary pages
- `reputable` — high-quality secondary sources (major outlets, respected technical pubs)
- `long_tail` — blogs, niche sites, unknown editorial controls
- `social` — forums, reddit, discord, X, etc.
- `unknown` — cannot classify confidently

**Rules**
- The model can *describe* tier, but cannot change tier.
- UI chip style uses `effective_tier` only.
- Gates enforce `source_policy` against `effective_tier`.

---

### 11.7 SourcePolicy resolution (effective policy)
A request may contain multiple policy hints (user request, domain defaults, overrides).

**Resolution order**
1) User explicit instruction (highest)
2) Mode defaults (e.g., high-rigor defaults to `reputable_only`)
3) Org / environment constraints (e.g., child-safe mode)
4) Developer/test overrides (lowest)

**Result**
- `effective_source_policy` is stored on the JobRecord and echoed into EvidencePack.
- All later stages read the effective policy, not raw user text.

---

## 12) Gates (enforcement)

### 12.1 Gate list (v0)
- **G_output_schema**
  - OutputEnvelope must parse.
  - ClaimMap schema must validate.

- **G_evidence_binding**
  - In high-rigor modes: every factual claim must bind to:
    - `cfb_ids[]` OR `evidence_span_ids[]` OR `unknown_id`.

- **G_source_policy_enforcer**
  - `official_only`: supported spans must be `effective_tier=official`
  - `reputable_only`: supported spans must be `official|reputable`
  - `anything`: any tier allowed, but UI + telemetry still show tiers

- **G_span_integrity**
  - Every referenced `evidence_span_id` must exist in EvidenceStore.
  - Span bounds must be valid within the referenced doc version.

- **G_budget**
  - EvidencePack excerpt budget (token/char) under cap.
  - Claim count under cap.

### 12.2 Repair behavior (regen vs UNKNOWN)
When a gate fails:
1) **Rebind/regenerate** (preferred)
   - ask model: “rebind claim(s) to allowed evidence OR mark UNKNOWN”
2) If regen budget exhausted:
   - convert violating claims to **UNKNOWN**
   - preserve non-violating claims

**No confidence laundering**: never keep the claim if support violates policy.

---

## 13) Background completion + notifications (No Silent Loss)

### 13.1 Requirement
If the user backgrounds SolM mid-run:
- the job continues
- the final answer is appended to the thread
- the user gets a completion notification
- reopening deep-links to the completed answer

### 13.2 Minimal JobRecord schema (v0)
```json
{
  "$id": "https://sollabshq.com/schemas/job_record.schema.json",
  "title": "JobRecord",
  "type": "object",
  "additionalProperties": false,
  "required": ["job_id", "thread_id", "state", "created_at", "updated_at"],
  "properties": {
    "job_id": { "type": "string", "minLength": 1 },
    "thread_id": { "type": "string", "minLength": 1 },
    "state": { "type": "string", "enum": ["queued", "running", "succeeded", "failed", "canceled"] },
    "mode_label": { "type": "string" },
    "source_policy": { "type": "string", "enum": ["official_only", "reputable_only", "anything"] },
    "progress": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "phase": { "type": "string", "enum": ["routing", "retrieval", "normalize", "model", "gating", "persist"] },
        "detail": { "type": "string" },
        "pct": { "type": "number", "minimum": 0, "maximum": 100 }
      }
    },
    "result_message_id": { "type": "string" },
    "error": {
      "type": "object",
      "additionalProperties": false,
      "properties": { "code": { "type": "string" }, "message": { "type": "string" } }
    },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  }
}
### 13.3 Minimal job state UX (SolM)
**Goal:** No silent loss, clear progress, low UI complexity.

**In-thread (foreground)**
- Show a single “working” card attached to the user’s prompt:
  - Title: `Working…`
  - Subtext: `phase_label` (e.g., “Retrieving sources”, “Normalizing”, “Binding claims”)
  - Optional: small percent (only if cheap to compute)
- Allow “Stop” (maps to `canceled` if safe; otherwise “best effort cancel”).
- On completion:
  - Replace card with the assistant message.
  - If partial + UNKNOWN conversions occurred, show a subtle “Some claims couldn’t be supported under policy” note.

**Backgrounded**
- Job continues (server or local runner).
- On completion:
  - Persist assistant message into the thread (authoritative).
  - Trigger notification: `Answer ready` (local notification if possible; push only if needed).

**Foreground resume**
- Thread loads and auto-scrolls to:
  - `result_message_id` (or nearest anchor)
- Provide a “Return to where I was” token if the user was reading elsewhere.

**Non-goals (v0)**
- No “edit old messages to regen” (history mutation).
- No multi-job queue UI beyond one active job indicator per thread.

---

## 14) EvidenceStore + offsets

### 14.1 Canonical locator
Evidence spans are anchored by:
- `doc_id`
- `doc_version_hash`
- `start_char`
- `end_char`

**Principle**
- Offsets are the truth.
- “Line numbers” are a display convenience, derived later.

---

### 14.2 EvidenceSpan schema (v0)
```json
{
  "$id": "https://sollabshq.com/schemas/evidence_span.schema.json",
  "title": "EvidenceSpan",
  "type": "object",
  "additionalProperties": false,
  "required": ["evidence_span_id", "doc_id", "doc_version_hash", "start_char", "end_char", "created_at"],
  "properties": {
    "evidence_span_id": { "type": "string", "minLength": 1 },
    "doc_id": { "type": "string", "minLength": 1 },
    "doc_version_hash": { "type": "string", "minLength": 1 },
    "start_char": { "type": "integer", "minimum": 0 },
    "end_char": { "type": "integer", "minimum": 1 },
    "created_at": { "type": "string", "format": "date-time" }
  }
}
### 14.3 “Lines metadata will be minimal” (clarified)

**Principle:** We do **not** store line numbers as primary truth.  
We store **offset spans** as canonical truth:
- `(doc_version_hash, start_char, end_char)`

**Render-time derivation (UI only)**
Line numbers are computed when displaying evidence:

- `line_start = count("\n" in normalized_text[0:start_char]) + 1`
- `line_end   = count("\n" in normalized_text[0:end_char]) + 1`

**Why this is the right trade**
- **Stable references:** offsets stay valid for a given `doc_version_hash`.
- **Normalization-safe:** line counts can shift with whitespace changes; offsets do not.
- **Storage-light:** avoids persisting redundant metadata.
- **Audit-friendly:** we can always reconstruct “lines X–Y” from stored text + offsets.

**UI contract**
- Chips may display “Lines X–Y” for humans.
The system always stores and gates on **offset spans**.


### 14.4 Token discipline: “content lines sent to the model” (budgeted excerpts)

**Goal:** Give the model *enough* text to ground claims, without blasting tokens.

**Rule**
- Model sees **short excerpts** (snippets) + **stable pointers** (spans).
- Full text is stored server-side for audit + UI drill-in, not stuffed into prompts.

**EvidenceItem prompt payload**
- `excerpt`: ~200–600 chars default (tunable)
- `support_spans`: 1–3 spans per item (offset-based)
- `title/domain/publisher/trust_tier`: always included
- Optional: `quote_candidates[]` (very short strings) if we want “quote drill” speed

**Excerpt sizing (default)**
- Mobile + fast lane: 200–350 chars
- Rigor lane: 350–600 chars
- Hard cap per run: e.g., 6–12 evidence items max, unless deep research mode is explicit

**If excerpt isn’t enough**
- Gate can request “more context” for the same doc span (expand window) rather than fetching new sources.
- Escalate to a second retrieval pass only if still unsupported.


---

## 15) Source Discovery + Fetch + Normalize (L1 detail)

### 15.1 Who “gets sources” (ownership model)

**SolServer owns source discovery + evidence.**
- The **model does not browse**. The model receives a curated EvidencePack.
- The **retrieval stack** produces:
  - candidate URLs/doc IDs
  - fetched content
  - normalized text + spans
  - trust tier + policy compliance
- The **model** produces:
  - answer text
  - `claim_map[]` bindings to evidence IDs/spans (or UNKNOWN)

This keeps provenance deterministic and gateable.


### 15.2 How systems usually do it (baseline patterns)

Common production patterns:
1) **Search API** → URL candidates  
   - e.g., Google Programmable Search / Bing Web Search / Brave Search / SerpAPI proxy
2) **Fetcher** → download pages (HTML/PDF)  
   - anti-bot aware, caching, timeouts, retries
3) **Normalizer** → convert to text + structure  
   - HTML readability extraction
   - PDF text extraction (or OCR fallback)
4) **Ranker** → pick best sources  
   - domain allow/deny lists, recency, embeddings, heuristics
5) **Evidence packer** → make prompt-minimal excerpts + pointers

SolServer should follow this shape (with SolOS governance constraints).


### 15.3 Concretely: how SolServer will do it (v0)

**Interfaces**
- `RetrievalService.discover(query, source_policy, topic_scope, locale)`
- `FetchService.fetch(url)` → raw payload + headers
- `NormalizeService.normalize(raw)` → `NormalizedDoc`
- `EvidenceBuilder.build(normalized_docs, policy)` → `EvidencePack`

**Discovery options**
- **Option A (simple):** one search provider (fastest ship)
- **Option B (better):** 2-provider fallback (more reliable, fewer “no results” cases)
- v0 recommendation: **Option B** if we can afford it operationally

**Ranking/selection**
- Enforce `source_policy` *before* ranking:
  - `official_only`: allowlist domains only (vendor docs, standards bodies, primary sources)
  - `reputable_only`: curated domain set + strong secondary sources
  - `anything`: wide net, but tiering still applied
- Select top K docs (K small), then extract top spans per doc.


### 15.4 Fetch: what we use vs reinvent

**We should not reinvent HTTP.**
Use a standard HTTP client (language-appropriate) with:
- timeouts (connect + read)
- retries with backoff
- user-agent discipline
- gzip/br support
- content-type aware handling (html/pdf/text)

**Caching (must-have)**
- Key: `(url, etag/last-modified, fetched_at_bucket)`
- Store: raw bytes + normalized text + doc hash
- Benefit: speeds repeated “official-only” queries and quote drills.


### 15.5 Normalize: “Option B” (Python NormalizeService) — why

**Requirement:** reliable + fast normalization across messy web content.

**NormalizeService (Python) responsibilities**
- HTML:
  - boilerplate removal (readability-style extraction)
  - strip nav/ads
  - preserve headings + paragraph boundaries
- PDF:
  - extract text if possible
  - fallback strategy (only if needed): OCR (costly; last resort)
- Output:
  - `normalized_text`
  - `structure_map` (paragraph offsets, headings)
  - `doc_version_hash` (hash of normalized text)
  - `provenance` (url, fetched_at, content_type, publisher)

**Why Python**
- Mature parsing ecosystem + faster iteration on weird edge cases
- We isolate it behind a stable contract, so the rest of SolServer stays clean


### 15.6 Trust tiering: system-owned, not model-owned

**Trust tier is assigned during retrieval/normalize**, not by the model.

Example tiers:
- `official` (first-party docs, standards bodies)
- `reputable` (major outlets, well-known references)
- `long_tail` (blogs, niche sites)
- `social` (forums, reddit)

Rules:
- Tier is **sticky**: model can describe it but cannot upgrade it.
- UI renders tier consistently (degraded chips for lower tiers).
- Gates enforce policy compliance using tier + domain.


### 15.7 Backgrounding + completion (no silent loss)

**Job model**
- Every run gets a `job_id` + `thread_id`.
- Server continues even if app backgrounds.
- On completion:
  - persist final answer + evidence metadata
  - send local notification (or push if needed)
- On re-open:
  - land user at completion state + “Return to where I was” token

This is core for latency-heavy flows and differentiates us from Perplexity pain.


### 15.8 Minimal v0 deliverable checklist

- [ ] `source_policy` enforced in discovery + selection
- [ ] `NormalizeService` producing stable `doc_version_hash` + offset spans
- [ ] `EvidencePack` prompt-minimal excerpts + pointers
- [ ] `claim_map[]` binding to evidence IDs/spans (or UNKNOWN)
- [ ] Gate: `evidence_binding` + `policy_enforcer`
- [ ] UI: tiered chips + source list + drill-in
- [ ] Background-safe job completion + notification