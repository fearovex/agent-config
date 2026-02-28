# Delta Spec: project-analysis

Change: audit-and-analyze-capabilities
Date: 2026-02-28
Base: openspec/specs/project-analysis/spec.md

## MODIFIED — ai-context/ creation behavior

### Requirement: `project-analyze` updates `ai-context/` using append/update strategy

*(Before: The scenario "First run creates `[auto-updated]` sections when `ai-context/` files are absent" stated that project-analyze creates `ai-context/stack.md`, `ai-context/architecture.md`, and `ai-context/conventions.md` if they do not exist.)*

The SKILL.md explicitly forbids creating the `ai-context/` directory or its files. The spec MUST be updated to match the SKILL.md runtime behavior.

#### Scenario: project-analyze does NOT create ai-context/ files when absent *(modified)*

- **GIVEN** the target project has no `ai-context/` directory
- **WHEN** `/project-analyze` runs
- **THEN** it does NOT create `ai-context/stack.md`, `ai-context/architecture.md`, or `ai-context/conventions.md`
- **AND** it produces only `analysis-report.md` at the project root
- **AND** it emits a message instructing the user to run `/memory-init` first to create the `ai-context/` directory

#### Scenario: project-analyze does NOT create individual ai-context/ files when directory exists but files are missing

- **GIVEN** the target project has an `ai-context/` directory but no `stack.md` file
- **WHEN** `/project-analyze` runs
- **THEN** it does NOT create `ai-context/stack.md`
- **AND** it skips the `[auto-updated]` section update for that file
- **AND** it proceeds with the remaining analysis steps without error

## REMOVED — First run creation scenario

### Scenario: First run creates `[auto-updated]` sections when `ai-context/` files are absent
*(Reason: Contradicts SKILL.md Rule 4 which states "NEVER creates ai-context/ if it does not exist". The SKILL.md is the runtime source of truth. This scenario was never implemented and causes verification failures.)*

---

## MODIFIED — `[auto-updated]` marker format

### Requirement: `[auto-updated]` section markers define overwrite boundaries in `ai-context/`

*(Before: The spec stated the marker format as `<!-- [auto-updated] start: <section-name> -->` and `<!-- [auto-updated] end: <section-name> -->`.)*

The actual marker format used by the SKILL.md and observed in existing `ai-context/` files is different. The spec MUST use the correct format.

#### Scenario: `[auto-updated]` marker format matches SKILL.md implementation *(modified)*

- **GIVEN** `project-analyze` has written to `ai-context/stack.md`
- **WHEN** the file is read
- **THEN** each auto-updated section begins with a line matching the format: `<!-- [auto-updated]: <section-id> -- last run: YYYY-MM-DD -->`
- **AND** ends with a line matching the format: `<!-- [/auto-updated] -->`
- **AND** the section-id is a stable identifier (e.g., `stack-detection`, `structure-mapping`, `drift-summary`, `observed-conventions`) that does not change between runs
- **AND** the `last run` date reflects the date of the current analysis run

#### Scenario: Consuming skills parse the correct marker format

- **GIVEN** `project-analyze` has written `[auto-updated]` sections to `ai-context/architecture.md`
- **WHEN** `/project-analyze` runs again on the same project
- **THEN** it locates existing sections using the format `<!-- [auto-updated]: <section-id> -- last run: YYYY-MM-DD -->`
- **AND** it replaces only the content between the opening and closing markers
- **AND** it does NOT create duplicate sections due to failing to match the old markers

---

## ADDED — Out of Scope clarification on ai-context/ file creation

### Requirement: Out of Scope item 8 is corrected for consistency

The Out of Scope section item 8 currently states: "project-analyze is designed for re-analysis of established projects, though it will create files if they are absent." This trailing clause contradicts the SKILL.md behavior.

#### Scenario: Out of Scope item 8 does not claim file creation

- **GIVEN** `openspec/specs/project-analysis/spec.md` is read
- **WHEN** the Out of Scope section item 8 is examined
- **THEN** the text states that `project-analyze` does NOT create `ai-context/` files when absent
- **AND** it recommends `memory-init` as the first-time initializer without suggesting project-analyze as an alternative for file creation
