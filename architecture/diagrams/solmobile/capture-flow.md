sequenceDiagram
  autonumber
  participant U as User
  participant TDV as ThreadDetailView
  participant SD as SwiftData (ModelContext)
  participant MSG as Message (@Model)
  participant TA as TransmissionActions
  participant PK as Packet
  participant TX as Transmission

  U->>TDV: Type message + Tap Send
  TDV->>SD: Create Message\ncreator=user\nthreadId=current
  TDV->>SD: Append Message to Thread.messages
  TDV->>SD: Save (local persistence)

  note over TDV,SD: UI optimism boundary\n(message exists even if network fails)

  TDV->>TA: enqueueChat(thread, message)
  TA->>SD: Create Packet\n(packetType=chat)\nmessageIds=[msgId]
  TA->>SD: Create Transmission\n(status=queued)\npacket=Packet
  TA->>SD: Save

  TDV->>TA: processOutbox()

  flowchart TD
  A[User types message] --> B[Tap Send]
  B --> C[Create Message (SwiftData)]
  C --> D[Append to Thread]
  D --> E[Save local state]
  E --> F[enqueueChat()]
  F --> G[Create Packet]
  G --> H[Create Transmission(status=queued)]
  H --> I[processOutbox()]