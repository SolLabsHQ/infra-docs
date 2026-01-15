workspace "SolLabsHQ" "SolMobile v0 architecture diagrams" {

  model {
    user = person "Individual User (Owner)" "Primary user who initiates sessions and explicitly saves memory."

    solMobile = softwareSystem "SolMobile" "Native iOS client for SolOS with local-first threads, explicit memory actions, and cost visibility."
    solServer = softwareSystem "SolServer" "Policy and orchestration runtime enforcing explicit memory and drift controls." {
        tags "SolServer"
    }
    llm = softwareSystem "Inference Provider (LLM)" "External managed inference service used as a stateless reasoning engine."
    observability = softwareSystem "Observability" "Error tracking and optional tracing for client and server."

    user -> solMobile "Uses"
    solMobile -> solServer "Sends requests to" "HTTPS"
    solServer -> llm "Requests inference from" "HTTPS"
    solMobile -> observability "Sends client errors to"
    solServer -> observability "Sends server errors and traces to"
  }

  views {
    systemContext solServer "C1_SystemContext_Updated" {
      include *
      autolayout lr
      title "C1: System Context (v0 Current State)"
      description "SolServer in context with SolMobile, the user, and external systems, reflecting the post-PR#19 state."
    }

    styles {
      element "Person" { shape person }
      element "Software System" { shape roundedbox }
    }
  }
}
