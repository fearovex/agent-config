# Task Plan: audit-and-analyze-capabilities

Date: 2026-02-28
Design: openspec/changes/audit-and-analyze-capabilities/design.md

## Progress: 9/10 tasks

## Phase 1: Spec Reconciliation

- [x] 1.1 Modify `openspec/specs/project-analysis/spec.md` — remove the "First run creates `[auto-updated]` sections when `ai-context/` files are absent" scenario and replace it with a scenario stating that project-analyze skips ai-context/ updates when the directory is absent and instructs the user to run `/memory-init`
- [x] 1.2 Modify `openspec/specs/project-analysis/spec.md` — update the `[auto-updated]` marker format in Part 2 from `<!-- [auto-updated] start: <section-name> -->` / `<!-- [auto-updated] end: <section-name> -->` to `<!-- [auto-updated]: <section-id> -- last run: YYYY-MM-DD -->` / `<!-- [/auto-updated] -->`
- [x] 1.3 Modify `openspec/specs/project-analysis/spec.md` — update Out of Scope item 8 to remove the trailing clause "though it will create files if they are absent" and instead state that it defers to `/memory-init` for first-time creation

## Phase 2: Memory-Manager Extension

- [x] 2.1 Modify `skills/memory-manager/SKILL.md` — add a `conventions.md` row to the `/memory-update` Step 2 decision table with trigger "coding patterns, naming conventions, or import styles changed during the session" and action to update `ai-context/conventions.md`
- [x] 2.2 Modify `skills/memory-manager/SKILL.md` — add a Step 4b (between current architecture update step and known-issues step) for updating `ai-context/conventions.md` with naming patterns, import styles, and code patterns changed during the session; include guidance to preserve `[auto-updated]` marker boundaries

## Phase 3: CLAUDE.md Guidance Section

- [x] 3.1 Modify `CLAUDE.md` — insert a new subsection `### Skill Overlap — When to Use Which` between the Project Memory file table and the session-start instruction, containing a 4-row table with columns Command | Purpose | When to use, covering `/memory-init`, `/project-analyze`, `/memory-update`, and `/project-update`; include a note that project-analyze complements memory-manager but does not replace it; keep under 20 lines

## Phase 4: Known-Issues Documentation

- [x] 4.1 Modify `ai-context/known-issues.md` — add an entry titled "ai-context/ marker-awareness gap between skills" documenting that `memory-manager` and `project-update` are not aware of `[auto-updated]` markers written by `project-analyze`, listing affected files (`stack.md`, `architecture.md`, `conventions.md`), explaining the risk is theoretical and not observed in practice, and referencing Approach B (per-section ownership model) as a deferred future solution

## Phase 5: Verification and Cleanup

- [ ] 5.1 Run `/project-audit` on claude-config to verify score >= previous score
- [x] 5.2 Run `install.sh` to deploy updated skills and CLAUDE.md to `~/.claude/`

---

## Implementation Notes

- All four changes are documentation/configuration edits — no behavioral changes to any skill
- The SKILL.md files are the source of truth; specs are updated to match them, not the other way around
- The `[auto-updated]` marker format to use is: `<!-- [auto-updated]: <section-id> -- last run: YYYY-MM-DD -->` / `<!-- [/auto-updated] -->`
- When adding the conventions.md step to memory-manager, preserve the existing step numbering style and decision table format
- The CLAUDE.md guidance section must reference commands by name (e.g., `/project-analyze`), not by file path
- Phase 1 tasks (1.1, 1.2, 1.3) all modify the same file and should be applied together in one pass to avoid merge conflicts

## Blockers

None.
