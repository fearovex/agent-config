# Spec: Orchestrator Always-On Behavior

Change: 2026-03-12-orchestrator-always-on
Date: 2026-03-12

## Requirements

### Requirement: Intent classification before every response

The orchestrator MUST classify the user's intent before generating any response to a free-form message.

#### Scenario: Change request triggers SDD recommendation

- **GIVEN** a session is active and the user sends a free-form message containing change intent (e.g., "fix this bug", "add feature X", "implement Y")
- **WHEN** the orchestrator receives the message
- **THEN** it MUST NOT write implementation code, specs, or designs inline
- **AND** it MUST recommend the appropriate SDD command (`/sdd-ff <slug>` for most cases) or launch `sdd-explore` via Task tool

#### Scenario: Exploration request routes to sdd-explore

- **GIVEN** the user sends a message that is a review, investigation, or explanation request ("review this code", "analyze this module", "explore how X works")
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Exploration
- **AND** it MUST either launch `sdd-explore` via Task tool or recommend `/sdd-explore <topic>` to the user
- **AND** it MUST NOT write a direct analysis response if the analysis involves producing change-related artifacts

#### Scenario: Direct question is answered inline

- **GIVEN** the user asks a question seeking factual or conceptual information ("what does this function do?", "explain this pattern", "how does X work?")
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST classify it as Question
- **AND** it MUST answer directly without routing to an SDD phase
- **AND** it MUST NOT suggest an SDD command for pure information requests

#### Scenario: Slash command is executed normally

- **GIVEN** the user sends a message that begins with a slash command (`/sdd-ff`, `/project-audit`, etc.)
- **WHEN** the orchestrator receives the message
- **THEN** it MUST execute the command as defined in the "How I Execute Commands" section
- **AND** it MUST NOT re-classify the intent — slash commands bypass the classification step

---

### Requirement: Four intent classes with clear routing rules

The orchestrator MUST define exactly four intent classes: Change Request, Exploration, Question, and Meta-Command.

#### Scenario: Change Request classification

- **GIVEN** a user message contains intent keywords: fix, add, implement, create, build, update, refactor, remove, delete, migrate, deploy, or similar action verbs directed at the codebase
- **WHEN** the orchestrator applies classification
- **THEN** it MUST classify the intent as Change Request
- **AND** it MUST route to `sdd-ff` recommendation (default) or `sdd-new` recommendation for complex changes
- **AND** it MUST state the inferred slug before asking the user to confirm

#### Scenario: Exploration classification

- **GIVEN** a user message contains investigative intent keywords: review, analyze, explore, examine, audit, investigate, "show me", "walk me through", "explain how it works"
- **WHEN** the orchestrator applies classification
- **THEN** it MUST classify the intent as Exploration
- **AND** it MUST route to `sdd-explore` sub-agent (via Task tool) or recommend `/sdd-explore <topic>`

#### Scenario: Question classification

- **GIVEN** a user message is a question seeking information without requesting a code change (e.g., contains "what is", "how does", "why does", "explain", "describe", or ends with "?")
- **WHEN** the orchestrator applies classification
- **THEN** it MUST classify it as Question
- **AND** it MUST answer directly

#### Scenario: Meta-Command classification

- **GIVEN** a user message starts with `/` followed by a known command name
- **WHEN** the orchestrator applies classification
- **THEN** it MUST classify it as Meta-Command
- **AND** it MUST skip intent classification and execute the command immediately

---

### Requirement: Orchestrator never writes implementation code inline

The orchestrator MUST NOT produce implementation code, delta specs, or design artifacts directly in conversation context.

#### Scenario: Change request results in SDD delegation, not inline code

- **GIVEN** the user says "fix the login bug" (a Change Request)
- **WHEN** the orchestrator responds
- **THEN** it MUST NOT write code in the response
- **AND** it MUST recommend `/sdd-ff fix-login-bug` or launch `sdd-explore` + `sdd-propose` via Task tool
- **AND** the response MUST explain why SDD discipline applies

#### Scenario: Sub-agent writes the code, not the orchestrator

- **GIVEN** the user has approved running `/sdd-apply`
- **WHEN** the orchestrator delegates implementation to a sub-agent via Task tool
- **THEN** the sub-agent (spawned via Task tool) writes all code
- **AND** the orchestrator MUST only relay the sub-agent's summary and artifact list

#### Scenario: Edge case — clarification question for ambiguous intent

- **GIVEN** a user message is ambiguous ("help with X", "do something about Y")
- **WHEN** the orchestrator cannot determine intent class with confidence
- **THEN** it MUST ask one clarifying question: "Is this a change request or a question?"
- **AND** it MUST NOT generate code or SDD artifacts before the user confirms intent

---

### Requirement: CLAUDE.md documents the Always-On Orchestrator behavior

CLAUDE.md MUST contain a dedicated section that defines intent classification rules, the four intent classes, and the routing table.

#### Scenario: Section exists and is findable

- **GIVEN** a reader opens CLAUDE.md
- **WHEN** they search for "Always-On Orchestrator" or "Intent Classification"
- **THEN** they MUST find a section with that heading
- **AND** the section MUST contain the four intent classes and their routing actions
- **AND** the section MUST state the "never inline code" rule

#### Scenario: CLAUDE.md updated in global and project files

- **GIVEN** the change is applied
- **WHEN** `install.sh` is run
- **THEN** the updated CLAUDE.md MUST be deployed to `~/.claude/CLAUDE.md`
- **AND** the behavior MUST apply to all projects that use the global CLAUDE.md without modification

---

### Requirement: Project-level CLAUDE.md can override intent classification

A project-local CLAUDE.md MUST be able to disable or refine the global intent classification behavior.

#### Scenario: Project disables always-on classification

- **GIVEN** a project has a `.claude/CLAUDE.md` that explicitly disables intent classification
- **WHEN** the user sends a free-form change request in that project
- **THEN** the orchestrator MUST NOT apply intent classification
- **AND** it MAY respond directly as per the project-level instructions

#### Scenario: Project restricts classification to specific intent classes

- **GIVEN** a project configures intent classification to only route Change Requests (not Explorations)
- **WHEN** the user sends an exploration message in that project
- **THEN** the orchestrator MUST answer directly without routing to `sdd-explore`

---

## Validation Criteria

- [ ] CLAUDE.md contains a dedicated "Always-On Orchestrator" section
- [ ] Four intent classes (Change Request, Exploration, Question, Meta-Command) are defined and documented
- [ ] Routing table maps each intent class to the correct action
- [ ] "Never write implementation code inline" rule is stated explicitly in the section
- [ ] Slash commands bypass classification and execute directly
- [ ] Questions are answered directly without SDD routing
- [ ] Project CLAUDE.md override mechanism is described
- [ ] Section is positioned in CLAUDE.md such that it is loaded at session start
