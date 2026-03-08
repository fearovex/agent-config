# Delta Spec: project-audit-core

## ADDED Requirements

### Requirement: project-audit enforces the active skill contract without legacy heading equivalence

The `project-audit` compatibility policy MAY explain historical terminology, but active-catalog validation MUST treat `## Rules` as the canonical terminal rules heading.

#### Scenario: Active skill validation requires canonical Rules heading

- **GIVEN** a developer reads `skills/project-audit/SKILL.md`
- **WHEN** they inspect the active skill-structure validation guidance
- **THEN** the guidance requires `## Rules` for active skill validation
- **AND** it does not mark `## Execution rules` as a passing equivalent for the live catalog
- **AND** any historical compatibility note is framed as archival context, not as active validation behavior
