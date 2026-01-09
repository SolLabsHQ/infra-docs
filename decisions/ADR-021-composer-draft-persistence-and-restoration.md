# ADR-021: Composer Draft Persistence and Restoration

- Status: Proposed
- Date: 2026-01-04
- Deciders: SolMobile maintainers
- Context: SolMobile v0.x UX reliability

## Context
Users compose long messages in the thread composer. Drafts can be lost when the app backgrounds, is terminated by the OS, or crashes. Draft loss breaks trust and discourages deep use, especially for long-form journaling and multi-paragraph prompts.

SolMobile is local-first; we can store drafts locally and restore them when a thread is reopened.

## Decision
Implement single-draft persistence per thread (v0 → v0.1):
- Autosave drafts locally using debounced saves while typing.
- Force-save on background transitions.
- Restore the draft automatically when reopening the same thread.
- Delete the draft on successful send, or when user discards/clears it.

Draft restore will be simple and low-friction:
- v0: silent restore into composer.
- v0.1: show a small "Recovered draft" banner with a Discard action.

We will NOT implement multiple drafts per thread in v0.x.

## Details
### Data model
DraftRecord:
- draft_id (UUID)
- thread_id (UUID)
- content (String)
- updated_at (Date)
- cursor_start / cursor_end (optional)
- last_sent_message_id (optional)

### Save triggers
- Debounced autosave on text change (e.g., 700ms).
- Immediate save on scene background/resign active.
- Delete record when content becomes empty (trimmed).

### Restore behavior
On thread open:
- restore DraftRecord into composer if newer than last sent state (if tracked).
- v0.1: show non-blocking banner with Discard.

### Cleanup rules
- On send success: delete DraftRecord.
- On send failure: keep DraftRecord.

## Consequences
### Positive
- Prevents draft loss and increases trust in long-form composition.
- Matches local-first ethos; no dependency on cloud or model providers.
- Minimal UI complexity; mostly invisible to the user.

### Negative / trade-offs
- Requires local persistence and lifecycle handling.
- Potential for confusion if stale drafts reappear; mitigated by last-sent tracking + discard action.
- Cursor/selection restore may be imperfect across text mutations; treat as best-effort.

## Alternatives considered
1) Do nothing: relies on iOS app state; not reliable across termination/crash.
2) Multiple drafts per thread: more power but higher UX complexity; deferred.
3) Cloud-sync drafts: adds privacy and complexity; deferred.

## Notes / follow-ups
- Add lightweight local observability counters (no content telemetry).
- Consider file protection settings for stored drafts.
- Consider future: attachment draft persistence, cross-device sync, multiple drafts (only if justified by usage data).