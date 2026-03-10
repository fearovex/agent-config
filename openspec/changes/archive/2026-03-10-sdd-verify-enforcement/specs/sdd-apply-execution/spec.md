# Delta Spec: sdd-apply-execution

Change: 2026-03-10-sdd-verify-enforcement
Date: 2026-03-10
Base: openspec/specs/sdd-apply-execution/spec.md

## ADDED — New requirements

### Requirement: sdd-apply final output MUST NOT suggest /commit

The `sdd-apply` skill MUST NOT include a `/commit` suggestion in its final output summary to the user. The only permitted next-step suggestion is `/sdd-verify <change-name>`.

#### Scenario: Final output suggests /sdd-verify only

- **GIVEN** `sdd-apply` has completed implementation of all assigned tasks
- **WHEN** it produces its final output summary to the user
- **THEN** the summary MUST include a suggestion to run `/sdd-verify <change-name>`
- **AND** the summary MUST NOT contain any mention of `/commit` or `git commit`

#### Scenario: Final output does not offer commit as an alternative

- **GIVEN** `sdd-apply` has completed all tasks for a phase
- **WHEN** the phase summary is presented
- **THEN** there MUST be no "Ready to /commit?" prompt or equivalent
- **AND** there MUST be no text suggesting the user can commit now

---

## Rules

- The `/commit` suggestion prohibition applies to ALL phases of `sdd-apply`, not only the final phase
- No exception exists for changes that are "obviously correct" or "documentation-only" — the rule is unconditional
- The next-step suggestion MUST use the exact form: `/sdd-verify <change-name>`
