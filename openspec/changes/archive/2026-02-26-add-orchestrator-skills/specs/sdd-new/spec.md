# Spec: sdd-new

Change: add-orchestrator-skills
Date: 2026-02-26

## Requirements

### Requirement: Argument parsing

The skill MUST accept a single positional argument `<change-name>`. If missing, the skill MUST stop and ask the user to supply it before proceeding.

#### Scenario: Change name provided
- **GIVEN** the user invokes `/sdd-new add-auth`
- **WHEN** the skill begins execution
- **THEN** `add-auth` is used as the change name for all subsequent phases and artifact paths

#### Scenario: Change name missing
- **GIVEN** the user invokes `/sdd-new` with no argument
- **WHEN** the skill begins execution
- **THEN** the skill MUST stop and ask: "What is the name of the change? (e.g. `/sdd-new my-change-name`)"
- **AND** MUST NOT proceed until a valid name is provided

---

### Requirement: Optional explore phase with user confirmation

Before proposing, the skill MUST ask the user whether an exploration phase is needed. The explore phase is only launched if the user explicitly confirms it.

#### Scenario: User requests explore phase
- **GIVEN** the skill asks "Do you need an exploration phase before proposing? (yes/no)"
- **WHEN** the user replies affirmatively
- **THEN** the skill MUST launch `sdd-explore` as a sub-agent with the change name
- **AND** MUST wait for the explore sub-agent to complete before proceeding to propose
- **AND** the exploration artifact path MUST be passed to the `sdd-propose` sub-agent as prior context

#### Scenario: User skips explore phase
- **GIVEN** the skill asks about the exploration phase
- **WHEN** the user replies negatively or says "skip"
- **THEN** the skill MUST proceed directly to the `sdd-propose` phase without launching `sdd-explore`

#### Scenario: Explore phase returns blocked or failed
- **GIVEN** the user requested an explore phase
- **WHEN** `sdd-explore` returns status `blocked` or `failed`
- **THEN** the skill MUST surface the blocking summary to the user
- **AND** MUST ask whether to proceed to `sdd-propose` anyway or abort the cycle

---

### Requirement: Propose, spec+design, tasks sequence with confirmation gates

After the optional explore step, the skill MUST execute: `sdd-propose` → (`sdd-spec` + `sdd-design` in parallel) → `sdd-tasks`. Each phase transition MUST be gated by a user confirmation step.

#### Scenario: Propose completes — user confirms proceeding to spec+design
- **GIVEN** `sdd-propose` completes with status `ok` or `warning`
- **WHEN** the skill presents the proposal summary to the user
- **THEN** the skill MUST ask: "Proposal looks good. Proceed to spec + design (parallel)? (yes/no)"
- **AND** MUST NOT launch spec or design until the user confirms

#### Scenario: User declines to proceed after propose
- **GIVEN** the skill asks for confirmation to proceed to spec+design
- **WHEN** the user replies negatively
- **THEN** the skill MUST stop the cycle at the proposal phase
- **AND** MUST inform the user they can resume with `/sdd-spec <change-name>` and `/sdd-design <change-name>` when ready

#### Scenario: Spec+design complete — user confirms proceeding to tasks
- **GIVEN** both `sdd-spec` and `sdd-design` complete with status `ok` or `warning`
- **WHEN** the skill presents the spec+design summary
- **THEN** the skill MUST ask: "Specs and design ready. Proceed to tasks? (yes/no)"
- **AND** MUST NOT launch `sdd-tasks` until the user confirms

#### Scenario: Propose returns blocked or failed
- **GIVEN** `sdd-propose` returns status `blocked` or `failed`
- **WHEN** the skill receives the result
- **THEN** the skill MUST stop the full cycle
- **AND** MUST surface the blocking summary and risks

#### Scenario: One of spec or design returns blocked or failed
- **GIVEN** at least one of the parallel phases returns `blocked` or `failed`
- **WHEN** the skill receives both results
- **THEN** the skill MUST stop before asking confirmation for tasks
- **AND** MUST present both phase results to the user

---

### Requirement: Full DAG status and remaining phases reminder

After `sdd-tasks` completes, the skill MUST present a complete summary of all completed phases and remind the user of the phases that remain (apply, verify, archive) and their commands.

#### Scenario: Tasks phase completes successfully
- **GIVEN** all five phases (optional explore + propose + spec + design + tasks) have completed
- **WHEN** the skill presents the final output
- **THEN** the user MUST see: a phase-by-phase completion table, all artifacts created, all risks, and a reminder of the remaining phases
- **AND** the reminder MUST list: `/sdd-apply <change-name>`, `/sdd-verify <change-name>`, `/sdd-archive <change-name>` in order

#### Scenario: Summary explicitly marks optional explore as skipped
- **GIVEN** the user chose to skip the explore phase
- **WHEN** the final summary is presented
- **THEN** the explore row MUST appear in the phase table marked as "skipped"

---

### Requirement: Sub-agent launch protocol

All sub-agents MUST be launched via the Task tool with the standard SDD delegation prompt, supplying absolute project path, change name, and prior artifact paths.

#### Scenario: Each sub-agent receives correct context
- **GIVEN** the skill is launching any SDD sub-agent
- **WHEN** the Task tool is invoked
- **THEN** the prompt MUST instruct the sub-agent to read its own SKILL.md as the first step
- **AND** MUST include the absolute project path and change name
- **AND** MUST include all previously created artifact paths from earlier phases in this cycle
