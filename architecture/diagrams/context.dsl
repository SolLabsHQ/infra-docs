workspace "SolLabsHQ" "SolMobile v0 architecture diagrams" {

  model {
    user = person "Individual User (Owner)" "Primary user who initiates sessions and explicitly saves memory."

    solMobile = softwareSystem "SolMobile" "Native iOS client for SolOS with local-first threads, explicit memory actions, and cost visibility."
    solServer = softwareSystem "SolServer" "Policy and orchestration runtime enforcing explicit memory and drift controls."
    llm = softwareSystem "Inference Provider (LLM)" "External managed inference service used as a stateless reasoning engine."
    memoryStore = softwareSystem "Memory Store" "Persistent store for user-explicitly saved memories."
    observability = softwareSystem "Observability" "Error tracking and optional tracing for client and server."
    devicePlatform = softwareSystem "iOS Platform" "Device platform hosting SolMobile and local storage."

    user -> solMobile "Uses"
    solMobile -> solServer "Sends requests to" "HTTPS"
    solServer -> llm "Requests inference from" "HTTPS"
    solServer -> memoryStore "Reads and writes explicit memory to" "DB"
    solMobile -> observability "Sends client errors to"
    solServer -> observability "Sends server errors and traces to"
    devicePlatform -> solMobile "Hosts"
  }

  views {
    systemContext solMobile "C1" {
      include *
      autolayout lr
      title "C4 Level 1: System Context"
      description "SolMobile v0 in context with user and external systems."
    }

    styles {
      element "Person" {
        shape person
      }
      element "Software System" {
        shape roundedbox
      }
    }
  }
}
