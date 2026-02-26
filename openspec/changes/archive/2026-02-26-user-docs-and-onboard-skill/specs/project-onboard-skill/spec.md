# Spec: project-onboard Skill

Change: user-docs-and-onboard-skill
Date: 2026-02-26

## Requirements

### Requirement: Skill file must exist with correct structure

`skills/project-onboard/SKILL.md` MUST be created. It MUST contain: a trigger definition that activates on `/project-onboard`, a process section with step-by-step detection logic, a rules section, and an output format section. The skill MUST be listed in `CLAUDE.md` Skills Registry under the meta-tools group.

#### Scenario: Skill file exists at correct path

- **GIVEN** the change has been applied
- **WHEN** the file system is inspected
- **THEN** `skills/project-onboard/SKILL.md` exists in the `claude-config` repository
- **AND** the directory `skills/project-onboard/` contains exactly one file (`SKILL.md`)

#### Scenario: Skill is discoverable from CLAUDE.md

- **GIVEN** `CLAUDE.md` exists in the repository
- **WHEN** a user reads the Skills Registry section
- **THEN** there is an entry for `skills/project-onboard/SKILL.md` in the meta-tools group
- **AND** the entry describes the skill as diagnosing the current project state and recommending the correct first command

---

### Requirement: Skill detects project state without user input

When triggered, `/project-onboard` MUST read the file system of the current project and determine which of the six cases applies. It MUST NOT ask the user any questions. The diagnosis MUST be derived from real file-system state, not from a static hardcoded case lookup table.

#### Scenario: Brand-new project detection (Case 1)

- **GIVEN** the current project has no `.claude/CLAUDE.md` file
- **WHEN** `/project-onboard` is run
- **THEN** the skill reads the file system and finds no `.claude/CLAUDE.md`
- **AND** it produces a diagnosis stating the project has no Claude configuration
- **AND** it recommends `/project-setup` as the first command
- **AND** it does NOT ask the user to confirm which case they are in

#### Scenario: CLAUDE.md present but no SDD structure (Case 2)

- **GIVEN** the current project has `.claude/CLAUDE.md` but neither `openspec/` nor `ai-context/` directories exist
- **WHEN** `/project-onboard` is run
- **THEN** the skill detects the absence of `openspec/config.yaml` and `ai-context/`
- **AND** it produces a diagnosis stating the project has CLAUDE.md but no SDD structure
- **AND** it recommends `/project-setup` (to initialize SDD) followed by `/memory-init`

#### Scenario: Partial SDD — openspec exists but ai-context is empty or missing files (Case 3)

- **GIVEN** `openspec/config.yaml` exists in the project
- **AND** `ai-context/` either does not exist or exists with fewer than 4 of the 5 expected memory files (`stack.md`, `architecture.md`, `conventions.md`, `known-issues.md`, `changelog-ai.md`)
- **WHEN** `/project-onboard` is run
- **THEN** the skill detects the partial SDD state
- **AND** it produces a diagnosis listing which ai-context files are missing
- **AND** it recommends `/memory-init` as the first command

#### Scenario: Local skill clutter detected (Case 4)

- **GIVEN** `.claude/skills/` exists in the project with one or more skill directories
- **AND** at least one skill directory contains a SKILL.md with non-English content OR a duplicate of a global skill name
- **WHEN** `/project-onboard` is run
- **THEN** the skill flags the local skill directory for review
- **AND** it describes which heuristic triggered the flag (non-English content detected, or name matches global catalog entry)
- **AND** it recommends running `/project-audit` to get a full diagnostic

#### Scenario: Orphaned changes detected (Case 5)

- **GIVEN** `openspec/changes/` contains one or more directories
- **AND** at least one of those directories is missing either `tasks.md` or `verify-report.md`
- **WHEN** `/project-onboard` is run
- **THEN** the skill lists the names of orphaned change directories
- **AND** it explains which file is missing for each
- **AND** it recommends resuming or archiving each orphaned change before starting new work

#### Scenario: Fully configured project (Case 6)

- **GIVEN** `openspec/config.yaml` exists
- **AND** `ai-context/` exists with all 5 memory files populated (non-empty)
- **AND** no local skill clutter is detected
- **AND** no orphaned changes exist in `openspec/changes/`
- **WHEN** `/project-onboard` is run
- **THEN** the skill produces a healthy-state diagnosis
- **AND** it recommends `/sdd-ff <change>` or `/sdd-new <change>` as the next command
- **AND** it does NOT recommend any remediation commands

#### Scenario: Detection priority order is respected

- **GIVEN** a project that simultaneously has no `CLAUDE.md` AND has orphaned changes (impossible in practice but used to verify priority)
- **WHEN** `/project-onboard` is run
- **THEN** the skill reports Case 1 (no CLAUDE.md) and does NOT also report Case 5 (orphaned changes)
- **AND** earlier checks in the priority order take precedence over later checks

---

### Requirement: Skill output is structured and actionable

The skill MUST emit a structured diagnosis block containing: the detected state label, the evidence observed (which files were found or missing), and an ordered recommended command sequence. It MUST NOT emit raw file listings or stack traces.

#### Scenario: Diagnosis block is readable and actionable

- **GIVEN** `/project-onboard` has determined the project state
- **WHEN** the output is read by a user
- **THEN** the output contains a clearly labeled "Detected state" line
- **AND** the output contains an "Evidence" section listing specific files checked and their presence/absence
- **AND** the output contains a "Recommended command sequence" with numbered steps
- **AND** each recommended command is runnable as-is (no placeholders left unfilled unless the user must supply a change name)

#### Scenario: Warnings are emitted for secondary issues

- **GIVEN** the primary case is Case 6 (fully configured) but `ai-context/onboarding.md` has a `Last verified:` date older than 90 days
- **WHEN** `/project-onboard` is run
- **THEN** the diagnosis includes the primary Case 6 result AND a WARNING section
- **AND** the WARNING mentions the stale `onboarding.md` and suggests running `/project-update`
- **AND** the WARNING does NOT prevent the primary recommended command sequence from being shown

---

### Requirement: Skill does not execute remediation commands automatically

`/project-onboard` MUST be a diagnostic-only skill. It MUST NOT run `/project-setup`, `/memory-init`, or any other command on behalf of the user. All execution remains with the user.

#### Scenario: Read-only behavior

- **GIVEN** `/project-onboard` is run on a project in Case 1 state
- **WHEN** the skill completes
- **THEN** the file system of the project is identical to its state before the skill ran
- **AND** no new files or directories have been created by the skill
- **AND** no existing files have been modified by the skill
