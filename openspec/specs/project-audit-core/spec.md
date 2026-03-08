# Spec: project-audit-core

Change: rewrite-project-audit-core
Date: 2026-03-06

## Requirements

### Requirement: project-audit exposes an explicit audit kernel

The `project-audit` skill MUST describe its command flow as a stable audit kernel with three stages: discovery, evaluation, and report generation.

#### Scenario: Skill documents the audit kernel as a top-level contract

- **GIVEN** a developer reads `skills/project-audit/SKILL.md`
- **WHEN** they read the top-level structure before the dimension bodies
- **THEN** they find an explicit section describing the audit kernel
- **AND** that section names discovery, evaluation, and report generation as the core stages
- **AND** the section states that the command remains read-only

#### Scenario: Audit kernel does not replace detailed dimension behavior

- **GIVEN** `skills/project-audit/SKILL.md` has been updated by this change
- **WHEN** the dimension sections are read
- **THEN** the existing detailed dimension behavior is still present
- **AND** the kernel section acts as an umbrella contract rather than a replacement for the dimension definitions

### Requirement: project-audit classifies dimensions by behavior type

The `project-audit` skill MUST distinguish between scored dimensions, informational dimensions, and compatibility rules.

#### Scenario: Scored and informational dimensions are separated conceptually

- **GIVEN** a developer reads `skills/project-audit/SKILL.md`
- **WHEN** they inspect the audit model before the dimension bodies
- **THEN** they can identify which dimensions contribute to the 100-point score
- **AND** they can identify which dimensions are informational only
- **AND** the distinction is described without changing the existing scoring table

#### Scenario: Compatibility rules are described separately from dimensions

- **GIVEN** a developer reads `skills/project-audit/SKILL.md`
- **WHEN** they inspect the contract sections before the dimension bodies
- **THEN** they find a compatibility policy section
- **AND** that section describes the role of transitional compatibility behavior separately from the dimension classes

### Requirement: project-audit avoids fragile count-based framing in its top-level process header

The main audit-process heading in `skills/project-audit/SKILL.md` MUST NOT depend on a hardcoded numeric dimension count.

#### Scenario: Main audit process heading is count-free

- **GIVEN** `skills/project-audit/SKILL.md` has been updated by this change
- **WHEN** a developer reads the main process heading
- **THEN** the heading does not claim a numeric total such as "10 Dimensions"
- **AND** the heading remains clear about the role of the section

### Requirement: project-audit has a direct master spec domain as one product

The repository MUST define a `project-audit-core` spec domain that describes `project-audit` as one product-level command.

#### Scenario: New master spec exists after archive

- **GIVEN** the change `rewrite-project-audit-core` has been archived
- **WHEN** the filesystem is inspected
- **THEN** `openspec/specs/project-audit-core/spec.md` exists
- **AND** it describes the audit kernel, dimension classification, and compatibility policy
- **AND** it complements rather than replaces `audit-execution`, `audit-dimensions`, and `audit-scoring`

### Requirement: project-audit uses canonical headings for active skill validation

The `project-audit` compatibility policy MAY acknowledge historical terminology, but the live validation contract MUST use canonical `## Process` and `## Rules` headings for active procedural skills.

#### Scenario: Compatibility policy keeps history separate from active validation

- **GIVEN** a developer reads `skills/project-audit/SKILL.md`
- **WHEN** they compare the compatibility policy with the skill-structure checks
- **THEN** the compatibility policy may mention historical terminology
- **AND** the active validation logic still requires `## Process` and `## Rules` for procedural skills
- **AND** the skill does not present `## Execution rules` as a passing equivalent for the live catalog

## Rules

- This change is structural and contractual; it MUST NOT alter the command name `/project-audit`
- This change MUST NOT change the read-only nature of `project-audit`
- This change MUST NOT alter the existing 100-point scoring model
- The new `project-audit-core` spec is the umbrella product contract; cross-cutting audit specs remain valid detailed specs