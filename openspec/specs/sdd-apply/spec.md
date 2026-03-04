# Spec: sdd-apply — Technology Skill Auto-Activation

*Created: 2026-03-03 by change "tech-skill-auto-activation"*

## Requirements

### Requirement: Step 0 — Technology Skill Preload

`sdd-apply` MUST execute a technology skill preload step (Step 0) before reading the change context (Step 1). Step 0 MUST be non-blocking: its failure or partial execution MUST NOT change the overall apply `status` to `blocked` or `failed`.

#### Scenario: Stack detected from ai-context/stack.md — matching skills exist

- **GIVEN** `ai-context/stack.md` exists and contains the keyword `"react"`
- **AND** `~/.claude/skills/react-19/SKILL.md` exists on disk
- **WHEN** `sdd-apply` reaches Step 0
- **THEN** it reads the contents of `~/.claude/skills/react-19/SKILL.md`
- **AND** it adds those contents as implementation context for subsequent steps
- **AND** it reports: `"Tech skill loaded: react-19 (source: ai-context/stack.md)"`

#### Scenario: Stack detected — multiple matching skills

- **GIVEN** `ai-context/stack.md` contains keywords `"typescript"`, `"react"`, and `"playwright"`
- **AND** all three corresponding skill files exist on disk
- **WHEN** `sdd-apply` reaches Step 0
- **THEN** it loads all three skills: `typescript`, `react-19`, `playwright`
- **AND** it reports one detection line per skill loaded

#### Scenario: Detected technology skill absent from disk

- **GIVEN** `ai-context/stack.md` contains `"django"`
- **AND** `~/.claude/skills/django-drf/SKILL.md` does NOT exist on disk
- **WHEN** `sdd-apply` reaches Step 0
- **THEN** the missing skill is silently skipped
- **AND** no `blocked` or `failed` status is produced
- **AND** apply proceeds normally with Step 1

#### Scenario: ai-context/stack.md absent

- **GIVEN** the project has no `ai-context/stack.md` file
- **WHEN** `sdd-apply` reaches Step 0
- **THEN** Step 0 is skipped with an INFO-level note: `"Tech skill preload: skipped (ai-context/stack.md not found)"`
- **AND** apply continues normally with Step 1

#### Scenario: Documentation-only change (scope guard)

- **GIVEN** the design.md file change matrix contains ONLY `.md` and `.yaml` file extensions (no source code files)
- **WHEN** `sdd-apply` reaches Step 0
- **THEN** Step 0 is skipped with note: `"Tech skill preload: skipped (documentation-only change)"`
- **AND** apply continues normally with Step 1

#### Scenario: openspec/config.yaml stack section used as secondary source

- **GIVEN** `ai-context/stack.md` is absent
- **AND** `openspec/config.yaml` contains a `project.stack` section with `language: "typescript"`
- **WHEN** `sdd-apply` reaches Step 0
- **THEN** it reads the `project.stack` section from `openspec/config.yaml`
- **AND** it applies keyword matching against the Stack-to-Skill Mapping Table
- **AND** it reports: `"Tech skill loaded: typescript (source: openspec/config.yaml)"`

---

### Requirement: Stack-to-Skill Mapping Table

`sdd-apply` MUST contain an exhaustive Stack-to-Skill Mapping Table that maps technology keywords to their corresponding skill paths. The table MUST cover all technology skills in the global catalog.

#### Scenario: Complete mapping coverage

- **GIVEN** the Stack-to-Skill Mapping Table is embedded in `sdd-apply/SKILL.md`
- **WHEN** a developer inspects the table
- **THEN** every technology skill in the CLAUDE.md Skills Registry is represented by at least one keyword row
- **AND** the mapping is unambiguous: each keyword maps to exactly one skill path

#### Scenario: Keyword matching is case-insensitive

- **GIVEN** `ai-context/stack.md` contains `"TypeScript"` (capital T)
- **AND** the mapping table has keyword `"typescript"` → `typescript/SKILL.md`
- **WHEN** Step 0 runs the matching
- **THEN** it matches `"TypeScript"` to `typescript` (case-insensitive comparison)
- **AND** `typescript` skill is loaded

---

### Requirement: Detection Report

`sdd-apply` MUST produce a detection report in its Step 0 output. The report MUST list every skill that was loaded or explain why preload was skipped.

#### Scenario: Normal detection report

- **GIVEN** Step 0 loaded two skills: `typescript` and `react-19`
- **WHEN** `sdd-apply` produces its output
- **THEN** the output includes:
  ```
  Tech skill preload:
    - typescript loaded (source: ai-context/stack.md)
    - react-19 loaded (source: ai-context/stack.md)
  ```

#### Scenario: Skipped skills appear in report

- **GIVEN** Step 0 detected `"python"` in stack.md
- **AND** `~/.claude/skills/pytest/SKILL.md` does not exist
- **WHEN** Step 0 produces the detection report
- **THEN** the report notes: `"pytest: skipped (file not found)"`

---

### Requirement: Backward compatibility with existing Code Standards section

The existing `## Code standards` section MUST be updated so the "I load technology skills if applicable" paragraph forwards to Step 0 rather than repeating the logic.

#### Scenario: No duplicate logic

- **GIVEN** the updated `sdd-apply/SKILL.md`
- **WHEN** an implementer reads the `## Code standards` section
- **THEN** the section references Step 0 for technology skill loading
- **AND** it does NOT contain the old "etc." list or duplicated vague instructions
