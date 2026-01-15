workspace "SolLabsHQ" "SolMobile v0 container view diagrams" {

  model {
    user = person "Individual User (Owner)" "Primary user who initiates sessions and explicitly saves memory."

    solMobileSystem = softwareSystem "SolMobile" "Native iOS client for SolOS with local-first threads and explicit memory actions."
    solServerSystem = softwareSystem "SolServer" "API and policy runtime enforcing budgets, retrieval caps, and explicit memory rules." {
        tags "SolServer"
    }

    iosApp = container solMobileSystem "SolMobile iOS App" "Swift iOS app" "Captures input, shows responses, stores local threads with TTL, and triggers explicit memory saves."
    localStore = container solMobileSystem "Local Thread Store" "On-device storage" "Stores threads and messages locally with TTL cleanup and pinning."

    api = container solServerSystem "API" "The public-facing API for SolServer, handling all incoming requests." "Node.js / HTTPS" {
        tags "Container"
    }
    controlPlaneDb = container solServerSystem "Control Plane DB" "Persistence for transmissions, traces, and evidence." "SQLite" {
        tags "Database"
    }

    llm = softwareSystem "Inference Provider (LLM)" "External managed inference service."
    observability = softwareSystem "Observability" "Error tracking and optional tracing."

    user -> iosApp "Uses"
    iosApp -> localStore "Reads and writes threads to"
    iosApp -> api "Calls" "HTTPS"
    api -> llm "Requests inference from" "HTTPS"
    api -> controlPlaneDb "Reads/Writes operational data" "File I/O"
    iosApp -> observability "Sends client errors to"
    api -> observability "Sends server errors and traces to"
  }

  views {
    container solServerSystem "C2_ContainerView_Updated" {
      include *
      autolayout lr
      title "C2: Container View (v0 Current State)"
      description "SolServer containers and their relationships, reflecting the post-PR#19 state."
    }

    styles {
      element "Person" { shape person }
      element "Software System" { shape roundedbox }
      element "Container" { shape roundedbox }
      element "Database" { shape cylinder }
    }
  }
}
