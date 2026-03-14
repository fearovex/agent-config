# Delta Spec: Orchestrator — Clarification Gate for Ambiguous Inputs

Change: 2026-03-14-add-clarification-gate-for-ambiguous-inputs
Date: 2026-03-14
Base: openspec/specs/orchestrator-behavior/spec.md

## ADDED — New requirements

### Requirement: Ambiguous input detection and clarification gate

The orchestrator MUST detect ambiguous inputs and present a **clarification gate** before defaulting to Question classification. An ambiguous input is one that lacks a clear action verb or target and could reasonably map to Change Request, Exploration, or Question.

#### Scenario: Single-word ambiguous noun triggers clarification

- **GIVEN** the user sends only "auth" (a single word with no action verb)
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST detect the ambiguity
- **AND** it MUST NOT immediately default to Question
- **AND** it MUST present a clarification prompt before routing
- **AND** the prompt MUST offer three options aligned to Change Request, Exploration, and Question
- **THEN** the user MUST respond with 1, 2, 3, or clarify in their own words
- **AND** the orchestrator MUST then route to the selected intent class

#### Scenario: Single-word verb with no target triggers clarification

- **GIVEN** the user sends only "refactor"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST detect that this is a change verb but lacks a target ("refactor what?")
- **AND** it MUST present the clarification prompt with three options
- **THEN** the user response is routed to the selected intent class

#### Scenario: Ambiguous phrase with weak intent signal triggers clarification

- **GIVEN** the user sends "improve the system" (vague object, no clear scope)
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST detect the vagueness
- **AND** it MUST present a clarification prompt
- **THEN** the user response determines the route

#### Scenario: Non-ambiguous inputs bypass the gate

- **GIVEN** the user sends "fix the login bug" (explicit action verb + clear target)
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST NOT trigger the clarification gate
- **AND** it MUST route directly to Change Request

#### Scenario: Explicit questions bypass the gate

- **GIVEN** the user sends "what is auth?" (ends with ?, contains "what is" pattern)
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST NOT trigger the clarification gate
- **AND** it MUST route directly to Question

---

### Requirement: Clarification prompt structure

The clarification prompt MUST present exactly three options corresponding to the three most common intent interpretations: Change Request, Exploration, and Question.

#### Scenario: Prompt format and content

- **GIVEN** the orchestrator has detected an ambiguous input and decided to present a clarification
- **WHEN** the prompt is displayed
- **THEN** it MUST include:
  - A summary of what was ambiguous (e.g., "I'm not sure what you'd like me to do with 'auth'")
  - Three numbered options:
    1. Change Request interpretation (e.g., "Refactor/fix some specific code (change request)")
    2. Exploration interpretation (e.g., "Explore/review auth patterns in the codebase (exploration)")
    3. Question interpretation (e.g., "Learn what auth is/how it works (question)")
  - An instruction: "Just reply with 1, 2, 3, or clarify in your own words."
- **AND** the prompt MUST be phrased in natural language (not a menu format)
- **AND** each option MUST be on its own line for readability

#### Scenario: Option 1 — Change Request context

- **GIVEN** the clarification prompt is displayed for an ambiguous verb like "refactor"
- **WHEN** Option 1 is shown
- **THEN** it MUST frame the Change Request interpretation contextually:
  - "Refactor some specific code" OR "Fix/improve a specific part of the system"
  - MUST include "(change request)" label

#### Scenario: Option 2 — Exploration context

- **GIVEN** the clarification prompt is displayed
- **WHEN** Option 2 is shown
- **THEN** it MUST frame the Exploration interpretation:
  - "Explore/review [the thing] in the codebase" OR "Show me how [the thing] works"
  - MUST include "(exploration)" label

#### Scenario: Option 3 — Question context

- **GIVEN** the clarification prompt is displayed
- **WHEN** Option 3 is shown
- **THEN** it MUST frame the Question interpretation:
  - "Learn what [the thing] is" OR "Understand how [the thing] works"
  - MUST include "(question)" label

---

### Requirement: Routing after clarification response

After the user responds to a clarification prompt, the orchestrator MUST route to the selected intent class with the same behavior as if the original message had contained that intent.

#### Scenario: User selects Change Request (option 1)

- **GIVEN** the user responds to a clarification prompt with "1" (or clarifies as a change request)
- **WHEN** the orchestrator processes the response
- **THEN** it MUST treat the original input as a Change Request
- **AND** it MUST recommend `/sdd-ff <inferred-slug>` or `/sdd-new` as appropriate
- **AND** it MUST infer the slug from the original ambiguous input + context

#### Scenario: User selects Exploration (option 2)

- **GIVEN** the user responds to a clarification prompt with "2" (or clarifies as exploration)
- **WHEN** the orchestrator processes the response
- **THEN** it MUST treat the original input as Exploration
- **AND** it MUST launch `sdd-explore` via Task tool or recommend `/sdd-explore <topic>`

#### Scenario: User selects Question (option 3)

- **GIVEN** the user responds to a clarification prompt with "3" (or clarifies as a question)
- **WHEN** the orchestrator processes the response
- **THEN** it MUST treat the original input as Question
- **AND** it MUST answer directly with factual/conceptual information about the topic

#### Scenario: User provides custom clarification

- **GIVEN** the user responds to a clarification prompt with their own clarification (not 1, 2, or 3)
- **WHEN** the orchestrator processes the custom text
- **THEN** it MUST apply the standard intent classification rules to the clarification
- **AND** it MUST route based on the standard classification of that text
- **AND** the response MUST acknowledge the clarification before routing

