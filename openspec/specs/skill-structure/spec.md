# Spec: Skill Structure Compliance

Change: skill-compliance-fixes
Date: 2026-03-03

## Requirements

### Requirement: smart-commit Triggers Marker Presence

`skills/smart-commit/SKILL.md` MUST contain a `**Triggers**` bold-marker line that satisfies the section detection rule used by `claude-folder-audit` P2-C and `project-audit` D4b.

The detection rule (from `ai-context/architecture.md`) is: "A section is present when at least one line STARTS with `## <section-name>`. Bold-trigger pattern (`**Triggers**`) is also a valid match for the Triggers section specifically."

#### Scenario: Audit tool detects Triggers section in smart-commit
- **GIVEN** that `skills/smart-commit/SKILL.md` has been updated with the compliance fix applied
- **WHEN** `claude-folder-audit` (P2-C) or `project-audit` (D4b) scans the file for the Triggers section
- **THEN** the scanner finds a line that starts with `**Triggers**`
- **AND** the Triggers check is reported as PASS (no finding raised for missing Triggers)

#### Scenario: Existing functional content is preserved
- **GIVEN** the updated `skills/smart-commit/SKILL.md`
- **WHEN** the file is read by an agent executing a commit
- **THEN** all existing process steps (Step 1 through Step 5), Anti-Patterns, Quick Reference, and Rules sections are present and unchanged
- **AND** the `## When to Use` section (or equivalent) is retained or its content is preserved within or below the Triggers marker

#### Scenario: Format contract is fully satisfied post-fix
- **GIVEN** the updated `skills/smart-commit/SKILL.md`
- **WHEN** a format contract check is run against the file (procedural format)
- **THEN** all three required elements are found: `**Triggers**` marker, `## Process` (or `### Step N`), and `## Rules`
- **AND** no MEDIUM or HIGH compliance finding is raised for this file

---

### Requirement: project-analyze Step 6 Merge Mechanism Specification

`skills/project-analyze/SKILL.md` Step 6 MUST explicitly name the tool sequence used to execute the `[auto-updated]` section merge algorithm so that any agent executing the skill applies the same mechanism.

#### Scenario: Agent reads Step 6 and identifies the correct tools
- **GIVEN** that `skills/project-analyze/SKILL.md` Step 6 has been updated with the tool specification
- **WHEN** an agent reads Step 6 to understand how to apply the merge algorithm
- **THEN** the agent finds an explicit statement naming "Read tool" and "Write tool" as the mechanism
- **AND** the statement confirms that Bash and the Edit tool are NOT used for this merge

#### Scenario: Merge produces no corruption of human-written sections
- **GIVEN** a target `ai-context/` file containing both human-written and `[auto-updated]` sections
- **WHEN** an agent executes Step 6 following the tool specification
- **THEN** content outside `<!-- [auto-updated]: ... -->` and `<!-- [/auto-updated] -->` markers is preserved byte-for-byte
- **AND** only the content between the matching markers is replaced

#### Scenario: Tool specification does not alter existing merge algorithm logic
- **GIVEN** the updated Step 6 text
- **WHEN** compared side-by-side with the pre-fix version
- **THEN** the pseudocode merge algorithm (READ, PARSE, FOR each block, REPLACE/APPEND, WRITE) is unchanged
- **AND** only the tool-identification sentence has been added

---

### Requirement: config-export Step 3 Transformation Mechanism Specification

`skills/config-export/SKILL.md` Step 3 MUST explicitly state that the transformation prompts embedded in the step are self-instructions executed by the agent using its own in-context LLM reasoning, with no external API calls or subprocess invocations required.

#### Scenario: Agent reads Step 3 and applies transformation without confusion
- **GIVEN** that `skills/config-export/SKILL.md` Step 3 has been updated with the mechanism statement
- **WHEN** an agent reads Step 3 to understand how to apply the Copilot, Gemini, or Cursor transformation prompts
- **THEN** the agent finds a sentence explicitly stating that the prompt is a self-instruction to the executing agent
- **AND** the agent understands that no external API call, subprocess, or additional tool invocation is needed

#### Scenario: Mechanism statement appears before the first transformation prompt block
- **GIVEN** the updated Step 3 text
- **WHEN** read top-to-bottom
- **THEN** the mechanism statement appears BEFORE the first transformation prompt (Copilot prompt block)
- **AND** it applies equally to all three transformation prompts (Copilot, Gemini, Cursor)

#### Scenario: Existing transformation prompt content is unchanged
- **GIVEN** the updated Step 3 text
- **WHEN** each transformation prompt block (Copilot, Gemini, Cursor) is compared to the pre-fix version
- **THEN** all STRIP, RETAIN, ADAPT, and FORMAT instructions in each prompt are identical
- **AND** only the mechanism statement has been added

---

### Requirement: No Regression in Functional Behavior

All three modified SKILL.md files MUST retain their full functional behavior after the compliance fixes are applied.

#### Scenario: smart-commit behaves identically before and after fix
- **GIVEN** a git repository with staged and unstaged changes
- **WHEN** the updated `skills/smart-commit/SKILL.md` is executed
- **THEN** all grouping, issue detection, message generation, and commit execution steps behave identically to the pre-fix version

#### Scenario: project-analyze produces identical output before and after fix
- **GIVEN** a project with source files and an existing `ai-context/` directory
- **WHEN** the updated `skills/project-analyze/SKILL.md` is executed
- **THEN** `analysis-report.md` and all updated `ai-context/` sections are identical in content and structure to what the pre-fix version would produce

#### Scenario: config-export produces identical output before and after fix
- **GIVEN** a project with `CLAUDE.md` and `ai-context/` files
- **WHEN** the updated `skills/config-export/SKILL.md` is executed for any target (copilot, gemini, cursor)
- **THEN** the generated output files are identical in content to what the pre-fix version would produce
