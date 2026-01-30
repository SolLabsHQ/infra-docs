# PR-040 Smoke: Lattice

This document is a runbook for manual smoke testing PR-040 Lattice behavior.

Scope
- Uses only endpoints defined in the PR-040 contract
  - POST /v1/chat
  - POST /v1/memories
  - GET /v1/memories/:id
  - GET /v1/memories
- Keeps outputs content-minimized: IDs, counts, timings, warnings, numeric scores only

Out of scope
- RRF fusion (explicitly deferred)
- Typed-edge traversal (v1)

## Score telemetry

Keep it tight. No query terms. No snippets. No embeddings. Numeric-only per retrieved ID.

### meta.lattice scoring rules
- `scores` is a map keyed by retrieved ID
- Each entry is `{ method, value }`
- `method` values:
  - `fts5_bm25` (lexical ordering signal, lower is better; not normalized)
  - `vec_distance` (vector distance, lower is better)

Example shape:

```json
{
  "meta": {
    "lattice": {
      "status": "hit",
      "retrieval_trace": {
        "memory_ids": ["mem_123", "mem_456"],
        "policy_capsule_ids": ["ADR-030#D6"]
      },
      "scores": {
        "mem_123": { "method": "fts5_bm25", "value": -4.21 },
        "mem_456": { "method": "vec_distance", "value": 0.18 }
      }
    }
  }
}
```

Notes
- `fts5_bm25` values are not comparable across databases or corpus sizes. Treat as ordering only.
- Do not mix lexical and vector scores into one shared threshold.

## LATTICE_OFFLINE badge

### Trigger
Show the badge when:
- `meta.lattice.status == "fail"`

Optional additional triggers:
- `warnings` contains `LATTICE_DB_BUSY`
- `warnings` contains `LATTICE_VEC_LOAD_FAILED`

### Scope
- Dev + staging only
- Controlled by `LATTICE_DEV_BADGE=1`
- Production stays silent (fail-open without UI noise)

## Recording results

After each run, record in `FIXLOG-PR-40-LATTICE.md`:
- environment (local or staging)
- flag values used
- observed `meta.lattice.status`
- observed `counts`, `bytes_total`, `timings_ms`
- observed `warnings`
- observed `scores` keys and methods (not memory text)

## Smoke test scripts

These scripts target only the contract endpoints and are safe to run repeatedly.

### Anchor message requirements
- Use the canonical chat endpoint used by SolMobile (`POST /v1/chat`).
- Capture the server message id from the response header `x-sol-transmission-id` or body `transmissionId`.
- Do not synthesize anchors. If the response lacks a transmission id, treat that as a bug.

### Memory save requirements
- POST /v1/memories requires: `request_id`, `consent`, `thread_id`, `anchor_message_id`, `window`, `memory_kind`.

### A) SolServer local smoke

