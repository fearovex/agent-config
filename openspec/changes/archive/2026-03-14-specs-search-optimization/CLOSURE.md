# Closure: specs-search-optimization

Start date: 2026-03-14
Close date: 2026-03-14

## Summary

Introduced a lightweight spec index at `openspec/specs/index.yaml` (55 entries) enabling targeted, keyword-driven spec file selection by sub-agents — replacing blind file listing or exhaustive loading. Updated `sdd-archive` to maintain the index when new domain specs are created, documented the lookup algorithm in `docs/SPEC-CONTEXT.md`, and recorded the SQLite/FTS5 migration path in ADR 034.

## Modified Specs

| Domain | Action | Change |
| -------- | ---------------------- | ------------- |
| sdd-archive-execution | Modified (requirement added) | New requirement: sdd-archive maintains spec index when a new domain spec is created |
| spec-index | Created (new domain) | Full spec for openspec/specs/index.yaml structure, correctness invariants, and sub-agent selection algorithm |

## Modified Code Files

- `openspec/specs/index.yaml` — created (55-entry flat YAML spec index)
- `skills/sdd-archive/SKILL.md` — Step 3a added (index maintenance on new domain creation)
- `docs/SPEC-CONTEXT.md` — "Using the spec index" section added
- `docs/adr/034-specs-search-optimization-architecture.md` — created (SQLite/FTS5 migration path, ADR status: Proposed)
- `openspec/specs/sdd-archive-execution/spec.md` — requirement appended (index maintenance)
- `openspec/specs/spec-index/spec.md` — created (new master spec)
- `openspec/specs/index.yaml` — entry for `spec-index` domain appended (Step 3a self-application)

## Key Decisions Made

- **Flat YAML index over SQLite (for now)**: The index is a single `index.yaml` file maintained manually by `sdd-archive`. SQLite/FTS5 migration is documented in ADR 034 as a future option triggered at 100+ domains.
- **3-file hard cap preserved**: Index-based selection respects the existing cap — sub-agents load at most 3 spec files per phase invocation.
- **Non-blocking index maintenance**: All index read/write failures in `sdd-archive` are WARNING-level only and never block archive completion.
- **sdd-archive self-applies Step 3a**: When archiving this change, the new `spec-index` domain was appended to `index.yaml` automatically per the Step 3a contract (index entry count: 55 → 56).

## Lessons Learned

- Hand-authoring 55 entries is feasible in one pass and produces a high-quality keyword set. Future domains are handled by sdd-archive automatically.
- The delta spec for `sdd-archive-execution` required an alignment fix mid-cycle (Option B: create minimal `index.yaml` when absent) after verify caught a spec/SKILL.md mismatch — demonstrates the value of the verify phase.

## User Docs Reviewed

NO — this change adds an internal spec index and updates sdd-archive behavior. It does not add, remove, or rename user-facing skills, does not change onboarding workflows, and introduces no new slash commands. No update to `scenarios.md`, `quick-reference.md`, or `onboarding.md` is needed.
