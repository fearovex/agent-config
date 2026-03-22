# Delta Spec: Orchestrator Behavior

Change: 2026-03-22-slim-orchestrator-context
Date: 2026-03-22
Base: openspec/specs/orchestrator-behavior/spec.md

## ADDED — New requirements

### Requirement: Orchestrator content MUST be split into classification-critical (inline) and presentation (skill-based) layers

The global CLAUDE.md MUST contain only classification-critical orchestrator content inline. Presentation-layer content (Communication Persona, Teaching Principles, New-User Detection, Session Banner) MUST reside in a dedicated skill file (`skills/orchestrator-persona/SKILL.md`) loaded on demand.

#### Scenario: Classification-critical content remains inline in global CLAUDE.md

- **GIVEN** a new session starts and Claude reads the global CLAUDE.md
- **WHEN** the first free-form user message arrives
- **THEN** the Classification Decision Table MUST be available in CLAUDE.md for immediate use
- **AND** the Scope Estimation Heuristic MUST be available in CLAUDE.md for immediate use
- **AND** the Ambiguity Detection Heuristics MUST be available in CLAUDE.md for immediate use
- **AND** the Intent Classes and Routing table MUST be available in CLAUDE.md for immediate use
- **AND** the Unbreakable Rules (1-7) MUST be available in CLAUDE.md for immediate use

#### Scenario: Presentation content is absent from global CLAUDE.md

- **GIVEN** a reader opens the global CLAUDE.md after this change is applied
- **WHEN** they search for "Communication Persona" or "Teaching Principles" or "New-User Detection" or "Tone Profile" or "Forbidden Mechanical Phrases"
- **THEN** they MUST NOT find those sections inline in CLAUDE.md
- **AND** they MUST find a reference or loading instruction pointing to `skills/orchestrator-persona/SKILL.md`

#### Scenario: Orchestrator loads persona skill before generating first free-form response

- **GIVEN** the orchestrator has classified a free-form message (Change Request, Exploration, Question, or Ambiguous)
- **WHEN** the orchestrator generates the response prose (after the intent classification signal)
- **THEN** the orchestrator MUST have loaded `skills/orchestrator-persona/SKILL.md` to apply tone, teaching, and persona rules
- **AND** if the persona skill cannot be loaded, the orchestrator MUST still generate a response (graceful degradation) using a neutral-warm default tone
- **AND** classification accuracy MUST NOT be affected by persona skill availability

#### Scenario: Slash command responses do not require persona skill loading

- **GIVEN** the user sends a slash command (Meta-Command)
- **WHEN** the orchestrator executes the command
- **THEN** the orchestrator MUST NOT be required to load the persona skill
- **AND** sub-agent responses from skill execution are not constrained by persona rules

---

### Requirement: Orchestrator persona skill MUST contain all presentation-layer content

A new skill `skills/orchestrator-persona/SKILL.md` MUST exist and MUST contain all orchestrator presentation-layer content extracted from CLAUDE.md.

#### Scenario: Persona skill contains Communication Persona content

- **GIVEN** a reader opens `skills/orchestrator-persona/SKILL.md`
- **WHEN** they read the skill content
- **THEN** the skill MUST contain the Tone Profile (warm, direct, confident, pedagogical)
- **AND** the skill MUST contain Response Voice templates for all 4 intent classes
- **AND** the skill MUST contain the Forbidden Mechanical Phrases deny-list
- **AND** the skill MUST contain the Adaptive Formality rules

#### Scenario: Persona skill contains Teaching Principles content

- **GIVEN** a reader opens `skills/orchestrator-persona/SKILL.md`
- **WHEN** they read the skill content
- **THEN** the skill MUST contain the 5 teaching principles (why-framing, educational gates, error reformulation, post-cycle reflection, progressive disclosure)
- **AND** the skill MUST contain the New-User Detection heuristic (archive directory check)

#### Scenario: Persona skill contains Session Banner content

- **GIVEN** a reader opens `skills/orchestrator-persona/SKILL.md`
- **WHEN** they read the skill content
- **THEN** the skill MUST contain the session-start orchestrator banner template
- **AND** the banner MUST retain its warm, welcoming tone