Save as `solserver/scripts/smoke_lattice_local.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8787}"
USER_ID="${USER_ID:-smoke-user-1}"
RUN_ID="${RUN_ID:-$(date +%s)}"
THREAD_ID="thr_smoke_${RUN_ID}"

echo "BASE_URL=$BASE_URL"

echo
echo "1) Create two anchor messages via POST /v1/chat (capture transmission id)"
CHAT1_HEADERS=$(mktemp)
CHAT1_BODY=$(mktemp)
curl -sS -D "$CHAT1_HEADERS" -o "$CHAT1_BODY" -X POST "$BASE_URL/v1/chat" \
  -H "Content-Type: application/json" \
  -H "x-sol-user-id: $USER_ID" \
  -d '{
    "threadId": "'"$THREAD_ID"'",
    "clientRequestId": "smoke-chat-1-'"$RUN_ID"'",
    "message": "Smoke anchor message 1"
  }'
cat "$CHAT1_BODY" | head -c 800
ANCHOR_ID=$(python3 - "$CHAT1_HEADERS" "$CHAT1_BODY" <<'PY'
import json, re, sys
headers = open(sys.argv[1]).read()
body = open(sys.argv[2]).read()
m = re.search(r'(?im)^x-sol-transmission-id:\\s*(\\S+)\\s*$', headers)
if m:
    print(m.group(1))
else:
    try:
        print(json.loads(body).get("transmissionId", ""))
    except Exception:
        print("")
PY
)
if [ -z "$ANCHOR_ID" ]; then
  echo "ERROR: chat response missing transmission id (header or body)"
  exit 1
fi

CHAT2=$(curl -sS -X POST "$BASE_URL/v1/chat" \
  -H "Content-Type: application/json" \
  -H "x-sol-user-id: $USER_ID" \
  -d '{
    "threadId": "'"$THREAD_ID"'",
    "clientRequestId": "smoke-chat-2-'"$RUN_ID"'",
    "message": "Smoke anchor message 2"
  }'
echo "$CHAT2" | head -c 800

echo
echo "2) Create memory via POST /v1/memories (anchor = transmission id)"
MEM_CREATE_RESP=$(curl -sS -X POST "$BASE_URL/v1/memories" \
  -H "Content-Type: application/json" \
  -H "x-sol-user-id: $USER_ID" \
  -d '{
    "request_id": "smoke-mem-'"$RUN_ID"'",
    "thread_id": "'"$THREAD_ID"'",
    "anchor_message_id": "'"$ANCHOR_ID"'",
    "window": { "before": 6, "after": 6 },
    "memory_kind": "workflow",
    "consent": { "explicit_user_consent": true }
  }')

echo "$MEM_CREATE_RESP"
MEM_ID=$(echo "$MEM_CREATE_RESP" | python3 -c 'import sys,json; print(json.load(sys.stdin)["memory"]["memory_id"])')
echo "memory_id=$MEM_ID"

echo
echo "3) Deref memory by id"
curl -sS "$BASE_URL/v1/memories/$MEM_ID" -H "x-sol-user-id: $USER_ID" | head -c 800
echo

echo
echo "4) List pinned memories"
curl -sS "$BASE_URL/v1/memories?lifecycle_state=pinned&limit=10" -H "x-sol-user-id: $USER_ID" | head -c 800
echo

echo
echo "5) Reminder: verify env flags in the running server process"
echo "LATTICE_ENABLED=${LATTICE_ENABLED:-}"
echo "LATTICE_VEC_ENABLED=${LATTICE_VEC_ENABLED:-}"
echo "LATTICE_VEC_QUERY_ENABLED=${LATTICE_VEC_QUERY_ENABLED:-}"

echo
echo "Done"
```

#### Expected results (local)
- POST /v1/chat
  - returns a transmission id (header `x-sol-transmission-id` or body `transmissionId`)
- POST /v1/memories
  - returns `memory_id`
  - returns `lifecycle_state` (default pinned)
  - returns `evidence_message_ids` and length should be greater than 1 for span saves
- GET /v1/memories/:id
  - returns the same `memory_id`
  - includes `evidence_message_ids`
- GET /v1/memories
  - includes `items[]`
  - includes the newly created memory when `lifecycle_state=pinned`

### B) Staging smoke

Run from `solserver/` repo root. Staging env vars must be set by `./env.staging.local` (or `./.env.staging.local` if that is the local filename).

