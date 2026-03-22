# Delta Spec: Orchestrator Behavior — Context-Aware Session Handoff

Change: 2026-03-21-orchestrator-mandatory-new-session
Date: 2026-03-22
Base: openspec/specs/orchestrator-behavior/spec.md

## MODIFIED — Modified requirements

### Requirement: Rule 6 — Cross-session ff handoff (context-aware heuristic)

_(Before: Rule 6 activated only when the user explicitly stated "new session", "next chat", "context reset", or "compaction imminent".)_

The orchestrator MUST evaluate session context depth before recommending `/sdd-ff` and route accordingly using a two-branch heuristic.

**Branch A — Significant prior context (heuristic: ~5+ messages exchanged, or other topics discussed before the change request):**
1. The orchestrator MUST create `openspec/changes/<slug>/proposal.md` immediately, capturing: problem statement, target files, constraints, and any decisions from the conversation.
2. The orchestrator MUST display the proposal file path.
3. The orchestrator MUST recommend a new session: "Open a new chat and run `/sdd-ff <slug>` — the proposal has the context."
4. The orchestrator MUST offer `/memory-update` before the session ends.

**Branch B — Clean session (heuristic: the change request is the first or second message with no substantial prior discussion):**
1. The orchestrator MUST create `proposal.md` inside the `sdd-ff` context extraction sub-step (as already designed).
2. The orchestrator MUST proceed with `/sdd-ff` in the same session — no new-session recommendation.

The heuristic threshold (~5 messages) is advisory. The orchestrator MUST use judgment; false negatives (missing a case where new session would help) are acceptable — the heuristic is not a hard block.

#### Scenario: Change request after long conversation triggers new-session recommendation

- **GIVEN** a session with significant prior context (more than ~5 messages exchanged before the change request, or substantive prior topics discussed)
- **WHEN** the orchestrator classifies a message as a Change Request
- **THEN** it MUST create `openspec/changes/<slug>/proposal.md` with problem, files, constraints, and decisions from the conversation
- **AND** it MUST display the proposal path
- **AND** it MUST recommend: "Open a new chat and run `/sdd-ff <slug>` — the proposal has the context."
- **AND** it MUST offer `/memory-update` before the session ends

#### Scenario: Clean session proceeds without new-session recommendation

- **GIVEN** a session where the change request is the first or second message with no substantial prior discussion
- **WHEN** the orchestrator classifies a message as a Change Request
- **THEN** it MUST NOT recommend starting a new session
- **AND** it MUST recommend `/sdd-ff <slug>` for same-session execution (or recommend the user run it directly)
- **AND** `proposal.md` creation is delegated to the `sdd-ff` context extraction sub-step

#### Scenario: /memory-update offered when proposal is created before session handoff

- **GIVEN** the orchestrator creates `proposal.md` and recommends a new session (Branch A)
- **WHEN** presenting the recommendation to the user
- **THEN** the orchestrator MUST include an offer to run `/memory-update` to persist session context before the session ends
- **AND** the offer MUST appear in the same response as the new-session recommendation

#### Scenario: Explicit user language no longer required to trigger handoff advice

- **GIVEN** a session with significant prior context
- **WHEN** the user sends a change request WITHOUT using words like "new session", "next chat", or "context reset"
- **THEN** the orchestrator MUST still apply the context-aware heuristic
- **AND** it MUST still create `proposal.md` and recommend a new session if the heuristic fires
- **AND** it MUST NOT wait for explicit opt-in language

## ADDED — New requirements

### Requirement: Natural language confirmation gates in phase transitions

Phase transition confirmations in SDD cycles MUST use natural language prompts as the primary gate. Command references are permitted as secondary, optional references — not as the primary action the user must take.

#### Scenario: Phase transition prompt uses natural language, not command-as-gate

- **GIVEN** an SDD cycle (e.g., sdd-ff) has completed a phase and is ready to proceed to apply
- **WHEN** the orchestrator presents the gate to the user
- **THEN** it MUST phrase the gate as a natural language question (e.g., "Continue with implementation? Reply **yes** to proceed.")
- **AND** it MAY include the command as an optional manual reference (e.g., "_(Manual: `/sdd-apply <slug>`)_")
- **AND** it MUST NOT frame the command as the only or primary action the user must take

#### Scenario: User replies "yes" to proceed with next phase

- **GIVEN** the orchestrator has presented a natural language confirmation gate
- **WHEN** the user replies "yes" (or equivalent affirmative: "y", "proceed", "continue", "go ahead")
- **THEN** the orchestrator MUST interpret the reply as confirmation and launch the next phase
- **AND** it MUST NOT require the user to type the slash command to proceed