#### Scenario: Persona skill is under 8,000 characters

- **GIVEN** the persona skill has been created
- **WHEN** its character count is measured
- **THEN** it MUST be under 8,000 characters
- **AND** it MUST conform to the SKILL.md structural contract (YAML frontmatter with `format:` field, `**Triggers**`, required sections per format, `## Rules`)

---

### Requirement: Redundant SDD flow documentation MUST be removed from global CLAUDE.md

Sections that duplicate content already present in skill files MUST be removed from the global CLAUDE.md.

#### Scenario: Fast-Forward section is absent from global CLAUDE.md

- **GIVEN** a reader opens the global CLAUDE.md after this change
- **WHEN** they search for "## Fast-Forward" or "## Fast-Forward (/sdd-ff)"
- **THEN** they MUST NOT find that section
- **AND** the authoritative source for the fast-forward algorithm MUST be `skills/sdd-ff/SKILL.md`

#### Scenario: Apply Strategy section is absent from global CLAUDE.md

- **GIVEN** a reader opens the global CLAUDE.md after this change
- **WHEN** they search for "## Apply Strategy"
- **THEN** they MUST NOT find that section

#### Scenario: SDD Flow Phase DAG section is absent from global CLAUDE.md

- **GIVEN** a reader opens the global CLAUDE.md after this change
- **WHEN** they search for "## SDD Flow" or "Phase DAG"
- **THEN** they MUST NOT find that section as a standalone heading
- **AND** a brief reference to the phase DAG MAY exist in the Architecture section (as a pointer, not a full diagram)

#### Scenario: How I Execute Commands delegation pattern is absent from global CLAUDE.md

- **GIVEN** a reader opens the global CLAUDE.md after this change
- **WHEN** they search for "## How I Execute Commands" or "Sub-agent launch pattern"
- **THEN** they MUST NOT find that section
- **AND** the delegation pattern MUST remain documented in `skills/sdd-ff/SKILL.md` and `skills/sdd-new/SKILL.md`

#### Scenario: Classification and routing logic remains unaffected

- **GIVEN** the redundant sections have been removed
- **WHEN** the orchestrator classifies a user message
- **THEN** the classification MUST produce identical results as before the removal
- **AND** no classification keyword, routing rule, scope estimation signal, or ambiguity heuristic MUST have been removed

---

### Requirement: Global CLAUDE.md MUST stay under 20,000 characters (budget governance)

The global CLAUDE.md (source: `CLAUDE.md` in repo root, deployed to `~/.claude/CLAUDE.md`) MUST NOT exceed 20,000 characters.

#### Scenario: Global CLAUDE.md is within budget after this change

- **GIVEN** the refactoring is complete and all sections have been extracted or condensed
- **WHEN** the character count of the global CLAUDE.md is measured
- **THEN** the count MUST be at most 20,000 characters

#### Scenario: Future additions that would exceed the budget are flagged

- **GIVEN** a future change proposes adding content to the global CLAUDE.md
- **WHEN** the resulting character count would exceed 20,000 characters
- **THEN** the `/project-audit` budget compliance check SHOULD flag a warning
- **AND** the change author MUST either extract content to a skill or increase the budget via a governance exception documented in an ADR

---

### Requirement: Project CLAUDE.md MUST be override-only and under 5,000 characters

The project-level CLAUDE.md (in the repo root for this project, or `.claude/CLAUDE.md` in other projects) MUST contain only project-specific overrides and MUST NOT duplicate global orchestrator content.

#### Scenario: Project CLAUDE.md contains only project-specific content

- **GIVEN** a reader opens the project CLAUDE.md after this change
- **WHEN** they read the content
- **THEN** it MUST contain a project identity header
- **AND** it MUST contain the project-specific Tech Stack table
- **AND** it MUST contain any project-specific Unbreakable Rules additions (if any)
- **AND** it MUST contain Project Memory section pointers
- **AND** it MUST contain project-local Skills Registry entries (if any)
- **AND** it MUST NOT contain the Classification Decision Table
- **AND** it MUST NOT contain the Scope Estimation Heuristic
- **AND** it MUST NOT contain the Ambiguity Detection Heuristics
- **AND** it MUST NOT contain the Communication Persona section
- **AND** it MUST NOT contain the Teaching Principles section
- **AND** it MUST NOT contain the SDD Flow, Fast-Forward, Apply Strategy, or delegation pattern sections

