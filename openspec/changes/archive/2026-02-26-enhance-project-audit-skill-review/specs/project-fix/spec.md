# Spec: project-fix — Phase 5 (Dimension 9 Handlers)

Change: enhance-project-audit-skill-review
Date: 2026-02-26

## Requirements

### Requirement: PF5-1 — Read skill_quality_actions from FIX_MANIFEST

When `/project-fix` reads the `FIX_MANIFEST`, it MUST parse `skill_quality_actions` as a new top-level key, alongside the existing keys. The skill MUST remain backward-compatible: if `skill_quality_actions` is absent from the manifest, Phase 5 MUST be silently skipped.

#### Scenario: FIX_MANIFEST contains skill_quality_actions
- **GIVEN** an `audit-report.md` whose `FIX_MANIFEST` includes a `skill_quality_actions` key with one or more entries
- **WHEN** `/project-fix` reads and parses the manifest
- **THEN** the fix summary presented to the user includes a line: `Phase 5 — Skill Quality Actions: [N] actions`
- **AND** the user's menu offers Phase 5 as an optional execution phase

#### Scenario: FIX_MANIFEST has no skill_quality_actions key
- **GIVEN** an `audit-report.md` whose `FIX_MANIFEST` does not contain `skill_quality_actions`
- **WHEN** `/project-fix` reads and parses the manifest
- **THEN** Phase 5 is silently skipped
- **AND** the fix summary does not mention Phase 5

#### Scenario: skill_quality_actions is an empty list
- **GIVEN** `skill_quality_actions: []` in the FIX_MANIFEST
- **WHEN** `/project-fix` reads and parses the manifest
- **THEN** Phase 5 is silently skipped

---

### Requirement: PF5-2 — Handle delete_duplicate action with user confirmation

For each `delete_duplicate` entry in `skill_quality_actions`, `/project-fix` MUST present the duplicate to the user with both the local and global paths, request explicit confirmation, and only then delete the local skill directory.

#### Scenario: User confirms deletion of a duplicate skill
- **GIVEN** a `delete_duplicate` action for `.claude/skills/typescript` with global counterpart `~/.claude/skills/typescript`
- **WHEN** Phase 5 executes
- **THEN** the user is shown:
  ```
  Duplicate detected: .claude/skills/typescript
  Global counterpart: ~/.claude/skills/typescript
  Delete the local copy? [y/N]
  ```
- **AND** upon answering `y`, the `.claude/skills/typescript/` directory is removed
- **AND** the action is recorded in `ai-context/changelog-ai.md`

#### Scenario: User declines deletion of a duplicate skill
- **GIVEN** a `delete_duplicate` action for `.claude/skills/typescript`
- **WHEN** Phase 5 presents the prompt and the user answers `N` or presses Enter
- **THEN** the local skill directory is NOT deleted
- **AND** the audit report action is marked as `skipped (user declined)`

#### Scenario: Local skill directory no longer exists at fix time
- **GIVEN** a `delete_duplicate` action for `.claude/skills/typescript`
- **AND** `.claude/skills/typescript/` has already been manually deleted before Phase 5 runs
- **WHEN** Phase 5 attempts the deletion
- **THEN** the action is marked as `skipped (already deleted)`
- **AND** no error is raised

---

### Requirement: PF5-3 — Handle add_missing_section action

For each `add_missing_section` entry in `skill_quality_actions`, `/project-fix` MUST append a stub section to the target `SKILL.md` without overwriting existing content.

The stub format for each section MUST be:
- **Triggers stub**: `\n\n**Triggers**: TODO — define triggers for this skill\n`
- **Process stub**: `\n\n## Process\n\n> TODO: define step-by-step process\n`
- **Rules stub**: `\n\n## Rules\n\n> TODO: define constraints\n`

#### Scenario: Add missing Rules section to a SKILL.md
- **GIVEN** an `add_missing_section` action targeting `.claude/skills/my-skill/SKILL.md` with `section: "Rules"`
- **AND** the file exists but has no `## Rules` or `## Execution rules` heading
- **WHEN** Phase 5 executes
- **THEN** the text `\n\n## Rules\n\n> TODO: define constraints\n` is appended to the end of the file
- **AND** all pre-existing content in the file is preserved unchanged
- **AND** the action is recorded in `ai-context/changelog-ai.md`

