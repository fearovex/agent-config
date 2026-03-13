# Delta Spec: Sub-Agent Governance Injection

Change: 2026-03-12-fix-subagent-project-context
Date: 2026-03-12
Base: N/A (new spec)

---

## Overview

This spec defines the observable behavior of governance context injection into sub-agent prompts launched by orchestrator skills (`sdd-ff`, `sdd-new`). The goal is to ensure sub-agents have visibility to project-level governance (CLAUDE.md) at startup, similar to the upfront context priming Copilot receives.

---

## Requirements

### Requirement: Orchestrator includes explicit governance path in sub-agent CONTEXT

When `sdd-ff` or `sdd-new` launches a sub-agent via the Task tool, the CONTEXT block MUST include an explicit reference to the project's CLAUDE.md file.

#### Scenario: Sub-agent prompt contains governance path

- **GIVEN** the orchestrator (`sdd-ff` or `sdd-new`) is about to launch a sub-agent (e.g., `sdd-explore`)
- **WHEN** it constructs the Task tool input prompt
- **THEN** the CONTEXT section MUST include a new line: `- Project governance: <project-root>/CLAUDE.md`
- **AND** this line MUST appear after the `- Project:` line and before the `- Change:` line

#### Scenario: Governance path is absolute and resolvable

- **GIVEN** the sub-agent receives the injected governance path in the Task prompt
- **WHEN** it attempts to read the file
- **THEN** the path MUST be an absolute path pointing to the project CLAUDE.md
- **AND** the path MUST be resolvable by the sub-agent's file read operations

#### Scenario: Path is included for all sub-agent launches

- **GIVEN** the orchestrator launches multiple sub-agents in sequence (explore, propose, spec, design, tasks)
- **WHEN** each sub-agent is invoked
- **THEN** every sub-agent prompt MUST include the governance path
- **AND** the path MUST be consistent across all launches for the same project

#### Scenario: Governance path is non-blocking if CLAUDE.md is absent

- **GIVEN** a project lacks a CLAUDE.md file
- **AND** the sub-agent receives the governance path in the CONTEXT block
- **WHEN** the sub-agent attempts to read the file
- **THEN** the read failure MUST NOT prevent the sub-agent from executing
- **AND** the sub-agent MUST emit an INFO-level note and continue execution

---

### Requirement: Sub-agent prompts reference governance visibility in instructions

The Task tool prompt text MUST instruct sub-agents to read the project governance file at Step 0 startup.

#### Scenario: Task prompt instructs sub-agent to read governance

- **GIVEN** the orchestrator has constructed the Task prompt
- **AND** the CONTEXT block contains the governance path
- **WHEN** the sub-agent reads the prompt
- **THEN** the prompt text MUST explicitly reference the governance path
- **AND** the prompt MUST direct the sub-agent to read it as part of Step 0a (context loading)

#### Scenario: Instruction is placed early in the prompt

- **GIVEN** a sub-agent prompt is structured with STEP 1, STEP 2, CONTEXT, TASK
- **WHEN** the instructions are read
- **THEN** the reference to governance reading MUST appear in the CONTEXT block or in STEP 2
- **AND** it MUST be read before the TASK description is processed

---

## Validation Criteria

- [ ] All sub-agent invocations in `sdd-ff` include the governance path in CONTEXT
- [ ] All sub-agent invocations in `sdd-new` include the governance path in CONTEXT
- [ ] The governance path is an absolute path to the project CLAUDE.md
- [ ] The path is consistent across all sub-agent launches in a single cycle
- [ ] Sub-agents can read and parse the governance file without errors
- [ ] Missing CLAUDE.md does not block sub-agent execution (non-blocking per Step 0a rules)
- [ ] The Task prompt explicitly instructs sub-agents to read governance in Step 0a

---

## Scenarios Not Covered (out of scope)

- Parsing and extracting specific sections from CLAUDE.md (handled in governance-discovery spec)
- Caching or memoizing the governance file
- Validation of CLAUDE.md content correctness
- Merging governance rules across multiple CLAUDE.md files in parent directories
