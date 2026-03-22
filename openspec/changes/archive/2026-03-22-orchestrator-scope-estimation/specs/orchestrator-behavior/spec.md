# Delta Spec: Orchestrator Behavior — Scope Estimation

Change: 2026-03-21-orchestrator-scope-estimation
Date: 2026-03-22
Base: openspec/specs/orchestrator-behavior/spec.md

## ADDED — Scope Estimation Heuristic for Change Requests

### Requirement: Change Requests MUST undergo scope estimation before routing

After classifying a message as a Change Request, the orchestrator MUST estimate the scope tier (Trivial, Moderate, or Complex) before selecting the routing action. Scope estimation is a post-classification, pre-routing step that applies only to Change Requests.

#### Scenario: Trivial change detected — user offered bypass or SDD

- **GIVEN** the user sends a Change Request message that matches all Trivial tier signals (e.g., "fix typo in README", "fix comment spelling in config.yaml")
- **WHEN** the orchestrator estimates scope
- **THEN** it MUST classify the scope as Trivial
- **AND** it MUST offer the user a choice: apply the change inline OR proceed with `/sdd-ff`
- **AND** the response MUST include the intent classification signal (`**Intent classification: Change Request**`)
- **AND** if the user chooses inline apply, the orchestrator MUST apply the change directly without SDD artifacts or sub-agent delegation

#### Scenario: Moderate change detected — standard SDD routing

- **GIVEN** the user sends a Change Request message that does not match Trivial signals and does not match Complex signals (e.g., "fix the login validation bug", "add retry logic to the payment service")
- **WHEN** the orchestrator estimates scope
- **THEN** it MUST classify the scope as Moderate
- **AND** it MUST recommend `/sdd-ff <inferred-slug>` (standard routing, no change from current behavior)

#### Scenario: Complex change detected — routed to sdd-new

- **GIVEN** the user sends a Change Request message that matches Complex tier signals (e.g., "rearchitect the auth system to use OAuth2", "migrate the database from Postgres to MongoDB")
- **WHEN** the orchestrator estimates scope
- **THEN** it MUST classify the scope as Complex
- **AND** it MUST recommend `/sdd-new <inferred-slug>` instead of `/sdd-ff`
- **AND** the response MUST explain that `/sdd-new` provides a full SDD cycle with explicit user gates at each phase

#### Scenario: Ambiguous scope defaults to Moderate

- **GIVEN** the user sends a Change Request message where scope signals are mixed or absent
- **WHEN** the orchestrator cannot confidently classify as Trivial or Complex
- **THEN** it MUST default to Moderate
- **AND** it MUST NOT default to Trivial under any ambiguity

---

### Requirement: Three scope tiers with explicit detection signals

The orchestrator MUST define exactly three scope tiers: Trivial, Moderate, and Complex. Each tier MUST have a keyword-based detection signal list and a routing behavior.

#### Scenario: Trivial tier signal list is restrictive

- **GIVEN** the orchestrator evaluates scope signals for the Trivial tier
- **WHEN** it checks the message against Trivial signals
- **THEN** Trivial MUST only trigger when ALL of the following conditions are met:
  - The message contains at least one Trivial keyword (typo, comment, wording, spelling, whitespace, formatting, doc fix, rename single file, punctuation)
  - The implied scope is a single file or a single line change
  - No structural, behavioral, or architectural keywords are present
- **AND** the Trivial signal list MUST NOT exceed 15 keywords

#### Scenario: Complex tier signal list captures multi-domain changes

- **GIVEN** the orchestrator evaluates scope signals for the Complex tier
- **WHEN** it checks the message against Complex signals
- **THEN** Complex MUST trigger when the message contains at least one Complex keyword (rearchitect, migrate, rewrite, redesign, overhaul, cross-domain, multi-service, breaking change, new system, platform change)
  - OR the message explicitly references multiple distinct domains or services
  - OR the message describes a migration or technology replacement
- **AND** the Complex signal list MUST NOT exceed 15 keywords

#### Scenario: Moderate tier is the residual class

- **GIVEN** the orchestrator has evaluated Trivial and Complex signals
- **WHEN** neither Trivial nor Complex conditions are fully met
- **THEN** the scope MUST be classified as Moderate
- **AND** Moderate does NOT have its own keyword list — it is the default

---

### Requirement: Scope estimation is documented in a dedicated CLAUDE.md section

CLAUDE.md MUST contain a `## Scope Estimation Heuristic` section that defines the three tiers, their detection signals, and routing behavior. The Classification Decision Table MUST reference this section from the Change Request branch.

#### Scenario: Scope Estimation Heuristic section exists and is findable

