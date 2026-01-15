workspace "SolLabsHQ" "SolServer v0 C4 diagrams" {

    !identifiers hierarchical

    model {
        user = person "End User" "A human user interacting with SolMobile on a personal device."

        solMobile = softwareSystem "SolMobile" "Native iOS client for a personal AI operating interface with explicit memory and drift control."
        inferenceProvider = softwareSystem "Inference Provider" "External managed LLM service used as a stateless reasoning engine."
        observability = softwareSystem "Observability" "Error tracking and optional tracing for client and server."

        solServer = softwareSystem "SolServer" "Backend policy/runtime: routing, budgets, drift controls, and explicit memory APIs." {
            tags "SolServer"

            api = container "API" "The public-facing API for SolServer, handling all incoming requests." "Node.js / HTTPS" {
                tags "Container"

                chatEndpoint = component "Chat Endpoint" "Implements POST /v1/chat and GET /transmissions/:id. Orchestrates the entire request lifecycle." "Node.js" {
                    tags "Component"
                }

                controlPlane = component "Control Plane" "Core logic for message processing, including routing, prompt assembly, and policy enforcement." "Node.js" {
                    tags "Component"
                }

                gates = component "Gates Pipeline" "Runs pre-processing validation and enrichment on incoming messages." "Node.js" {
                    tags "Component"
                }

                store = component "Control Plane Store" "Persistence layer for all operational data, including transmissions, traces, and evidence." "SQLite" {
                    tags "Component" "Database"
                }
            }

            user -> solMobile "Uses"
            solMobile -> api "Sends requests to" "HTTPS"
            api -> inferenceProvider "Requests inference from" "HTTPS"
            api -> observability "Sends errors and traces to" "HTTPS"

            api.chatEndpoint -> api.controlPlane "Delegates to"
            api.controlPlane -> api.gates "Executes"
            api.controlPlane -> api.store "Reads/Writes"
            api.controlPlane -> inferenceProvider "Requests inference from"
        }
    }

    views {
        // C1: System Context
        systemContext solServer "C1_SystemContext" {
            include *
            autolayout lr
            title "C1: System Context for SolServer"
            description "High-level view of SolServer and its interactions with users and other systems."
        }

        // C2: Container View for SolServer
        container solServer "C2_ContainerView" {
            include *
            autolayout lr
            title "C2: Container View for SolServer"
            description "Shows the containers within the SolServer system."
        }

        // C3: Component View for the API Container
        component solServer.api "C3_ComponentView" {
            include *
            autolayout lr
            title "C3: Component View for the API Container"
            description "Shows the components within the API container and their interactions."
        }

        // C4: Detailed Component View for the Control Plane
        component solServer.api.controlPlane "C4_ControlPlane" {
            include *
            autolayout lr
            title "C4: Detailed View of the Control Plane"
            description "A closer look at the components that make up the Control Plane."
        }

        styles {
            element "Person" { shape Person }
            element "Software System" { shape RoundedBox; background #1168bd; color #ffffff; }
            element "Container" { shape RoundedBox; background #438dd5; color #ffffff; }
            element "Component" { shape RoundedBox; background #85bbf0; color #000000; }
            element "Database" { shape Cylinder; background #85bbf0; color #000000; }
        }
    }
}


        // Dynamic View 1: Successful Sync Chat Turn
        dynamic solServer.api "D1_SuccessTurn" {
            title "D1: Successful Sync Chat Turn"
            description "A detailed walkthrough of a successful, single-attempt chat turn."

            solMobile -> solServer.api.chatEndpoint "1. POST /v1/chat"
            solServer.api.chatEndpoint -> solServer.api.store "2. Create TraceRun"
            solServer.api.chatEndpoint -> solServer.api.gates "3. Execute Gates"
            solServer.api.chatEndpoint -> solServer.api.controlPlane "4. Route Mode & Process Evidence"
            solServer.api.controlPlane -> solServer.api.controlPlane "5. Assemble Prompt Pack"
            solServer.api.controlPlane -> inferenceProvider "6. Request Inference (Attempt 0)"
            inferenceProvider -> solServer.api.controlPlane "7. Return Raw Output"
            solServer.api.controlPlane -> solServer.api.controlPlane "8. Validate Output Envelope"
            solServer.api.controlPlane -> solServer.api.gates "9. Run Post-Linter"
            solServer.api.controlPlane -> solServer.api.store "10. Persist Results"
            solServer.api.chatEndpoint -> solMobile "11. Return 200 OK with Envelope"

            autolayout lr
        }

        // Dynamic View 2: Driver Block Enforcement with Retry
        dynamic solServer.api "D2_RetryFlow" {
            title "D2: Driver Block Enforcement with Retry"
            description "Shows the two-attempt retry flow when a driver block violation occurs."

            solServer.api.controlPlane -> inferenceProvider "1. Request Inference (Attempt 0)"
            inferenceProvider -> solServer.api.controlPlane "2. Return Raw Output"
            solServer.api.controlPlane -> solServer.api.gates "3. Post-Linter finds violation"
            solServer.api.controlPlane -> solServer.api.controlPlane "4. Add Correction to Prompt"
            solServer.api.controlPlane -> inferenceProvider "5. Request Inference (Attempt 1)"
            inferenceProvider -> solServer.api.controlPlane "6. Return New Output"
            solServer.api.controlPlane -> solServer.api.gates "7. Post-Linter passes"
            solServer.api.controlPlane -> solServer.api.store "8. Persist Results"

            autolayout lr
        }

        // Dynamic View 3: Async Chat Turn with Polling
        dynamic solServer.api "D3_AsyncTurn" {
            title "D3: Async Chat Turn with Polling"
            description "Illustrates the flow for a simulated (simulate=true) request."

            solMobile -> solServer.api.chatEndpoint "1. POST /v1/chat (simulate=true)"
            solServer.api.chatEndpoint -> solServer.api.store "2. Create Transmission"
            solServer.api.chatEndpoint -> solMobile "3. Return 202 Accepted"
            note over solServer.api "Background Job"
            solServer.api.chatEndpoint -> solServer.api.controlPlane "4. Execute Full Turn (as in D1)"
            solServer.api.controlPlane -> solServer.api.store "5. Persist Final Results"
            solMobile -> solServer.api.chatEndpoint "6. GET /transmissions/:id"
            solServer.api.chatEndpoint -> solServer.api.store "7. Read Results"
            solServer.api.chatEndpoint -> solMobile "8. Return 200 OK with Results"

            autolayout lr
        }
