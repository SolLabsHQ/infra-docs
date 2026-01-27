# SolLabsHQ — Infrastructure & Architecture Docs

This repository is the canonical architecture and decision record for systems developed under SolLabsHQ.

It exists to:
- Establish authorship and timeline
- Document system architecture before implementation details
- Record intentional design decisions
- Provide a stable reference across repositories

This repo is intentionally documentation-first and code-light.

---

## Scope

This repository covers:
- Cross-system architecture (C4-style)
- System boundaries and responsibilities
- Runtime and infrastructure decisions
- Versioned schemas and interfaces
- Design tradeoffs and constraints
- Timeline entries establishing evolution and priority

It does **not** contain:
- Application code
- Secrets or credentials
- Customer or personal data

---

## Active Systems

- **SolOS**  
  Personal cognitive architecture and decision framework.

- **SolMobile**  
  Native iOS client for SolOS with explicit memory, drift control, and user agency.

- **SolServer**  
  Lightweight runtime services supporting SolMobile.

---

## Structure

- architecture/ — system architecture and flow specs (v0)
- decisions/ — ADRs (architecture decisions)
- schema/ — versioned JSON schemas and api contracts
- domains/ — domain boundaries and rules
- timeline/ — milestones and history
- pr/ — PR execution artifacts and reviews
- codex/ — working inputs, reviews, and checklists
- solmobile/ / solserver/ / ios/ — platform-specific reference notes

---

## PR-010 (Consented Journaling v0)

Key docs:
- `schema/v0/api-contracts.md` — endpoints for journal drafts/entries and trace events
- `decisions/ADR-024-ghost-deck-physicality-accessibility-v0.md` — label-only Ascend gating
- `decisions/ADR-025-consented-journaling-v0-muse-offer-memento-affect-device-muse-trace.md`
- `architecture/solserver/control-plane-v0.md` — journal offer and draft flow
- `architecture/solserver/message-processing-gates-v0.md` — deterministic JournalOfferClassifier
- `architecture/solserver/output-envelope-v0-min.md` — meta.journal_offer
- `architecture/solmobile/trace-ui-v0.md` — trace ingestion and privacy
- `architecture/diagrams/solmobile/transmission.md` — ThreadMemento v0.1 notes
- `architecture/solmobile/solm-apple-intelligence-integration.md` — DeviceMuse trace-only
- `pr/PR-010/` — source artifacts (review, fixlog, checklist, input)
