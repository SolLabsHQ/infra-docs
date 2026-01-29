# PR 40 Fixlog: Lattice v0 + v0.1 + vector flagged

## Summary
- (fill after implementation)

## infra-docs changes
- [ ] ADR-030 updated:
  - [ ] meta.lattice always present
  - [ ] critical constraints not dependent on lattice retrieval
  - [ ] scoring semantics separated for lexical vs vector
- [ ] Lattice v0 doc updated (if touched)

## solserver changes
Memory API
- [ ] POST /v1/memories span save
- [ ] GET /v1/memories list
- [ ] GET /v1/memories/:id detail
- [ ] memory lifecycle_state column + filters

Lattice gate
- [ ] hybrid trigger rules
- [ ] caps enforcement
- [ ] injection into PromptPack retrieval section only

meta.lattice + trace
- [ ] meta.lattice always present
- [ ] gate_lattice trace event emitted
- [ ] explicit timings added (db, lattice total, model total, request total)

sqlite-vec
- [ ] vec0.so packaged in image
- [ ] loadExtension wired behind LATTICE_VEC_ENABLED
- [ ] vector queries behind LATTICE_VEC_QUERY_ENABLED
- [ ] CI smoke test added
- [ ] fail-open behavior verified

## solmobile changes
- [ ] cache memory_ids and dereference
- [ ] memory list + detail UI wiring
- [ ] ghost card 👍 accept
- [ ] auto-accept setting

## Known issues / deferred
- [ ] RRF fusion (lex + vec)
- [ ] policy capsule UI rendering beyond IDs
- [ ] multi-instance storage upgrade path (Turso/libSQL)
