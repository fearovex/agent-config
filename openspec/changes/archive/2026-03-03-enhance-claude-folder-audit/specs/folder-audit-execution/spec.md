# Delta Spec: folder-audit-execution

Change: enhance-claude-folder-audit
Date: 2026-03-03
Base: openspec/specs/folder-audit-execution/spec.md

---

## ADDED — New requirements

---

### Requirement: Check P1 MUST additionally validate CLAUDE.md content quality

After confirming `.claude/CLAUDE.md` exists and has a Skills Registry section (existing P1
requirement), the skill MUST read the file's content and perform sub-checks for mandatory
sections, minimum content length, and SDD command references. These sub-checks extend P1
and use the same check section in the report.

**Section detection rule**: a section is present when at least one line in the file starts
with `## <section-name>` (top-level markdown heading). This rule applies across all
content-quality checks in P1, P2, P3, P6, P7, and P8. Lines inside fenced code blocks
(```` ``` ````) are NOT considered section headers for this purpose.

#### Scenario: CLAUDE.md contains all mandatory sections — no finding from P1 sub-checks

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` is present and passes the existing P1 existence and Skills Registry check
- **AND** the file contains lines starting with `## Tech Stack`, `## Architecture`, `## Unbreakable Rules`, `## Plan Mode Rules`, and `## Skills Registry` (or `## Stack` as an accepted alias for `## Tech Stack`)
- **AND** the file has more than 50 lines
- **AND** the file contains at least one of `/sdd-ff` or `/sdd-new` anywhere in its content
- **WHEN** Check P1 runs
- **THEN** no finding is recorded from the content sub-checks
- **AND** the P1 section in the report notes all mandatory sections are present

#### Scenario: CLAUDE.md is missing a mandatory section — MEDIUM finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` exists and has a Skills Registry section
- **AND** one or more of the following section headings are absent: `## Tech Stack` (or `## Stack`), `## Architecture`, `## Unbreakable Rules`, `## Plan Mode Rules`
- **WHEN** Check P1 runs
- **THEN** a MEDIUM finding is recorded for each missing section: "CLAUDE.md is missing mandatory section: <section-name>"
- **AND** the remediation hint reads: "Add the missing section to .claude/CLAUDE.md — refer to the global CLAUDE.md in the claude-config repo as a template"

#### Scenario: CLAUDE.md has fewer than 30 lines — MEDIUM finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` exists
- **AND** the total line count of the file is fewer than 30
- **WHEN** Check P1 runs
- **THEN** a MEDIUM finding is recorded: "CLAUDE.md appears too short (<30 lines) — may be a stub or placeholder"
- **AND** the remediation hint reads: "Populate .claude/CLAUDE.md with at minimum a ## Tech Stack, ## Architecture, ## Unbreakable Rules, ## Plan Mode Rules, and ## Skills Registry section"

#### Scenario: CLAUDE.md has between 30 and 50 lines — LOW finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` exists
- **AND** the total line count is between 30 and 50 (inclusive)
- **WHEN** Check P1 runs
- **THEN** a LOW finding is recorded: "CLAUDE.md is short (30–50 lines) — may not contain enough context"
- **AND** the remediation hint reads: "Consider expanding .claude/CLAUDE.md with richer context — aim for >50 lines"

#### Scenario: CLAUDE.md has no SDD command references — LOW finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` exists
- **AND** the file contains neither `/sdd-ff` nor `/sdd-new` anywhere in its content
- **WHEN** Check P1 runs
- **THEN** a LOW finding is recorded: "CLAUDE.md has no SDD command references (/sdd-ff, /sdd-new) — SDD workflow may not be configured"
- **AND** the remediation hint reads: "Add SDD commands to the Available Commands section; consult the global CLAUDE.md for the standard SDD command table"

#### Scenario: Skills Registry section exists but contains no skill path entries — LOW finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` contains a `## Skills Registry` heading
- **AND** no line in the file matches `~/.claude/skills/` or `.claude/skills/` path patterns
- **WHEN** Check P1 runs
- **THEN** a LOW finding is recorded: "CLAUDE.md has a ## Skills Registry section but contains no skill path entries"
- **AND** the remediation hint reads: "Register skills by adding path entries under ## Skills Registry — use ~/.claude/skills/<name>/SKILL.md for global skills or .claude/skills/<name>/SKILL.md for local ones"

---

### Requirement: Check P2 and P3 MUST additionally validate SKILL.md frontmatter and section contracts

After confirming a SKILL.md exists (existing P2/P3 reachability requirement), the skill MUST read each SKILL.md file and apply two-stage content quality sub-checks:

- **Stage 1 — Frontmatter**: verify YAML frontmatter block is present, `name:` field is present, and `format:` field is present with a valid value.
- **Stage 2 — Section contract**: based on the detected (or defaulted) `format:` value, verify that all required sections are present using the section detection rule.

Section contracts (authoritative source: `docs/format-types.md`):
- `procedural` (or absent format): requires `**Triggers**` or `## Triggers`, `## Process` or at least one `### Step N` heading, and `## Rules`
- `reference`: requires `**Triggers**` or `## Triggers`, `## Patterns` or `## Examples`, and `## Rules`
- `anti-pattern`: requires `**Triggers**` or `## Triggers`, `## Anti-patterns`, and `## Rules`

These sub-checks apply to all SKILL.md files verified during P2 (global-path registrations) and P3 (local-path registrations). P4 orphan detection does NOT trigger these sub-checks — orphaned skills are structural findings, not content findings.

#### Scenario: SKILL.md has valid frontmatter and all required sections — no finding from sub-checks

- **GIVEN** execution mode is `project`
- **AND** a SKILL.md file passes the existing P2 or P3 reachability check
- **AND** the file begins with a `---` YAML frontmatter block
- **AND** the frontmatter contains a `name:` field and a `format:` field with value `procedural`, `reference`, or `anti-pattern`
- **AND** the file contains all required sections for the declared format type
- **WHEN** Checks P2/P3 run the content sub-checks
- **THEN** no finding is recorded from the content sub-checks for this SKILL.md

#### Scenario: SKILL.md has no YAML frontmatter block — MEDIUM finding

- **GIVEN** execution mode is `project`
- **AND** a SKILL.md file passes the P2 or P3 reachability check
- **AND** the file does NOT begin with a `---` line
- **WHEN** Checks P2/P3 run the content sub-checks
- **THEN** a MEDIUM finding is recorded: "SKILL.md for skill '<name>' is missing YAML frontmatter — the file must begin with a '---' block"
- **AND** the remediation hint reads: "Add a YAML frontmatter block (---) with at minimum name:, description:, and format: fields"
- **AND** subsequent frontmatter and section contract sub-checks for this SKILL.md are skipped

#### Scenario: SKILL.md frontmatter is missing the format: field — LOW finding

- **GIVEN** execution mode is `project`
- **AND** a SKILL.md file has a valid frontmatter block
- **AND** the frontmatter does NOT contain a `format:` field
- **WHEN** Checks P2/P3 run the content sub-checks
- **THEN** a LOW finding is recorded: "SKILL.md for skill '<name>' has no 'format:' field in frontmatter — defaulting to 'procedural'"
- **AND** the remediation hint reads: "Add 'format: procedural' (or 'reference' or 'anti-pattern') to the SKILL.md frontmatter"
- **AND** the section contract check proceeds using `procedural` as the default format

#### Scenario: SKILL.md frontmatter has an unrecognized format: value — LOW finding

- **GIVEN** execution mode is `project`
- **AND** a SKILL.md file has a valid frontmatter block
- **AND** the frontmatter contains a `format:` field with a value other than `procedural`, `reference`, or `anti-pattern`
- **WHEN** Checks P2/P3 run the content sub-checks
- **THEN** a LOW finding is recorded: "SKILL.md for skill '<name>' has unrecognized format value '<value>' — defaulting to 'procedural'"
- **AND** the remediation hint reads: "Valid format values are: procedural, reference, anti-pattern"
- **AND** the section contract check proceeds using `procedural` as the default format

#### Scenario: procedural SKILL.md is missing a required section — MEDIUM finding

- **GIVEN** execution mode is `project`
- **AND** a SKILL.md has `format: procedural` (or defaulted to procedural)
- **AND** one or more of `**Triggers**`/`## Triggers`, `## Process`/`### Step N`, `## Rules` are absent
- **WHEN** Checks P2/P3 run the section contract sub-check
- **THEN** a MEDIUM finding is recorded for each missing required element: "SKILL.md for skill '<name>' (procedural) is missing required section: <section>"
- **AND** the remediation hint reads: "Add the missing section to the SKILL.md — procedural format requires: **Triggers**, ## Process (or ### Step N steps), and ## Rules"

#### Scenario: reference SKILL.md is missing a required section — MEDIUM finding

- **GIVEN** execution mode is `project`
- **AND** a SKILL.md has `format: reference`
- **AND** one or more of `**Triggers**`/`## Triggers`, `## Patterns`/`## Examples`, `## Rules` are absent
- **WHEN** Checks P2/P3 run the section contract sub-check
- **THEN** a MEDIUM finding is recorded for each missing required element: "SKILL.md for skill '<name>' (reference) is missing required section: <section>"
- **AND** the remediation hint reads: "Add the missing section to the SKILL.md — reference format requires: **Triggers**, ## Patterns or ## Examples, and ## Rules"

#### Scenario: anti-pattern SKILL.md is missing a required section — MEDIUM finding

- **GIVEN** execution mode is `project`
- **AND** a SKILL.md has `format: anti-pattern`
- **AND** one or more of `**Triggers**`/`## Triggers`, `## Anti-patterns`, `## Rules` are absent
- **WHEN** Checks P2/P3 run the section contract sub-check
- **THEN** a MEDIUM finding is recorded for each missing required element: "SKILL.md for skill '<name>' (anti-pattern) is missing required section: <section>"
- **AND** the remediation hint reads: "Add the missing section to the SKILL.md — anti-pattern format requires: **Triggers**, ## Anti-patterns, and ## Rules"

#### Scenario: SKILL.md body (post-frontmatter) has fewer than 30 lines — LOW finding

- **GIVEN** execution mode is `project`
- **AND** a SKILL.md file passes the P2 or P3 reachability check
- **AND** after stripping the frontmatter block, the remaining lines number fewer than 30
- **WHEN** Checks P2/P3 run the content sub-checks
- **THEN** a LOW finding is recorded: "SKILL.md for skill '<name>' has very short body (<30 lines post-frontmatter) — may be a stub"
- **AND** the remediation hint reads: "Review and populate this SKILL.md — stubs should have a plan or be removed"

#### Scenario: SKILL.md body contains TODO: in a required section area — INFO note

- **GIVEN** execution mode is `project`
- **AND** a SKILL.md file contains one or more lines with `TODO:` anywhere in the file content
- **WHEN** Checks P2/P3 run the content sub-checks
- **THEN** an INFO note is recorded: "SKILL.md for skill '<name>' contains TODO: markers — may be a work-in-progress"

---

### Requirement: Check P6 MUST verify the ai-context/ memory layer in project mode

The skill MUST check for the presence of the `ai-context/` directory and its five required
core files in project mode. If the directory is absent, a MEDIUM finding is recorded.
If the directory is present but missing core files, a LOW finding is recorded per missing file.

Required core files: `stack.md`, `architecture.md`, `conventions.md`, `known-issues.md`, `changelog-ai.md`.

#### Scenario: ai-context/ directory is absent entirely — MEDIUM finding

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/` does NOT exist
- **WHEN** Check P6 runs
- **THEN** a MEDIUM finding is recorded: "ai-context/ directory not found — project memory layer is absent"
- **AND** the remediation hint reads: "Run /memory-init to generate the ai-context/ layer for this project"
- **AND** the five core-file checks are skipped (the directory does not exist)

#### Scenario: ai-context/ exists and all five core files are present — no finding

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/` exists
- **AND** all five files `stack.md`, `architecture.md`, `conventions.md`, `known-issues.md`, `changelog-ai.md` exist under `<cwd>/ai-context/`
- **WHEN** Check P6 runs
- **THEN** no finding is recorded for this check

#### Scenario: ai-context/ exists but one or more core files are missing — LOW finding per missing file

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/` exists
- **AND** one or more of the five required core files are not present
- **WHEN** Check P6 runs
- **THEN** a LOW finding is recorded for each missing file: "ai-context/<filename> is missing"
- **AND** the remediation hint reads: "Run /memory-init or manually create ai-context/<filename> to restore the project memory layer"

#### Scenario: a core ai-context/ file has fewer than 10 lines — INFO note

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/<filename>` exists
- **AND** the file has fewer than 10 lines of content
- **WHEN** Check P6 runs
- **THEN** an INFO note is recorded: "ai-context/<filename> is very short (<10 lines) — may not contain useful context"

---

### Requirement: Check P7 MUST verify the ai-context/features/ layer in project mode (ADR-015 V2)

The skill MUST check for the presence of `ai-context/features/` and the quality of any
non-template feature files found within it. The `_template.md` file and any file whose
name starts with an underscore MUST be excluded from all quality checks.

Required sections per feature file (authoritative source: `ai-context/features/_template.md`):
1. `## Domain Overview`
2. `## Business Rules and Invariants`
3. `## Data Model Summary`
4. `## Integration Points`
5. `## Decision Log`
6. `## Known Gotchas`

P7 is advisory — feature files are voluntarily authored. Absence of `ai-context/features/` is
an INFO observation, not a MEDIUM finding. Per ADR-015 non-blocking design intent, this
check MUST NOT produce findings above LOW severity.

#### Scenario: ai-context/features/ directory is absent — INFO note

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/features/` does NOT exist
- **WHEN** Check P7 runs
- **THEN** an INFO note is recorded: "ai-context/features/ not found — feature-domain knowledge layer not initialized for this project"
- **AND** no LOW or higher finding is recorded

#### Scenario: ai-context/features/ exists but contains only the template file — INFO note

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/features/` exists
- **AND** the only file present is `_template.md` (or all files start with `_`)
- **WHEN** Check P7 runs
- **THEN** an INFO note is recorded: "ai-context/features/ contains only the template file — no feature domain knowledge files authored yet"
- **AND** no LOW or higher finding is recorded

#### Scenario: a non-template feature file contains all six required sections — no finding

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/features/<name>.md` exists and does not start with `_`
- **AND** the file contains lines starting with `## Domain Overview`, `## Business Rules and Invariants`, `## Data Model Summary`, `## Integration Points`, `## Decision Log`, and `## Known Gotchas`
- **WHEN** Check P7 runs
- **THEN** no finding is recorded for this feature file

#### Scenario: a non-template feature file is missing one or more required sections — LOW finding

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/features/<name>.md` exists and does not start with `_`
- **AND** one or more of the six required sections are absent
- **WHEN** Check P7 runs
- **THEN** a LOW finding is recorded for each missing section: "Feature file 'ai-context/features/<name>.md' is missing section: <section-name>"
- **AND** the remediation hint reads: "Add the missing section to the feature file — refer to ai-context/features/_template.md for the required structure"

#### Scenario: a non-template feature file has fewer than 30 lines — INFO note

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/features/<name>.md` exists and does not start with `_`
- **AND** the file has fewer than 30 lines
- **WHEN** Check P7 runs
- **THEN** an INFO note is recorded: "Feature file 'ai-context/features/<name>.md' is very short (<30 lines) — likely a stub not yet populated"

#### Scenario: _template.md is present — INFO note confirming template presence

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/ai-context/features/_template.md` exists
- **WHEN** Check P7 runs
- **THEN** an INFO note is recorded: "ai-context/features/_template.md is present"
- **AND** the template file is NOT subjected to section quality checks

---

### Requirement: Check P8 MUST enumerate the .claude/ folder for unexpected items

The skill MUST list all items (files and directories) directly under `<cwd>/.claude/` and
compare them against the known expected set. Any item not in the expected set MUST be
flagged as MEDIUM. The `hooks/` directory, if present, must have non-empty script files.

Known expected items in `.claude/`:
`CLAUDE.md`, `skills/`, `audit-report.md`, `claude-folder-audit-report.md`,
`settings.json`, `settings.local.json`, `openspec/`, `ai-context/`, `hooks/`

#### Scenario: .claude/ contains only expected items — no finding

- **GIVEN** execution mode is `project`
- **AND** every item directly under `<cwd>/.claude/` is in the known expected set
- **WHEN** Check P8 runs
- **THEN** no finding is recorded
- **AND** the P8 section in the report notes the inventory count: "N item(s) found, all expected"

#### Scenario: .claude/ contains an item not in the expected set — MEDIUM finding

- **GIVEN** execution mode is `project`
- **AND** a file or directory exists directly under `<cwd>/.claude/` whose name does NOT appear in the known expected set
- **WHEN** Check P8 runs
- **THEN** a MEDIUM finding is recorded for each unexpected item: "Unexpected item in .claude/: '<name>' — possible manual edit or stale artifact"
- **AND** the remediation hint reads: "Review the item manually; if it should not be there, remove it; if it is intentional, consider documenting it in .claude/CLAUDE.md"

#### Scenario: hooks/ directory is present but contains empty script files — LOW finding

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/.claude/hooks/` exists
- **AND** one or more `.js` or `.sh` files within it have zero bytes (empty content)
- **WHEN** Check P8 runs
- **THEN** a LOW finding is recorded for each empty hook file: "Hook script '.claude/hooks/<filename>' is empty — likely a placeholder"
- **AND** the remediation hint reads: "Populate the hook script with valid logic or remove it if not needed"

#### Scenario: hooks/ directory is present with non-empty scripts — no finding from hooks sub-check

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/.claude/hooks/` exists
- **AND** all `.js` and `.sh` files within it are non-empty
- **WHEN** Check P8 runs
- **THEN** no finding is recorded from the hooks sub-check

#### Scenario: hooks/ directory is absent — no finding from hooks sub-check

- **GIVEN** execution mode is `project`
- **AND** `<cwd>/.claude/hooks/` does NOT exist
- **WHEN** Check P8 runs
- **THEN** no finding is recorded for the hooks sub-check
- **AND** an INFO note is recorded: "No hooks/ directory found in .claude/ — hook execution is not configured for this project"

---

### Requirement: all project-mode checks MUST continue to run even if P1 content sub-checks fail

All 8 project-mode checks (P1 through P8) MUST run to completion regardless of findings
from earlier checks. The existing behavior — P2/P3 record an INFO skip note when CLAUDE.md
is absent — is preserved and is the ONLY exception to this rule.

#### Scenario: P1 MEDIUM content finding does not block P6, P7, P8

- **GIVEN** execution mode is `project`
- **AND** Check P1 records a MEDIUM finding (e.g., missing mandatory section in CLAUDE.md)
- **WHEN** all checks complete
- **THEN** Checks P6, P7, and P8 each still execute against the filesystem
- **AND** the report includes output sections for all 8 checks (P1 through P8)

---

## MODIFIED — Modified requirements

### Requirement: project mode — checks MUST all execute even when earlier checks find HIGH issues

*(Base: openspec/specs/folder-audit-execution/spec.md — Requirement: project mode — checks MUST all execute even when earlier checks find HIGH issues)*

Updated to cover 8 checks (P1 through P8) instead of 5 (P1 through P5).

#### Scenario: P1 produces HIGH but P4, P5, P6, P7, P8 still run *(modified)*

- **GIVEN** execution mode is `project`
- **AND** Check P1 records a HIGH finding (CLAUDE.md absent or missing Skills Registry)
- **WHEN** all checks complete
- **THEN** Checks P2 and P3 each record an INFO skip note
- **AND** Checks P4, P5, P6, P7, and P8 still execute against the filesystem
- **AND** the report includes output sections for all 8 checks (P1 through P8)

---

## REMOVED — Removed requirements

*(None — all existing requirements are preserved.)*
