# Delta Spec: Orchestrator Behavior

Change: 2026-03-21-orchestrator-teaching
Date: 2026-03-21
Base: openspec/specs/orchestrator-behavior/spec.md

## ADDED — Teaching Principles section in CLAUDE.md

### Requirement: CLAUDE.md MUST contain a Teaching Principles section with exactly 5 rules

CLAUDE.md MUST contain a `## Teaching Principles` section defining exactly 5 concise teaching rules. The section MUST NOT exceed 15 lines total. The 5 rules are: why-framing, educational gates, error reformulation, post-cycle reflection, and progressive disclosure.

#### Scenario: Teaching Principles section exists and is complete

- **GIVEN** a reader opens CLAUDE.md
- **WHEN** they search for "Teaching Principles"
- **THEN** they MUST find a section with that heading
- **AND** the section MUST contain exactly 5 numbered teaching rules
- **AND** the section MUST NOT exceed 15 lines (excluding the heading)

#### Scenario: Teaching Principles section does not alter intent classification logic

- **GIVEN** the Teaching Principles section is present in CLAUDE.md
- **WHEN** the orchestrator applies intent classification
- **THEN** the classification logic (keyword matching, routing table, ambiguity heuristics) MUST remain unchanged
- **AND** teaching content MUST be additive annotation only — not a new routing pathway

---

## ADDED — Why-framing on Change Request classification

### Requirement: Change Request classification responses MUST include a why-sentence

When the orchestrator classifies a free-form message as a Change Request, the response MUST include one sentence (maximum) explaining what risk the SDD cycle prevents for this specific change.

#### Scenario: Change Request response includes why-framing

- **GIVEN** the user sends "fix the login bug"
- **WHEN** the orchestrator classifies the intent as Change Request
- **THEN** the response MUST include the intent classification signal (`**Intent classification: Change Request**`)
- **AND** the response MUST include the `/sdd-ff` recommendation
- **AND** the response MUST include exactly one sentence explaining why the SDD cycle applies (e.g., "Running through the SDD cycle ensures the fix is specified before implementation, preventing regressions in adjacent auth flows.")
- **AND** the why-sentence MUST NOT exceed one sentence

#### Scenario: Why-framing is specific to the change, not generic

- **GIVEN** the user sends "add a payment retry mechanism"
- **WHEN** the orchestrator classifies the intent as Change Request
- **THEN** the why-sentence MUST reference the specific domain or risk (e.g., payment, retry, error handling)
- **AND** the why-sentence MUST NOT be a generic "SDD is good practice" statement

#### Scenario: Why-framing does not appear on Questions or Explorations

- **GIVEN** the user sends "how does the auth module work?"
- **WHEN** the orchestrator classifies the intent as Question
- **THEN** the response MUST NOT include a why-framing sentence about SDD risk prevention

---

## ADDED — Educational gates for confirmation prompts

### Requirement: Confirmation gates MUST include the consequence being avoided

When the orchestrator presents a confirmation gate (Rule 7 removal confirmation, contradiction gate), the gate prompt MUST include one sentence stating the consequence that the gate prevents.

#### Scenario: Rule 7 removal confirmation includes educational framing

- **GIVEN** the user sends "remove the periodic refresh hook"
- **WHEN** the orchestrator presents the Rule 7 removal confirmation gate
- **THEN** the gate MUST include the standard confirmation prompt (detected intent, yes/no options)
- **AND** the gate MUST include one sentence explaining the consequence (e.g., "Confirming removal intent upfront prevents the SDD cycle from preserving behavior you want deleted.")

#### Scenario: Contradiction gate includes educational framing

- **GIVEN** sdd-ff presents a contradiction gate for an UNCERTAIN contradiction
- **WHEN** the gate prompt is displayed
- **THEN** the gate MUST include the contradiction details and user options (Yes/No/Review)
- **AND** the gate MUST include one sentence explaining why contradictions are surfaced (e.g., "Resolving this now prevents the spec and design from making conflicting assumptions.")

---

## ADDED — Error reformulation in sdd-ff

### Requirement: sdd-ff MUST reformulate blocked/failed sub-agent statuses as learning messages

When a sub-agent returns `status: blocked` or `status: failed` during an sdd-ff cycle, the orchestrator MUST reframe the error as a learning message with cause and prevention guidance.

#### Scenario: Sub-agent returns blocked status

- **GIVEN** the sdd-spec sub-agent returns `status: blocked` with summary "Ambiguous business rule — cannot determine correct behavior"
- **WHEN** sdd-ff presents the error to the user
- **THEN** sdd-ff MUST NOT relay the raw status verbatim as the only content
- **AND** sdd-ff MUST present a reformulated message with structure: "This happened because [cause]. To resolve it, [action]."
- **AND** the cause MUST be derived from the sub-agent's summary
- **AND** the action MUST be a concrete next step the user can take

#### Scenario: Sub-agent returns failed status

