# SolServer Control Plane: Evidence‑Bound Gates + Offline Critic Loop (v0)

*Purpose:* turn “trust me bro” into **mechanical enforcement**: the server **forces** the model to (a) speak in a strict contract, (b) cite only evidence we provide, and (c) leave an audit trail we can replay, critique, and tighten into policy.

This doc captures the concrete “who computes what” and how **gates actually enforce** behavior (not vibes).

---

## 0. Core idea

We don’t “verify truth” in the abstract. We verify **conformance**:

- The model may only treat **our EvidencePack** as factual input.
- If it can’t tie a claim to evidence, it must mark it **UNKNOWN** (or decline).
- The server rejects outputs that violate these rules and forces regen with tighter deltas.

This makes the model *behave* like a bounded system even when it’s not omniscient.

---

## 1. Who computes what (no hand‑waving)

### 1.1 Routing Ladder ownership

**Step 0/1 (Deterministic Router) — SolServer code**
- Detect explicit mode requests (“System-mode”, etc.)
- Detect high‑rigor triggers (finance/legal/architecture/SolOS governance)
- Produce a `ModeDecision` candidate and confidence

**Step 2 (Selector) — LLM only when needed**
- Only called if deterministic confidence `< threshold` OR intent is mixed
- Returns **ModeDecision JSON** (schema‑validated)
- SolServer clamps + calibrates confidence and finalizes `ModeDecision`

**Step 3 (Main) — LLM**
- Returns **OutputEnvelope JSON** (schema‑validated)
- SolServer parses, runs gates, may regen, then returns `assistant_text` to client

---

## 2. “Enforce” means “server rejects + regen”, concretely

### 2.1 Enforcement mechanics
A gate “enforces” a rule by doing all of this **in code**:

1) **Validate** model output against a strict schema (Zod / JSON Schema)  
2) **Check** rule conditions (citations map, allowed evidence IDs, budgets, etc.)  
3) If fail: **emit GateResult FAIL** + **regen** with a targeted delta (up to caps)  
4) If still fail: degrade (safe minimal response) + store failure artifacts

No gate relies on “the model says it complied”. The model *provides structured data*, the server *verifies that structure and references* are consistent.

---

## 3. Contracts (X returned → parsed into Y)

### 3.1 `ModeDecision` (Selector output X; SolServer parses into Y)
**X:** Model returns ModeDecision JSON  
**Y:** SolServer parses into `ModeDecision` struct and applies post‑processing

Minimal fields (aligned to current CP pack):
- `modeLabel`
- `domainFlags[]`
- `rigorConfig`
- `clusterIds[]`
- `checkpointNeeded`
- `confidence`
- `reasons[]`
- `version`

**Post‑processing in code:**
- clamp confidence 0..1
- apply overrides: high‑rigor triggers force strictness regardless of selector optimism
- apply disagreement penalty: if selector contradicts deterministic signals strongly, reduce confidence / escalate

### 3.2 `OutputEnvelope` (Main output X; SolServer parses into Y)
**X:** Model returns OutputEnvelope JSON  
**Y:** SolServer parses into `OutputEnvelope` struct and then returns only `assistant_text` to client

OutputEnvelope shape (v0 recommendation):

```json
{
  "assistant_text": "…what the user sees…",
  "meta": {
    "modeLabel": "System",
    "domainFlags": ["architecture"],
    "citations": [
      { "claim_id": "c3", "evidence_ids": ["E2","E5"] }
    ],
    "claim_map": [
      { "claim_id": "c3", "text": "We use Fly.io for hosting.", "evidence_ids": ["E2"] },
      { "claim_id": "c4", "text": "Turso is our SQLite provider.", "evidence_ids": ["E5"] }
    ],
    "used_evidence_ids": ["E2","E5"],
    "ignored_evidence_ids": ["E7"],
    "checkpointSuggested": false
  }
}
```

**Why this matters:** it gives the server something *checkable*:
- every claim references evidence IDs
- citations must point to evidence items that were actually in the input pack
- “ignored evidence” becomes a tuning signal (not required for correctness)