---

### Requirement: Ambiguity detection heuristics

The orchestrator MUST define clear heuristics for when to trigger the clarification gate. An input is ambiguous if it matches one or more of these patterns:

1. **Single-word input** — exactly one word with no punctuation or modifiers
   - Examples: "auth", "login", "refactor", "help"
   - Exception: single-word inputs that are obviously part of a complete thought ("yes", "no", "true", "false") are NOT ambiguous

2. **Standalone action verb with no object** — a verb from the change verb list ("refactor", "fix", "improve") with no clear target
   - Examples: "refactor", "fix", "improve"
   - Exception: "refactor everything" has an object, so it is NOT ambiguous

3. **Vague noun phrase** — a phrase that references something but provides no context or verb
   - Examples: "the system", "the flow", "the layer"
   - Criterion: phrase length ≤ 4 words AND no action verb present

4. **Compound phrase with weak binding** — a phrase where multiple interpretations are equally plausible
   - Examples: "help with X", "something about Y", "deal with Z"
   - Criterion: contains "with", "about", "deal with", "look into" without a clear intent verb ("fix", "review", "understand")

#### Scenario: Detection accuracy — single-word nouns

- **GIVEN** the user sends "auth"
- **WHEN** the orchestrator applies heuristic 1
- **THEN** it MUST classify as ambiguous

#### Scenario: Detection accuracy — standalone verbs

- **GIVEN** the user sends "refactor"
- **WHEN** the orchestrator applies heuristic 2
- **THEN** it MUST classify as ambiguous

#### Scenario: Non-ambiguous single-word cases are excluded

- **GIVEN** the user sends "yes" or "help" (a natural response word)
- **WHEN** the orchestrator applies heuristics
- **THEN** it MUST NOT classify as ambiguous (these are contextual responses, not change intent)

#### Scenario: Phrases with objects are not ambiguous

- **GIVEN** the user sends "refactor the auth module"
- **WHEN** the orchestrator applies heuristics
- **THEN** it MUST NOT classify as ambiguous (has clear action verb + object)

---

### Requirement: Clarification gate does not interfere with slash commands or strong signals

The clarification gate MUST NOT activate for messages that are already clearly classified via other mechanisms.

#### Scenario: Slash commands bypass the gate

- **GIVEN** the user sends `/sdd-ff refactor-auth`
- **WHEN** the orchestrator processes the message
- **THEN** it MUST NOT trigger the clarification gate
- **AND** it MUST execute the slash command directly

#### Scenario: Messages with explicit intent verbs bypass the gate

- **GIVEN** the user sends "fix the auth bug"
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST NOT trigger the clarification gate (clear Change Request signal)

#### Scenario: Messages ending with ? bypass the gate

- **GIVEN** the user sends "auth?" (single word but ends with ?)
- **WHEN** the orchestrator classifies the intent
- **THEN** it MUST NOT trigger the clarification gate
- **AND** it MUST classify as Question (punctuation is a strong signal)

---

## MODIFIED — Modified requirements

### Requirement: Ambiguous single-word messages _(modified from default-to-question)_

A message with a single word that does not contain an explicit intent verb or punctuation _(previously: MUST be classified as Question)_ **now MUST trigger a clarification gate UNLESS the word is a natural response (yes, no, etc.) or ends with punctuation.**

#### Scenario: Single-word noun — triggers clarification (modified)

- **GIVEN** the user sends only "login"
- **WHEN** the orchestrator classifies the intent
- **THEN** _(modified)_ it MUST trigger the clarification gate, NOT immediately default to Question
- **AND** the gate MUST ask: "Is this a change request, exploration, or question?"
- **THEN** the user MUST respond before routing proceeds

_(Before: "it MUST classify it as Question (default ambiguous)")_

#### Scenario: Single-word verb with no target _(modified)_

- **GIVEN** the user sends only "refactor"
- **WHEN** the orchestrator classifies the intent
- **THEN** _(modified)_ it MUST trigger the clarification gate
- **AND** it MUST NOT ask "What would you like me to refactor?" (too directive)
- **AND** it MUST offer three equally-weighted options (Change Request, Exploration, Question)

_(Before: "it MUST classify it as Question (default ambiguous) AND it MUST ask: 'What would you like me to refactor?'")_

#### Scenario: Ambiguous acronym or label _(modified)_

- **GIVEN** the user sends only "auth"
- **WHEN** the orchestrator classifies the intent
- **THEN** _(modified)_ it MUST trigger the clarification gate
- **AND** the gate MUST NOT default to Question

_(Before: "it MUST classify it as Question (default ambiguous)")_

---

## Validation Criteria

- [ ] Ambiguity detection heuristics (4 categories) are clearly defined in CLAUDE.md
- [ ] Clarification prompt template includes all required elements (summary, 3 options, instruction)
- [ ] Prompt is phrased in natural language (not a menu)
- [ ] Orchestrator detects single-word ambiguous inputs (e.g., "auth", "refactor")
- [ ] Orchestrator detects standalone verbs with no object
- [ ] Orchestrator detects vague phrases with weak intent signals
- [ ] Non-ambiguous inputs (with clear action verbs or punctuation) bypass the gate
- [ ] Slash commands bypass the gate
- [ ] After clarification, routing follows standard classification rules for the selected option
- [ ] Custom clarifications (free text) are re-classified via standard rules
- [ ] Clarification gate does not appear for strong signals (explicit verbs, "?", slash commands)
- [ ] Manual testing in 2+ independent sessions confirms correct gate triggers and routing
