# Proposal: audit-and-analyze-capabilities

Date: 2026-02-28
Status: Draft

## Intent

Eliminate documented spec-vs-SKILL.md contradictions and add missing user guidance so that the audit, analyze, and memory skills work together without confusion or silent data conflicts.

## Motivation

The exploration (Approach A) identified 12 gaps across project-audit, project-analyze, memory-manager, and project-update. The most impactful are:

- **Spec contradictions** (GAP-2, GAP-7): The project-analysis spec claims project-analyze creates ai-context/ files when absent; the SKILL.md explicitly forbids this. The spec also uses a different auto-updated marker format than what actually runs. These contradictions will cause verification failures and mislead future skill authors.
- **Missing conventions.md support** (GAP-1): `/memory-update` has no mechanism to record convention changes, leaving a dead zone in the memory layer.
- **No "when to use which" guidance** (GAP-9, GAP-12): Three skills write to ai-context/ files with overlapping capabilities. Users have no documented guidance on which command to run and when.
- **Undocumented marker-awareness limitation** (GAP-3, GAP-4): memory-manager and project-update are unaware of `[auto-updated]` markers, creating a theoretical data-corruption risk that should be acknowledged.

## Scope

### Included

1. **Fix spec-SKILL.md misalignments** — Update `openspec/specs/project-analysis/spec.md` to match the SKILL.md on two points: (a) project-analyze never creates ai-context/ directory (GAP-2), (b) correct the auto-updated marker format to `<!-- [auto-updated]: section-id — last run: YYYY-MM-DD -->` (GAP-7)
2. **Add conventions.md to memory-manager update list** — Add a row to the `/memory-update` step table in `skills/memory-manager/SKILL.md` with trigger: "coding patterns, naming conventions, or import styles changed during the session" (GAP-1)
3. **Add "When to use which skill" guidance** — Add a clear guidance section to CLAUDE.md explaining the distinct purposes of `/project-analyze`, `/memory-update`, `/project-update`, and `/memory-init`, and document that project-analyze complements memory-manager but does not replace it (GAP-9, GAP-12)
4. **Add known-issues entry for marker-awareness gap** — Document in `ai-context/known-issues.md` that memory-manager and project-update are not aware of `[auto-updated]` markers, and that running them after project-analyze could theoretically overwrite marker boundaries (GAP-3, GAP-4)

### Excluded (explicitly out of scope)

- **Approach B (ownership model)** — Defining per-section ownership of ai-context/ files is deferred to a future change if marker conflicts are observed in practice
- **Approach C (merge skills)** — Merging memory-manager into project-analyze is a major refactor deferred indefinitely
- **Modifying project-update skill behavior** — project-update is not changed; only documentation is added
- **Adding new skills or commands** — No new commands are introduced
- **Score changes in project-audit** — Audit dimensions and scoring remain unchanged
- **Modifying project-analyze SKILL.md** — The SKILL.md is the source of truth; only the spec is updated to match it

## Proposed Approach

Four independent documentation/configuration changes, all low-risk:

1. **Spec reconciliation**: Edit the project-analysis spec to remove the "creates ai-context/ files when absent" scenario and replace the marker format examples with the actual format used by the SKILL.md.
2. **Memory-manager extension**: Add one row to the existing update-decision table in memory-manager's SKILL.md. No process flow changes.
3. **CLAUDE.md guidance section**: Add a new section titled "Skill Overlap — When to Use Which" in the Project Memory area of CLAUDE.md. This is a documentation-only addition that helps users choose the right command.
4. **Known-issues documentation**: Add a single entry to `ai-context/known-issues.md` describing the marker-awareness limitation with a clear description of when it matters and when it does not.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `openspec/specs/project-analysis/spec.md` | Modified | Medium — fixes two contradictions |
| `skills/memory-manager/SKILL.md` | Modified | Low — adds one table row |
| `CLAUDE.md` | Modified | Low — adds guidance section |
| `ai-context/known-issues.md` | Modified | Low — adds one entry |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Spec update introduces new inconsistency | Low | Medium | Cross-check every changed line against SKILL.md before finalizing |
| CLAUDE.md guidance section becomes stale as skills evolve | Medium | Low | Keep it concise and reference skill names, not line numbers |
| Memory-manager conventions.md row triggers unexpected updates | Low | Low | Use conservative trigger wording ("coding patterns changed") so it only fires when relevant |

## Rollback Plan

All changes are documentation/configuration edits to four files. Rollback is a simple `git revert` of the commit. No runtime behavior changes, no new files created, no scripts modified.

Specific rollback steps:
1. `git revert <commit-hash>` — reverts all four file changes
2. Run `install.sh` to redeploy the previous versions to `~/.claude/`
3. Verify with `/project-audit` that score is unchanged

## Dependencies

- Exploration artifact must exist: `openspec/changes/audit-and-analyze-capabilities/exploration.md` (completed)
- No other active changes to the four affected files

## Success Criteria

- [ ] `openspec/specs/project-analysis/spec.md` no longer claims project-analyze creates ai-context/ when absent
- [ ] `openspec/specs/project-analysis/spec.md` uses the correct auto-updated marker format matching the SKILL.md
- [ ] `skills/memory-manager/SKILL.md` has a `conventions.md` row in the `/memory-update` decision table
- [ ] `CLAUDE.md` contains a "When to use which" guidance section distinguishing project-analyze, memory-update, project-update, and memory-init
- [ ] `ai-context/known-issues.md` documents the marker-awareness limitation (GAP-3/GAP-4)
- [ ] `/project-audit` score is >= previous score after all changes

## Effort Estimate

Low (1-2 hours). Four targeted edits to existing files, no new files, no behavioral changes.
