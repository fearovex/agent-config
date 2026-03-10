# Closure: codebase-teach-skill

Start date: 2026-03-10
Close date: 2026-03-10

## Summary

Created the `codebase-teach` skill — a new meta-tool that analyzes project bounded contexts, extracts domain knowledge from source code, writes structured `ai-context/features/<context>.md` files, and produces a `teach-report.md` with coverage metrics. Registered the skill in CLAUDE.md and deployed via install.sh.

## Modified Specs

| Domain | Action | Change |
| ------ | ------ | ------ |
| codebase-teach | Created | New domain spec defining all 7 requirements and 19 scenarios for the skill |

## Modified Code Files

- `skills/codebase-teach/SKILL.md` — new skill (Steps 0–4, Rules, Output)
- `CLAUDE.md` — `/codebase-teach` added to Available Commands and Skills Registry

## Key Decisions Made

- **Context detection via directory heuristics** (depth ≤ 2 under `src/`, `app/`, `features/`, `domain/`, `openspec/specs/`): consistent with `project-analyze` approach; no AST parsing required in a Markdown skill.
- **Sequential processing** of bounded contexts: prevents context window saturation; each context is self-contained.
- **Configurable file cap** (`teach_max_files_per_context`, default 10): prevents overflow on large codebases; configurable per project via `openspec/config.yaml`.
- **`[auto-updated]` marker preservation**: consistent with the `project-analyze` convention already used in `ai-context/stack.md`, `ai-context/architecture.md`, `ai-context/conventions.md`. Human-authored content outside markers is preserved byte-for-byte.
- **`_template.md` guard**: any file beginning with `_` in `ai-context/features/` is excluded from reads and writes at all steps.
- **Manual-only invocation**: `codebase-teach` is never auto-triggered by any other skill — user-initiated command only.

## Lessons Learned

- Step 0 non-blocking pattern (established by sdd-project-context-awareness) was cleanly applicable here: load context opportunistically without blocking on missing files.
- The six-section feature file format from `_template.md` maps naturally to the signal types extractable by code inspection (rules, invariants, entities, integrations, decisions, gotchas).
- Full `/project-audit` run was deferred to the next interactive session; structural compliance confirmed by code inspection.

## User Docs Reviewed

N/A — no `scenarios.md`, `quick-reference.md`, or `onboarding.md` exist in this repo. CLAUDE.md is the canonical command reference and was updated as part of the change.
