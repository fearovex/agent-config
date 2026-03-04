# Delta Spec: project-claude-organizer

Change: project-claude-organizer-cleanup-after-migrate
Date: 2026-03-04
Base: openspec/specs/project-claude-organizer/spec.md

## ADDED — New requirements

### Requirement: Post-migration cleanup prompt per applicable strategy

After each legacy migration category is applied in Step 5.7, and only for strategies that
perform actual file writes (`copy`, `append`, `scaffold`, `user-choice`), the skill MUST
offer the user an opportunity to delete the successfully migrated source files.

The cleanup prompt MUST:
- Be presented AFTER the migration for the category has completed
- List the source files that were successfully migrated (those with `applied`, `copied`, `appended`, or `scaffolded` outcomes) and would be eligible for deletion
- List separately any source files that were skipped (due to destination-exists or other reasons) and would NOT be deleted
- Prompt: `Delete source files from .claude/<category>/? (yes/no)`
- Wait for explicit user input before performing any deletion

The cleanup prompt MUST NOT be presented:
- For the `delegate` strategy (`commands/`) — no actual file writes occurred
- For the `section-distribute` strategy (`project.md`, `readme.md`) — the source file may contain additional sections not distributed

#### Scenario: cleanup prompt presented after successful copy migration (docs/)

- **GIVEN** the user confirmed `docs/` migration and all files were successfully copied
- **WHEN** the migration for `docs/` completes
- **THEN** the skill presents a prompt listing all successfully copied files
- **AND** the prompt is: `Delete source files from .claude/docs/? (yes/no)`
- **AND** the skill waits for user confirmation before deleting anything

#### Scenario: cleanup prompt shows two lists for partial migration

- **GIVEN** the user confirmed `docs/` migration
- **AND** `auth.md` was copied successfully but `payments.md` was skipped (destination exists)
- **WHEN** the migration for `docs/` completes
- **THEN** the skill presents a prompt listing:
  - "Will be deleted: auth.md"
  - "Will be preserved (skipped — destination exists): payments.md"
- **AND** the prompt is: `Delete source files from .claude/docs/? (yes/no)`

#### Scenario: cleanup prompt NOT presented for delegate strategy

- **GIVEN** the user confirmed `commands/` migration (delegate strategy)
- **WHEN** the migration for `commands/` completes
- **THEN** NO deletion prompt is presented for `commands/`
- **AND** the source files in `.claude/commands/` are never offered for deletion

#### Scenario: cleanup prompt NOT presented for section-distribute strategy

- **GIVEN** the user confirmed `project.md` migration (section-distribute strategy)
- **WHEN** the section-distribute migration completes
- **THEN** NO deletion prompt is presented for `project.md`
- **AND** the source file `.claude/project.md` is never offered for deletion

#### Scenario: cleanup prompt NOT presented when no files were successfully migrated

- **GIVEN** the user confirmed `docs/` migration
- **AND** all files in `docs/` were skipped (destination-exists for each)
- **WHEN** the migration for `docs/` completes
- **THEN** the skill does NOT present a deletion prompt for `docs/`
- **AND** no source files are deleted

---

### Requirement: Deletion executes only on explicit user confirmation, targeting only successfully migrated files

When the user responds affirmatively to the cleanup prompt, the skill MUST:
- Delete ONLY the source files that were successfully migrated (appear in the "will be deleted" list)
- NOT delete any file that was skipped, failed, or excluded
- NOT delete the parent source directory itself (only the individual files)
- Record each deletion outcome in the report

When the user declines the cleanup prompt, the skill MUST:
- Perform zero deletions for that category
- Record the skip in the report

#### Scenario: user confirms deletion — only successful files are deleted

- **GIVEN** the cleanup prompt for `docs/` lists `auth.md` (will be deleted) and `payments.md` (will be preserved)
- **WHEN** the user responds `yes`
- **THEN** `.claude/docs/auth.md` is deleted
- **AND** `.claude/docs/payments.md` is NOT deleted
- **AND** the `.claude/docs/` directory itself is NOT deleted

#### Scenario: user declines deletion — no files removed

- **GIVEN** the cleanup prompt for `templates/` is displayed
- **WHEN** the user responds `no`
- **THEN** zero files are deleted from `.claude/templates/`
- **AND** the report records `templates/ — cleanup declined by user`

#### Scenario: failed migrations are never offered for deletion

- **GIVEN** `docs/` migration ran and `auth.md` failed (e.g., copy error) and `events.md` was copied successfully
- **WHEN** the cleanup prompt is presented
- **THEN** only `events.md` appears in the "will be deleted" list
- **AND** `auth.md` does NOT appear in the "will be deleted" list
- **AND** `auth.md` is never deleted regardless of user input

---

### Requirement: Report MUST record all deletion outcomes in a new subsection

When at least one deletion occurred (across any category), the report MUST include a
"Deleted from .claude/" subsection under "Legacy migrations". The subsection MUST list
every file that was deleted along with its full original source path.

When no deletions occurred (all declined or no eligible files), the subsection MAY be
omitted, or included as empty — either is acceptable.

#### Scenario: deletion subsection records deleted paths

- **GIVEN** the user confirmed deletion for `docs/` category (deleting `auth.md`)
- **AND** the user declined deletion for `templates/` category
- **WHEN** the report is written
- **THEN** the report includes a "Deleted from .claude/" subsection under Legacy migrations
- **AND** it lists: `.claude/docs/auth.md — deleted`
- **AND** it lists: `templates/ — cleanup declined by user`

#### Scenario: deletion subsection omitted when no deletions occurred

- **GIVEN** the user declined all cleanup prompts during the run
- **WHEN** the report is written
- **THEN** the "Deleted from .claude/" subsection MAY be omitted from the report

---

## MODIFIED — Modified requirements

### Requirement: Skill invariant — source files MUST NOT be deleted without user confirmation AND successful migration

*(Replaces the existing invariant "source files are NEVER deleted, moved, or modified" for applicable strategies only)*

The new invariant is: source files MUST NOT be deleted without BOTH conditions being true:
1. The file was successfully migrated (copied, appended, scaffolded, or user-choice applied)
2. The user explicitly confirmed the deletion prompt for that category

The "never delete" invariant remains fully in force for:
- The `delegate` strategy (`commands/`)
- The `section-distribute` strategy (`project.md`, `readme.md`)
- Any file with a failed or skipped migration outcome

#### Scenario: source file preserved when migration failed

- **GIVEN** a `docs/` migration where `auth.md` failed during copy
- **WHEN** the cleanup prompt is presented (for successfully migrated files only)
- **THEN** `auth.md` is NOT included in the deletable list
- **AND** `.claude/docs/auth.md` is never deleted regardless of user input

#### Scenario: source files preserved for delegate strategy regardless of any setting

- **GIVEN** `commands/` is processed via delegate strategy
- **WHEN** the delegate strategy completes
- **THEN** all files in `.claude/commands/` are unconditionally preserved — no prompt is issued, no deletion occurs
