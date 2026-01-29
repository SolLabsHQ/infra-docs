# PR #39 (SSE-01) Release Review Bundle

## PR links
- infra-docs: https://github.com/SolLabsHQ/infra-docs/pull/18
- solserver: https://github.com/SolLabsHQ/solserver/pull/39
- solmobile: https://github.com/SolLabsHQ/solmobile/pull/32

## Merge order
1) infra-docs
2) solserver
3) solmobile

## Staging inline processing note
Staging verification was completed with `SOL_INLINE_PROCESSING=1` because worker-emitted SSE events do not reach API-held SSE connections under the in-memory hub.

Post-merge revert (staging only):
```
flyctl secrets unset SOL_INLINE_PROCESSING -a solserver-staging
# (or) flyctl secrets set SOL_INLINE_PROCESSING=0 -a solserver-staging
```

## Deferred items (v0.1)
- RedisHub cross-process fanout (worker → SSE connections)
- Reconnect soak test + memory profile (Fly staging)
- Last-Event-ID replay/catch-up
