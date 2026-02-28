# Delta Spec: memory-management

Change: audit-and-analyze-capabilities
Date: 2026-02-28
Base: skills/memory-manager/SKILL.md (no existing openspec spec)

## ADDED — conventions.md support in /memory-update

### Requirement: `/memory-update` includes conventions.md in its update decision table

The `/memory-update` process Step 2 decision table MUST include a row for `conventions.md` so that convention changes observed during a session can be recorded.

#### Scenario: conventions.md row exists in /memory-update decision table

- **GIVEN** `skills/memory-manager/SKILL.md` is read
- **WHEN** the `/memory-update` process Step 2 decision table is examined
- **THEN** a row for `conventions.md` is present
- **AND** the trigger condition for that row specifies: "coding patterns, naming conventions, or import styles changed during the session"
- **AND** the update action describes adding or modifying convention entries in `ai-context/conventions.md`

#### Scenario: /memory-update updates conventions.md when coding patterns change

- **GIVEN** a session where the user changed the project's naming convention from camelCase to snake_case
- **WHEN** `/memory-update` is invoked at the end of the session
- **THEN** the skill recognizes that conventions changed
- **AND** it updates `ai-context/conventions.md` with the new convention information
- **AND** it does NOT overwrite or remove `[auto-updated]` sections that were written by `project-analyze`

#### Scenario: /memory-update does NOT update conventions.md when no convention changes occurred

- **GIVEN** a session where the user added a new API endpoint but did not change any coding patterns
- **WHEN** `/memory-update` is invoked
- **THEN** `ai-context/conventions.md` is NOT modified
- **AND** the summary output does not list `conventions.md` as an updated file

#### Scenario: conventions.md update preserves auto-updated markers

- **GIVEN** `ai-context/conventions.md` contains an `[auto-updated]: observed-conventions` section written by `project-analyze`
- **AND** the user changed a naming convention during the session
- **WHEN** `/memory-update` runs
- **THEN** the `[auto-updated]` section boundaries are preserved intact
- **AND** the new convention entry is written outside the `[auto-updated]` markers
- **AND** the content between the markers is NOT modified by memory-manager
