# ADR-008: SolMobile Offline-First and iOS OS-Level Integrations

## Status
Accepted

## Context
SolMobile v0 is a personal-scale iOS client focused on capture, interaction, and explicit memory actions.
The user experience must remain reliable under weak connectivity, airplane mode, or server downtime.

iOS provides OS-level capabilities that can reduce custom backend work, improve reliability, and enable automation:
- On-device storage
- Background execution windows
- Shortcuts and App Intents
- Widgets
- Notifications
- System sharing and file providers

We also anticipate future optional sync and multi-device support.

## Decision
SolMobile will be built offline-first with local persistence as the default.

### Local-first rules
- Threads and messages are stored on device.
- TTL cleanup applies to non-pinned items.
- Pinning is explicit and user-controlled.
- “Save to memory” is an explicit action that results in a server write.
- The app remains usable without the server for reading, searching local threads, and drafting.

### iOS integration posture
We will prioritize OS-level capabilities before building custom equivalents:
- App Intents and Shortcuts for capture and automation
- Widgets for quick capture and status
- BackgroundTasks for scheduled maintenance and uploads when allowed
- Notifications for reminders and system prompts
- Share sheet capture for text and attachments
- Optional future: CloudKit or equivalent sync for user-controlled cross-device continuity

## Consequences
- Higher reliability and lower perceived latency.
- Clear separation between local context and server memory.
- More complex client state management, but more resilience.
- Server becomes an enhancement and policy layer, not a single point of failure.

## Notes
This decision aligns with explicit memory, user agency, and cost control.