#### Scenario: Project CLAUDE.md is within budget

- **GIVEN** the refactoring is complete
- **WHEN** the character count of the project CLAUDE.md is measured
- **THEN** the count MUST be at most 5,000 characters

#### Scenario: Combined always-loaded context is under 25,000 characters

- **GIVEN** both global and project CLAUDE.md have been refactored
- **WHEN** their combined character count is measured
- **THEN** the combined count MUST be at most 25,000 characters

---

### Requirement: Character budgets MUST be documented and enforceable

Three character budgets MUST be defined and documented: global CLAUDE.md (20k), project CLAUDE.md (5k), and new orchestrator skills (8k per skill).

#### Scenario: Budget constants are documented in an ADR

- **GIVEN** this change is complete
- **WHEN** a reader opens the new ADR for this change
- **THEN** the ADR MUST state the three budgets:
  - Global CLAUDE.md: 20,000 characters maximum
  - Project CLAUDE.md: 5,000 characters maximum
  - New orchestrator skills: 8,000 characters maximum per skill
- **AND** the ADR MUST document the exception process (explicit ADR approval to exceed a budget)
- **AND** the ADR MUST state that existing skills are grandfathered (budget applies to newly created orchestrator skills only)

#### Scenario: Conventions reflect the inline-vs-skill boundary

- **GIVEN** `ai-context/conventions.md` is updated
- **WHEN** a reader searches for "inline" or "skill boundary"
- **THEN** they MUST find a statement reflecting the refined boundary: classification logic stays inline in CLAUDE.md; presentation content (persona, teaching, session banner) is skill-based and loaded on demand

---

### Requirement: ADR MUST document the refined inline-vs-skill boundary

