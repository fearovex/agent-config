# Delta Spec: sdd-apply-quality-gate

Change: solid-ddd-quality-enforcement
Date: 2026-03-04
Base: openspec/specs/sdd-apply/spec.md

## ADDED — New requirements

---

### Requirement: solid-ddd unconditional preload for all non-documentation code changes

`sdd-apply` MUST load `~/.claude/skills/solid-ddd/SKILL.md` during Step 0 for every non-documentation code change, regardless of the project's technology stack. The scope guard (documentation-only exclusion) that already gates tech skill preloads MUST also gate the `solid-ddd` preload — when the scope guard skips tech skill preloads, it MUST also skip `solid-ddd` preload. For all other changes, `solid-ddd` is always loaded alongside any matched framework skills.

#### Scenario: solid-ddd is loaded for a code-touching change with no stack match

- **GIVEN** `ai-context/stack.md` exists but contains no keyword matching any technology skill
- **AND** the design.md change matrix contains at least one non-documentation file extension
- **WHEN** `sdd-apply` executes Step 0
- **THEN** `~/.claude/skills/solid-ddd/SKILL.md` is read
- **AND** the Step 0 report includes: `"solid-ddd loaded (unconditional — code change)"`
- **AND** the sub-agent's implementation context includes the solid-ddd patterns

#### Scenario: solid-ddd is loaded alongside framework skills for a code-touching change

- **GIVEN** `ai-context/stack.md` contains `"react"` and `"typescript"`
- **AND** `~/.claude/skills/react-19/SKILL.md` and `~/.claude/skills/typescript/SKILL.md` exist
- **AND** the design.md change matrix contains `.tsx` and `.ts` files
- **WHEN** `sdd-apply` executes Step 0
- **THEN** `react-19`, `typescript`, AND `solid-ddd` are all loaded
- **AND** each is reported in the Step 0 detection report

#### Scenario: solid-ddd is skipped for documentation-only changes

- **GIVEN** the design.md change matrix contains ONLY `.md` and `.yaml` file extensions
- **WHEN** `sdd-apply` executes Step 0
- **THEN** neither framework skills NOR `solid-ddd` is loaded
- **AND** Step 0 reports: `"Tech skill preload: skipped (documentation-only change)"`

#### Scenario: solid-ddd file absent from disk — silently skipped

- **GIVEN** `~/.claude/skills/solid-ddd/SKILL.md` does NOT exist on disk
- **AND** the change is non-documentation
- **WHEN** `sdd-apply` Step 0 attempts to load `solid-ddd`
- **THEN** the missing file is silently skipped (same non-blocking rule as other tech skills)
- **AND** no `blocked` or `failed` status is produced
- **AND** apply proceeds normally with Step 1

#### Scenario: Stack-to-Skill Mapping Table contains the solid-ddd entry

- **GIVEN** the updated `sdd-apply/SKILL.md`
- **WHEN** a developer reads the Stack-to-Skill Mapping Table
- **THEN** an entry for `solid-ddd` is present
- **AND** the entry is marked as unconditional (or "all code changes") rather than keyword-triggered
- **AND** the path in the entry resolves to `~/.claude/skills/solid-ddd/SKILL.md`

---

### Requirement: sdd-apply enforces a structured Quality Gate before task completion

`sdd-apply` MUST replace the vague "Code Standards" or "Code standards" section with a structured Quality Gate. The Quality Gate MUST contain a numbered checklist of at least 5 independently verifiable criteria. A sub-agent executing a code task MUST evaluate each criterion before marking the task `[x]` complete.

#### Scenario: Quality Gate checklist has at least 5 criteria

- **GIVEN** the updated `sdd-apply/SKILL.md`
- **WHEN** a developer reads the Quality Gate section
- **THEN** the section contains a numbered list with at least 5 items
- **AND** each item is independently verifiable (a reader can determine pass/fail without ambiguity)
- **AND** no item is a vague directive like "follow conventions" or "no over-engineering" without a concrete signal

#### Scenario: Quality Gate covers single responsibility verification

- **GIVEN** the updated Quality Gate checklist
- **WHEN** a sub-agent reads it before marking a task complete
- **THEN** at least one criterion explicitly asks the sub-agent to verify that each new class, function, or module has a single well-defined responsibility
- **AND** the criterion provides a concrete signal (e.g., "could this be described in one sentence without using 'and'?")

#### Scenario: Quality Gate covers abstraction and dependency direction

- **GIVEN** the updated Quality Gate checklist
- **WHEN** a sub-agent reads it before marking a task complete
- **THEN** at least one criterion addresses dependency direction (higher-level modules do not import lower-level details directly)
- **AND** at least one criterion addresses abstraction appropriateness (no leaking of implementation details through public interfaces)

#### Scenario: Quality Gate covers domain model integrity

- **GIVEN** the updated Quality Gate checklist
- **WHEN** a sub-agent reads it before marking a task complete
- **THEN** at least one criterion addresses domain model integrity — specifically, that business logic lives in domain objects, not solely in service classes
- **AND** the criterion is marked N/A-eligible when the task does not touch domain model code

#### Scenario: Quality Gate covers over-engineering prevention

