# Spec: feedback-session

Change: sdd-feedback-persistence
Date: 2026-03-10

---

## Requirements

### Requirement: Feedback items MUST be persisted as proposal.md files before any SDD cycle

When the user provides feedback (bug observations, improvement ideas, process complaints, or
improvement requests), the orchestrator MUST convert each distinct feedback item into a
`proposal.md` file stored at `openspec/changes/YYYY-MM-DD-<slug>/proposal.md` before any SDD
cycle is started. The orchestrator MUST NOT start `/sdd-ff`, `/sdd-new`, `/sdd-apply`, or any
implementation command within the same session in which feedback is collected.

#### Scenario: User provides a single feedback item in a session

- **GIVEN** the user opens a session and provides one feedback item (e.g., "the orchestrator
  sometimes skips the proposal phase")
- **WHEN** the orchestrator receives the feedback
- **THEN** the orchestrator creates exactly one `proposal.md` at
  `openspec/changes/<YYYY-MM-DD-slug>/proposal.md`
- **AND** the orchestrator does NOT suggest or invoke `/sdd-ff`, `/sdd-apply`, or any
  implementation command
- **AND** the session ends with the orchestrator listing the created proposal path

#### Scenario: User provides multiple feedback items in a single session

- **GIVEN** the user provides N distinct feedback items in a session (N >= 2)
- **WHEN** the orchestrator processes the feedback list
- **THEN** exactly N `proposal.md` files are created, each in its own
  `openspec/changes/<YYYY-MM-DD-slug>/` directory
- **AND** each proposal has a unique, descriptive slug derived from the feedback item
- **AND** the orchestrator does NOT start any SDD cycle during the same session
- **AND** the orchestrator ends the session with a summary listing all N proposal paths

#### Scenario: User insists on implementing in the same feedback session

- **GIVEN** the orchestrator has identified the current session as a feedback session
- **WHEN** the user explicitly asks to run `/sdd-ff` or begin implementation immediately
- **THEN** the orchestrator declines and explains Rule 5 — Feedback persistence
- **AND** the orchestrator offers to create the `proposal.md` first
- **AND** the orchestrator does NOT bypass the rule under any circumstances

#### Scenario: Ambiguous input — is it feedback or a direct command?

- **GIVEN** the user provides input that could be interpreted as either feedback or a direct
  `/sdd-new` request (e.g., "I'd like to add X feature")
- **WHEN** the orchestrator cannot unambiguously classify the input as a command
- **THEN** the orchestrator treats it as a feedback item and creates a `proposal.md`
- **AND** the orchestrator informs the user of the interpretation and how to proceed

---

### Requirement: Each proposal.md created from feedback MUST contain four required sections

Every `proposal.md` produced during a feedback session MUST include the following sections:
`## Intent`, `## Motivation`, `## Scope`, and `## Success Criteria`.

The `## Motivation` section MUST include a reference to the original feedback that triggered it —
either a direct quote or a faithful paraphrase. The `## Success Criteria` section MUST contain at
least 3 verifiable criteria expressed as unchecked checkboxes (`- [ ]`).

#### Scenario: Proposal created from a clear feedback item

- **GIVEN** the user provides the feedback "when I give a list of improvements, the AI starts
  implementing the first one immediately instead of saving them"
- **WHEN** the orchestrator creates the `proposal.md`
- **THEN** the file contains `## Intent`, `## Motivation`, `## Scope`, and `## Success Criteria`
- **AND** `## Motivation` contains a quote or paraphrase of the original feedback
- **AND** `## Success Criteria` has at least 3 `- [ ]` items

#### Scenario: Proposal with fewer than 3 success criteria

- **GIVEN** the orchestrator is producing a `proposal.md` from a feedback item
- **WHEN** the orchestrator can only derive 1 or 2 verifiable criteria from the feedback
- **THEN** the orchestrator MUST infer additional criteria from the feedback context to reach 3
- **AND** the orchestrator MUST NOT write a `proposal.md` with fewer than 3 `- [ ]` criteria
- **AND** if criteria cannot be inferred, the orchestrator marks the extras as
  `- [ ] [Pending clarification: describe what is needed]`

---

### Requirement: The orchestrator MUST provide a session-closing summary after a feedback session

After all `proposal.md` files have been created for a feedback session, the orchestrator MUST
provide a closing summary to the user.

#### Scenario: Feedback session ends successfully

- **GIVEN** the orchestrator has created one or more `proposal.md` files in the session
- **WHEN** all feedback items have been processed
- **THEN** the orchestrator outputs a summary listing each proposal path and its one-line intent
- **AND** the summary instructs the user to start a new session and reference the proposal path
  to begin implementation (e.g., "run `/sdd-apply sdd-feedback-persistence` in a new session")
- **AND** the orchestrator does NOT offer any implementation command at the end of the summary

---

### Requirement: The feedback → proposal → separate session workflow MUST be documented

The protocol MUST be documented at `docs/workflows/feedback-to-proposal.md`. The document MUST
describe: (1) what constitutes a feedback session, (2) how to initiate implementation in a new
session, and (3) the folder layout for proposals.

#### Scenario: User asks how to implement a proposal created in a previous session

- **GIVEN** a `proposal.md` exists at a known path
- **WHEN** the user opens a new session and references the proposal path
- **THEN** the user can run `/sdd-ff <change-name>` and the SDD cycle begins normally
- **AND** the existing `proposal.md` serves as the input artifact for the spec and design phases

#### Scenario: docs/workflows/feedback-to-proposal.md is absent

- **GIVEN** `docs/workflows/feedback-to-proposal.md` does not exist after the change is applied
- **WHEN** a user or auditor checks the docs/workflows/ directory
- **THEN** this is treated as a failing success criterion in `verify-report.md`

---

### Requirement: Rule 5 — Feedback persistence MUST appear in CLAUDE.md Unbreakable Rules

The CLAUDE.md Unbreakable Rules section MUST contain a Rule 5 entry titled "Feedback persistence"
that prohibits starting SDD cycles or implementations in the same session as feedback collection.

#### Scenario: Rule 5 is present in CLAUDE.md

- **GIVEN** CLAUDE.md has been updated by the sdd-apply phase
- **WHEN** the Unbreakable Rules section is read
- **THEN** a rule named "Feedback persistence" or "Rule 5 — Feedback persistence" is present
- **AND** the rule states that feedback sessions MUST produce only `proposal.md` files
- **AND** the rule explicitly prohibits `/sdd-ff` and `/sdd-apply` within a feedback session

#### Scenario: Orchestrator is initialized with Rule 5 present

- **GIVEN** CLAUDE.md contains Rule 5 — Feedback persistence
- **WHEN** a session begins and the user immediately provides feedback items
- **THEN** the orchestrator enters feedback-session mode without needing explicit instruction
- **AND** the Unbreakable Rules section takes precedence over any user override request