A new ADR MUST be created documenting the decision to refine the inline-vs-skill boundary for orchestrator content. The ADR supersedes the original decision (ADR #18 spirit) that kept all orchestrator behavior inline.

#### Scenario: ADR exists and documents the boundary

- **GIVEN** the change is complete
- **WHEN** a reader opens `docs/adr/` and examines the new ADR
- **THEN** the ADR MUST state:
  - **Context**: CLAUDE.md grew to ~88k characters (global + project) through successive additive changes
  - **Decision**: Classification logic (Decision Table, Scope Estimation, Ambiguity Heuristics) remains inline; presentation logic (Persona, Teaching, Banner) moves to `skills/orchestrator-persona/SKILL.md`
  - **Consequences**: Always-loaded context reduced to under 25k characters; classification timing safety preserved; future additions governed by character budgets

#### Scenario: ADR is referenced in the ADR index

- **GIVEN** the ADR is created
- **WHEN** a reader opens `docs/adr/README.md`
- **THEN** the new ADR MUST appear in the index with its number, title, and status

---

## MODIFIED — Modified requirements

### Requirement: CLAUDE.md documents the Always-On Orchestrator behavior _(modified)_

_(Before: "CLAUDE.md MUST contain a dedicated section that defines intent classification rules, the four intent classes, and the routing table." — no distinction between inline-required and extractable content.)_

CLAUDE.md MUST contain the intent classification rules, the four intent classes, and the routing table **inline**. Presentation-layer content (Communication Persona, Teaching Principles, Session Banner, New-User Detection) MUST be located in `skills/orchestrator-persona/SKILL.md`, not inline in CLAUDE.md. A loading instruction in CLAUDE.md MUST reference the persona skill.

#### Scenario: Section exists with inline classification content and a persona skill reference

- **GIVEN** a reader opens CLAUDE.md
- **WHEN** they search for "Always-On Orchestrator" or "Intent Classification"
- **THEN** they MUST find a section with that heading
- **AND** the section MUST contain the four intent classes and their routing actions inline
- **AND** the section MUST state the "never inline code" rule (with Trivial exception)
- **AND** the section MUST reference `skills/orchestrator-persona/SKILL.md` for tone, teaching, and persona rules
- **AND** the section MUST NOT contain the full Communication Persona or Teaching Principles content

### Requirement: CLAUDE.md MUST contain a Communication Persona section _(modified — relocated to skill)_

_(Before: "CLAUDE.md MUST contain a `## Communication Persona` section defining the orchestrator's tone, response style, and adaptive formality rules.")_

The Communication Persona content MUST be located in `skills/orchestrator-persona/SKILL.md`, NOT inline in CLAUDE.md. The behavioral requirements (tone, forbidden phrases, adaptive formality) remain unchanged — only the storage location changes.

#### Scenario: Communication Persona is not in CLAUDE.md

- **GIVEN** a reader opens CLAUDE.md
- **WHEN** they search for "Communication Persona"
- **THEN** they MUST NOT find a full section with persona rules
- **AND** they MAY find a brief reference or loading instruction

#### Scenario: All persona behavioral requirements still apply

- **GIVEN** the orchestrator generates a response to a free-form message
- **WHEN** the response is presented
- **THEN** the tone MUST still be warm, direct, confident, and pedagogical
- **AND** forbidden mechanical phrases MUST still be excluded
- **AND** adaptive formality MUST still be applied
- **AND** these rules are now sourced from `skills/orchestrator-persona/SKILL.md` instead of CLAUDE.md

### Requirement: CLAUDE.md MUST contain a Teaching Principles section with exactly 5 rules _(modified — relocated to skill)_

_(Before: "CLAUDE.md MUST contain a `## Teaching Principles` section defining exactly 5 concise teaching rules.")_

The Teaching Principles content MUST be located in `skills/orchestrator-persona/SKILL.md`, NOT inline in CLAUDE.md. The 5 teaching rules remain unchanged — only the storage location changes.

#### Scenario: Teaching Principles is not in CLAUDE.md

- **GIVEN** a reader opens CLAUDE.md
- **WHEN** they search for "Teaching Principles"
- **THEN** they MUST NOT find a full section with 5 teaching rules
- **AND** they MAY find a brief reference or loading instruction

#### Scenario: All teaching behavioral requirements still apply

- **GIVEN** the orchestrator generates a response that requires why-framing, educational gates, or error reformulation
- **WHEN** the response is presented
- **THEN** the teaching principles MUST still be applied
- **AND** these rules are now sourced from `skills/orchestrator-persona/SKILL.md` instead of CLAUDE.md

### Requirement: Session-start orchestrator banner _(modified — relocated to skill)_

_(Before: "The orchestrator MUST display a session banner at the start of every session." — Banner template was inline in CLAUDE.md.)_

The session banner template MUST be located in `skills/orchestrator-persona/SKILL.md`. The behavioral requirement (display once at session start, warm tone, covers all four intent classes) remains unchanged.

#### Scenario: Banner template is not in CLAUDE.md

- **GIVEN** a reader opens CLAUDE.md
- **WHEN** they search for "Session Banner" or "Orchestrator Session Banner"
- **THEN** they MUST NOT find the full banner template inline
- **AND** they MAY find a brief loading instruction referencing the persona skill

#### Scenario: Banner still displays at session start

- **GIVEN** a new session starts and the orchestrator loads the persona skill
- **WHEN** the first message arrives
- **THEN** the orchestrator MUST still display the session banner with welcoming tone
- **AND** the banner MUST appear exactly once per session

---

## REMOVED — Removed requirements

### Requirement: Updated CLAUDE.md Fast-Forward section

_(Reason: The Fast-Forward section was an inline summary of `sdd-ff/SKILL.md` content. The skill file is the authoritative source. The requirement to maintain a parallel summary in CLAUDE.md is removed to eliminate duplication. The sdd-orchestration spec requirement "Updated CLAUDE.md Fast-Forward section" is superseded by the skill-as-authoritative-source principle.)_

### Requirement: The Communication Persona section MUST be positioned in CLAUDE.md after the Teaching Principles section and before the Plan Mode Rules section

_(Reason: Both Communication Persona and Teaching Principles are relocated to `skills/orchestrator-persona/SKILL.md`. The positioning rule in CLAUDE.md is no longer applicable. Positioning within the skill file is governed by the SKILL.md structural contract.)_