---

## 4. EvidencePack (the only “facts” the model is allowed to treat as true)

### 4.1 EvidencePack format
SolServer builds an EvidencePack per request:

```json
{
  "evidence": [
    {
      "id": "E1",
      "type": "CFB",
      "title": "Stack facts",
      "text": "We host on Fly.io. DB is Turso (SQLite).",
      "hash": "sha256:…",
      "trust_tier": "authoritative"
    },
    {
      "id": "E2",
      "type": "RETRIEVAL_SNIPPET",
      "title": "ADR-011 boundary",
      "text": "Client/server responsibility boundary…",
      "hash": "sha256:…",
      "trust_tier": "authoritative"
    }
  ],
  "rules": {
    "must_cite_for_factual_claims": true,
    "allowed_evidence_ids": ["E1","E2"],
    "unknown_label_required": true
  }
}
```

### 4.2 “How do we ensure it only uses our facts?”
We do **two things**:

1) **Prompt rule (soft)**: “Treat EvidencePack as the only factual source.”
2) **Server gate (hard)**: reject any OutputEnvelope where:
   - factual claims lack evidence IDs, OR
   - evidence IDs don’t exist in the pack, OR
   - claim is marked factual but has empty evidence IDs

In strict mode, you can go even harder:
- require **every sentence** to have at least one citation reference (claim_map granularity = sentence)

---

## 5. Gates (what they do, who fills GateResult)

### 5.1 GateRegistry (static)
Every gate is registered with:
- `gate_id`, `version`
- `cost_class`: cheap | medium | expensive
- `when`: always | only_if(domainFlags contain X) | only_if(confidence < X) | etc.

### 5.2 GateResult (always filled by SolServer code)
Every gate function returns a GateResult record:

```json
{
  "gate_id": "evidence_binding",
  "gate_version": "v1",
  "result": "fail",
  "reason_codes": ["UNCITED_CLAIM"],
  "evidence_refs": ["sha256:claim_map:c7"],
  "cost_class": "cheap",
  "measured": { "latency_ms": 3, "tokens_in": 0, "tokens_out": 0 }
}
```

**Key:** even if a gate calls an LLM, it’s still the gate function that emits GateResult.

### 5.3 Concrete gate implementations (v0 set)

**G1 — output_schema (cheap)**
- Parse OutputEnvelope with Zod / JSON Schema
- Fail if invalid JSON or missing required fields

**G2 — mode_echo_match (cheap)**
- Verify `meta.modeLabel == ModeDecision.modeLabel`

**G3 — evidence_binding (cheap)**
- For each `claim_map` entry:
  - if `evidence_ids` empty AND not labeled UNKNOWN → fail
  - if any `evidence_id` not present in EvidencePack → fail
- Optional strict: ensure every claim in assistant_text is present in claim_map (see below)

**G4 — citation_integrity (cheap)**
- Ensure `citations[].evidence_ids` are subset of EvidencePack IDs
- Ensure `citations[].claim_id` exist in claim_map

**G5 — budget_enforcer (cheap)**
- Ensure tool calls, retries, tokens, and time are within BudgetConfig

**G6 — retrieval_required (medium)**
- If domain requires retrieval and EvidencePack has none → fail or route to tool
- This gate is “medium” because it may execute retrieval

**G7 — semantic_critic_sync (expensive; rare)**
- Called only when policy says so (see §9)
- Asks a critic model: "Given EvidencePack + claim_map, identify uncited or contradicted claims."
- Outputs structured `CriticFinding` JSON

### 5.4 Trace sequencing contract (metadata.seq)

The gates pipeline emits gate-phase trace events in a deterministic, stable order per trace run. Each gate trace event includes `metadata.seq`, a monotonic integer assigned by the pipeline, starting at 0 and increasing by 1 for each emitted gate event in that run. The ordering of gate phases is a v0 behavior contract (tests rely on it): `evidence_intake` → `gate_normalize_modality` → `gate_intent_risk` → `gate_lattice`. Any new gate phases must append after the existing sequence (no reordering). Refactors must preserve this sequencing and `seq` semantics to avoid drift and to keep trace consumers able to reconstruct the pipeline flow.

