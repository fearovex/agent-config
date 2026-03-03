# Delta Spec: folder-audit-reporting

Change: claude-folder-audit-project-mode
Date: 2026-03-03
Base: openspec/specs/folder-audit-reporting/spec.md

## MODIFIED — Modified requirements

### Requirement: report MUST be written to a mode-specific, predictable location
*(Before: report was always written to `~/.claude/claude-folder-audit-report.md` regardless of mode)*

In `global-config` and `global` modes the report path MUST remain `~/.claude/claude-folder-audit-report.md`
(unchanged from the base spec). In `project` mode the report MUST be written to
`.claude/claude-folder-audit-report.md` relative to CWD (i.e., inside the project's own
`.claude/` directory). The report MUST NOT be written to `~/.claude/` when in `project` mode.

#### Scenario: global-config and global modes — report path unchanged

- **GIVEN** execution mode is `global-config` or `global`
- **WHEN** the skill writes its output
- **THEN** the file `~/.claude/claude-folder-audit-report.md` is created or overwritten
- **AND** no report file is written to any project `.claude/` directory

#### Scenario: project mode — report written to .claude/ inside the project

- **GIVEN** execution mode is `project`
- **AND** the project root is `<cwd>`
- **WHEN** the skill writes its output
- **THEN** the file `<cwd>/.claude/claude-folder-audit-report.md` is created or overwritten
- **AND** no report file is written to `~/.claude/`
- **AND** the skill emits a message: "Report written to: <cwd>/.claude/claude-folder-audit-report.md"

#### Scenario: project mode — .claude/ directory exists (guaranteed by mode detection)

- **GIVEN** execution mode is `project`
- **AND** mode detection already confirmed `.claude/` exists at CWD (precondition for project mode)
- **WHEN** the skill writes the report
- **THEN** the write succeeds without needing to create the `.claude/` directory
- **AND** a pre-existing `claude-folder-audit-report.md` from a previous run is overwritten

---

### Requirement: report header MUST reflect project mode metadata
*(Before: header declared `Mode:` as either `global-config` or `global` only)*

In `project` mode, the report header MUST contain all mandatory fields updated to
reflect the project context.

#### Scenario: project mode header block is present and complete

- **GIVEN** execution mode is `project`
- **AND** the skill completes all 5 project checks (P1–P5) without aborting
- **WHEN** the report is read
- **THEN** the report begins with a header block containing:
  - `Run date:` in ISO 8601 format
  - `Mode: project`
  - `Project root:` — the expanded absolute path to CWD
  - `Project .claude/ dir:` — the expanded absolute path to `<cwd>/.claude/`
  - `Global runtime:` — the expanded absolute path to `~/.claude/` (shown for P2/P5 reference)
  - `Summary:` — e.g., "1 HIGH, 2 MEDIUM, 0 LOW, 3 INFO"

#### Scenario: project mode header does not include Source root field

- **GIVEN** execution mode is `project`
- **WHEN** the report header is read
- **THEN** the header does NOT contain a `Source root:` field (that field is specific to global-config mode)
- **AND** the header DOES contain `Project root:` and `Project .claude/ dir:` fields instead

---

## ADDED — New requirements

### Requirement: project mode report MUST use project-specific check section labels

The per-check sections in the report MUST use project-mode labels (P1–P5) to distinguish
them from the global-mode check labels (Check 1–Check 5).

#### Scenario: project mode report uses P1–P5 section headers

- **GIVEN** execution mode is `project`
- **AND** the skill has completed all checks
- **WHEN** the report is read
- **THEN** the per-check sections are labeled:
  - `## Check P1 — CLAUDE.md Presence and Skills Registry`
  - `## Check P2 — Global Skill Registrations Reachability`
  - `## Check P3 — Local Skill Registrations Reachability`
  - `## Check P4 — Orphaned Local Skills`
  - `## Check P5 — Scope Tier Overlap`
- **AND** no section uses the global-mode labels `Check 1` through `Check 5`

#### Scenario: each project-mode check section appears even when it has no findings

- **GIVEN** execution mode is `project`
- **AND** Check Pn produces zero findings of any severity
- **WHEN** the report is written
- **THEN** the section for Check Pn still appears with the text "No findings"

