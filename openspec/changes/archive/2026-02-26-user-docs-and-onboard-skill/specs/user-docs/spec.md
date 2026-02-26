# Spec: User Documentation

Change: user-docs-and-onboard-skill
Date: 2026-02-26

## Requirements

### Requirement: scenarios.md must exist and cover all six project states

`ai-context/scenarios.md` MUST be created in the `claude-config` repository and MUST cover exactly six project-state cases. Each case MUST follow a fixed template containing: a label, observable symptoms, an ordered command sequence, expected outcome per command, and a failure-modes table with recovery steps. The file MUST begin with a `Last verified:` date field so freshness checks can parse it.

#### Scenario: New project with no Claude config at all (Case 1)

- **GIVEN** `ai-context/scenarios.md` does not exist in `claude-config`
- **WHEN** the file is created as part of this change
- **THEN** the file exists at `ai-context/scenarios.md`
- **AND** it contains a section for "Case 1 — Brand-new project" that lists `/project-setup` as the first command
- **AND** the symptoms listed are observable without running any command (e.g., absence of `.claude/CLAUDE.md`)

#### Scenario: All six cases are present and structurally complete

- **GIVEN** `ai-context/scenarios.md` has been written
- **WHEN** it is opened and read
- **THEN** it contains exactly 6 case sections
- **AND** each case section contains: a Symptoms block, a Command sequence block, an Expected outcome per command block, and a Common failure modes table
- **AND** no case section is missing any of these four blocks

#### Scenario: File has a parseable Last verified date

- **GIVEN** `ai-context/scenarios.md` has been created
- **WHEN** the `project-audit` D2 freshness check reads the file
- **THEN** it finds a line matching `Last verified: YYYY-MM-DD` within the first 10 lines of the file
- **AND** the date is parseable as an ISO 8601 date

#### Scenario: Case 6 covers the fully-configured state

- **GIVEN** `ai-context/scenarios.md` exists
- **WHEN** a user reads Case 6
- **THEN** they find the correct command to start a new feature (`/sdd-ff` or `/sdd-new`) listed as the first command
- **AND** the case does NOT recommend running `/project-setup` (which would be destructive for an already-configured project)

---

### Requirement: quick-reference.md must exist and be self-contained

`ai-context/quick-reference.md` MUST be created and MUST contain four sections: a situation-to-first-command table, an ASCII diagram of the SDD flow, a one-line-per-command glossary, and a decision rule for choosing `/sdd-ff` vs `/sdd-new`. The file MUST begin with a `Last verified:` date field.

#### Scenario: Situation table covers common entry points

- **GIVEN** `ai-context/quick-reference.md` has been created
- **WHEN** a user opens the file
- **THEN** the situation table contains at least 5 rows
- **AND** each row maps an observable situation to exactly one first command
- **AND** no two rows map to conflicting first commands for the same situation

#### Scenario: SDD flow ASCII diagram is present

- **GIVEN** `ai-context/quick-reference.md` has been created
- **WHEN** the file is read
- **THEN** it contains an ASCII art block depicting the SDD phase flow (explore → propose → spec/design → tasks → apply → verify → archive)
- **AND** the diagram is enclosed in a code block

#### Scenario: Command glossary lists every meta-tool and SDD phase command

- **GIVEN** `ai-context/quick-reference.md` has been created
- **WHEN** the glossary section is read
- **THEN** it lists all meta-tool commands: `/project-setup`, `/project-audit`, `/project-fix`, `/project-update`, `/project-onboard`, `/skill-create`, `/skill-add`, `/memory-init`, `/memory-update`
- **AND** it lists all SDD phase commands: `/sdd-new`, `/sdd-ff`, `/sdd-explore`, `/sdd-propose`, `/sdd-spec`, `/sdd-design`, `/sdd-tasks`, `/sdd-apply`, `/sdd-verify`, `/sdd-archive`, `/sdd-status`
- **AND** each command has exactly one line of description

#### Scenario: sdd-ff vs sdd-new decision rule is unambiguous

- **GIVEN** `ai-context/quick-reference.md` has been created
- **WHEN** a user reads the `/sdd-ff` vs `/sdd-new` section
- **THEN** there is a clear criterion that distinguishes the two commands (e.g., "use `/sdd-new` when you need the full cycle with explicit proposal review; use `/sdd-ff` for known changes where you want to proceed directly to implementation")
- **AND** the rule does NOT require the user to read CLAUDE.md to understand it

#### Scenario: File has a parseable Last verified date

- **GIVEN** `ai-context/quick-reference.md` has been created
- **WHEN** the `project-audit` D2 freshness check reads the file
- **THEN** it finds a line matching `Last verified: YYYY-MM-DD` within the first 10 lines of the file
- **AND** the date is parseable as an ISO 8601 date

---

### Requirement: User docs must not overlap or contradict each other

`ai-context/scenarios.md`, `ai-context/quick-reference.md`, and `ai-context/onboarding.md` MUST be consistent. Where the same command appears in multiple documents, its description MUST NOT contradict.

#### Scenario: No conflicting first-command recommendations between docs

- **GIVEN** all three user-facing docs exist
- **WHEN** a user reads the recommendation for a brand-new project in `scenarios.md` and in `onboarding.md`
- **THEN** both documents recommend `/project-setup` as the first command
- **AND** neither document contradicts the other on the expected outcome

#### Scenario: quick-reference glossary is consistent with scenarios.md command sequences

- **GIVEN** `quick-reference.md` glossary and `scenarios.md` command sequences both exist
- **WHEN** a command appears in a scenarios.md command sequence
- **THEN** the same command also appears in the quick-reference glossary
- **AND** its one-line description does not contradict the expected outcome described in scenarios.md
