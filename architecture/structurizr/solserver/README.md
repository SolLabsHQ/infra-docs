# SolServer Structurizr Workspace

This directory contains the Structurizr DSL workspace for SolServer v0, providing C4 model diagrams and dynamic views of the system architecture.

## Current State

This workspace reflects the **post-PR#19 state** of SolServer, including:

- Evidence intake pipeline (PR #5, #7, #7.1)
- Gates pipeline framework (PR #16)
- Trace infrastructure with flag-only responses (PR #16)
- Driver Blocks post-linter (PR #17)
- Driver Blocks enforcement with retry (PR #18)
- Output Envelope v0-min validation (PR #19)

## Views Included

### Static Views

| View | Level | Description |
| :--- | :--- | :--- |
| **C1_SystemContext** | System Context | High-level view of SolServer and its interactions with users and other systems |
| **C2_ContainerView** | Container | Shows the containers within the SolServer system |
| **C3_ComponentView** | Component | Shows the components within the API container and their interactions |
| **C4_ControlPlane** | Component Detail | A closer look at the components that make up the Control Plane |

### Dynamic Views

| View | Description |
| :--- | :--- |
| **D1_SuccessTurn** | A detailed walkthrough of a successful, single-attempt chat turn |
| **D2_RetryFlow** | Shows the two-attempt retry flow when a driver block violation occurs |
| **D3_AsyncTurn** | Illustrates the flow for a simulated (simulate=true) request |

## How to View

### Using Structurizr Lite (Recommended)

Run Structurizr Lite with Docker and mount this directory:

```bash
cd /path/to/infra-docs/architecture/structurizr/solserver
docker run --rm -it \
  -p 8080:8080 \
  -v "$(pwd):/usr/local/structurizr" \
  structurizr/lite
```

Then open: http://localhost:8080

### Using Structurizr Cloud

Upload the `workspace.dsl` file to your Structurizr Cloud workspace.

## Updating the Diagrams

As new PRs are completed, update this workspace to reflect the current state of the system. The diagrams should always mirror the canonical architecture documents in `infra-docs/architecture/`.

### Update Process

1. **After each PR merge**, review the changes and identify new components or relationships.
2. **Update the DSL** to add or modify elements in the model.
3. **Add dynamic views** if new flows are introduced.
4. **Update this README** to reflect the new state.
5. **Commit and push** the changes to the repository.

## Design Rules

- Diagrams must not contradict the corresponding architecture markdown files.
- If the system boundary or trust boundary changes, update the markdown and add an ADR first.
- Diagrams should stay minimal and readable.
- Use hierarchical identifiers for clarity.

## Component Mapping

The following table maps the components in the diagrams to their corresponding source files in the codebase:

| Component | Source File(s) |
| :--- | :--- |
| **Chat Endpoint** | `src/routes/chat.ts` |
| **Control Plane** | `src/control-plane/router.ts`, `src/control-plane/prompt_pack.ts`, `src/control-plane/driver_blocks.ts`, `src/control-plane/evidence.ts` |
| **Gates Pipeline** | `src/gates/gates_pipeline.ts`, `src/gates/post_linter.ts` |
| **Control Plane Store** | `src/store/control_plane_store.ts`, `src/store/sqlite_control_plane_store.ts` |

## Future Work

The following features are planned but not yet implemented:

- Placeholder gates (Normalize, Intent/Risk, Lattice)
- Driver Blocks input-side (bounds, ordering, prompt assembly)
- LLM-driven evidence generation

As these features are implemented, the diagrams will be updated to reflect the new components and flows.
