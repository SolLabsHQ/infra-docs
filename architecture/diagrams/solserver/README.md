# SolServer Architecture Diagrams (PNG)

This directory contains rendered PNG versions of the SolServer C4 architecture diagrams.

## Diagrams

| File | Description |
| :--- | :--- |
| `c1_system_context.png` | C4 Level 1: System Context showing SolServer in the ecosystem |
| `c2_container_view.png` | C4 Level 2: Container View showing API and Control Plane DB |
| `c3_component_view.png` | C4 Level 3: Component View showing internal API components |
| `d1_success_turn.png` | Dynamic View: Successful sync chat turn (11 steps) |
| `d2_retry_flow.png` | Dynamic View: Driver Block enforcement with retry (8 steps) |
| `d3_async_turn.png` | Dynamic View: Async turn with polling (8 steps) |

## Source

These diagrams are rendered from the Structurizr DSL workspace located at:

`architecture/structurizr/solserver/workspace.dsl`

## Updating

When the workspace is updated, regenerate these PNGs using the Mermaid source files in the repository or by exporting from Structurizr Lite.

## Current State

These diagrams reflect the **post-PR#19 state** of SolServer, including:

- Evidence intake pipeline
- Gates pipeline framework
- Trace infrastructure with flag-only responses
- Driver Blocks post-linter and enforcement
- Output Envelope v0-min validation
