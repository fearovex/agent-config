# Proposal: project-claude-organizer-cleanup-after-migrate

Date: 2026-03-04
Status: Draft

## Intent

Add a post-migration cleanup step to `project-claude-organizer` that offers to delete source files from `.claude/<category>/` after each category is successfully migrated, with explicit user confirmation required before any deletion.

## Motivation

The `project-claude-organizer` skill successfully migrates files from legacy `.claude/` directories to their SDD-aligned destinations (`ai-context/`, `openspec/`, `docs/`, etc.). However, source files are never removed after migration, leaving the original `.claude/` directories intact and still containing their original content. This defeats the purpose of the reorganization: after "migrating" all plans, docs, and requirements, the `.claude/` folder looks the same as before the skill ran.

Without cleanup, users must manually delete the source directories — a tedious, error-prone step that is easy to forget. The result is a `.claude/` folder that remains structurally non-canonical even after the organizer runs successfully.

## Scope

### Included

- Post-migration cleanup prompt per category: after successful migration of a category, ask "Delete source files from `.claude/<category>/`? (yes/no)"
- Deletion only for strategies that perform actual file writes: `copy`, `append`, `scaffold`, `user-choice`
- Per-category confirmation gate: deletion requires explicit user confirmation AFTER successful migration
- Partial-migration handling: when some files in a category were skipped (destination-exists), clearly enumerate which files WILL be deleted vs. which were skipped, then confirm
- Report enhancement: add "Deleted from .claude/" subsection recording all deleted paths
- Update to the description field in SKILL.md frontmatter to reflect the new behavior

### Excluded (explicitly out of scope)

- Deletion for `delegate` strategy (`commands/`): advisories were issued only — no actual migration occurred, so nothing to clean up
- Deletion for `section-distribute` strategy (`project.md`, `readme.md`): sections were appended to destinations but the source file may contain other sections not distributed; deleting would cause data loss
- Deletion without user confirmation: the invariant "no deletion without explicit user confirmation AND successful prior migration" is unbreakable
- Recursive deletion of source directories (only the individual migrated files are deleted, not the parent directory itself, unless it is then empty — and even then, directory removal is not in scope for V1)
- Batch "delete all" shortcut across all categories: each category gets its own deletion prompt
- Rollback of deletions: once confirmed, deletions are permanent

## Proposed Approach

After each category finishes its migration operations in Step 5.7, inject a new sub-step that:

1. Checks whether any files in the category were successfully migrated (at least one `applied` outcome, zero `failed` outcomes)
2. If yes: presents the user with the list of files that were successfully migrated and would be deleted, and a separate list of skipped files that would NOT be deleted
3. Prompts: `Delete source files from .claude/<category>/? (yes/no)`
4. If confirmed: deletes only the successfully migrated source files; records each deletion in the report
5. If declined or if there were no successes: records the skip in the report

The new deletion logic is injected as a sub-step (e.g., 5.7.1-cleanup, 5.7.3-cleanup, etc.) appended immediately after each applicable strategy sub-step. The `delegate` (5.7.1) and `section-distribute` (5.7.2) sub-steps are excluded.

The report section "Legacy migrations" is extended with a "Deleted from .claude/" subsection.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/project-claude-organizer/SKILL.md` — Step 5.7 (all applicable sub-steps) | Modified — add cleanup sub-steps after 5.7.3, 5.7.4, 5.7.5, 5.7.6, 5.7.7 | Medium |
| `skills/project-claude-organizer/SKILL.md` — Step 6 (report format) | Modified — add "Deleted from .claude/" subsection | Low |
| `skills/project-claude-organizer/SKILL.md` — frontmatter description | Modified — remove "Never deletes" language, replace with new invariant | Low |
| `skills/project-claude-organizer/SKILL.md` — Rules section | Modified — replace Rule 2 invariant language | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| User accidentally confirms deletion of files that weren't fully migrated | Low | High | Only offer deletion when ALL selected files in the category have `applied` status; failed files are excluded from the deletion list |
| User confirms deletion of a partial migration (some files skipped) | Medium | Medium | Present two explicit lists: "will be deleted" vs. "will be preserved (skipped)"; require confirmation only after seeing both lists |
| Deletion of source files that contain content not captured in the migration (e.g. `project.md` edge cases) | Low | Medium | `section-distribute` strategy is fully excluded from deletion; no other strategy risks this because full file copies/appends capture all content |
| Skill description becomes inaccurate if update is partial | Low | Low | Update frontmatter description and Rules section in the same change |

## Rollback Plan

If the cleanup step causes issues:

1. The source files that were deleted cannot be recovered from the skill alone — users should rely on version control (`.claude/` should be git-tracked in the project).
2. To revert the skill itself: restore `skills/project-claude-organizer/SKILL.md` to the previous committed version via `git checkout HEAD~1 -- skills/project-claude-organizer/SKILL.md`.
3. Run `install.sh` to redeploy the reverted skill to `~/.claude/`.
4. The deleted source files in the project's `.claude/` can be recovered from git if the project has version control: `git checkout HEAD -- .claude/<category>/`.

## Dependencies

- The existing `project-claude-organizer` skill (Step 5.7 and all sub-steps) must be fully understood before modifying — this proposal was written with complete knowledge of the current SKILL.md.
- No other skills depend on the `Never deletes` invariant (it is documented only within this skill's Rules section and report footer).

## Success Criteria

- [ ] After a successful `copy` strategy migration (e.g., `docs/`), the skill presents a deletion prompt listing only the successfully copied files
- [ ] After a partial migration (some files skipped due to destination-exists), the skill presents both a "will delete" list and a "preserved (skipped)" list before prompting
- [ ] If the user declines deletion, zero source files are removed and the report records the skip
- [ ] If the user confirms deletion, only the listed files are removed; the parent directory itself is NOT removed
- [ ] The `delegate` strategy (`commands/`) never triggers a deletion prompt under any circumstance
- [ ] The `section-distribute` strategy (`project.md`, `readme.md`) never triggers a deletion prompt under any circumstance
- [ ] Failed migrations never appear in the "will delete" list
- [ ] The report includes a "Deleted from .claude/" subsection when at least one deletion occurred
- [ ] The frontmatter description and Rules section no longer state "Never deletes" unconditionally

## Effort Estimate

Low (hours) — this is a targeted additive change to a single skill file. Each strategy sub-step gets a short cleanup sub-step appended; the report format gets one new subsection. No new files are created.