#### Scenario: Section already present (idempotency)
- **GIVEN** an `add_missing_section` action for a SKILL.md that already contains the target section (race condition or stale manifest)
- **WHEN** Phase 5 attempts to add the section
- **THEN** the section is NOT appended again
- **AND** the action is marked as `skipped (section already present)`

#### Scenario: Target SKILL.md file does not exist
- **GIVEN** an `add_missing_section` action targeting a file that does not exist on disk
- **WHEN** Phase 5 attempts to add the section
- **THEN** the action is marked as `failed (file not found)`
- **AND** the user is notified with the exact path that was expected

---

### Requirement: PF5-4 — Handle flag_irrelevant action

For each `flag_irrelevant` entry in `skill_quality_actions`, `/project-fix` MUST insert a comment block at the very top of the target `SKILL.md`. This action does NOT require user confirmation and MUST NOT delete or modify any existing content below the comment.

The comment block format MUST be:
```
<!-- AUDIT: skill may be irrelevant to current stack — review and remove if not needed -->
```

#### Scenario: Flag an irrelevant skill
- **GIVEN** a `flag_irrelevant` action targeting `.claude/skills/spring-boot-3/SKILL.md`
- **WHEN** Phase 5 executes
- **THEN** the comment block is inserted as the first line of the file
- **AND** all existing file content is preserved unchanged after the comment
- **AND** the action is recorded in `ai-context/changelog-ai.md`

#### Scenario: Comment block already present (idempotency)
- **GIVEN** a `flag_irrelevant` action for a SKILL.md that already starts with the AUDIT comment block
- **WHEN** Phase 5 attempts to flag it
- **THEN** the comment is NOT inserted again
- **AND** the action is marked as `skipped (already flagged)`

---

### Requirement: PF5-5 — Handle flag_language_violation action

For each `flag_language_violation` entry in `skill_quality_actions`, `/project-fix` MUST record the finding in `ai-context/changelog-ai.md` and notify the user that manual translation is required. The skill MUST NOT auto-translate or modify the file content.

#### Scenario: Language violation flagged in changelog
- **GIVEN** a `flag_language_violation` action for `.claude/skills/mi-skill/SKILL.md`
- **WHEN** Phase 5 processes the entry
- **THEN** `ai-context/changelog-ai.md` receives an entry noting the file and recommending manual translation
- **AND** the user is shown: `Language violation in .claude/skills/mi-skill/SKILL.md — manual translation required.`
- **AND** the SKILL.md file is NOT modified

---

### Requirement: PF5-6 — Record all Phase 5 actions in changelog-ai.md

Every action executed in Phase 5 MUST be recorded in `ai-context/changelog-ai.md` under a new date entry (or appended to today's entry if one already exists from Phase 1–4).

#### Scenario: Phase 5 actions appended to changelog
- **GIVEN** Phase 5 executes two actions: `delete_duplicate` (confirmed) and `add_missing_section`
- **WHEN** Phase 5 completes
- **THEN** `ai-context/changelog-ai.md` contains an entry dated today listing:
  - Which skills were deleted and why
  - Which SKILL.md files were modified and what was added
- **AND** the entry follows the existing `## YYYY-MM-DD` format used in that file

---

### Requirement: PF5-7 — Phase 5 executes after Phase 4 with a checkpoint

Phase 5 MUST follow Phase 4 in the existing phase sequence. Before Phase 5 begins, the user MUST be shown a summary of pending Phase 5 actions and asked for confirmation to proceed. The user MUST be able to skip Phase 5 entirely.

#### Scenario: User proceeds through Phase 5
- **GIVEN** Phase 4 has completed and `skill_quality_actions` contains 2 entries
- **WHEN** the Phase 5 checkpoint is presented
- **THEN** the user sees: `Phase 5 — Skill Quality Actions: 2 pending. Proceed? [Y/n]`
- **AND** upon answering `Y`, Phase 5 executes the listed actions

#### Scenario: User skips Phase 5
- **GIVEN** Phase 4 has completed and `skill_quality_actions` contains 2 entries
- **WHEN** the Phase 5 checkpoint is presented and the user answers `n`
- **THEN** Phase 5 is skipped entirely
- **AND** the final fix report notes: `Phase 5 skipped by user`
