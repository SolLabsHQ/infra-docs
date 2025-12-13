workspace "SolLabsHQ" "SolMobile v0 container view diagrams" {

  model {
    user = person "Individual User (Owner)" "Primary user who initiates sessions and explicitly saves memory."

    solMobileSystem = softwareSystem "SolMobile" "Native iOS client for SolOS with local-first threads and explicit memory actions."
    solServerSystem = softwareSystem "SolServer" "API and policy runtime enforcing budgets, retrieval caps, and explicit memory rules."

    iosApp = container solMobileSystem "SolMobile iOS App" "Swift iOS app" "Captures input, shows responses, stores local threads with TTL, and triggers explicit memory saves."
    localStore = container solMobileSystem "Local Thread Store" "On-device storage" "Stores threads and messages locally with TTL cleanup and pinning."

    api = container solServerSystem "SolServer API" "Node.js service in container" "Validates requests, enforces budgets, performs retrieval, routes inference, persists explicit memories, returns usage and audit fields."
    postgres = container solServerSystem "Fly Postgres" "PostgreSQL" "Stores explicit memory objects and minimal metadata."

    llm = softwareSystem "Inference Provider (LLM)" "External managed inference service."
    observability = softwareSystem "Observability" "Error tracking and optional tracing."

    objectStore = softwareSystem "Object Store (Future)" "Cloudflare R2 or equivalent" "Stores attachments and large objects when needed."

    user -> iosApp "Uses"
    iosApp -> localStore "Reads and writes threads to"
    iosApp -> api "Calls" "HTTPS"
    api -> llm "Requests inference from" "HTTPS"
    api -> postgres "Reads and writes explicit memory to" "DB"
    iosApp -> observability "Sends client errors to"
    api -> observability "Sends server errors and traces to"
    api -> objectStore "Stores and retrieves attachments from" "HTTPS"
  }

  views {
    container solMobileSystem "C2-SolMobile" {
      include *
      autolayout lr
      title "C4 Level 2: Containers"
      description "SolMobile and SolServer containers and their relationships."
    }

    styles {
      element "Person" {
        shape person
      }
      element "Software System" {
        shape roundedbox
      }
      element "Container" {
        shape roundedbox
      }
    }
  }
}