- **GIVEN** the sdd-design sub-agent returns `status: failed` with summary "Cannot read required artifact"
- **WHEN** sdd-ff presents the error to the user
- **THEN** sdd-ff MUST present a reformulated message explaining what went wrong and how to fix it
- **AND** the message MUST NOT use jargon without explanation (e.g., "status: failed" alone is insufficient)

#### Scenario: Sub-agent returns ok or warning — no reformulation needed

- **GIVEN** a sub-agent returns `status: ok` or `status: warning`
- **WHEN** sdd-ff processes the result
- **THEN** sdd-ff MUST NOT apply error reformulation
- **AND** the normal summary presentation MUST proceed unchanged

---

## ADDED — Post-cycle reflection in sdd-ff Step 5 summary

### Requirement: sdd-ff Step 5 summary MUST include a narrative reflection paragraph

After presenting the structured phase results and artifact list in Step 5, sdd-ff MUST append a narrative paragraph (1 paragraph maximum) summarizing what the cycle produced and what it protects.

#### Scenario: Post-cycle narrative appears after artifact list

- **GIVEN** sdd-ff completes all phases (explore, propose, spec, design, tasks) successfully
- **WHEN** the Step 5 summary is presented to the user
- **THEN** the summary MUST include the existing structured output (phase results, artifacts)
- **AND** the summary MUST append one narrative paragraph after the artifact list
- **AND** the paragraph MUST summarize what was decided, what was specified, and what risks were mitigated
- **AND** the paragraph MUST NOT exceed one paragraph (no multi-paragraph reflections)

#### Scenario: Post-cycle narrative references the specific change

- **GIVEN** the change is "add-payment-retry"
- **WHEN** the narrative paragraph is written
- **THEN** the paragraph MUST reference the specific domain (e.g., payment retry)
- **AND** the paragraph MUST NOT be a generic "the SDD cycle completed successfully" statement

#### Scenario: Post-cycle narrative does not appear when cycle is incomplete

- **GIVEN** sdd-ff was halted at a gate or due to a sub-agent failure
- **WHEN** the summary is presented
- **THEN** no narrative paragraph MUST be appended
- **AND** only the error or gate information MUST be shown

---

## ADDED — Progressive disclosure for new users

### Requirement: New-user detection heuristic triggers brief SDD context note

When `ai-context/changelog-ai.md` shows 0 archived changes (indicating a new project or new user), the orchestrator MUST prepend a brief context note to the first SDD-routed response in the session.

#### Scenario: New project with 0 archived changes — context note appears

- **GIVEN** the orchestrator reads `ai-context/changelog-ai.md` and finds 0 entries indicating archived changes
- **WHEN** the orchestrator classifies the first free-form message as a Change Request or Exploration
- **THEN** the response MUST include a brief context note (2-3 sentences maximum) explaining what the SDD cycle is and why it is being recommended
- **AND** the note MUST appear before the standard classification response
- **AND** the note MUST appear only once per session (not on every message)

#### Scenario: Established project with archived changes — no context note

- **GIVEN** the orchestrator reads `ai-context/changelog-ai.md` and finds 1 or more entries indicating archived changes
- **WHEN** the orchestrator classifies any message
- **THEN** the response MUST NOT include the new-user context note
- **AND** the standard classification response MUST proceed as normal

#### Scenario: Missing changelog-ai.md — treat as new user

- **GIVEN** `ai-context/changelog-ai.md` does not exist
- **WHEN** the orchestrator attempts to check for archived changes
- **THEN** the orchestrator MUST treat the project as having 0 archived changes
- **AND** the new-user context note MUST be triggered on the first SDD-routed response

#### Scenario: Context note does not appear on Questions

- **GIVEN** the project has 0 archived changes
- **WHEN** the user sends a Question (not a Change Request or Exploration)
- **THEN** the new-user context note MUST NOT appear
- **AND** the Question MUST be answered directly as normal

---

## ADDED — Teaching content conciseness constraints

### Requirement: All teaching content MUST respect conciseness limits

Teaching content added by this change MUST adhere to strict size limits to avoid slowing down expert users.

#### Scenario: Why-framing sentence limit

- **GIVEN** the orchestrator generates a why-framing sentence for a Change Request
- **WHEN** the sentence is measured
- **THEN** it MUST be exactly 1 sentence (not 2 or more)

#### Scenario: Post-cycle narrative paragraph limit

- **GIVEN** sdd-ff generates a post-cycle narrative
- **WHEN** the narrative is measured
- **THEN** it MUST be exactly 1 paragraph (not 2 or more)

#### Scenario: New-user context note limit

- **GIVEN** the new-user context note is triggered
- **WHEN** the note is measured
- **THEN** it MUST NOT exceed 3 sentences

#### Scenario: Educational gate additions do not extend gate prompts significantly

- **GIVEN** a confirmation gate prompt includes an educational sentence
- **WHEN** the gate prompt is compared to the non-teaching version
- **THEN** the educational addition MUST be exactly 1 sentence appended to the existing prompt
- **AND** the gate options and structure MUST remain unchanged
