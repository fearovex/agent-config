# Spec: audit-dimensions

Change: deprecate-commands-normalize-skills
Date: 2026-02-26

## Overview

This spec describes the observable behavior of `project-audit` at the dimension level after the commands deprecation. It covers: removal of Dimension 5 entirely, removal of the "Has Commands registry" check from Dimension 1, and the addition of a passive INFO notice when a legacy `commands/` directory is detected.

---

## Requirements

### Requirement: Dimension 5 (Commands Quality) is fully removed from project-audit

`project-audit/SKILL.md` MUST NOT contain any Dimension 5 section, D5 checks, or commands-focused audit logic after this change.

#### Scenario: SKILL.md has no Dimension 5 section

- **GIVEN** `skills/project-audit/SKILL.md` has been updated
- **WHEN** a developer reads the file from top to bottom
- **THEN** there is no section heading "Dimension 5" or "Commands Quality"
- **AND** there are no sub-checks 5a or 5b in the file
- **AND** the file's dimension count is 8 explicitly numbered dimensions (1, 2, 3, 4, 6, 7, 8, 9) plus D9

#### Scenario: Report format has no D5 block

- **GIVEN** the report format section of `project-audit/SKILL.md` defines the structure of the generated report
- **WHEN** that section is read
- **THEN** there is no "Dimension 5 — Commands" block in the report format template
- **AND** there is no row for D5 in any score table template
- **AND** the FIX_MANIFEST YAML template within the report format does not reference any commands-related action types (e.g., `fix_commands_registry`)

---

### Requirement: Dimension 1 does not penalize absence of a commands registry

The "Has Commands registry" check MUST be removed from Dimension 1's check table. Its absence MUST NOT be reported as a finding or deduct from D1's score.

#### Scenario: D1 check table has no commands registry row

- **GIVEN** `skills/project-audit/SKILL.md` D1 section is read
- **WHEN** a developer reads the "Checks to run" table
- **THEN** the table has no row with text "Has Commands registry" or equivalent
- **AND** no severity value is assigned for a missing commands table in CLAUDE.md

#### Scenario: D1 report format has no commands registry row

- **GIVEN** the D1 block in the report format template is read
- **WHEN** the table of checks and statuses is examined
- **THEN** there is no "Commands registry present" row in the template table
- **AND** the template table contains a "Skills registry present" row (unchanged)

#### Scenario: Audit on a project whose CLAUDE.md has no commands table

- **GIVEN** a project whose `CLAUDE.md` contains a Skills registry table but no Commands registry table
- **WHEN** `/project-audit` is run
- **THEN** the D1 score is unaffected by the absence of a Commands registry
- **AND** no D1 finding of any severity is emitted for "missing Commands registry"

---

### Requirement: Legacy commands/ directory triggers a passive INFO notice

If the target project has a `.claude/commands/` directory, `project-audit` MUST emit exactly one LOW/INFO finding recommending migration to skills. This finding MUST carry zero score penalty.

#### Scenario: INFO notice emitted for a project with commands/ present

- **GIVEN** the target project has a `.claude/commands/` directory with at least one file
- **WHEN** `/project-audit` runs
- **THEN** exactly one LOW finding appears in the report with text that:
  - identifies that a legacy `.claude/commands/` directory was detected
  - recommends migrating to `.claude/skills/` following the official Claude Code standard
- **AND** the finding severity is LOW (informational only)
- **AND** the finding does NOT appear in the `required_actions.critical`, `required_actions.high`, or `required_actions.medium` blocks of the FIX_MANIFEST

#### Scenario: No INFO notice emitted for a project without commands/

- **GIVEN** the target project has NO `.claude/commands/` directory
- **WHEN** `/project-audit` runs
- **THEN** no finding related to commands/ is emitted anywhere in the report

#### Scenario: INFO notice does not affect score

- **GIVEN** two identical projects, one with `.claude/commands/` and one without
- **WHEN** `/project-audit` is run on each
- **THEN** both projects receive the same numeric score
- **AND** the only difference in the reports is the presence or absence of the LOW INFO finding about commands/

---

### Requirement: The commands deprecation change itself is not audited or penalized

`project-audit` MUST NOT, after this change, generate any FIX_MANIFEST actions that would cause `project-fix` to create, repair, or populate a `.claude/commands/` directory.

#### Scenario: FIX_MANIFEST contains no commands-related actions for a compliant project

- **GIVEN** a project that correctly uses only `.claude/skills/` and has no `.claude/commands/` directory
- **WHEN** `/project-audit` is run and a FIX_MANIFEST is generated
- **THEN** the FIX_MANIFEST `required_actions` blocks contain no action with a `target` pointing to `.claude/commands/`
- **AND** no action type of `fix_commands_registry` or similar is present

---

## Rules

- The INFO notice for legacy commands/ is observable behavior — its presence and wording in the report are verifiable criteria
- Score impact is verifiable by comparing scores between runs on identical projects with and without commands/
- These specs do not constrain how the commands/ detection is implemented internally — only that the observable output matches the scenarios above
