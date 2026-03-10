# Closure: sdd-parallelism-adr

Start date: 2026-03-10
Close date: 2026-03-10

## Summary

Created ADR 028 documenting the SDD parallelism model: maximum 2 parallel Tasks, file conflict boundary rule (same-file writes must be sequential), and evaluation of bounded-context parallel apply (conditionally feasible under 3 explicit conditions; implementation deferred). CLAUDE.md was confirmed accurate and left unmodified.

## Modified Specs

| Domain | Action | Change |
| ------ | ------ | ------ |
| sdd-parallelism | Created | New master spec at openspec/specs/sdd-parallelism/spec.md — defines parallelism model requirements for the SDD cycle |

## Modified Code Files

- `docs/adr/028-sdd-parallelism-model.md` — new ADR defining the parallelism model
- `docs/adr/README.md` — registered ADR 028 in the index table

## Key Decisions Made

- Maximum 2 parallel Task sub-agents (conservative limit based on observed behavior with spec+design pair)
- File conflict boundary rule: Tasks writing to the same files MUST be sequential; Tasks with non-overlapping file sets MAY run in parallel
- Bounded-context parallel apply is conditionally feasible but implementation deferred to a separate change
- CLAUDE.md Fast-Forward and Apply Strategy sections are accurate as-is; no modification needed

## Lessons Learned

- ADR number was computed at spec-time (026) but had to be adjusted at apply-time to 028 because two ADRs (026, 027) were merged between spec and apply. The tasks.md anticipated this with an explicit note: "verify at apply time by re-counting." This pattern (dynamic ADR numbering) works correctly when the task includes a verification step.

## User Docs Reviewed

NO — this change adds an ADR (internal architectural documentation). It does not add, remove, or rename skills, change onboarding workflows, or introduce new commands visible to users.
