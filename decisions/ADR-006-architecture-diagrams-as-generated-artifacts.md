# ADR-006: Architecture Diagrams as Generated Artifacts

## Status
Accepted

## Context
SolLabsHQ uses C4-style architecture diagrams to document system structure and relationships.
Early experiments showed that treating Structurizr DSL files as first-class documentation caused
confusion, tool friction, and unnecessary indirection for readers.

The primary audience for architecture documentation is humans, not diagram tooling.

## Decision
Architecture diagrams will be treated as generated artifacts.

- Structurizr DSL and JSON files are maintained as implementation inputs.
- Rendered PNG exports are the authoritative, human-readable artifacts.
- Only exported images are referenced from documentation.
- Tool cache and intermediate artifacts are not committed.

## Consequences
- Diagrams are easy to view in GitHub without tooling.
- Documentation remains stable even if diagram tooling changes.
- Regeneration is explicit and intentional, not automatic.

## Notes
Structurizr Lite is used as a rendering tool, not a documentation system.