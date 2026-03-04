# Task Plan: project-claude-organizer-cleanup-after-migrate

Date: 2026-03-04
Design: openspec/changes/project-claude-organizer-cleanup-after-migrate/design.md

## Progress: 12/12 tasks

## Phase 1: Skill Metadata and Invariant Documentation

- [x] 1.1 Modify `skills/project-claude-organizer/SKILL.md` frontmatter — update the `description:` field to remove "Never deletes or moves files" and replace with "After successful migration, offers to delete source files from .claude/<category>/ with explicit user confirmation."
- [x] 1.2 Modify `skills/project-claude-organizer/SKILL.md` Rules section — add Rule 5 stating the new source-file deletion invariant: "Source files MUST NOT be deleted without BOTH (a) successful prior migration AND (b) explicit user confirmation. The `delegate` and `section-distribute` strategies are permanently exempt from cleanup prompts."

## Phase 2: Cleanup Sub-steps for Copy Strategy Categories

- [x] 2.1 Modify `skills/project-claude-organizer/SKILL.md` — append cleanup sub-step **5.7.3-cleanup** immediately after sub-step 5.7.3 (copy strategy: `docs/` and `templates/`). The sub-step must: (a) check if any files were successfully copied, (b) if yes, present WILL_DELETE list (outcome = "copied") and WILL_PRESERVE list (outcome = "skipped"), (c) prompt `Delete source files from .claude/<category>/? (yes/no)`, (d) if yes: delete each WILL_DELETE file and record; if no: record `<category> — cleanup declined by user`.
- [x] 2.2 Modify `skills/project-claude-organizer/SKILL.md` — append cleanup sub-step **5.7.7-cleanup** immediately after sub-step 5.7.7 (copy strategy: `plans/`). Same structure as 5.7.3-cleanup: check for successful copies, present both lists, prompt, act on response.

## Phase 3: Cleanup Sub-steps for Append, Scaffold, and User-Choice Strategy Categories

- [x] 3.1 Modify `skills/project-claude-organizer/SKILL.md` — append cleanup sub-step **5.7.4-cleanup** immediately after sub-step 5.7.4 (append strategy: `system/`). The sub-step must: (a) check for files with outcome "appended to ...", (b) build WILL_DELETE list (appended files) and WILL_PRESERVE list (skipped or no-routing-rule files), (c) prompt `Delete source files from .claude/system/? (yes/no)`, (d) act on response and record.
- [x] 3.2 Modify `skills/project-claude-organizer/SKILL.md` — append cleanup sub-step **5.7.5-cleanup** immediately after sub-step 5.7.5 (scaffold strategy: `requirements/`). The sub-step must: (a) check for files with outcome "scaffolded to ...", (b) build WILL_DELETE list (scaffolded files) and WILL_PRESERVE list (scaffold-skipped files), (c) prompt `Delete source files from .claude/requirements/? (yes/no)`, (d) act on response and record.
- [x] 3.3 Modify `skills/project-claude-organizer/SKILL.md` — append cleanup sub-step **5.7.6-cleanup** immediately after sub-step 5.7.6 (user-choice strategy: `sops/`). The sub-step must: (a) check for files with outcome "copied to ..." or "appended to ...", (b) build WILL_DELETE list (successfully processed files) and WILL_PRESERVE list (skipped files), (c) prompt `Delete source files from .claude/sops/? (yes/no)`, (d) act on response and record.

## Phase 4: Report Format Extension

- [x] 4.1 Modify `skills/project-claude-organizer/SKILL.md` Step 6 report format — add a "Deleted from .claude/" subsection template under the "Legacy migrations" section. The subsection must: list each deleted file as `.claude/<category>/<filename> — deleted`; list each declined category as `<category>/ — cleanup declined by user`; be omitted entirely when no cleanup prompts were presented during the run.
- [x] 4.2 Modify `skills/project-claude-organizer/SKILL.md` Step 6 report format — update the existing footer note (currently "All source files in legacy categories were preserved — no files were deleted or moved") to be conditional: display the preservation note only when no files were deleted; omit it (or replace with a deletion summary line) when deletions occurred.

## Phase 5: Dry-Run Plan Update

- [x] 5.1 Modify `skills/project-claude-organizer/SKILL.md` Step 4 dry-run plan display — update the note under "Legacy migrations:" from "Source files are never deleted, moved, or modified" (or equivalent language) to reflect the new conditional behavior: "Source files are offered for deletion after successful migration — deletion requires explicit user confirmation."

## Phase 6: Documentation and Memory

- [x] 6.1 Verify `docs/adr/021-project-claude-organizer-cleanup-after-migrate-conv.md` exists and is listed in `docs/adr/README.md` index (already created in the design phase — confirm and mark done).
- [x] 6.2 After running `install.sh` to deploy, manually verify on a test project: (a) run `/project-claude-organizer` with at least one eligible legacy category; (b) confirm cleanup prompt appears after migration; (c) confirm deletion occurs only for confirmed files; (d) confirm report includes "Deleted from .claude/" subsection.

---

## Implementation Notes

- All changes are confined to a single file: `skills/project-claude-organizer/SKILL.md`. No new files need to be created beyond the ADR already produced in the design phase.
- The cleanup sub-steps follow a strict template (check → present → prompt → act → record). Each sub-step must be self-contained and reference only the outcome records produced by its corresponding 5.7.x sub-step.
- The WILL_DELETE / WILL_PRESERVE classification must be based on the outcome language already established in each 5.7.x sub-step: "copied to", "appended to", "scaffolded to" indicate success; "skipped (destination exists)", "failed", "no routing rule; skipped" indicate non-deletion candidates.
- The `delegate` strategy (5.7.1) and `section-distribute` strategy (5.7.2) MUST NOT receive cleanup sub-steps. Do not add 5.7.1-cleanup or 5.7.2-cleanup.
- After all SKILL.md edits are done, run `install.sh` to deploy to `~/.claude/` before testing.

## Blockers

None.
