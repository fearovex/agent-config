# Technical Design: audit-and-analyze-capabilities

Date: 2026-02-28
Proposal: openspec/changes/audit-and-analyze-capabilities/proposal.md

## General Approach

Four independent, low-risk edits to existing files that reconcile documentation with implementation reality and add missing user guidance. No behavioral changes — only spec corrections, one table row addition, one CLAUDE.md guidance section, and one known-issues entry. Each change is isolated and can be applied or reverted independently.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Where to place "When to use which" guidance | New subsection under `## Project Memory` in CLAUDE.md | Separate `ai-context/skill-overlap.md` file; Add to each skill's SKILL.md | CLAUDE.md is read at session start and is the single point of reference for command selection. A separate file would be missed; adding to each skill creates duplication. |
| How to fix spec marker format (GAP-7) | Update spec to match SKILL.md format (`<!-- [auto-updated]: section-id -- last run: YYYY-MM-DD -->`) | Update SKILL.md to match spec | The SKILL.md is the runtime artifact and the existing `ai-context/` files already use its format. Changing the spec is zero-risk; changing the SKILL.md would require re-running project-analyze on all projects. |
| How to fix spec creation behavior (GAP-2) | Remove the scenario claiming project-analyze creates files when absent; add a note that it defers to memory-init | Modify SKILL.md to actually create files | The SKILL.md rule 4 ("NEVER creates ai-context/ if it does not exist") is intentional. The spec was aspirational and never matched the implementation. |
| Where to add conventions.md support in memory-manager | Add a row to the existing Step 2 decision table | Add a new Step 4.5 between architecture and known-issues; Create a separate conventions update step | The decision table already determines which files to update. Adding a row is the minimal, consistent change. No new process step needed. |
| How to document marker-awareness limitation | Single entry in `ai-context/known-issues.md` | Add warnings to memory-manager and project-update SKILL.md files | known-issues.md is the canonical location for documented limitations. Adding warnings to skills would clutter their process sections for a theoretical risk. |

## Data Flow

No new data flows are introduced. The existing flow is unchanged:

```
/project-analyze  ──produces──►  analysis-report.md  ──consumed by──►  /project-audit (D7)
        │
        └──updates──►  ai-context/{stack,architecture,conventions}.md
                        (only [auto-updated] sections)

/memory-update  ──updates──►  ai-context/{stack,architecture,conventions,known-issues,changelog-ai}.md
                              (incremental, full-file — NOT marker-aware)

/project-update ──updates──►  ai-context/stack.md (Case A)
                              CLAUDE.md (Case B)
```

The known-issues entry documents the overlap zone where `/memory-update` and `/project-update` write to the same files as `/project-analyze` without marker awareness.

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `openspec/specs/project-analysis/spec.md` | Modify | (1) Remove the "First run creates [auto-updated] sections when ai-context/ files are absent" scenario (lines 156-162) and replace with a scenario stating project-analyze skips ai-context/ updates when the directory is absent and instructs user to run /memory-init. (2) Update the `[auto-updated]` marker format in Part 2 (lines 233-234) from `<!-- [auto-updated] start: <section-name> -->` / `<!-- [auto-updated] end: <section-name> -->` to `<!-- [auto-updated]: <section-id> -- last run: YYYY-MM-DD -->` / `<!-- [/auto-updated] -->`. |
| `skills/memory-manager/SKILL.md` | Modify | Add one row to the Step 2 decision table (after line 213): `Conventions were defined/changed` → `conventions.md`. Also add a Step 4b (between current Step 4 and Step 5) for updating conventions.md with a brief description of what to update (naming patterns, import styles, code patterns changed during session). |
| `CLAUDE.md` | Modify | Insert a new subsection `### Skill Overlap — When to Use Which` between the Project Memory file table (line 277) and the session-start instruction (line 279). Content: 4-row table mapping each command to its purpose and typical timing. |
| `ai-context/known-issues.md` | Modify | Append a new entry (before the final `---` or at end of file) titled "ai-context/ marker-awareness gap between skills" documenting that memory-manager and project-update are not aware of [auto-updated] markers written by project-analyze, with a description of when this matters and when it does not. |

## Interfaces and Contracts

No new interfaces. All changes are documentation edits. The existing contracts remain:

- `analysis-report.md` format (consumed by D7): unchanged
- `[auto-updated]` marker format: unchanged in implementation, corrected in spec only
- `ai-context/` file ownership: unchanged (documented as a known limitation, not enforced)

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Integration | Run `/project-audit` after all changes to verify score >= previous | `/project-audit` skill |
| Manual | Read each modified file and verify against proposal success criteria | Human review |
| Manual | Verify the spec marker format now matches the actual `ai-context/` file markers | Diff comparison |

No automated tests exist for skills (documented in known-issues.md). Verification is via `/project-audit` score and manual review of the 6 success criteria from the proposal.

## Migration Plan

No data migration required. All changes are documentation/configuration edits. No runtime artifacts are modified.

## Open Questions

None. All four changes are well-defined by the proposal and exploration artifacts. The scope is deliberately minimal (Approach A from the exploration).
