# Spec: skill-add

Change: add-orchestrator-skills
Date: 2026-02-26

## Requirements

### Requirement: Argument parsing

The skill MUST accept a single positional argument `<name>` representing the skill to add. If the argument is missing, the skill MUST stop and ask the user to specify a skill name before proceeding.

#### Scenario: Skill name provided
- **GIVEN** the user invokes `/skill-add typescript`
- **WHEN** the skill begins execution
- **THEN** `typescript` is used as the lookup key in the global catalog

#### Scenario: Skill name missing
- **GIVEN** the user invokes `/skill-add` with no argument
- **WHEN** the skill begins execution
- **THEN** the skill MUST stop and display the list of available skills from the global catalog
- **AND** MUST ask: "Which skill would you like to add? Run `/skill-add <name>` with a skill name."

---

### Requirement: Global catalog existence check

The skill MUST verify that `~/.claude/skills/<name>/SKILL.md` exists before taking any action on the project. If the file does not exist, the skill MUST fail with a clear message and MUST NOT modify the project.

#### Scenario: Skill exists in global catalog
- **GIVEN** the user requests `/skill-add typescript`
- **WHEN** the skill checks `~/.claude/skills/typescript/SKILL.md`
- **THEN** the file is found and the skill proceeds to the addition step

#### Scenario: Skill does not exist in global catalog
- **GIVEN** the user requests `/skill-add angular`
- **WHEN** the skill checks `~/.claude/skills/angular/SKILL.md`
- **THEN** the file is NOT found
- **AND** the skill MUST display: "The skill 'angular' is not in the global catalog."
- **AND** MUST list similar or related skills from the catalog as suggestions
- **AND** MUST offer: "Do you want to create a new one with `/skill-create angular`?"
- **AND** MUST NOT make any changes to the project's CLAUDE.md or `.claude/` directory

#### Scenario: Skill name is a partial match
- **GIVEN** the user requests `/skill-add react` but the catalog has `react-19` and `react-native`
- **WHEN** the skill does not find an exact match
- **THEN** the skill MUST display all partial matches from the catalog
- **AND** MUST ask the user to specify the exact name

---

### Requirement: Addition mode selection

The skill MUST offer the user two options for adding the skill and MUST wait for a choice before proceeding:
- Option A: Conceptual reference (add a pointer in the project CLAUDE.md only)
- Option B: Local copy (copy the SKILL.md to the project's `.claude/skills/<name>/SKILL.md`)

#### Scenario: User selects Option A (reference)
- **GIVEN** the skill is found in the global catalog
- **WHEN** the user selects Option A
- **THEN** the skill MUST add an entry to the project CLAUDE.md Skills Registry pointing to `~/.claude/skills/<name>/SKILL.md`
- **AND** MUST NOT copy any files to the project's `.claude/skills/` directory

#### Scenario: User selects Option B (local copy)
- **GIVEN** the skill is found in the global catalog
- **WHEN** the user selects Option B
- **THEN** the skill MUST create `.claude/skills/<name>/` directory if it does not exist
- **AND** MUST copy `~/.claude/skills/<name>/SKILL.md` to `.claude/skills/<name>/SKILL.md`
- **AND** MUST add an origin note at the top of the copied file indicating it was copied from the global catalog on the current date
- **AND** MUST add an entry to the project CLAUDE.md Skills Registry pointing to `.claude/skills/<name>/SKILL.md`

#### Scenario: .claude/skills/ directory does not exist in the project
- **GIVEN** the user selects Option B
- **WHEN** the target directory `.claude/skills/` does not exist
- **THEN** the skill MUST create `.claude/skills/` before copying the skill file

---

### Requirement: Project CLAUDE.md Skills Registry update

After adding the skill (either mode), the skill MUST update the current project's CLAUDE.md Skills Registry section to include the new skill entry. If no Skills Registry section exists, the skill MUST create one.

#### Scenario: Skills Registry section exists and skill is appended
- **GIVEN** the project CLAUDE.md has a `## Skills Registry` or equivalent section
- **WHEN** the skill adds `typescript` via Option A
- **THEN** the entry `~/.claude/skills/typescript/SKILL.md — TypeScript strict mode, utility types, advanced patterns` MUST be appended to the registry

#### Scenario: Skills Registry section does not exist
- **GIVEN** the project CLAUDE.md has no skills registry section
- **WHEN** the skill completes the addition
- **THEN** the skill MUST add a new `## Active Skills` section to the project CLAUDE.md
- **AND** MUST add the new skill entry under it

#### Scenario: Skill is already registered
- **GIVEN** the project CLAUDE.md already lists `~/.claude/skills/typescript/SKILL.md`
- **WHEN** the user runs `/skill-add typescript` again
- **THEN** the skill MUST detect the duplicate
- **AND** MUST inform the user: "The skill 'typescript' is already registered in this project's CLAUDE.md."
- **AND** MUST NOT add a duplicate entry

---

### Requirement: Confirmation before writing

The skill MUST show the user a preview of all changes it will make (CLAUDE.md diff and/or files to copy) and MUST ask for confirmation before executing any write operation.

#### Scenario: User confirms
- **GIVEN** the skill has prepared its changes
- **WHEN** the skill shows the preview and the user confirms
- **THEN** the skill MUST execute all write operations

#### Scenario: User cancels
- **GIVEN** the skill shows the preview
- **WHEN** the user declines or cancels
- **THEN** the skill MUST abort without making any changes
- **AND** MUST display: "Cancelled. No changes were made."

---

### Requirement: Clear distinction from /skill-create

The skill MUST communicate to the user that `/skill-add` is for adding existing global-catalog skills only, and that `/skill-create` is the command for creating new skills from scratch. This distinction MUST be visible in the skill's help text or when a missing skill is requested.

#### Scenario: User requests a non-existent skill
- **GIVEN** the requested skill is not in the global catalog
- **WHEN** the skill surfaces the "not found" message
- **THEN** the output MUST include a clarifying note: "`/skill-add` adds skills from the global catalog. To create a brand-new skill, use `/skill-create <name>`."
