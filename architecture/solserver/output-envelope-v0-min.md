# Output Envelope v0-min

## Client-Visible Surface Table

| Endpoint | Behavior |
| --- | --- |
| `POST /v1/chat` | 200 responses include `assistant` and `outputEnvelope` with `assistant_text` matching `assistant`. On 422 failures, `outputEnvelope` is omitted. `outputEnvelope` is success-only. |
| `GET /v1/transmissions/:id` | Always returns `assistant` from `chat_results` (may be a stub on failures). Error details are surfaced via `attempts[].error`. |

## Acceptance Criteria

- [ ] 200 responses include `assistant` and `outputEnvelope` with `assistant_text` matching `assistant`.
- [ ] 422 responses omit `outputEnvelope` (success-only invariant).
