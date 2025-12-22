---
id: 018
title: ADR-018: Search v0.1 (Local FTS + Re-entry)
date: 2025-12-16
status: Accepted
---

# ADR-018: Search v0.1 (Local FTS + Re-entry)

## Context
SolMobile needs reliable search and re-entry that works offline and does not depend on SolServer.

## Decision
Implement search entirely on-device using SQLite FTS5, with UX features that support re-entry:

- Global search powered by SQLite FTS5
- Results deep-link to the exact `message_id`
- In-thread Find with next, prev, and match count
- Return Stack: when search is invoked inside a thread, provide “Back to where I was”

## Alternatives
- Server-side search (SolServer indexes and queries)
- Defer search until later

## Consequences
- More local database and indexing complexity
- No server cost for search
- Offline and airplane-mode search works
- Navigation and re-entry become first-class, reducing “lost place” frustration

## Notes
Local and offline means on-device SQLite plus FTS5, not SolServer.