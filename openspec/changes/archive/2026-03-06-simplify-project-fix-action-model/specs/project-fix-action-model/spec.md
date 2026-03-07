# Spec: project-fix-action-model

Change: simplify-project-fix-action-model
Date: 2026-03-06

## Requirements

### Requirement: project-fix exposes an explicit execution model

The `project-fix` skill MUST describe its command flow as a stable execution model with three stages: manifest intake, phase execution, and final reporting.

#### Scenario: Skill documents the execution model as a top-level contract

- **GIVEN** a developer reads `skills/project-fix/SKILL.md`
- **WHEN** they read the top-level structure before the phase details
- **THEN** they find an explicit section describing the execution model
- **AND** that section names manifest intake, phase execution, and final reporting as the core stages
- **AND** that section states that the command never invents fixes outside `FIX_MANIFEST`

### Requirement: project-fix classifies actions by behavior type

The `project-fix` skill MUST distinguish between automatic actions, guided actions, and informational actions.

#### Scenario: Action classes are separated conceptually

- **GIVEN** a developer reads `skills/project-fix/SKILL.md`
- **WHEN** they inspect the action model before the handler details
- **THEN** they can identify which actions are automatic
- **AND** they can identify which actions always require confirmation
- **AND** they can identify which actions are informational only

#### Scenario: Existing handlers remain valid under the action classes

- **GIVEN** `skills/project-fix/SKILL.md` has been updated by this change
- **WHEN** the handler sections are read
- **THEN** the existing handler details are still present
- **AND** the action-class section acts as an umbrella contract rather than replacing handler behavior

### Requirement: project-fix has an explicit compatibility policy

The `project-fix` skill MUST describe compatibility behavior as a separate policy layer.

#### Scenario: Compatibility rules are described separately from handlers

- **GIVEN** a developer reads `skills/project-fix/SKILL.md`
- **WHEN** they inspect the top-level contract sections
- **THEN** they find a compatibility policy section
- **AND** that section describes how deprecated, stale, or unknown action types are handled separately from ordinary action execution

### Requirement: unknown or deprecated action types never trigger automatic side effects

If `project-fix` encounters an action type that is deprecated, unsupported, or unknown, it MUST produce a recommendation or skip note rather than performing an automatic mutation.

#### Scenario: Unknown action type is treated as non-automatic

- **GIVEN** a `FIX_MANIFEST` contains an action type not recognized by `project-fix`
- **WHEN** `/project-fix` evaluates the action
- **THEN** the action is not executed automatically
- **AND** the user receives a note that the action was skipped or downgraded to recommendation
- **AND** no side effects occur from that unknown action type

### Requirement: project-fix has a direct master spec domain as one product

The repository MUST define a `project-fix-action-model` spec domain that describes `project-fix` as one product-level command.

#### Scenario: New master spec exists after archive

- **GIVEN** the change `simplify-project-fix-action-model` has been archived
- **WHEN** the filesystem is inspected
- **THEN** `openspec/specs/project-fix-action-model/spec.md` exists
- **AND** it describes the execution model, action classes, and compatibility policy
- **AND** it complements rather than replaces `project-fix-behavior` and `fix-setup-behavior`

## Rules

- This change is structural and contractual; it MUST NOT alter the command name `/project-fix`
- This change MUST preserve the rule that `project-fix` only implements `FIX_MANIFEST`
- This change MUST preserve the no-commands constraint and the no-global-write constraint already defined in existing specs
- The new `project-fix-action-model` spec is the umbrella product contract; existing detailed behavior specs remain valid