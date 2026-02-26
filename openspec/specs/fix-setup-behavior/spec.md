# Spec: fix-setup-behavior

Change: deprecate-commands-normalize-skills
Date: 2026-02-26

## Overview

This spec describes the observable behavior of `project-fix` and `project-setup` after the commands deprecation. Both skills MUST stop creating, repairing, or referencing `.claude/commands/` directories. In addition, `project-fix` MUST explicitly refuse to act on any commands-related FIX_MANIFEST entry from stale audit reports.

---

## Requirements

### Requirement: project-fix never creates or modifies files under .claude/commands/

`project-fix` MUST NOT create, overwrite, append to, or otherwise modify any file located under `.claude/commands/` in the target project, regardless of what the FIX_MANIFEST specifies.

#### Scenario: FIX_MANIFEST from a stale audit contains a commands registry action

- **GIVEN** a `FIX_MANIFEST` in `audit-report.md` was generated before this change and contains a `fix_commands_registry` action under `required_actions`
- **WHEN** `/project-fix` reads the FIX_MANIFEST and processes actions
- **THEN** the `fix_commands_registry` action (or any action targeting `.claude/commands/`) is NOT executed
- **AND** `project-fix` logs or notes in its output that the action was skipped because commands are deprecated
- **AND** no file under `.claude/commands/` is created or modified

#### Scenario: project-fix on a fresh audit report (post-change) — no commands action present

- **GIVEN** `/project-audit` has been run after this change is applied, producing a FIX_MANIFEST with no commands-related actions
- **WHEN** `/project-fix` processes that FIX_MANIFEST
- **THEN** `project-fix` executes all other required actions normally
- **AND** the session output contains no reference to commands/ directory operations

#### Scenario: project-fix does not add a commands table to CLAUDE.md

- **GIVEN** a target project whose `CLAUDE.md` has no commands registry section
- **AND** the FIX_MANIFEST contains a `fix_commands_registry` action (stale report)
- **WHEN** `/project-fix` runs
- **THEN** `CLAUDE.md` is NOT modified to add a commands registry section
- **AND** the project's `CLAUDE.md` remains free of any commands table after the fix run

---

### Requirement: project-fix/SKILL.md explicitly states it never touches commands/

`project-fix/SKILL.md` MUST contain an explicit rule in its Rules section stating that the skill never creates or modifies any file under `.claude/commands/`.

#### Scenario: SKILL.md Rules section contains the no-commands constraint

- **GIVEN** `skills/project-fix/SKILL.md` has been updated
- **WHEN** a developer reads the Rules section
- **THEN** they find a rule that explicitly prohibits creating or modifying any file under `.claude/commands/`
- **AND** the rule explains that commands/ is deprecated and skills/ is the only supported extensibility mechanism

#### Scenario: Step 2.4 "Fix Commands registry" is removed from project-fix process

- **GIVEN** the previous version of `project-fix/SKILL.md` contained a step 2.4 that handled commands registry repair
- **WHEN** the updated `project-fix/SKILL.md` is read
- **THEN** no step numbered 2.4 exists, OR if step numbering is preserved, the step formerly titled "Fix Commands registry" is gone
- **AND** the process steps do not include any commands/ directory operations at any step number

---

### Requirement: project-setup never creates a .claude/commands/ directory

`project-setup` MUST NOT create a `.claude/commands/` directory or any file inside it when setting up a new project.

#### Scenario: project-setup run on a clean project — no commands/ directory created

- **GIVEN** a project directory with no existing Claude configuration
- **WHEN** `/project-setup` is run
- **THEN** no `.claude/commands/` directory is created
- **AND** no file with a path matching `.claude/commands/*` is created
- **AND** all other standard setup outputs (CLAUDE.md, openspec/, ai-context/ stubs, skills/ if applicable) are still created as before

#### Scenario: project-setup/SKILL.md Rules section contains the no-commands constraint

- **GIVEN** `skills/project-setup/SKILL.md` has been updated
- **WHEN** a developer reads the Rules section
- **THEN** they find an explicit note that `project-setup` does not create a `.claude/commands/` directory
- **AND** the note states that `.claude/skills/` is the only supported extensibility mechanism for new projects

---

### Requirement: CLAUDE.md (global) does not reference commands as an audit dimension or registry requirement

The global `CLAUDE.md` (at repo root, deployed to `~/.claude/CLAUDE.md`) MUST NOT contain any reference to "Commands registry" as an audit dimension or as a required CLAUDE.md element.

#### Scenario: CLAUDE.md contains no commands registry row in audit dimensions

- **GIVEN** `CLAUDE.md` at the repo root has been updated
- **WHEN** the file is read
- **THEN** there is no row, bullet, or section describing "Commands registry" as something a project's CLAUDE.md must have
- **AND** there is no mention of a commands table as a required element of project configuration

#### Scenario: CLAUDE.md Skills Registry section still accurately lists all skills

- **GIVEN** the update to `CLAUDE.md` removes commands references
- **WHEN** the Skills Registry section is read
- **THEN** all skills previously listed remain listed (no accidental removals)
- **AND** the registry accurately reflects the skills catalog without any commands section

---

## Rules

- Specs describe observable outcomes — what is present or absent in files and what actions are or are not taken
- The prohibition on `project-fix` touching commands/ is absolute: it applies even if a FIX_MANIFEST explicitly requests it
- These specs do not restrict how project-fix internally parses the FIX_MANIFEST — only that the observable output matches the no-commands constraint
