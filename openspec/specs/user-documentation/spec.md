# Spec: user-documentation

Change: 2026-03-12-project-user-docs
Date: 2026-03-12

---

## Requirements

### Requirement: docs/user-guide.md created with all required sections

`docs/user-guide.md` MUST be created as a new file in the repository. The file MUST contain the following six top-level sections, in order:

1. What is agent-config?
2. Deployment model
3. Global configuration out-of-the-box
4. Project-level customization
5. Conflict resolution workflow
6. Quick-start checklist

The document MUST be between 250 and 400 lines (including blank lines and headings). It MUST use plain Markdown with standard headings, tables, and code blocks — no proprietary syntax.

#### Scenario: New file is created with all six sections

- **GIVEN** the change is applied
- **WHEN** `docs/user-guide.md` is opened
- **THEN** the file exists and is readable
- **AND** it contains headings for all six required sections
- **AND** the file length is between 250 and 400 lines

#### Scenario: File is absent before the change is applied

- **GIVEN** the change has not been applied yet
- **WHEN** `docs/user-guide.md` path is checked
- **THEN** the file does not exist in the repository

---

### Requirement: "What is agent-config?" section provides a human-readable introduction

The first section MUST describe the agent-config system in plain language accessible to someone unfamiliar with it. It MUST NOT assume the reader has read CLAUDE.md. It MUST cover:

- What the system is (a Claude Code configuration meta-system)
- The two main components: skill catalog and memory layer
- The purpose (reusable SDD-driven development workflow across projects)

#### Scenario: First-time reader can understand the system purpose

- **GIVEN** a user who has not read CLAUDE.md
- **WHEN** they read the "What is agent-config?" section
- **THEN** they understand that agent-config is a Claude Code configuration repository
- **AND** they understand that it provides reusable skills and project memory
- **AND** no jargon is used without a brief inline definition

#### Scenario: Section does not exceed one screen of text

- **GIVEN** the "What is agent-config?" section
- **WHEN** its line count is measured
- **THEN** it is no longer than 40 lines (readable without scrolling on a standard terminal)

---

### Requirement: Deployment model section explains install.sh and sync.sh

The deployment section MUST explain the two-script model:

- `install.sh`: copies the repo to `~/.claude/` (repo-authoritative, one-way deploy)
- `sync.sh`: captures `~/.claude/memory/` back to `repo/memory/` only (memory capture, not config deploy)

It MUST include a diagram or code block showing the repo → `~/.claude/` flow and the memory sync direction. It MUST explicitly state that `sync.sh` does NOT deploy skills or CLAUDE.md changes.

#### Scenario: Reader understands why sync.sh does not deploy their skill changes

- **GIVEN** a user who edited a skill in the repo and ran sync.sh
- **WHEN** they read the deployment section
- **THEN** they learn that sync.sh does not copy skills to ~/.claude/
- **AND** they learn that install.sh is the correct command for deploying config changes

#### Scenario: New-machine workflow is documented

- **GIVEN** a user setting up agent-config on a new machine
- **WHEN** they read the deployment section
- **THEN** they can find the exact commands: `git clone <repo> && bash install.sh`
- **AND** no additional steps are undocumented

#### Scenario: Deployment flow diagram is present

- **GIVEN** the deployment section
- **WHEN** it is read
- **THEN** a diagram or ASCII art block shows the direction of each script (repo → ~/.claude/ for install.sh, ~/.claude/memory/ → repo/memory/ for sync.sh)

---

### Requirement: Global/local precedence diagram and interaction rules are included

The "Project-level customization" section MUST include a precedence diagram showing skill resolution order:

1. `.claude/skills/` (project-local — highest priority)
2. `openspec/config.yaml` skill_overrides (explicit redirect)
3. `~/.claude/skills/` (global catalog — fallback)

It MUST contain one worked example demonstrating: a global skill being overridden by a project-local version, with realistic file paths and directory layout shown.

#### Scenario: Reader can identify which skill version will be used

- **GIVEN** a user whose project has a `.claude/skills/sdd-apply/SKILL.md`
- **WHEN** they read the precedence diagram
- **THEN** they understand that the project-local skill takes priority over the global catalog
- **AND** the diagram explicitly shows three tiers in priority order

#### Scenario: Worked example uses realistic paths

- **GIVEN** the worked example in the project customization section
- **WHEN** it is read
- **THEN** it shows a concrete directory tree or set of paths illustrating override behavior
- **AND** the example is self-contained (does not require the reader to look up another document)

---

### Requirement: Conflict resolution workflow includes step-by-step guide

The "Conflict resolution" section MUST provide a step-by-step workflow for resolving configuration conflicts. The workflow MUST reference:

1. `/project-audit` — detect issues (produces audit-report.md)
2. `/project-fix` — apply corrections from audit-report.md
3. `/project-update` — sync CLAUDE.md and stack.md with global catalog

