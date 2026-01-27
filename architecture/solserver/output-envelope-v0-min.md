# Output Envelope v0-min

## Client-Visible Surface Table

| Endpoint | Behavior |
| --- | --- |
| `POST /v1/chat` | Canonical OutputEnvelope for v0 chat. 200 responses include `assistant` and `outputEnvelope` with `assistant_text` matching `assistant`. On 422 failures, `outputEnvelope` is omitted. `outputEnvelope` is success-only. |
| `GET /v1/transmissions/:id` | Always returns `assistant` from `chat_results` (may be a stub on failures). Error details are surfaced via `attempts[].error`. |

## PR10 delta
- Optional field: `outputEnvelope.meta.journalOffer` (present only when an offer is eligible).
- Client gating is label-only: SolMobile must not recompute fidelity/directness; Ascend uses server labels.
- Legacy alias normalization: accept `ghost_type` and normalize to `ghost_kind` before strict validation.

## Notes
- `schema/v0/output_envelope.schema.json` is legacy/experimental and not used for v0 `/v1/chat` responses.

## Acceptance Criteria

- [ ] 200 responses include `assistant` and `outputEnvelope` with `assistant_text` matching `assistant`.
- [ ] 422 responses omit `outputEnvelope` (success-only invariant).