- **GIVEN** a reader opens CLAUDE.md
- **WHEN** they search for "Scope Estimation Heuristic"
- **THEN** they MUST find a section with that heading
- **AND** the section MUST define Trivial, Moderate, and Complex tiers
- **AND** the section MUST list detection signals for Trivial and Complex
- **AND** the section MUST specify routing behavior per tier

#### Scenario: Classification Decision Table references scope estimation

- **GIVEN** a reader examines the Classification Decision Table's Change Request branch
- **WHEN** they read the routing logic
- **THEN** they MUST find a cross-reference to the Scope Estimation Heuristic section
- **AND** the cross-reference MUST indicate that scope estimation runs after intent classification and before routing

---

## MODIFIED — Orchestrator never writes implementation code inline

### Requirement: Orchestrator never writes implementation code inline _(modified — Trivial tier exception)_

The orchestrator MUST NOT produce implementation code, delta specs, or design artifacts directly in conversation context — **except** when the scope tier is Trivial and the user has explicitly chosen inline apply.

_(Before: "The orchestrator MUST NOT produce implementation code, delta specs, or design artifacts directly in conversation context." — absolute prohibition with no exceptions.)_

#### Scenario: Trivial inline apply is permitted

- **GIVEN** the orchestrator has classified a Change Request as scope tier Trivial
- **AND** the user has explicitly chosen inline apply (not `/sdd-ff`)
- **WHEN** the orchestrator applies the change
- **THEN** it MAY write the change directly without SDD artifacts or sub-agent delegation
- **AND** this is a formal exception to the "never inline code" rule

#### Scenario: Non-Trivial changes still require SDD delegation

- **GIVEN** the orchestrator has classified a Change Request as scope tier Moderate or Complex
- **WHEN** the orchestrator responds
- **THEN** it MUST NOT write code in the response
- **AND** it MUST recommend the appropriate SDD command

#### Scenario: Trivial bypass without user confirmation is prohibited

- **GIVEN** the orchestrator has classified a Change Request as scope tier Trivial
- **WHEN** the orchestrator responds
- **THEN** it MUST present the inline apply option to the user
- **AND** it MUST NOT apply the change inline without the user explicitly choosing that option
- **AND** the user MUST always have the option to choose `/sdd-ff` instead

---

## MODIFIED — Unbreakable Rule 1 exception clause

### Requirement: Unbreakable Rule 1 gains a formal Trivial tier exception

Unbreakable Rule 1 ("I NEVER write implementation code, specs, or designs inline") MUST be updated to include a parenthetical exception clause acknowledging Trivial tier inline apply.

#### Scenario: Rule 1 text includes exception clause

- **GIVEN** a reader opens CLAUDE.md
- **WHEN** they read Unbreakable Rule 1
- **THEN** the rule MUST contain a parenthetical or clause acknowledging the Trivial tier exception
- **AND** the exception MUST state that it applies only when scope signals are unambiguously trivial and the user has chosen inline apply

#### Scenario: Exception clause does not weaken Rule 1 for non-Trivial changes

- **GIVEN** a Change Request is classified as Moderate or Complex
- **WHEN** the orchestrator evaluates Rule 1
- **THEN** Rule 1 MUST apply in full force — no inline code, mandatory SDD delegation
- **AND** the Trivial exception MUST NOT be cited as justification for bypassing SDD on non-Trivial changes

---

## ADDED — Scope tier visibility in response signal

### Requirement: Scope tier MAY be included in the intent classification signal

The orchestrator MAY include the estimated scope tier in the intent classification signal for Change Requests.

#### Scenario: Change Request signal includes scope tier

- **GIVEN** the orchestrator classifies a message as Change Request with scope tier Moderate
- **WHEN** the orchestrator generates the response signal
- **THEN** it MAY display: `**Intent classification: Change Request (Moderate)**`
- **AND** this is optional — the orchestrator MAY also display just `**Intent classification: Change Request**`

---

## Rules

- Scope estimation applies ONLY to Change Requests — Questions, Explorations, and Meta-Commands are not affected
- The default scope tier is Moderate — never Trivial
- Trivial tier requires ALL conditions to be met (restrictive); Complex requires ANY condition (permissive)
- Trivial inline apply is artifact-free: no proposal.md, no spec, no design, no tasks, no verify-report
- The user MUST always be offered `/sdd-ff` as an alternative to Trivial inline apply
- Scope estimation does not replace intent classification — it is a sub-step within the Change Request branch
- Signal keyword lists for Trivial and Complex MUST NOT exceed 15 entries each
- Scope estimation is inline logic in CLAUDE.md — no separate skill or sub-agent
