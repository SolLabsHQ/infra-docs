workspace "SolLabsHQ" "SolMobile v0 C4 diagrams" {

    !identifiers hierarchical

    model {
        user = person "End User" "A human user interacting with SolMobile on a personal device."

        solServer = softwareSystem "SolServer" "Backend policy/runtime: routing, budgets, drift controls, and explicit memory APIs." {
            memoryDb = container "Memory Store" "Explicit memory persistence" "PostgreSQL"
            api = container "SolServer API" "Containerized API + policy enforcement layer" "Node.js / HTTPS" {
                auth = component "AuthN/AuthZ" "Authentication, authorization, and step-up hooks (future)." "Node.js"
                chatEndpoint = component "Chat Endpoint" "Implements POST /v1/chat; validates Packet/Transmission and budgets." "Node.js"
                policyEngine = component "Policy Engine" "Applies routing/budgets/drift controls; gates calls and shapes context." "Node.js"
                retrievalService = component "Retrieval Service" "Selects memory summaries for injection (domain-scoped, capped)." "Node.js"
                inferenceClient = component "Inference Client" "Calls external LLM provider as stateless inference." "HTTPS"
                memoryService = component "Memory Service" "Explicit memory save/list APIs." "Node.js"
                usageService = component "Usage Service" "Token/cost accounting and daily rollups." "Node.js"

                chatEndpoint -> auth "Checks" "in-proc"
                chatEndpoint -> policyEngine "Evaluates" "in-proc"
                policyEngine -> retrievalService "Requests retrieval" "in-proc"
                policyEngine -> inferenceClient "Requests inference" "HTTPS"
                policyEngine -> usageService "Records usage" "in-proc"

                memoryService -> auth "Checks" "in-proc"
                memoryService -> solServer.memoryDb "Reads/Writes" "SQL"
                retrievalService -> solServer.memoryDb "Reads summaries" "SQL"
                usageService -> solServer.memoryDb "Writes rollups" "SQL"
            }
        }

        solMobile = softwareSystem "SolMobile" "Native iOS client for a personal AI operating interface with explicit memory and drift control." {
            mobileApp = container "iOS App" "Native iOS client for SolMobile" "Swift / SwiftUI" {
                uiShell = component "UI Shell" "Tabs, navigation, and top-level routing." "SwiftUI"
                threadStore = component "Thread Store" "Creates/lists Threads; pinning/TTL metadata; last-active tracking." "Swift"
                messageStore = component "Message Store" "Stores Messages for a Thread; append/read/query." "Swift"
                captureProcessor = component "Capture Processor" "Processes Captures (transcribe/extract/fetch) and updates Capture records." "Swift"
                anchorStore = component "Anchor Store" "Stores Anchors that reference Messages." "Swift"
                checkpointStore = component "Checkpoint Store" "Stores Checkpoints (capsules) for Threads." "Swift"
                transmissionStore = component "Transmission Store" "Offline-first Transmission store queue; retry via DeliveryAttempts." "Swift"
                solServerClient = component "SolServer Client" "HTTP client for SolServer (/v1/chat, /v1/memories, /v1/usage)." "HTTPS/JSON"
                preferencesStore = component "Preferences Store" "User Preferences (budgets/toggles)." "Swift"
                environment = component "Environment" "Runtime configuration (endpoints, build flags, diagnostics)." "Swift"

                uiShell -> threadStore "Reads/writes" "in-proc"
                uiShell -> messageStore "Reads/writes" "in-proc"
                uiShell -> anchorStore "Reads/writes" "in-proc"
                uiShell -> checkpointStore "Reads/writes" "in-proc"
                uiShell -> preferencesStore "Reads/writes" "in-proc"
                uiShell -> environment "Reads" "in-proc"

                messageStore -> captureProcessor "Processes pending Captures" "in-proc"
                messageStore -> transmissionStore "Enqueue Transmission + Packet" "in-proc"
                transmissionStore -> solServerClient "Sends Transmissions" "in-proc"
                solServerClient -> messageStore "Appends assistant Message" "in-proc"

                solServerClient -> solServer.api.chatEndpoint "Calls /v1/chat" "HTTPS/JSON"
                solServerClient -> solServer.api.memoryService "Calls /v1/memories" "HTTPS/JSON"
                solServerClient -> solServer.api.usageService "Calls /v1/usage" "HTTPS/JSON"
            }
        }

        solServer.api.chatEndpoint -> solMobile.mobileApp.solServerClient "Responds" "HTTPS/JSON"

        inferenceProvider = softwareSystem "Inference Provider" "External managed LLM service used as a stateless reasoning engine."
        observability = softwareSystem "Observability" "Error tracking and optional tracing for client and server."

        user -> solMobile "Uses" "HTTPS"
        user -> solMobile.mobileApp.uiShell "Interacts with UI" "iOS Touch Interface"

        solMobile.mobileApp -> solServer.api "Calls API" "HTTPS/JSON"
        solServer.api -> solServer.memoryDb "Reads/Writes explicit memory" "SQL"
        solServer.api -> inferenceProvider "Requests inference" "HTTPS"
        solServer.api.inferenceClient -> inferenceProvider "Requests inference" "HTTPS"
        solMobile.mobileApp -> observability "Sends client errors" "HTTPS"
        solServer.api -> observability "Sends server errors" "HTTPS"
    }

    views {
        systemContext solMobile "C1" {
            include user
            include solMobile
            include solServer
            include inferenceProvider
            include observability
            autolayout lr
        }

        container solMobile "C2" {
            include user
            include solMobile.mobileApp
            include solServer
            include solServer.api
            autolayout lr
        }

        container solServer "C3" {
            include solServer.api
            include solServer.memoryDb
            include solMobile
            include solMobile.mobileApp
            include inferenceProvider
            include observability
            autolayout lr
        }

        component solMobile.mobileApp "C4-SolMobile" {
            include user
            include *
            include solServer.api
            include solServer.api.auth
            include solServer.api.chatEndpoint
            include solServer.api.policyEngine
            include solServer.api.retrievalService
            include solServer.api.inferenceClient
            include solServer.api.memoryService
            include solServer.api.usageService
            autolayout lr
        }

        component solServer.api "C4-SolServerAPI" {
            include *
            include solServer.memoryDb
            include inferenceProvider
            include observability
            autolayout lr
        }

        dynamic solMobile.mobileApp "D1-ChatTurn" {
            title "Chat turn: Packet → ModeDecision → Prompt → Inference"
            description "Client creates a Message, enqueues a Transmission+Packet, sends /v1/chat, server applies control plane (mode+gates), may read/write explicit memory, calls inference, and returns an assistant message."

            user -> solMobile.mobileApp.uiShell "Interacts with UI" "iOS Touch Interface"
            solMobile.mobileApp.uiShell -> solMobile.mobileApp.messageStore "Reads/writes" "in-proc"
            solMobile.mobileApp.messageStore -> solMobile.mobileApp.transmissionStore "Enqueue Transmission + Packet" "in-proc"
            solMobile.mobileApp.transmissionStore -> solMobile.mobileApp.solServerClient "Sends Transmissions" "in-proc"
            solMobile.mobileApp.solServerClient -> solServer.api.chatEndpoint "Calls /v1/chat" "HTTPS/JSON"

            solServer.api.chatEndpoint -> solServer.api.policyEngine "Evaluates" "in-proc"
            solServer.api.policyEngine -> solServer.api.retrievalService "Requests retrieval" "in-proc"
            solServer.api.retrievalService -> solServer.memoryDb "Reads summaries" "SQL"

            solServer.api.policyEngine -> solServer.api.inferenceClient "Requests inference" "HTTPS"
            solServer.api.inferenceClient -> inferenceProvider "Requests inference" "HTTPS"

            solServer.api.policyEngine -> solServer.api.usageService "Records usage" "in-proc"
            solServer.api.usageService -> solServer.memoryDb "Writes rollups" "SQL"

            solServer.api.chatEndpoint -> solMobile.mobileApp.solServerClient "Responds" "HTTPS/JSON"

            solMobile.mobileApp.solServerClient -> solMobile.mobileApp.messageStore "Appends assistant Message" "in-proc"

            autolayout lr
        }

        dynamic solMobile.mobileApp "D2-TransmissionRetry" {
            title "Transmission retry: DeliveryAttempts"
            description "Transmission Store retries sending a Transmission; each send attempt is recorded as a DeliveryAttempt (modeled as internal state). requestId provides idempotency server-side."

            solMobile.mobileApp.transmissionStore -> solMobile.mobileApp.solServerClient "Sends Transmissions" "in-proc"
            solMobile.mobileApp.solServerClient -> solServer.api.chatEndpoint "Calls /v1/chat" "HTTPS/JSON"
            solServer.api.chatEndpoint -> solMobile.mobileApp.solServerClient "Responds" "HTTPS/JSON"

            solMobile.mobileApp.transmissionStore -> solMobile.mobileApp.solServerClient "Sends Transmissions" "in-proc"
            solMobile.mobileApp.solServerClient -> solServer.api.chatEndpoint "Calls /v1/chat" "HTTPS/JSON"
            solServer.api.chatEndpoint -> solMobile.mobileApp.solServerClient "Responds" "HTTPS/JSON"

            autolayout lr
        }

        dynamic solMobile.mobileApp "D3-SelectorEscalation" {
            title "Selector escalation: ambiguous routing"
            description "When deterministic routing is low-confidence, SolServer performs an extra inference pass to select ModeDecision before generating the final assistant response. (Two inference calls shown in order.)"

            solMobile.mobileApp.solServerClient -> solServer.api.chatEndpoint "Calls /v1/chat" "HTTPS/JSON"
            solServer.api.chatEndpoint -> solServer.api.policyEngine "Evaluates" "in-proc"

            solServer.api.policyEngine -> solServer.api.inferenceClient "Requests inference" "HTTPS"
            solServer.api.inferenceClient -> inferenceProvider "Requests inference" "HTTPS"

            solServer.api.policyEngine -> solServer.api.inferenceClient "Requests inference" "HTTPS"
            solServer.api.inferenceClient -> inferenceProvider "Requests inference" "HTTPS"

            solServer.api.chatEndpoint -> solMobile.mobileApp.solServerClient "Responds" "HTTPS/JSON"
            autolayout lr
        }

        styles {
            element Person {
                shape Person
            }
            element "Software System" {
                shape RoundedBox
            }
            element Container {
                shape RoundedBox
            }
            element Component {
                shape RoundedBox
            }
            element Database {
                shape Cylinder
            }
            relationship * {
                thickness 4
            }
        }
    } 
}