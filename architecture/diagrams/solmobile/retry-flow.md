# Retry Flow (SolMobile) — v0.1

**Purpose:** Document the user-driven retry path for a failed `Transmission` so UI, outbox processing, and server outcomes are captured in a drift-resistant way.

## Mermaid (Sequence) — failed → retry → queued → send → pending/success/failure

```mermaid
sequenceDiagram
  autonumber
  participant U as User
  participant TDV as ThreadDetailView
  participant TA as TransmissionActions
  participant SD as SwiftData
  participant TX as Transmission
  participant T as ChatTransport
  participant SV as SolServer

  note over TX: Transmission.status == failed\nlastError != nil

  U->>TDV: Tap Retry
  TDV->>TA: retryFailed(transmission)
  TA->>SD: Clear lastError
  TA->>SD: tx.status = queued
  TA->>SD: Save

  TDV->>TA: processOutbox()

  TA->>SD: Fetch queued tx
  TA->>SD: tx.status = sending
  TA->>T: send(envelope)

  alt Pending (202)
    T->>SV: POST /v1/chat
    SV-->>T: 202 + transmissionId
    T-->>TA: pending=true
    TA->>SD: recordAttempt(pending)
    TA->>SD: tx.status = queued
  else Success (200)
    T->>SV: POST /v1/chat
    SV-->>T: 200 + assistant
    TA->>SD: recordAttempt(succeeded)
    TA->>SD: append assistant message
    TA->>SD: tx.status = succeeded
  else Failure
    T--x TA: error
    TA->>SD: recordAttempt(failed)
    TA->>SD: tx.status = failed
  end

  TA->>SD: Save
```

## Mermaid (Flowchart) — status transitions

```mermaid
flowchart TD
  A[Transmission failed] --> B[User taps Retry]
  B --> C[retryFailed]
  C --> D[Clear lastError]
  D --> E[tx.status = queued]
  E --> F[processOutbox]

  F --> G[send or poll]
  G --> H{Result}
  H -- success --> I[tx.status = succeeded]
  H -- pending --> J[tx.status = queued]
  H -- failure --> K[tx.status = failed]
```