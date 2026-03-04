# Spec: skill-orchestration

Change: project-claude-organizer-smart-migration
Date: 2026-03-04

---

## Overview

This spec defines the observable behavior of the new "skill-to-skill advisory" pattern introduced
by the `commands/` legacy pattern handling in `project-claude-organizer`. This is the first
instance where one skill recognizes content that qualifies as a new skill and surfaces a
recommendation to delegate to `/skill-create`. The pattern is advisory — the organizer prepares
information and surfaces it; the user decides whether to act.

---

## Requirements

### Requirement: commands/ content analysis MUST classify .md files as qualifying or non-qualifying for skill scaffolding

When the `commands/` legacy pattern is processed in Step 5.7, the skill MUST read each `.md` file
at the immediate `commands/` level and evaluate it against "reusable workflow" markers.

**Qualifying markers (any one is sufficient):**
- The file contains step-by-step numbered or bulleted process sections (e.g., lines matching `1.`, `- Step`, `### Step`)
- The file contains a named trigger or invocation pattern (e.g., lines starting with `/command-name` or containing "trigger:")
- The file contains a section with the heading `## Process`, `## Steps`, `## How to`, or `## Instructions`
- The file's filename stem matches a known command naming pattern (e.g., `deploy`, `rollback`, `setup`, `onboard`, `audit`)

**Non-qualifying markers:**
- The file contains only prose notes without a structured process
- The file contains only configuration data (key: value pairs without procedural steps)
- The file is empty or fewer than 10 non-blank lines

#### Scenario: qualifying file produces an advisory with suggested skill name

- **GIVEN** `commands/deploy.md` contains a `## Process` section with numbered steps
- **WHEN** Step 5.7 applies the delegate strategy for `commands/`
- **THEN** the skill outputs an advisory message for `deploy.md`:
  "deploy.md — qualifying workflow detected. Suggested skill name: deploy. To scaffold: /skill-create deploy"
- **AND** no files are created or modified
- **AND** the skill does NOT invoke `/skill-create` automatically

#### Scenario: non-qualifying file produces an archival recommendation

- **GIVEN** `commands/scratch-notes.md` contains fewer than 10 non-blank lines of prose
- **WHEN** Step 5.7 applies the delegate strategy
- **THEN** the advisory output for `scratch-notes.md` reads:
  "scratch-notes.md — non-qualifying (no structured workflow detected). Recommend manual archival."
- **AND** no files are created or modified

#### Scenario: advisory output includes format and trigger suggestions for qualifying files

- **GIVEN** `commands/rollback.md` is a qualifying file
- **WHEN** the advisory is generated
- **THEN** the advisory SHOULD include:
  - Suggested skill name (derived from filename stem)
  - Suggested format: `procedural` (since rollback workflows are step-by-step)
  - A reminder that the user must invoke `/skill-create <name>` manually
- **AND** the advisory MUST NOT include any automated action

#### Scenario: commands/ with no .md files produces an empty advisory

- **GIVEN** `commands/` exists as a directory but contains no `.md` files at the immediate level
- **WHEN** Step 5.7 processes the `commands/` delegate strategy
- **THEN** the skill outputs: "commands/ — no .md files found at immediate level; nothing to advise"
- **AND** no files are created or modified

#### Scenario: commands/ processing is non-recursive — subdirectories are skipped

- **GIVEN** `commands/` contains `deploy.md` at the root level and a subdirectory `archived/` containing `old-deploy.md`
- **WHEN** Step 5.7 applies the delegate strategy
- **THEN** only `deploy.md` is evaluated and included in the advisory
- **AND** `archived/old-deploy.md` is NOT evaluated

---

### Requirement: the skill-to-skill advisory pattern MUST be strictly non-automating

The `commands/` delegate strategy — and any future advisory that references another skill —
MUST NOT invoke or call that other skill. The organizer's role is to prepare information and
present it to the user. The user remains in control of whether and when to invoke `/skill-create`.

#### Scenario: skill-create is not invoked during commands/ processing

- **GIVEN** one or more qualifying files are identified in `commands/`
- **AND** the user has confirmed the `commands/` category
- **WHEN** Step 5.7 completes
- **THEN** `/skill-create` has NOT been invoked
- **AND** no new skill directories or SKILL.md files have been created
- **AND** the report documents advisory outputs, not skill creation outcomes

#### Scenario: user can choose to invoke skill-create after reviewing the advisory

- **GIVEN** the advisory listed `deploy.md — suggested skill name: deploy`
- **WHEN** the organizer run completes and the user reads the report
- **THEN** the user has sufficient information to invoke `/skill-create deploy` manually
- **AND** the organizer report provides the suggested name and a reminder of the command

---

## Rules

- The delegate strategy MUST read `.md` files at the immediate `commands/` level only — no recursion
- Classification as qualifying or non-qualifying MUST be based solely on the 4 qualifying markers defined above — no heuristic beyond these markers is permitted
- The skill MUST NOT invoke `/skill-create` or any other skill as a sub-step — advisory output only
- Advisory output for qualifying files MUST include at minimum: filename, suggested skill name, and the exact command to invoke (`/skill-create <name>`)
- Advisory output for non-qualifying files MUST include: filename and an explicit "recommend archival" note
- The delegate strategy produces zero file writes — any write under the `commands/` processing step is a violation