It MUST include a realistic scenario: a user whose project audit fails due to a missing skill entry, showing the audit output snippet and the fix command.

#### Scenario: User can follow the conflict resolution workflow without prior knowledge

- **GIVEN** a user whose project audit report shows a missing skill entry
- **WHEN** they read the conflict resolution section
- **THEN** they can identify the three-step workflow (audit → fix → update)
- **AND** they know which command to run at each step
- **AND** they can recognize a realistic audit-report.md snippet indicating the issue

#### Scenario: Realistic scenario output is present

- **GIVEN** the conflict resolution section
- **WHEN** it is read
- **THEN** it contains an example audit-report.md snippet or simulated command output
- **AND** the snippet shows at least one failing criterion and the resolution command

---

### Requirement: Command reference table covers at least 15 key commands

The guide MUST include a human-readable command reference table. The table MUST:

- List at least 15 commands with one-line human-readable descriptions
- Group commands by category (e.g., Meta-tools, SDD Phases)
- Use plain language (not copy-paste from CLAUDE.md technical descriptions)
- NOT reproduce the full CLAUDE.md command list verbatim

#### Scenario: Reader can find the right command without reading CLAUDE.md

- **GIVEN** a user who wants to start a new SDD change but doesn't know the command
- **WHEN** they read the command reference table
- **THEN** they find `/sdd-ff` or `/sdd-new` listed with a plain-language description
- **AND** the table is scannable (grouped, ≤ 3 columns)

#### Scenario: Table contains at least 15 entries

- **GIVEN** the command reference table
- **WHEN** its rows are counted (excluding header and group separator rows)
- **THEN** the count is at least 15 distinct commands

---

### Requirement: Quick-start checklist covers three scenarios

The "Quick-start checklist" section MUST contain three checklists:

1. New machine setup (clone, install, verify)
2. First SDD cycle (propose → spec+design → tasks → apply → verify → archive)
3. Deploying a config change (edit repo → install.sh → git commit)

Each checklist MUST be formatted as a Markdown task list (`- [ ]`). Each item MUST be an actionable step (a command or a verifiable action).

#### Scenario: User can onboard a new machine using only the checklist

- **GIVEN** a user with a freshly cloned repository on a new machine
- **WHEN** they follow the "New machine setup" checklist
- **THEN** they execute `bash install.sh` and can verify the deployment succeeded
- **AND** no step references external documentation as a prerequisite

#### Scenario: First SDD cycle checklist maps to actual commands

- **GIVEN** a user starting their first SDD cycle
- **WHEN** they follow the "First SDD cycle" checklist
- **THEN** each step contains the exact command to run (e.g., `/sdd-ff <change-name>`)
- **AND** the checklist proceeds in DAG order (propose before spec, tasks after spec+design)

#### Scenario: Config change deployment checklist includes install.sh and git commit

- **GIVEN** a user who edited a SKILL.md in the repo
- **WHEN** they follow the "Deploying a config change" checklist
- **THEN** they run `bash install.sh` before committing
- **AND** the checklist includes a git commit step with a suggested commit format

---

### Requirement: README.md updated with link to user-guide.md

`README.md` MUST be updated to include a reference to `docs/user-guide.md`. The link MUST appear in the overview or getting-started section (not buried in a footnote or appendix). The link text MUST be descriptive (e.g., "User Guide" or "Getting Started Guide") and the relative path MUST be correct.

#### Scenario: New user finds the guide from the README

- **GIVEN** a user who opens the repository README for the first time
- **WHEN** they scan the overview section
- **THEN** they find a link to `docs/user-guide.md` within the first 40 lines of README.md
- **AND** the link is labeled with a descriptive name (not a bare URL)

#### Scenario: Link path is not broken

- **GIVEN** the link `docs/user-guide.md` added to README.md
- **WHEN** a Markdown renderer resolves it relative to the repository root
- **THEN** the path resolves to the correct file
- **AND** `docs/user-guide.md` exists at that path after apply

---

### Requirement: No broken cross-links to existing technical docs

`docs/user-guide.md` MUST reference at least the following existing documents using relative Markdown links:

- `docs/SKILL-RESOLUTION.md`
- `docs/ORCHESTRATION.md`
- `docs/format-types.md`
- `skills/README.md`

Each reference MUST use a relative path that resolves correctly from the `docs/` directory. The guide MUST NOT link to documents that do not exist in the repository.

#### Scenario: All cross-links resolve to existing files

- **GIVEN** the user-guide.md is created
- **WHEN** each relative link in the document is resolved from `docs/`
- **THEN** every linked file exists at its expected path

#### Scenario: Guide does not reference non-existent files

- **GIVEN** the user-guide.md document
- **WHEN** all Markdown link targets are extracted and checked
- **THEN** no link points to a path that does not exist in the repository