---

## 6. “But how do we know claim_map matches the actual text?”
Two approaches (pick one for v0):

### Option A (simplest): enforce *citation density*
- Strict mode requires every sentence to have at least one claim_map entry
- Gate checks sentence count vs claim_map count (heuristic OK early)
- This is harsh, but it’s enforceable

### Option B (better): enforce “claim anchors”
Require claim_map entries to include `span` anchors:
- `start_char`, `end_char` (or sentence index)
Then the gate verifies:
- spans are within assistant_text length
- spans do not overlap illegally
- every sentence has at least one span in strict mode

This makes enforcement mechanical.

---

## 7. Offline Batch Critic (multi‑model tuning loop)

### 7.1 What we log
For each request we write a trace bundle (redacted):

- `ModeDecision` (final)
- EvidencePack (hashes + text snippets; redacted)
- OutputEnvelope (full)
- GateResults
- Token/latency/cost
- Regen attempts and deltas

### 7.2 How we run the batch critic (Jam + “cheap GPT” + other models)
- Export trace bundles → JSONL
- Feed into:
  - ChatGPT (consumer) for fast iteration
  - Gemini / Claude / Grok as adversarial critics (optional)
- Ask for **CriticFinding JSON**:
  - “Which claims are uncited or unsupported?”
  - “Which evidence items were ignored?”
  - “Which gate should have fired but didn’t?”
  - “Suggest a policy/gate update (machine‑readable)”

### 7.3 What we distill
Jam reviews findings and promotes into:
- GateRegistry updates (add gate, tighten condition, change strictness)
- Selector rubric tweaks
- Prompt module deltas (Mounted Law)
- ADR entry when it changes governance behavior

---

## 8. Sync Semantic Critic (expensive, rare, policy‑driven)

### 8.1 When to call it (policy conditions)
Call a synchronous critic gate only when:
- `domainFlags` high‑rigor AND
- either:
  - router confidence is very low, OR
  - claim_map has many UNKNOWNs, OR
  - evidence_binding is barely passing by density but risk is high, OR
  - user action is consequential (writes / money / legal)

### 8.2 What it returns
Critic model returns `CriticFinding[]`:

```json
{
  "finding_id": "F17",
  "severity": "high",
  "type": "UNSUPPORTED_CLAIM",
  "claim_id": "c9",
  "explanation": "Claim asserts X but no evidence IDs support it.",
  "suggested_gate_delta": {
    "gate_id": "evidence_binding",
    "new_rule": "In legal domain, disallow factual claims without evidence_ids and without UNKNOWN label."
  }
}
```

Server can then:
- fail the request and regen with tighter instruction, or
- return a cautious response (“I can’t verify that from provided evidence.”)

---

## 9. Five concrete end‑to‑end flows (Step 0→3 + gates + artifacts)

Below, each flow shows:
- **Inputs:** user message + EvidencePack source
- **Steps:** what runs
- **Outputs:** X returned by LLM, parsed into Y
- **Gates:** what passes/fails
- **Artifacts stored:** what’s logged

### Flow 1 — Simple rewrite (low rigor)
**User:** “Tighten this paragraph.”

**EvidencePack:** none required (or a small “style rules” CFB)

**Step 0/1:** Deterministic router → `ModeDecision=Ida`, confidence high  
**Step 2:** skipped  
**Step 3:** main LLM returns OutputEnvelope JSON

**Gates:**
- output_schema ✅
- budget_enforcer ✅
- evidence_binding ❌ (skipped by policy because domainFlags=writing)

**Artifacts stored:** ModeDecision, OutputEnvelope, GateResults (mostly pass)

---

### Flow 2 — Architecture question with provided facts
**User:** “What’s our CP approach and why?”

**EvidencePack:** authoritative CFBs from your repo docs (stack/budget/process pack snippets)

