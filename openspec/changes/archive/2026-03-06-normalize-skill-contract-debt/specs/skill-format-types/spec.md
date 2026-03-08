# Delta Spec: skill-format-types

## ADDED Requirements

### Requirement: Active procedural skills use a literal Process heading

The active repository catalog MUST treat `## Process` as the canonical main section for procedural skills.

#### Scenario: Active procedural skills expose a literal Process heading

- **GIVEN** an active procedural skill in the live catalog
- **WHEN** the file is read for structure validation
- **THEN** the file exposes a literal `## Process` heading
- **AND** nested `### Step N` headings remain allowed beneath that section
- **AND** alternate top-level headings such as `## Setup Process`, `## Audit Process`, or `## Fix Process` are not used as the active canonical heading

### Requirement: Active skill format docs name canonical Rules only

Active format documentation MUST name `## Rules` as the canonical terminal rules heading for live skills.

#### Scenario: docs/format-types.md describes canonical Rules heading

- **GIVEN** `docs/format-types.md` is read after this change
- **WHEN** any format table lists the required terminal rules section
- **THEN** it names `## Rules`
- **AND** it does not describe `## Execution rules` as an equivalent active heading for live catalog validation
