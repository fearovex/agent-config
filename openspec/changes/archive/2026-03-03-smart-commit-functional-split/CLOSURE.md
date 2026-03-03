# Closure: smart-commit-functional-split

Start date: 2026-03-03
Close date: 2026-03-03

## Summary

Extended the `smart-commit` skill to analyze staged files by functional area and propose separate, semantically grouped commits instead of always committing everything as a single block. A priority-ordered grouping heuristic (test → config/infra → docs → directory prefix → misc) clusters staged files; a single-group result falls through to the existing single-commit flow unchanged.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| smart-commit | Created | New master spec at `openspec/specs/smart-commit/spec.md` — SR-01 through SR-09 defining file grouping, per-group message generation, single-group fast-path, multi-commit plan presentation, sequential execution, error blocking, no-omission invariant, backward compatibility, and partial-execution surfacing |

## Modified Code Files

- `skills/smart-commit/SKILL.md` — inserted Step 1b (group staged files by priority-ordered heuristic), inserted Step 1c (multi-commit plan generation and presentation), extended Step 5 (sequential per-group commit execution with "commit all", "step-by-step", "abort remaining" paths), updated Rules section (9 rules total)

## Key Decisions Made

- **Grouping heuristic placement**: new Step 1b inserted between existing Step 1 and Step 2, keeping all commit logic in one skill file. The hook remains context-injection only.
- **Priority order (spec-authoritative)**: test(1) → config/infra(2) → docs(3) → directory prefix(4) → misc fallback. Note: design.md table transposed docs/config-infra — implementation and spec are correct; design.md has documentation drift.
- **Single-group fast-path**: grouping producing exactly one group falls through to existing Steps 2–5 unchanged — zero regression risk for focused commits.
- **Multi-commit plan shown in full before first commit fires**: allows clean abort before any side effect.
- **Sequential execution only**: no parallel commits; partial execution after first commit fires is surfaced but not rolled back (out of scope per proposal).
- **No external dependencies**: SKILL.md only change; hook and settings.json untouched.
- **Error blocking scope**: any ERROR in any group halts the entire plan; WARNINGs are non-blocking and displayed in the plan summary.

## Lessons Learned

- The verify-report found a priority-order transposition in design.md (docs and config/infra swapped in the data-flow table). The SKILL.md and spec.md are correct; design.md has minor documentation drift. Tracked as WARNING-01 in the verify-report. Recommended follow-up: correct design.md or note in ADR README.
- All 11 tasks completed in a single session with no blocking issues. The self-contained nature of SKILL.md changes (no code, no build, no migration) made for a clean cycle.

## User Docs Reviewed

N/A — pre-dates this requirement. The checkbox was absent from the verify-report.