**Step 0/1:** router sees architecture trigger → System mode, strictness medium  
**Step 2:** skipped (confidence high)  
**Step 3:** main LLM returns OutputEnvelope with claim_map and evidence_ids

**Gates:**
- output_schema ✅
- mode_echo_match ✅
- evidence_binding ✅ (all claims cite evidence)
- citation_integrity ✅

**Artifacts stored:** includes `used_evidence_ids` and ignored list for tuning

---

### Flow 3 — High-rigor legal/finance (evidence‑bound “I don’t know”)
**User:** “LLC tax implications?”

**EvidencePack:** only what you provide (e.g., your own notes / links / retrieved statutes)

**Step 0:** high‑rigor trigger forces strictness high  
**Step 3:** model must either cite evidence or mark UNKNOWN

**Gates:**
- evidence_binding enforces: uncited factual claims must be UNKNOWN or fail
- citation_integrity enforces: citations must reference pack IDs only

**Outcome:** model likely responds with:
- “From provided evidence E3/E4…” or
- “UNKNOWN given provided evidence; here’s what to gather next.”

---

### Flow 4 — Retrieval required (server enforces tool use)
**User:** “What does ADR‑011 say about client/server boundary?”

**EvidencePack initial:** empty or minimal

**Step 1:** router sets domainFlags include “requires_retrieval”  
**Gate G6 retrieval_required:** FAILS because evidence missing → CP runs retrieval tool  
**EvidencePack updated:** includes snippet(s) from local store/DB  
**Step 3:** main call proceeds with evidence bound response

**Gates:** then pass evidence_binding/citation_integrity

**Artifacts stored:** shows tool call, snippets used, cost impact

---

### Flow 5 — Output format violation → regen enforced
**User:** anything (failure case)

**Step 3 attempt #1:** model returns prose (not JSON)  
**Gate output_schema:** FAIL  
**CP regen delta:** “Return ONLY JSON matching OutputEnvelope schema.”  
**Step 3 attempt #2:** returns valid JSON  
**Gates:** pass

**Artifacts stored:** DeliveryAttempts 1/2, fail reason codes, regen delta

---

## 10. “Turn our work inside out” during testing (Jam + Andrea + beyond)
Your plan is coherent:

1) **Jam-only phase:** maximize tuning speed using consumer ChatGPT + cheap API models  
2) **Andrea phase:** widen diversity of prompts and “human feedback tags”  
3) **Beyond:** add more users and watch gate metrics:
   - % responses requiring regen
   - top GateResult failures by gate_id
   - citation density compliance
   - UNKNOWN rate (too high means evidence packs are thin or prompts unclear)

The differentiator isn’t “better model”; it’s **stronger control**:
- evidence‑bound responses
- replay + critique pipeline
- policy bundle evolution

*Potential IP angle:* the combo of **EvidencePack → structured claim_map → gate enforcement → batch critic distillation → policy promotion** is a distinctive system pattern. (Not legal advice; you’d still run it by counsel.)

---

## 11. Implementation sketch (where this lives in code)

### 11.1 Core functions (pseudo)
- `runRouting(packet) -> ModeDecision`
- `buildEvidencePack(packet, modeDecision) -> EvidencePack`
- `callSelectorIfNeeded(modeDecisionDraft) -> ModeDecision`
- `callMain(modeDecision, evidencePack) -> OutputEnvelope`
- `runGates(modeDecision, evidencePack, outputEnvelope) -> GateResults[]`
- `maybeRegen(...) -> OutputEnvelope`

### 11.2 Storage (SQLite/Turso)
Tables (v0):
- `gate_results`
- `critic_findings`
- `human_feedback`
- `trace_bundles` (or a file path + hash index)

---

## 12. Ida summary (what we’re doing)
We’re making the server the “adult in the room.”

- Models output **strict JSON**; we parse it.
- Facts come only from **EvidencePack** we provide.
- The server **rejects** uncited factual claims and forces regen.
- We log everything, run offline critics (multiple models), and Jam promotes learnings into **versioned policies**.

That’s how we get to “stronger than consumer ChatGPT”: not smarter brains, better guardrails.
