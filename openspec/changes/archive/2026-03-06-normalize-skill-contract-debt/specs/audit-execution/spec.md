# Delta Spec: audit-execution

## ADDED Requirements

### Requirement: Batching rule is documented in the canonical Rules section

The batching constraint in `project-audit` MUST live in the skill's canonical `## Rules` section.

#### Scenario: Rules section contains the batching constraint

- **GIVEN** a developer or Claude reads `skills/project-audit/SKILL.md`
- **WHEN** they read the `## Rules` section
- **THEN** they find a rule that explicitly states shell discovery must be consolidated into a single Bash script call
- **AND** the rule states the maximum number of Bash calls allowed per audit run
- **AND** the rule prohibits individual ad-hoc shell discovery calls per dimension
