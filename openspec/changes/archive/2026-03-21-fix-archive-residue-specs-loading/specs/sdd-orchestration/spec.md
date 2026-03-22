# Delta Spec: sdd-orchestration

Change: 2026-03-21-fix-archive-residue-specs-loading
Date: 2026-03-21
Base: openspec/specs/sdd-orchestration/spec.md

---

## ADDED — sdd-ff Post-Explore Contradiction Gate (ADR 023 Implementation)

### Requirement: sdd-ff MUST check for UNCERTAIN contradictions after exploration

After the `sdd-explore` sub-agent completes (Step 0 of sdd-ff), and before launching `sdd-propose` (Step 1), the orchestrator MUST examine the generated `exploration.md` file for a `## Contradiction Analysis` section. If UNCERTAIN contradictions are found, the orchestrator MUST present a user confirmation gate.

The gate serves two purposes:
1. Surface ambiguities that exploration could not fully resolve
2. Capture explicit user intent before committing to the proposal

#### Scenario: Exploration reports no contradictions — gate does not fire

- **GIVEN** the user invokes `/sdd-ff add-email-notification-system`
- **WHEN** sdd-explore completes and generates exploration.md
- **AND** the exploration.md `## Contradiction Analysis` section states: "No contradictions detected"
- **THEN** sdd-ff MUST NOT present a gate
- **AND** sdd-ff MUST proceed immediately to sdd-propose (Step 1) with no user interaction
- **AND** the summary output MUST include: "Exploration complete (no contradictions)"

#### Scenario: Exploration reports UNCERTAIN contradictions — gate fires

- **GIVEN** the exploration.md reports:
  ```
  ## Contradiction Analysis

  ### Contradiction: Mobile performance constraint implied but not explicit in proposal
  Classification: UNCERTAIN
  Severity: WARNING
  Description: User mentioned "sub-500ms latency" in the conversation, but the proposal.md does not list this as a constraint. Unclear if this is an explicit requirement or an implicit performance goal.
  ```
- **WHEN** sdd-ff finishes exploration and checks for contradictions
- **THEN** sdd-ff MUST present a gate with:
  1. A header: "Exploration found UNCERTAIN contradictions — clarification required"
  2. List each UNCERTAIN contradiction with:
     - The contradiction name
     - The severity level
     - The description
  3. Prompt: "Does the proposal intend to include the mobile performance constraint (sub-500ms latency)?"
  4. Two options:
     - **Option A**: "Yes, confirm constraint" → Update proposal.md and continue to sdd-propose
     - **Option B**: "No, clarify in exploration" → Return to exploration with user's explicit clarification
- **AND** the gate MUST wait for the user's response before proceeding

#### Scenario: Multiple UNCERTAIN contradictions are listed in a single gate

- **GIVEN** exploration.md reports 3 UNCERTAIN contradictions
- **WHEN** the gate fires
- **THEN** all 3 contradictions MUST be listed together in a single gate
- **AND** the gate MUST ask the user to address each one (or confirm that they are intentional mismatches)
- **AND** a single user response (Option A or B) applies to all listed contradictions

#### Scenario: CERTAIN contradictions do not trigger the gate

- **GIVEN** exploration.md reports:
  ```
  ### Contradiction: Feature removal violates existing contract
  Classification: CERTAIN
  Severity: ERROR
  ```
- **WHEN** sdd-ff checks for UNCERTAIN contradictions
- **THEN** CERTAIN contradictions MUST NOT trigger the gate
- **AND** this contradiction is already documented in the exploration.md for user review, but does not pause the orchestrator
- **AND** sdd-ff proceeds to sdd-propose with no gate (the user has already accepted this contradiction in the exploration context)

#### Scenario: Pre-existing exploration.md — gate does not re-fire

- **GIVEN** a change directory already contains an exploration.md from a prior session
- **AND** the user runs `/sdd-ff` on the same change again in a new session
- **WHEN** sdd-ff detects the existing exploration.md
- **THEN** sdd-ff MUST NOT re-run exploration (Step 0 reuses the existing exploration.md)
- **AND** sdd-ff MUST NOT re-fire the contradiction gate
- **AND** the gate only fires when a NEW exploration.md is created in the current session
- **AND** the summary notes: "Reusing prior exploration (created [timestamp])"

---

### Requirement: User confirmation at the gate updates proposal.md with explicit intent

When the user confirms at the contradiction gate (Option A), sdd-ff MUST record the confirmation in the proposal.md `## Decisions` section. This record flows to all downstream phases and becomes the authoritative decision for the cycle.

#### Scenario: User confirms a constraint — proposal.md is updated

- **GIVEN** the gate presents a mobile constraint clarification
- **WHEN** the user selects Option A: "Yes, confirm constraint"
- **THEN** sdd-ff MUST update the proposal.md with a new or expanded `## Decisions` section:
  ```
  ## Decisions

  ### User Confirmation: Mobile Performance Constraint
  Date: 2026-03-21 14:30 UTC
  Status: CONFIRMED

  The proposal MUST include the mobile performance constraint (sub-500ms latency)
  as a hard requirement. This was confirmed at the post-explore gate.
  ```
