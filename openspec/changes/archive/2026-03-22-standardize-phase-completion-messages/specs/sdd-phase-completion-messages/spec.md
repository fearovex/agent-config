# Spec: sdd-phase-completion-messages

Change: 2026-03-22-standardize-phase-completion-messages
Date: 2026-03-22

## Overview

This spec defines the observable behavior of phase completion messages across all SDD phase
skills. It establishes a uniform natural language confirmation gate pattern that replaces
the command-as-gate pattern at every inter-phase boundary.

The `sdd-ff` Step 4 gate (natural language) and the `sdd-new` confirmation gates already
conform to this pattern and are excluded from the change scope. This spec covers the
remaining phase skills: `sdd-verify`, `sdd-archive`, `sdd-explore`, `sdd-propose`,
`sdd-spec`, `sdd-design`, and `sdd-tasks`.

---

## Requirements

### Requirement: Natural language gate template

Every SDD phase skill that transitions to the next phase MUST use the following two-line
natural language gate template as its completion message:

```
Continue with <next phase>? Reply **yes** to proceed or **no** to pause.
(Manual: /sdd-<next-phase> <slug>)
```

The natural language question MUST appear on the first line. The command reference MUST
appear on the second line as a parenthetical secondary reference. The command MUST NOT
appear as the sole or primary gate prompt.

#### Scenario: sdd-verify completion message uses natural language gate

- **GIVEN** `sdd-verify` has finished producing the `verify-report.md`
- **WHEN** it presents its completion message to the user
- **THEN** the message MUST read: "Continue with archive? Reply **yes** to proceed or **no** to pause."
- **AND** the command reference MUST appear as: "(Manual: /sdd-archive <slug>)"
- **AND** the message MUST NOT read solely: "Ready to archive. Run: /sdd-archive <slug>"

#### Scenario: sdd-propose completion message uses natural language gate

- **GIVEN** `sdd-propose` has finished writing `proposal.md`
- **WHEN** it presents its completion message
- **THEN** the message MUST read: "Continue with spec and design? Reply **yes** to proceed or **no** to pause."
- **AND** the command reference MUST appear as: "(Manual: /sdd-spec <slug>)"
- **AND** the sole prompt MUST NOT be a command invocation instruction

#### Scenario: sdd-spec completion message uses natural language gate

- **GIVEN** `sdd-spec` has finished writing the delta spec files
- **WHEN** it presents its completion message
- **THEN** the message MUST read: "Continue with design? Reply **yes** to proceed or **no** to pause."
- **AND** the command reference MUST appear as: "(Manual: /sdd-design <slug>)"
- **AND** the gate MUST be conversational — not a copy-paste instruction

#### Scenario: sdd-design completion message uses natural language gate

- **GIVEN** `sdd-design` has finished writing `design.md`
- **WHEN** it presents its completion message
- **THEN** the message MUST read: "Continue with tasks? Reply **yes** to proceed or **no** to pause."
- **AND** the command reference MUST appear as: "(Manual: /sdd-tasks <slug>)"

#### Scenario: sdd-tasks completion message uses natural language gate

- **GIVEN** `sdd-tasks` has finished writing `tasks.md`
- **WHEN** it presents its completion message
- **THEN** the message MUST read: "Continue with implementation? Reply **yes** to proceed or **no** to pause."
- **AND** the command reference MUST appear as: "(Manual: /sdd-apply <slug>)"

#### Scenario: sdd-explore completion message uses natural language gate

- **GIVEN** `sdd-explore` has finished writing `exploration.md` and is invoked as a
  standalone command (not as a sub-agent of `sdd-ff` or `sdd-new`)
- **WHEN** it presents its completion message
- **THEN** the message MUST read: "Continue with proposal? Reply **yes** to proceed or **no** to pause."
- **AND** the command reference MUST appear as: "(Manual: /sdd-propose <slug>)"
- **AND** the gate MUST NOT appear when `sdd-explore` is launched as a sub-agent (no completion gate needed in that context)