---

### Requirement: project mode Findings Summary table MUST reference project-specific remediation actions

In `project` mode, the Findings Summary table MUST be present and MUST reference
project-specific remediation actions rather than global `install.sh` instructions.

#### Scenario: Findings Summary table uses project-appropriate remediation hints

- **GIVEN** execution mode is `project`
- **AND** one or more HIGH or MEDIUM findings are present
- **WHEN** the report's "## Findings Summary" table is read
- **THEN** remediation hints in the table reference project-local actions (e.g.,
  "Create the skill file at .claude/skills/<name>/SKILL.md", "Add entry to .claude/CLAUDE.md Skills Registry")
- **AND** the hint "Run install.sh from the claude-config repo" MUST NOT appear as a primary action for
  findings that are about project-local configuration (P3, P4)
- **AND** for P2 findings (global skill not deployed), the hint "Run install.sh from the claude-config repo"
  IS appropriate and MUST appear

---

### Requirement: project mode Recommended Next Steps MUST be project-context-aware

In `project` mode, the "## Recommended Next Steps" section MUST provide actions
relevant to fixing the project's Claude configuration, not the global runtime.

#### Scenario: P1 HIGH finding — first recommended step is to fix .claude/CLAUDE.md

- **GIVEN** execution mode is `project`
- **AND** Check P1 produced a HIGH finding (CLAUDE.md absent or missing Skills Registry)
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the first item is: "1. Create or update .claude/CLAUDE.md — ensure it contains a ## Skills Registry section with all skill paths"

#### Scenario: P2 HIGH finding — first recommended step is to run install.sh

- **GIVEN** execution mode is `project`
- **AND** Check P2 produced a HIGH finding (global skill not deployed)
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the recommended step references: "Run install.sh from the claude-config repo to deploy missing global skills"

#### Scenario: P3 or P4 findings — recommended step targets the project .claude/ directory

- **GIVEN** execution mode is `project`
- **AND** Check P3 or P4 produced HIGH or MEDIUM findings
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the recommended steps reference the `.claude/skills/` directory within the project
- **AND** the steps do NOT reference `~/.claude/` as the fix location

#### Scenario: no HIGH or MEDIUM findings in project mode — healthy state confirmed

- **GIVEN** execution mode is `project`
- **AND** the report contains zero HIGH findings and zero MEDIUM findings
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the section contains: "Project Claude configuration appears healthy — no required actions detected"
- **AND** any LOW or INFO findings are listed as optional review items below

---

### Requirement: project mode report MUST NOT be committed to the project repository

The report file `.claude/claude-folder-audit-report.md` is a runtime audit artifact.
It MUST NOT be committed to the project's version control. The skill MUST note in the
report footer that this file should be excluded from git.

#### Scenario: report footer includes a git-exclusion reminder

- **GIVEN** execution mode is `project`
- **AND** the report has been written to `.claude/claude-folder-audit-report.md`
- **WHEN** the report's footer is read
- **THEN** it includes a note: "This file is a runtime artifact. Add .claude/claude-folder-audit-report.md to .gitignore to prevent accidental commits."
- **AND** this note is the last content in the report

#### Scenario: skill does not modify .gitignore itself

- **GIVEN** execution mode is `project`
- **AND** the project's `.gitignore` does not already exclude `.claude/claude-folder-audit-report.md`
- **WHEN** the skill completes execution
- **THEN** the skill does NOT modify `.gitignore` — it remains strictly read-only except for the report output
- **AND** the report footer note (above) is the extent of the skill's guidance on this matter

---

## Rules (additions)

- In `project` mode, the report MUST be written to `<cwd>/.claude/claude-folder-audit-report.md` — never to `~/.claude/`
- The report file path MUST always be shown to the user at the end of execution (expanded absolute path)
- The report MUST be overwritten (not appended) on every run, in all modes
- The report MUST remain valid Markdown in all modes; bold severity labels (`**HIGH**`, `**MEDIUM**`, `**LOW**`, `**INFO**`) apply in project mode as in global mode
- The `.claude/` directory is guaranteed to exist when project mode is active (mode detection precondition); the skill MUST NOT attempt to create it