- **GIVEN** the updated Quality Gate checklist
- **WHEN** a sub-agent reads it before marking a task complete
- **THEN** at least one criterion explicitly checks that no speculative abstractions, unnecessary layers, or unused interfaces have been introduced
- **AND** the criterion provides a concrete signal (e.g., "is there a real use case today for this abstraction, or is it speculative?")

#### Scenario: N/A-with-reason is an accepted Quality Gate outcome

- **GIVEN** a sub-agent is evaluating the Quality Gate for a task that does not touch domain model code
- **WHEN** the sub-agent reaches the domain model integrity criterion
- **THEN** the sub-agent MAY mark that criterion as N/A
- **AND** the sub-agent MUST record a brief reason for the N/A (e.g., "task adds a CLI flag — no domain model touched")
- **AND** the N/A designation does NOT prevent the task from being marked `[x]` complete

#### Scenario: Quality Gate violation produces QUALITY_VIOLATION note

- **GIVEN** a sub-agent evaluates the Quality Gate and finds that a new class has more than one clear responsibility (SRP violation)
- **WHEN** the sub-agent reaches that criterion
- **THEN** the sub-agent MUST NOT silently mark the task `[x]` complete
- **AND** the sub-agent records a `QUALITY_VIOLATION: <description>` note in the task output
- **AND** the violation is escalated to `DEVIATION` status if it contradicts an observable behavior defined in the spec
- **AND** the task SHOULD be reworked before being marked complete, unless the sub-agent documents a specific justification

#### Scenario: QUALITY_VIOLATION is non-blocking by default

- **GIVEN** a sub-agent records a `QUALITY_VIOLATION` note on a task
- **AND** the violation does NOT contradict any scenario in the spec
- **WHEN** the sub-agent decides whether to continue
- **THEN** the sub-agent MAY continue to the next task without blocking the entire apply phase
- **AND** the orchestrator MUST surface the QUALITY_VIOLATION notes in the phase summary for user review
- **AND** the overall apply status MUST be `warning` (not `failed`) when violations are present but non-contradicting

---

### Requirement: loaded technology skills and solid-ddd are treated as acceptance criteria, not reference

When `sdd-apply` loads technology skills and/or `solid-ddd` in Step 0, the sub-agent MUST treat the patterns in those skills as acceptance criteria to be checked before task completion — not as contextual reference material to be optionally consulted.

#### Scenario: tech skill pattern used as acceptance criterion

- **GIVEN** `react-19` was loaded in Step 0
- **AND** a task requires implementing a React component
- **WHEN** the sub-agent completes the task implementation
- **THEN** the sub-agent verifies that the component follows the patterns in `react-19/SKILL.md`
- **AND** if the implementation contradicts a pattern (e.g., uses a deprecated API), the sub-agent records a `QUALITY_VIOLATION` note

#### Scenario: solid-ddd patterns used as acceptance criteria

- **GIVEN** `solid-ddd` was loaded in Step 0
- **AND** a task requires introducing a new class
- **WHEN** the sub-agent completes the task implementation
- **THEN** the sub-agent checks the new class against the SOLID and DDD patterns in `solid-ddd/SKILL.md`
- **AND** any identified violation is recorded as `QUALITY_VIOLATION` with a specific principle reference (e.g., "QUALITY_VIOLATION: SRP — AuthService handles both authentication and user profile updates")

---

## MODIFIED — Modified requirements

### Requirement: Backward compatibility with existing Code Standards section *(modified)*

The existing `## Code standards` or `## Code Standards` section MUST be replaced (not supplemented) by the new Quality Gate section. The reference to "I load technology skills if applicable" MUST remain, forwarding to Step 0 as previously required.

*(Before: the Code Standards section contained vague directives with no actionable checklist — "follow conventions", "no over-engineering" — and instructed sub-agents to load technology skills but provided no enforcement mechanism for their patterns.)*

#### Scenario: old Code Standards section is fully replaced

- **GIVEN** the updated `sdd-apply/SKILL.md`
- **WHEN** a developer searches for the old vague directives ("follow conventions", "no over-engineering" as standalone instructions)
- **THEN** those phrases do NOT appear as the sole content of a quality criterion
- **AND** they are either absent or appear only as context within a more specific verifiable criterion

#### Scenario: Quality Gate section references Step 0 for skill loading

- **GIVEN** the updated Quality Gate section
- **WHEN** an implementer reads it
- **THEN** it references Step 0 as the mechanism by which technology skills and solid-ddd are loaded
- **AND** it does NOT re-list the loading logic inline

---

## Rules

- The Quality Gate checklist MUST use a numbered list format (not bullet points) so items can be referenced by number in QUALITY_VIOLATION notes
- Each Quality Gate criterion MUST include a "what to look for" signal or heuristic — vague criteria are non-conforming
- The solid-ddd entry in the Stack-to-Skill Mapping Table MUST appear in a visually distinct row or with a comment indicating it is unconditional (not keyword-matched)
- QUALITY_VIOLATION notes MUST use the exact format `QUALITY_VIOLATION: <principle> — <description>` when a specific SOLID or DDD principle is implicated
- The N/A-with-reason option MUST be documented in the Quality Gate section itself, not only implied; a sub-agent MUST be able to find it without consulting external docs
