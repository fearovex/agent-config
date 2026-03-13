# Delta Spec: Sub-Agent Execution Contract Update

Change: 2026-03-12-fix-subagent-project-context
Date: 2026-03-12
Base: openspec/agent-execution-contract.md

---

## Overview

This delta updates the agent execution contract to document the addition of the "Project governance" CONTEXT field and clarifies the sub-agent output format for governance visibility reporting.

---

## ADDED — New requirements

### Requirement: Agent Execution Contract documents Project governance CONTEXT field

The agent execution contract MUST include documentation of the new "Project governance" field in the CONTEXT section of the sub-agent input prompt.

#### Scenario: Contract input format includes governance path

- **GIVEN** the agent execution contract describes the input format for sub-agents
- **WHEN** the CONTEXT block is documented
- **THEN** a new entry MUST be added to the CONTEXT fields table:
  ```
  | Field | Type | Required | Description |
  | Project governance | absolute path | no | Path to project CLAUDE.md for governance context injection |
  ```
- **AND** the field MUST be listed after the `Project` field and before the `Change` field

#### Scenario: Contract example prompt includes governance path

- **GIVEN** the contract includes an example Task tool prompt
- **WHEN** the example CONTEXT block is shown
- **THEN** the example MUST include a line like: `- Project governance: <project-root>/CLAUDE.md`
- **AND** the line MUST be annotated with a brief description: "Governance rules and tech stack for context priming"

#### Scenario: Governance path field is non-blocking per Step 0a rules

- **GIVEN** the contract documents the governance path field
- **WHEN** a sub-agent cannot read the file (missing CLAUDE.md)
- **THEN** the contract MUST note: "Non-blocking — if absent, sub-agent logs INFO note and continues"

---

### Requirement: Sub-agent output documents governance visibility in summary

Sub-agents MUST include governance visibility information in their output summary to the orchestrator.

#### Scenario: Sub-agent summary reports loaded governance

- **GIVEN** a sub-agent completes Step 0a (governance discovery)
- **WHEN** it produces its output to the orchestrator
- **THEN** the `summary` field MUST include a governance visibility note, such as:
  ```
  Loaded project governance: 5 unbreakable rules, tech stack: Markdown + YAML + Bash, intent classification: enabled.
  Spec for [change-name]: [N] requirements, [M] scenarios.
  ```
- **AND** the governance note MUST appear early in the summary (before domain/artifact specifics)

#### Scenario: Sub-agent output indicates governance loading failure gracefully

- **GIVEN** a sub-agent attempted to load governance but the CLAUDE.md file was absent
- **WHEN** it produces its output
- **THEN** the `summary` field SHOULD include a note: `(governance context unavailable — using global defaults)`
- **AND** the status MUST remain `ok` or `warning` (never `blocked` or `failed` due to missing governance)

#### Scenario: Governance visibility improves artifact quality assessment

- **GIVEN** the orchestrator receives sub-agent output with governance visibility information
- **WHEN** it evaluates the artifacts
- **THEN** the governance visibility note MUST help the orchestrator assess whether sub-agent decisions reflect project conventions
- **AND** if governance shows intent classification is disabled, the orchestrator MUST adjust expectations for sub-agent behavior

---

### Requirement: Contract documents governance-informed decision verification

The contract MUST clarify that sub-agent artifacts SHOULD be verifiable against loaded governance rules.

#### Scenario: Artifacts are checked against loaded governance

- **GIVEN** a sub-agent has reported loaded governance (e.g., "English-only content rule")
- **WHEN** the orchestrator or a subsequent phase reviews artifacts
- **THEN** artifacts SHOULD be spot-checked for compliance with the stated rules
- **AND** if a violation is found, it is flagged as a `DEVIATION` (not a contract breach, but a decision inconsistency)

#### Scenario: Contract provides example governance verification

- **GIVEN** the contract is read by a skill author
- **WHEN** they implement a phase that consumes sub-agent output
- **THEN** the contract SHOULD include an example of governance verification:
  ```
  Example: If sub-agent reported "English-only content rule", verify that all generated
  text is in English. If non-English content is found, log: DEVIATION — governance rule violated.
  ```

---

## MODIFIED — Modified requirements

### Requirement: Input CONTEXT section is expanded

*Before:* CONTEXT block contains `Project`, `Change`, `Previous artifacts`.

*After:* CONTEXT block contains `Project`, `Project governance` (new), `Change`, `Previous artifacts`.

#### Scenario: CONTEXT block field order

- **GIVEN** a sub-agent receives a Task prompt with the updated CONTEXT block
- **WHEN** the fields are read
- **THEN** the order MUST be:
  1. `Project: <path>`
  2. `Project governance: <path>` (NEW)
  3. `Change: <slug>`
  4. `Previous artifacts: <list>`

---

### Requirement: Sub-agent output summary format includes governance visibility

*Before:* Summary field contains only phase-specific information (e.g., "Spec for X: N requirements, M scenarios").

*After:* Summary field MUST start with a governance visibility line before phase-specific content.

#### Scenario: Summary format example

- **GIVEN** `sdd-spec` completes execution
- **WHEN** it produces output
- **THEN** the summary MUST follow this format:
  ```
  Loaded project governance: [count] unbreakable rules, tech stack: [stack], intent classification: [enabled|disabled|restricted].
  Spec for [change-name]: [N] requirements, [M] scenarios.
  ```

#### Scenario: Summary order ensures governance context appears first

- **GIVEN** a sub-agent writes its output summary
- **WHEN** the summary is formatted
- **THEN** governance visibility MUST be the first sentence
- **AND** phase-specific content MUST follow after a period or paragraph break

---

## Rules

- The Project governance field is optional (no|yes) because CLAUDE.md may not exist
- When the field is absent from the CONTEXT, sub-agents MUST NOT attempt to read governance (graceful fallback)
- Governance visibility notes in summary MUST be concise (one sentence maximum, 100 characters)
- Contract documents MUST NOT mandate governance compliance in sub-agent artifacts — governance is enrichment, not enforcement
- Governance deviations are logged as DEVIATION, not ERROR, allowing human judgment in exception cases

---

## Validation Criteria

- [ ] Agent execution contract documents "Project governance" CONTEXT field
- [ ] Field is positioned after "Project" and before "Change"
- [ ] Example prompt in contract includes governance path
- [ ] Sub-agent output summary includes governance visibility line
- [ ] Governance visibility note appears at the start of summary
- [ ] Missing CLAUDE.md is handled gracefully (no blocking)
- [ ] Contract clarifies governance is enrichment, not enforcement
- [ ] Governance verification example is provided for skill authors
