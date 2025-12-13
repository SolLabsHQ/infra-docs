# Architecture Diagrams

This directory contains Structurizr DSL files that render C4 views of SolLabsHQ systems.

These diagrams mirror the canonical architecture documents in `infra-docs/architecture/`.

Markdown documents define architectural truth.
Diagrams are visual projections of that truth.

---

## Current Views (v0)

- `context.dsl`
  C4 Level 1 System Context view for SolMobile v0.

- `containers.dsl`
  C4 Level 2 Container view for SolMobile v0.

Lower-level views (C4 Level 3 and 4) are intentionally deferred.

---

## How to View (Structurizr Lite)

Structurizr Lite runs from a directory containing `workspace.dsl`.

Recommended approach:
- Maintain a dedicated `workspace.dsl` that loads or contains the desired model and views.
- Run Structurizr Lite with Docker and mount the workspace directory.

Example:

docker run --rm -it \
  -p 8080:8080 \
  -v "<path-to-workspace-dir>:/usr/local/structurizr" \
  structurizr/lite

Then open:
http://localhost:8080

---

## Design Rules

- Diagrams must not contradict the corresponding architecture markdown files.
- If the system boundary or trust boundary changes, update the markdown and add an ADR first.
- Diagrams should stay minimal and readable.
