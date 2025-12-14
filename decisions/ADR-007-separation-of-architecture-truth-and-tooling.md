# ADR-007: Separation of Architecture Truth and Tooling Inputs

## Status
Accepted

## Context
There is a distinction between:
- Architectural intent (what the system is)
- Tooling configuration (how diagrams are produced)

Blending these concerns leads to confusion, duplication, and misplaced authority.

## Decision
The following hierarchy is established:

1. **Markdown documents** express architectural intent.
2. **PNG diagrams** visualize that intent.
3. **Structurizr DSL/JSON** exists only to generate diagrams.

Tooling inputs are not considered architectural truth.

## Consequences
- Markdown remains the primary narrative layer.
- Diagrams support, not replace, written architecture.
- Tool churn does not invalidate documentation.

## Notes
This aligns with documentation-first and architecture-as-literature principles.