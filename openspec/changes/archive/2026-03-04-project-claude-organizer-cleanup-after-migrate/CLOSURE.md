# Closure: project-claude-organizer-cleanup-after-migrate

Start date: 2026-03-04
Close date: 2026-03-04

## Summary

Added post-migration cleanup sub-steps to the `project-claude-organizer` skill so that, after each applicable legacy category is successfully migrated, the user is offered an opportunity to delete the source files from `.claude/<category>/` with explicit per-category confirmation. The `delegate` and `section-distribute` strategies are permanently exempt.

## Modified Specs
| Domain | Action | Change |
|--------|--------|--------|
| project-claude-organizer | Modified | Source file preservation invariant updated to reflect new conditional deletion behavior |
| project-claude-organizer | Added | Requirement: Post-migration cleanup prompt per applicable strategy |
| project-claude-organizer | Added | Requirement: Deletion executes only on explicit user confirmation, targeting only successfully migrated files |
| project-claude-organizer | Added | Requirement: Report MUST record all deletion outcomes in a new subsection |

## Modified Code Files

- `skills/project-claude-organizer/SKILL.md` — added 5 cleanup sub-steps (5.7.3-cleanup through 5.7.7-cleanup), updated frontmatter description, added Rule 5, updated Step 4 dry-run note, extended Step 6 report format with "Deleted from .claude/" subsection

## Key Decisions Made

- Cleanup prompt is placed immediately after each 5.7.x apply sub-step (per-category), not globally at end of Step 5.7 — consistent with the skill's existing per-category confirmation gate UX
- Deletion granularity is individual successfully migrated files only; parent directory is never removed
- `delegate` and `section-distribute` strategies are permanently exempt — no cleanup sub-steps 5.7.1-cleanup or 5.7.2-cleanup exist
- Failed and skipped migration outcomes are unconditionally excluded from the WILL_DELETE list
- Rule 5 was added (not replacing Rule 2) to document the new dual-condition source-file invariant
- ADR 021 documents the new confirmed-deletion post-migration convention

## Lessons Learned

- The skill tagline (markdown blockquote at line 17 beneath the heading) was not included in the task list and remains stale ("Never deletes or moves files") even though the frontmatter description and Rules section were correctly updated. Future changes affecting skill-level summary language should explicitly list the blockquote tagline as a modification target.
- The per-sub-step "Source files are NEVER deleted, moved, or modified." lines within each 5.7.x apply sub-step remain technically correct (they describe the apply step before cleanup runs) but may cause reader confusion when immediately followed by a cleanup sub-step. A clarifying note could improve readability in a future cleanup.

## User Docs Reviewed

NO — this change modifies an internal skill's behavior (post-migration cleanup UX). It does not add or rename skills visible in the CLAUDE.md commands table, nor does it affect onboarding workflows or quick-reference materials for users. No updates to scenarios.md, quick-reference.md, or onboarding.md are required.
