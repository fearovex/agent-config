# Closure: tech-skill-auto-activation

Start date: 2026-03-03
Close date: 2026-03-03

## Summary

Added Step 0 — Technology Skill Preload to `skills/sdd-apply/SKILL.md`. The step reads `ai-context/stack.md` (primary) or `openspec/config.yaml project.stack` (secondary), matches detected technology keywords against an inline Stack-to-Skill Mapping Table (21 entries covering all catalog skills), reads matching skill files into implementation context before Step 1, and produces a detection report. Includes a scope guard that skips preload for documentation-only changes. Fully non-blocking. The `## Code standards` forward reference was updated to point to Step 0. ADR-017 documenting the inline mapping table convention was pre-created by the sdd-ff agent.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| `sdd-apply` | Created | New master spec for Technology Skill Auto-Activation (Step 0, Stack-to-Skill Mapping Table, Detection Report, Backward Compatibility) |

## Modified Code Files

- `skills/sdd-apply/SKILL.md` — Step 0 inserted before Step 1; Stack-to-Skill Mapping Table embedded (21 rows); `## Code standards` forward reference updated
- `docs/adr/017-tech-skill-mapping-table-inline-convention.md` — pre-created by sdd-ff agent
- `docs/adr/README.md` — ADR-017 row pre-added by sdd-ff agent
- `ai-context/changelog-ai.md` — entry appended by sdd-apply agent

## Key Decisions Made

- **Inline mapping table** (ADR-017): The Stack-to-Skill Mapping Table is embedded directly in `sdd-apply/SKILL.md` rather than in a shared config file. This makes the skill self-contained and deployable in isolation. It introduces a cross-cutting convention: any new technology skill added to the catalog MUST also add a row to this mapping table.
- **Case-insensitive substring matching**: Robust to version-annotated entries (e.g., `"React 19"` still matches `"react"`). `react native`/`expo` rows placed before `react` to prevent short-keyword false positives.
- **Non-blocking design**: Consistent with the TDD detection step (Step 2). Missing `ai-context/stack.md` or absent skill files degrade gracefully to INFO notes, never to `blocked` or `failed`.
- **Scope guard based on file-extension analysis**: The design.md file change matrix is already available at apply time. Checking for `.md`/`.yaml`-only extensions is reliable and requires no extra configuration.
- **Placement before Step 1**: Technology context must be available before the implementer reads specs and design. Loading inside Step 4 would be too late and inconsistent across tasks.

## Lessons Learned

No deviations from the design. The scope guard implementation detail (default to `scope_guard_triggered = false` when `design.md` is absent) was noted in the verify-report as a safe default — no action needed. The design mapping table includes `github-pr`, `jira-task`, and `jira-epic` as entries; these are process/tooling skills unlikely to match via `stack.md` in practice but included per the exhaustive coverage requirement.

## User Docs Reviewed

N/A — pre-dates this requirement (verify-report.md does not contain the User Docs checkbox).
