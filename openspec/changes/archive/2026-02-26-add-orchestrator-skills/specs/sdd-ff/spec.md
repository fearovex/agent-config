# Spec: sdd-ff

Change: add-orchestrator-skills
Date: 2026-02-26

## Requirements

### Requirement: Argument parsing

The skill MUST accept a single positional argument `<change-name>` supplied by the user after the `/sdd-ff` trigger. The argument MUST be treated as the canonical change identifier used to locate and create artifacts under `openspec/changes/<change-name>/`.

#### Scenario: Change name provided
- **GIVEN** the user invokes `/sdd-ff my-feature`
- **WHEN** the skill begins execution
- **THEN** `my-feature` is used as the change name for all subsequent sub-agent invocations and artifact paths

#### Scenario: Change name missing
- **GIVEN** the user invokes `/sdd-ff` with no argument
- **WHEN** the skill begins execution
- **THEN** the skill MUST stop immediately and ask the user: "What is the name of the change? (e.g. `/sdd-ff my-feature-name`)"
- **AND** the skill MUST NOT launch any sub-agent until a valid change name is provided

#### Scenario: Change name contains spaces or special characters
- **GIVEN** the user invokes `/sdd-ff "my feature"` or `/sdd-ff my feature`
- **WHEN** the skill begins execution
- **THEN** the skill SHOULD warn the user that change names must be kebab-case with no spaces
- **AND** SHOULD suggest a normalized version (e.g. `my-feature`)
- **AND** MUST ask for confirmation before proceeding

---

### Requirement: Sequential phase orchestration

The skill MUST execute the SDD fast-forward sequence in strict order: `sdd-propose`, then `sdd-spec` and `sdd-design` in parallel, then `sdd-tasks`. The skill MUST NOT advance to the next phase until the current phase reports status `ok` or `warning`.

#### Scenario: Successful propose phase
- **GIVEN** the change name is valid
- **WHEN** the skill launches the `sdd-propose` sub-agent and receives status `ok`
- **THEN** the skill MUST proceed to launch `sdd-spec` and `sdd-design` simultaneously

#### Scenario: Propose phase returns blocked or failed
- **GIVEN** the `sdd-propose` sub-agent returns status `blocked` or `failed`
- **WHEN** the skill receives the result
- **THEN** the skill MUST stop the fast-forward sequence
- **AND** MUST present the sub-agent's summary and risks to the user
- **AND** MUST NOT launch spec, design, or tasks phases

#### Scenario: Spec or design phase returns blocked or failed
- **GIVEN** at least one of `sdd-spec` or `sdd-design` returns status `blocked` or `failed`
- **WHEN** the skill receives both parallel results
- **THEN** the skill MUST stop before launching `sdd-tasks`
- **AND** MUST surface the blocking sub-agent's summary and risks to the user

#### Scenario: All phases complete with warning status
- **GIVEN** one or more phases return status `warning` (but none return `blocked` or `failed`)
- **WHEN** the skill assembles the final summary
- **THEN** the skill MUST proceed through all phases to completion
- **AND** MUST highlight warnings prominently in the final summary

---

### Requirement: Parallel spec and design execution

The skill MUST launch `sdd-spec` and `sdd-design` as two independent concurrent sub-agents after `sdd-propose` completes. It MUST wait for both to finish before launching `sdd-tasks`.

#### Scenario: Both parallel phases succeed
- **GIVEN** `sdd-propose` has completed with status `ok` or `warning`
- **WHEN** the skill launches `sdd-spec` and `sdd-design`
- **THEN** both MUST be started without waiting for either one to finish first
- **AND** the skill MUST collect both results before proceeding

#### Scenario: Spec finishes before design
- **GIVEN** `sdd-spec` completes before `sdd-design`
- **WHEN** the skill receives the spec result
- **THEN** the skill MUST wait for `sdd-design` to complete before proceeding to `sdd-tasks`
- **AND** MUST NOT launch `sdd-tasks` with only one of the two parallel results available

---

### Requirement: Sub-agent launch protocol

Each sub-agent MUST be launched using the Task tool with the standard SDD delegation prompt. The prompt MUST supply: the absolute project path, the change name, and the list of artifact paths from all prior phases.

#### Scenario: Sub-agent prompt is well-formed
- **GIVEN** the skill is launching `sdd-propose` for change `my-feature` in project `/home/user/my-project`
- **WHEN** the Task tool is invoked
- **THEN** the prompt MUST include the absolute project path `/home/user/my-project`
- **AND** the prompt MUST include the change name `my-feature`
- **AND** the prompt MUST instruct the sub-agent to read `~/.claude/skills/sdd-propose/SKILL.md` as its first step

#### Scenario: Sub-agent for spec receives proposal artifact path
- **GIVEN** `sdd-propose` completed and created `openspec/changes/my-feature/proposal.md`
- **WHEN** the skill launches `sdd-spec`
- **THEN** the Task prompt MUST include `openspec/changes/my-feature/proposal.md` in the previous artifacts list

---

### Requirement: Complete summary presentation

After all four phases complete, the skill MUST present a consolidated summary to the user containing the results of all phases before asking for apply confirmation.

#### Scenario: Summary after successful fast-forward
- **GIVEN** all four phases (propose, spec, design, tasks) have completed
- **WHEN** the skill presents the final output
- **THEN** the user MUST see: the change name, the status of each phase, the list of all artifacts created, and any risks surfaced by any phase
- **AND** the skill MUST end with the question: "Ready to implement with `/sdd-apply <change-name>`?"

#### Scenario: Summary includes warnings
- **GIVEN** one phase returned status `warning` with risks listed
- **WHEN** the skill presents the final output
- **THEN** the warning risks MUST be displayed in a clearly marked section before the apply confirmation prompt

---

### Requirement: Apply confirmation gate

The skill MUST ask the user for explicit confirmation before the session ends. It MUST NOT automatically invoke `/sdd-apply`. The user's reply determines the next action outside this skill's scope.

#### Scenario: User confirms readiness
- **GIVEN** the skill presents the apply confirmation prompt
- **WHEN** the user replies affirmatively (e.g. "yes", "go ahead", "apply")
- **THEN** the skill MUST inform the user to run `/sdd-apply <change-name>` to continue
- **AND** MUST NOT invoke sdd-apply itself

#### Scenario: User declines or asks for changes
- **GIVEN** the skill presents the apply confirmation prompt
- **WHEN** the user replies negatively or requests modifications
- **THEN** the skill MUST acknowledge and stop — the SDD cycle remains paused at the tasks phase
