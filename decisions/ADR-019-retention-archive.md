---
id: 019
title: ADR-019: Retention, TTL, Pinning, and Optional Cold Archive
date: 2025-12-16
status: Accepted
---

# ADR-019: Retention, TTL, Pinning, and Optional Cold Archive

## Context
SolMobile will accumulate data. Without explicit retention rules, storage grows unpredictably and trust erodes. Attachments create the primary storage pressure. We need clear user control and scalable behavior while keeping local-first as the default.

## Decision
Adopt a retention system with these components:

### Retention and control
- TTL for on-device content, with user-configurable defaults
- Pinning overrides TTL (pinned content is retained)
- Attachments treated as the primary storage driver, with offload hooks

### Maintenance
- BackgroundTasks maintenance hooks for:
  - FTS optimize
  - DB compaction and vacuum strategy
  - Cache cleanup

### Optional cold archive (v1.0 capability)
- Optional encrypted iCloud cold archive for older threads and blobs
  - CryptoKit encryption
  - iCloud Drive app container storage
- Local Archive Catalog for discoverability
- “Search iCloud archive” appears at end of search results when online
- On-demand fetch and decrypt per thread

## Alternatives
- Unlimited local retention
- Mandatory server archive and search
- iCloud archive without encryption

## Consequences
- Additional plumbing and background maintenance work
- Predictable storage behavior with user control
- Scales without making SolServer a dependency
- Clear separation between local canonical store and optional cold archive

## Notes
Archive is optional. The local on-device store remains canonical.