- **AND** the timestamp reflects when the confirmation occurred
- **AND** the decision is binding for all downstream phases

#### Scenario: User declines clarification — exploration restarts with context

- **GIVEN** the user selects Option B: "No, clarify in exploration"
- **WHEN** sdd-ff processes this response
- **THEN** sdd-ff MUST:
  1. NOT proceed to sdd-propose
  2. Capture the user's clarification request: "Please clarify: [user-provided text]"
  3. Return to sdd-explore with the clarification request as a new context block
  4. Re-launch sdd-explore with instructions to investigate the specific contradiction
- **AND** the user is NOT forced to start over; exploration resumes with the additional context

---

### Requirement: Gate placement in sdd-ff sequence

The contradiction gate MUST run as a sub-step between Step 0 (Exploration) and Step 1 (Propose). It is called "Step 0c: Post-explore contradiction gate" in the orchestration sequence.

#### Scenario: sdd-ff execution sequence includes the contradiction gate

- **GIVEN** the sdd-ff orchestrator processes a change
- **WHEN** the execution sequence is examined
- **THEN** the steps MUST be:
  - Step 0: sdd-explore
  - **Step 0c: Check for UNCERTAIN contradictions and present gate if found** (NEW)
  - Step 1: sdd-propose
  - Step 2: sdd-spec + sdd-design (parallel)
  - Step 3: sdd-tasks
- **AND** the gate is blocking if contradictions are present (user must respond)
- **AND** the gate is non-existent if no UNCERTAIN contradictions are found

---

### Requirement: Gate output is logged in sdd-ff summary

When the contradiction gate fires or is skipped, sdd-ff's final summary MUST report its outcome.

#### Scenario: Summary mentions gate was skipped

- **GIVEN** exploration found no UNCERTAIN contradictions
- **WHEN** sdd-ff completes all phases and presents the final summary
- **THEN** the summary MUST include: `✓ Post-explore gate: no contradictions detected`

#### Scenario: Summary mentions gate confirmed user intent

- **GIVEN** the gate fired and the user confirmed intent
- **WHEN** sdd-ff completes and presents the final summary
- **THEN** the summary MUST include: `✓ Post-explore gate: [N] contradiction(s) confirmed by user`
- **AND** it MUST reference the proposal.md `## Decisions` section for details

#### Scenario: Summary notes gate clarification request

- **GIVEN** the gate fired and the user requested clarification
- **WHEN** sdd-ff returns control to exploration
- **THEN** sdd-ff MUST NOT produce a final summary (the cycle is paused)
- **AND** the user sees: `ⓘ Returning to exploration for clarification — please re-run /sdd-ff when ready`

---

### Requirement: Contradiction Analysis section format in exploration.md

For the post-explore gate to function, exploration.md MUST include a `## Contradiction Analysis` section with a predictable format. This spec defines the expected structure.

#### Scenario: Contradiction Analysis section structure

- **GIVEN** exploration.md is generated
- **WHEN** the document is examined
- **THEN** it MUST contain a `## Contradiction Analysis` section that includes:
  - **"No contradictions detected"** (if applicable) OR
  - A list of contradictions, each with:
    - `### Contradiction: [Name]` (heading)
    - `Classification: [CERTAIN | UNCERTAIN]` (field)
    - `Severity: [ERROR | WARNING | INFO]` (field)
    - `Description: [text]` (field)
  - Optional subsections: `## Contradiction Resolution` (for CERTAIN contradictions that sdd-explore has already resolved)

#### Scenario: sdd-ff parses the Classification field to identify UNCERTAIN contradictions

- **GIVEN** exploration.md contains multiple contradictions
- **WHEN** sdd-ff reads the `## Contradiction Analysis` section
- **THEN** it MUST parse each contradiction's `Classification:` field
- **AND** it MUST treat contradictions with `Classification: UNCERTAIN` as gate triggers
- **AND** it MUST treat contradictions with `Classification: CERTAIN` as informational (no gate)

---

## Rules (Post-Explore Gate)

- Gate fires ONLY if exploration.md contains one or more UNCERTAIN contradictions
- Gate is a blocking pause: user MUST respond before sdd-ff continues
- User response MUST be recorded in proposal.md `## Decisions` section (binding for downstream phases)
- If user selects Option B (clarify), exploration restarts with new context; sdd-ff does not continue
- Pre-existing exploration.md does NOT trigger the gate (gate only fires on newly created exploration)
- CERTAIN contradictions are informational; they do NOT trigger a gate (user has already seen them in exploration context)
- The gate MUST list each UNCERTAIN contradiction with its severity and description
- Gate output is logged in sdd-ff's final summary
- Gate is a sub-step of Step 0 (post-explore, pre-propose) and does NOT affect step numbering of subsequent phases

---