---

### Requirement: Command demoted to secondary reference

The slash command for the next phase MUST remain visible but demoted. It MUST NOT be
removed, only repositioned as a parenthetical manual alternative beneath the natural
language question.

#### Scenario: Command reference is present but not primary

- **GIVEN** any SDD phase skill at its completion step
- **WHEN** the natural language gate is displayed
- **THEN** the command reference MUST be present in the output
- **AND** the command MUST appear after the natural language question (second line or below)
- **AND** the command line MUST be visually secondary (e.g., wrapped in parentheses, or smaller emphasis)

#### Scenario: Command reference is not removed

- **GIVEN** any SDD phase skill is updated to use natural language gates
- **WHEN** a user who prefers explicit commands reads the completion message
- **THEN** they MUST be able to see and use the slash command reference
- **AND** typing the command explicitly MUST be treated as equivalent to replying "yes"

---

### Requirement: Consistent wording across all phases

All phase completion natural language gates MUST use the same template structure. Wording
MUST NOT vary between phases beyond the substitution of the next-phase name and slug.

#### Scenario: Wording is consistent across phases

- **GIVEN** a user has observed completion messages from multiple phase skills during a cycle
- **WHEN** they compare the message formats
- **THEN** all messages MUST follow the pattern: "Continue with <X>? Reply **yes** to proceed or **no** to pause."
- **AND** all command references MUST follow the pattern: "(Manual: /sdd-<phase> <slug>)"
- **AND** no phase MUST use a divergent phrasing (e.g., "Shall I continue?", "Would you like to proceed?", "Ready to...")

---

### Requirement: sdd-ff Step 4 and sdd-new gates remain unchanged

The natural language gates in `sdd-ff` Step 4 ("Continue with implementation? Reply **yes** to proceed.") and all `sdd-new` confirmation gates are already compliant and MUST NOT be modified by this change.

#### Scenario: sdd-ff Step 4 gate is not touched

- **GIVEN** `sdd-ff` is fully updated
- **WHEN** Step 4 is examined
- **THEN** it MUST still read: "Continue with implementation? Reply **yes** to proceed."
- **AND** it MUST NOT be reformatted to match the two-line template (it already conforms in spirit)

---

### Requirement: Affirmative replies to the gate trigger the next phase

When the gate is active, an affirmative reply from the user MUST trigger the next phase
without requiring the user to type the slash command.

#### Scenario: User replies "yes" at any phase gate

- **GIVEN** any phase skill has presented the natural language gate
- **WHEN** the user replies with an affirmative ("yes", "y", "proceed", "go ahead", "continue", or equivalent)
- **THEN** the next phase MUST begin without further user input
- **AND** the user MUST NOT be required to re-type the slash command to proceed

#### Scenario: User replies "no" at any phase gate

- **GIVEN** any phase skill has presented the natural language gate
- **WHEN** the user replies with a negative ("no", "n", "pause", "stop", or equivalent)
- **THEN** the phase skill MUST acknowledge the pause and NOT launch the next phase
- **AND** the slash command reference remains available for when the user is ready

#### Scenario: User types the slash command directly — treated as affirmative

- **GIVEN** any phase skill has presented the natural language gate
- **WHEN** the user types the displayed slash command explicitly (e.g., "/sdd-archive <slug>")
- **THEN** this MUST be treated as equivalent to "yes"
- **AND** the next phase MUST begin

---

## Rules

- The natural language question is the PRIMARY gate — the slash command is a secondary reference only
- The two-line pattern (question + command) is the required format for all phase boundaries covered by this spec
- sdd-ff Step 4 and sdd-new gates are explicitly out of scope — they are already compliant and MUST NOT be touched
- Phase skills invoked as sub-agents (not standalone) MAY omit the gate: the orchestrator (sdd-ff, sdd-new) manages continuation in those contexts
- Affirmative replies and direct command input are both valid gate responses — neither is preferred over the other
- Wording divergence (synonyms, reordering) is a violation of the consistency requirement