Save as `solserver/scripts/smoke_lattice_staging.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="./env.staging.local"
if [ ! -f "$ENV_FILE" ]; then
  ENV_FILE="./.env.staging.local"
fi
if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: env.staging.local not found (expected ./env.staging.local or ./.env.staging.local)"
  exit 1
fi
set -a
source "$ENV_FILE"
set +a

BASE_URL="${BASE_URL:-${SOLSERVER_STAGING_HOST:-}}"
if [ -z "$BASE_URL" ]; then
  echo "ERROR: BASE_URL not set (set BASE_URL or SOLSERVER_STAGING_HOST in env.staging.local)"
  exit 1
fi
USER_ID="${USER_ID:-${SOL_TEST_USER_ID:-staging-smoke-user-1}}"
RUN_ID="${RUN_ID:-$(date +%s)}"
THREAD_ID="thr_staging_smoke_${RUN_ID}"
AUTH_HEADERS=()
if [ -n "${SOLSERVER_STAGING_TOKEN:-}" ]; then
  AUTH_HEADERS+=(-H "Authorization: Bearer ${SOLSERVER_STAGING_TOKEN}")
  AUTH_HEADERS+=(-H "x-sol-api-key: ${SOLSERVER_STAGING_TOKEN}")
fi
echo "BASE_URL=$BASE_URL"

echo
echo "1) Create two anchor messages via POST /v1/chat (capture transmission id)"
CHAT1_HEADERS=$(mktemp)
CHAT1_BODY=$(mktemp)
curl -sS -D "$CHAT1_HEADERS" -o "$CHAT1_BODY" -X POST "$BASE_URL/v1/chat" \
  -H "Content-Type: application/json" \
  -H "x-sol-user-id: $USER_ID" \
  "${AUTH_HEADERS[@]}" \
  -d '{
    "threadId": "'"$THREAD_ID"'",
    "clientRequestId": "staging-chat-1-'"$RUN_ID"'",
    "message": "Staging anchor message 1"
  }')
cat "$CHAT1_BODY" | head -c 800
ANCHOR_ID=$(python3 - "$CHAT1_HEADERS" "$CHAT1_BODY" <<'PY'
import json, re, sys
headers = open(sys.argv[1]).read()
body = open(sys.argv[2]).read()
m = re.search(r'(?im)^x-sol-transmission-id:\\s*(\\S+)\\s*$', headers)
if m:
    print(m.group(1))
else:
    try:
        print(json.loads(body).get("transmissionId", ""))
    except Exception:
        print("")
PY
)
if [ -z "$ANCHOR_ID" ]; then
  echo "ERROR: chat response missing transmission id (header or body)"
  exit 1
fi

CHAT2=$(curl -sS -X POST "$BASE_URL/v1/chat" \
  -H "Content-Type: application/json" \
  -H "x-sol-user-id: $USER_ID" \
  "${AUTH_HEADERS[@]}" \
  -d '{
    "threadId": "'"$THREAD_ID"'",
    "clientRequestId": "staging-chat-2-'"$RUN_ID"'",
    "message": "Staging anchor message 2"
  }')
echo "$CHAT2" | head -c 800

echo
echo "2) Create memory (anchor = transmission id)"
MEM_CREATE_RESP=$(curl -sS -X POST "$BASE_URL/v1/memories" \
  -H "Content-Type: application/json" \
  -H "x-sol-user-id: $USER_ID" \
  "${AUTH_HEADERS[@]}" \
  -d '{
    "request_id": "staging-mem-'"$RUN_ID"'",
    "thread_id": "'"$THREAD_ID"'",
    "anchor_message_id": "'"$ANCHOR_ID"'",
    "window": { "before": 6, "after": 6 },
    "memory_kind": "workflow",
    "consent": { "explicit_user_consent": true }
  }')

echo "$MEM_CREATE_RESP"
MEM_ID=$(echo "$MEM_CREATE_RESP" | python3 -c 'import sys,json; print(json.load(sys.stdin)["memory"]["memory_id"])')
echo "memory_id=$MEM_ID"

echo
echo "3) Deref memory by id"
curl -sS "$BASE_URL/v1/memories/$MEM_ID" -H "x-sol-user-id: $USER_ID" "${AUTH_HEADERS[@]}" | head -c 800
echo

echo
echo "4) List pinned memories"
curl -sS "$BASE_URL/v1/memories?lifecycle_state=pinned&limit=10" -H "x-sol-user-id: $USER_ID" "${AUTH_HEADERS[@]}" | head -c 800
echo

echo
echo "5) Record flags used for this run"
echo "LATTICE_ENABLED=${LATTICE_ENABLED:-}"
echo "LATTICE_VEC_ENABLED=${LATTICE_VEC_ENABLED:-}"
echo "LATTICE_VEC_QUERY_ENABLED=${LATTICE_VEC_QUERY_ENABLED:-}"

echo
echo "Done"
```

#### Expected results (staging)
Same as local, plus:
- `meta.lattice` is present on chat responses (always-on)
- `timings_ms` includes lattice and model timings (direct comparison)

## Flag matrix test plan

Run the smoke scripts and one chat-path request (see next section) under these configurations.
Record each run in FIXLOG.

### Case A: Vector fully disabled
- `LATTICE_VEC_ENABLED=0`
- `LATTICE_VEC_QUERY_ENABLED=0`
Expected:
- retrieval remains lexical
- `warnings` includes a vec-disabled code if implemented

### Case B: Vector loads but is not queried
- `LATTICE_VEC_ENABLED=1`
- `LATTICE_VEC_QUERY_ENABLED=0`
Expected:
- extension load succeeds
- retrieval remains lexical
- no `vec_distance` score entries

### Case C: Vector queried
- `LATTICE_VEC_ENABLED=1`
- `LATTICE_VEC_QUERY_ENABLED=1`
Expected:
- vector query path executes
- `scores` includes at least one `vec_distance` entry when a hit occurs

## Chat-path validation

Canonical chat endpoint: `POST /v1/chat` (same route SolMobile uses). If this changes, update this runbook and scripts; do not substitute other paths.

Chat-path behavior is validated by:
- `lattice_retrieval.test.ts` integration test (POST /v1/memories then next chat retrieval)

For manual chat validation, use the repo’s canonical chat endpoint and verify:
- `meta.lattice` exists on every response
- `meta.lattice.status` is `hit|miss|fail`
- `retrieval_trace.memory_ids[]` are dereferenceable via GET /v1/memories/:id
- `scores` are numeric-only when present
- `timings_ms` includes lattice and model timings
