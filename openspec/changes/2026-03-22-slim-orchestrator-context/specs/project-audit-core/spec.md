# Delta Spec: Project Audit Core

Change: 2026-03-22-slim-orchestrator-context
Date: 2026-03-22
Base: openspec/specs/project-audit-core/spec.md

## ADDED — New requirements

### Requirement: project-audit MUST include a budget compliance check for CLAUDE.md character counts

The `project-audit` skill MUST include a check that measures the character count of CLAUDE.md files and compares them against defined budgets. This check is an informational dimension — it produces warnings, not score deductions.

#### Scenario: Global CLAUDE.md within budget — no warning

- **GIVEN** the project has a global CLAUDE.md (at repo root or `~/.claude/CLAUDE.md`)
- **AND** the file is at most 20,000 characters
- **WHEN** project-audit runs the budget compliance check
- **THEN** the check MUST report the character count
- **AND** the check MUST NOT produce a warning
- **AND** the report line MUST show the count and the budget (e.g., "Global CLAUDE.md: 18,432 / 20,000 chars")

#### Scenario: Global CLAUDE.md exceeds budget — warning emitted

- **GIVEN** the project has a global CLAUDE.md that exceeds 20,000 characters
- **WHEN** project-audit runs the budget compliance check
- **THEN** the check MUST produce a WARNING finding
- **AND** the finding MUST state the current character count and the 20,000 character budget
- **AND** the finding MUST recommend extracting content to a skill or requesting a budget exception via ADR

#### Scenario: Project CLAUDE.md within budget — no warning

- **GIVEN** the project has a project-level CLAUDE.md (at project root or `.claude/CLAUDE.md`)
- **AND** the file is at most 5,000 characters
- **WHEN** project-audit runs the budget compliance check
- **THEN** the check MUST report the character count
- **AND** the check MUST NOT produce a warning

#### Scenario: Project CLAUDE.md exceeds budget — warning emitted

- **GIVEN** the project has a project-level CLAUDE.md that exceeds 5,000 characters
- **WHEN** project-audit runs the budget compliance check
- **THEN** the check MUST produce a WARNING finding
- **AND** the finding MUST state the current character count and the 5,000 character budget

#### Scenario: Budget check applies only when budget governance is active

- **GIVEN** a project does NOT have `openspec/` directory (not an SDD-managed project)
- **WHEN** project-audit runs
- **THEN** the budget compliance check MAY be skipped
- **AND** skipping MUST NOT produce an error or a score deduction

#### Scenario: Budget check is informational — does not affect the audit score

- **GIVEN** the budget compliance check detects an over-budget CLAUDE.md
- **WHEN** the audit score is calculated
- **THEN** the over-budget finding MUST NOT deduct points from the 100-point audit score
- **AND** the finding MUST appear in the report as an informational warning, not a scored dimension

#### Scenario: Combined context budget check

- **GIVEN** both global and project CLAUDE.md files exist
- **WHEN** project-audit runs the budget compliance check
- **THEN** the check MUST also compute the combined character count (global + project)
- **AND** if the combined count exceeds 25,000 characters, a WARNING MUST be emitted
- **AND** the warning MUST state both individual counts and the combined total

---

### Requirement: Budget compliance check MUST distinguish global vs. project CLAUDE.md

The budget check MUST correctly identify which CLAUDE.md is the global file and which is the project file, even when both exist in the same filesystem context.

#### Scenario: Agent-config repo has both files pointing to same source

- **GIVEN** the project is the agent-config repo itself (where the repo root CLAUDE.md IS the global source deployed via install.sh)
- **WHEN** project-audit runs the budget check
- **THEN** it MUST treat the repo root CLAUDE.md as the global file
- **AND** it MUST apply the 20,000 character budget (not the 5,000 project budget)
- **AND** it SHOULD note that in this repo the global and project files are the same source

#### Scenario: Standard project has distinct global and project files

- **GIVEN** a standard project with `~/.claude/CLAUDE.md` (global) and a project-level `.claude/CLAUDE.md` or root `CLAUDE.md`
- **WHEN** project-audit runs the budget check
- **THEN** it MUST check the project-level file against the 5,000 character budget
- **AND** it MUST NOT check the global file (which is outside the project scope)
- **AND** it MAY note the global file's character count as informational context
