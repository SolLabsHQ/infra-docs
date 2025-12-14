workspace "SolLabsHQ" "SolMobile v0 C4 diagrams" {

    !identifiers hierarchical

    model {
        user = person "End User" "A human user interacting with SolMobile on a personal device."

        solMobile = softwareSystem "SolMobile" "Native iOS client for a personal AI operating interface with explicit memory and drift control." {
            mobileApp = container "iOS App" "Native iOS client for SolMobile" "Swift / SwiftUI"
        }

        solServer = softwareSystem "SolServer" "Backend policy/runtime: routing, budgets, drift controls, and explicit memory APIs." {
            api = container "SolServer API" "Containerized API + policy enforcement layer" "Node.js / HTTPS"
            memoryDb = container "Memory Store" "Explicit memory persistence" "PostgreSQL"
        }

        inferenceProvider = softwareSystem "Inference Provider" "External managed LLM service used as a stateless reasoning engine."
        observability = softwareSystem "Observability" "Error tracking and optional tracing for client and server."

        user -> solMobile "Uses" "HTTPS"
        user -> solMobile.mobileApp "Interacts with UI" "iOS Touch Interface"

        solMobile.mobileApp -> solServer.api "Calls API" "HTTPS/JSON"
        solServer.api -> solServer.memoryDb "Reads/Writes explicit memory" "SQL"
        solServer.api -> inferenceProvider "Requests inference" "HTTPS"
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
            element Database {
                shape Cylinder
            }
            relationship * {
                thickness 4
            }
        }
    } 
}