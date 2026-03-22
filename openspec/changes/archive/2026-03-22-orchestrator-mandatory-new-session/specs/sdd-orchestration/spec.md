# Delta Spec: SDD Orchestration — sdd-ff Confirmation Gate

Change: 2026-03-21-orchestrator-mandatory-new-session
Date: 2026-03-22
Base: openspec/specs/sdd-orchestration/spec.md

## MODIFIED — Modified requirements

### Requirement: sdd-ff Step 4 — ask-before-apply gate uses natural language

_(Before: Step 4 presented "Ready to implement? Run: `/sdd-apply <slug>`" as the primary gate — a command-as-gate pattern.)_

The sdd-ff skill MUST present the ask-before-apply gate as a natural language question. The slash command MUST be demoted to a secondary, optional reference.

#### Scenario: sdd-ff step 4 confirmation gate (natural language)

- **GIVEN** all sdd-ff phases (explore, propose, spec, design, tasks) have completed successfully
- **WHEN** the orchestrator presents Step 4 to the user
- **THEN** the gate MUST read: "Continue with implementation? Reply **yes** to proceed."
- **AND** the command reference MUST appear as a secondary note: "_(Manual: `/sdd-apply <slug>`)_"
- **AND** it MUST NOT read: "Ready to implement? Run: `/sdd-apply <slug>`" as the sole or primary prompt

#### Scenario: User replies "yes" to apply gate triggers sdd-apply

- **GIVEN** the sdd-ff ask-before-apply gate is active
- **WHEN** the user replies with an affirmative ("yes", "y", "proceed", "go ahead", "continue")
- **THEN** the orchestrator MUST launch the `sdd-apply` sub-agent via Task tool
- **AND** it MUST NOT require the user to re-type the `/sdd-apply <slug>` command

#### Scenario: User replies with the command directly — also accepted

- **GIVEN** the sdd-ff ask-before-apply gate is active
- **WHEN** the user types `/sdd-apply <slug>` explicitly
- **THEN** the orchestrator MUST treat this as equivalent to "yes" and launch sdd-apply
- **AND** commands remain valid as an alternative input path
