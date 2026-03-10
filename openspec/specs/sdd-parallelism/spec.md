# Spec: SDD Parallelism Model

Change: 2026-03-10-sdd-parallelism-adr
Date: 2026-03-10
Base: N/A (new domain spec — ADR documentation)

## Requirements

### Requirement: ADR document must define the current parallelism model

The system MUST have `docs/adr/026-sdd-parallelism-model.md` documenting the SDD parallelism model with Status, Context, Decision, Consequences, and Parallelism Limits Table sections.

#### Scenario: ADR file is created with required sections

- **GIVEN** no `docs/adr/026-sdd-parallelism-model.md` exists
- **WHEN** the apply phase runs
- **THEN** the file MUST be created
- **AND** it MUST contain a `## Status` section with a valid status value
- **AND** it MUST contain a `## Context` section explaining why the parallelism model matters
- **AND** it MUST contain a `## Decision` section with specific, actionable limits
- **AND** it MUST contain a `## Consequences` section listing positive and negative trade-offs

#### Scenario: ADR is registered in the index

- **GIVEN** `docs/adr/README.md` contains the ADR index table
- **WHEN** the new ADR is added
- **THEN** `docs/adr/README.md` MUST have a new row for ADR 026
- **AND** the row MUST include: number, title, status, and date fields

### Requirement: ADR must define maximum parallel Task count with rationale

The ADR MUST define a concrete maximum number of simultaneously running Task sub-agents, with documented rationale based on observed behavior.

#### Scenario: Parallelism limit is stated concretely

- **GIVEN** the ADR Context and Decision sections are written
- **WHEN** a reader looks for the parallel Task limit
- **THEN** the ADR MUST state a specific number (e.g., "maximum 2 Tasks in parallel")
- **AND** the Decision section MUST state this limit in unambiguous terms
- **AND** the rationale MUST explain what factors constrain the limit

#### Scenario: Limit is based on observed behavior, not speculation

- **GIVEN** the ADR is about the current system
- **WHEN** the evidence basis is examined
- **THEN** the ADR MUST note when reasoning is based on "observed behavior" rather than hard technical constraints
- **AND** it MUST acknowledge that limits may be revised if empirical evidence changes

### Requirement: ADR must define the file conflict boundary rule

The ADR MUST state a rule distinguishing which Task sub-agents can and cannot run in parallel based on file write conflicts.

#### Scenario: Safe parallelism boundary is defined

- **GIVEN** two Tasks that write to different files
- **WHEN** the ADR is consulted
- **THEN** it MUST state that Tasks writing to non-overlapping files MAY run in parallel
- **AND** it MUST state that Tasks writing to the same files MUST NOT run in parallel

#### Scenario: Current parallel pair (spec + design) is justified

- **GIVEN** the current model runs sdd-spec and sdd-design in parallel
- **WHEN** the ADR justifies this choice
- **THEN** the ADR MUST confirm that spec and design write to different files
- **AND** it MUST confirm this is the known safe parallel boundary within the SDD cycle

### Requirement: ADR must evaluate bounded-context parallel apply

The ADR MUST evaluate whether `sdd-apply` batches can run in parallel when tasks touch independent bounded contexts.

#### Scenario: Multi-domain parallel apply is evaluated

- **GIVEN** a change touches 3 independent bounded contexts (e.g., auth, notifications, audit)
- **WHEN** the ADR evaluates parallel apply
- **THEN** the ADR MUST state whether this is feasible, not feasible, or feasible under specific conditions
- **AND** the evaluation MUST address file conflict risk for cross-domain files (e.g., CLAUDE.md, ai-context/)

#### Scenario: Implementation of parallel apply is deferred

- **GIVEN** the ADR recommends a position on parallel apply
- **WHEN** that position implies implementation changes
- **THEN** the ADR MUST note that implementation (if any) is a separate change
- **AND** the ADR itself MUST NOT implement any SKILL.md changes

### Requirement: CLAUDE.md SDD Flow section may be updated with parallelism notes

If the ADR changes the current model, CLAUDE.md MUST be updated. If the ADR confirms the current model, CLAUDE.md MUST NOT be modified unnecessarily.

#### Scenario: Current model is confirmed — CLAUDE.md unchanged

- **GIVEN** the ADR concludes that the current model (spec+design parallel, everything else sequential) is correct
- **WHEN** the apply phase completes
- **THEN** CLAUDE.md MUST NOT be modified
- **AND** the ADR MUST reference the existing CLAUDE.md Fast-Forward section as accurate

#### Scenario: Current model is extended — CLAUDE.md updated

- **GIVEN** the ADR introduces a new parallel boundary (e.g., parallel apply allowed under conditions)
- **WHEN** the apply phase runs
- **THEN** the CLAUDE.md `## Fast-Forward` and/or `## Apply Strategy` sections MUST be updated
- **AND** the change MUST be minimal and precise — only the sentences that describe parallelism limits

---

## Validation Criteria

- [ ] `docs/adr/026-sdd-parallelism-model.md` exists with all 4 required sections
- [ ] `docs/adr/README.md` registers ADR 026
- [ ] ADR states a concrete maximum parallel Task count with rationale
- [ ] ADR defines the file conflict boundary rule (same-file writes must be sequential)
- [ ] ADR evaluates bounded-context parallel apply and states a position
- [ ] ADR confirms whether CLAUDE.md update is needed and acts accordingly
- [ ] ADR clearly marks conclusions as "based on observed behavior" where empirical evidence is absent

---

## Notes

- This change is documentation-only: no SKILL.md files are modified
- The ADR number (026) is determined by counting existing `docs/adr/[0-9][0-9][0-9]-*.md` files; verify at apply time
- The spec leaves the parallelism limit value open for the design to determine based on research; the spec only requires the limit exists and is justified
