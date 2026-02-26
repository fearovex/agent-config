# Spec: sdd-status

Change: add-orchestrator-skills
Date: 2026-02-26

## Requirements

### Requirement: No argument required

The skill MUST execute when invoked as `/sdd-status` with no arguments. It MUST NOT require or accept a change-name argument. The skill operates on the entire `openspec/changes/` directory of the current project.

#### Scenario: Invoked with no arguments
- **GIVEN** the user types `/sdd-status`
- **WHEN** the skill begins execution
- **THEN** the skill MUST immediately read the `openspec/changes/` directory of the current project without prompting the user for any input

#### Scenario: Invoked with an unexpected argument
- **GIVEN** the user types `/sdd-status some-argument`
- **WHEN** the skill begins execution
- **THEN** the skill SHOULD ignore the argument and proceed normally
- **AND** SHOULD note in the output that `/sdd-status` takes no arguments

---

### Requirement: Active change discovery

The skill MUST read `openspec/changes/` and identify all subdirectories that are NOT inside `openspec/changes/archive/`. Each non-archive subdirectory is treated as an active change.

#### Scenario: Multiple active changes exist
- **GIVEN** `openspec/changes/` contains directories `add-auth`, `fix-logging`, and `archive/2026-01-15-old-change`
- **WHEN** the skill scans the directory
- **THEN** the skill MUST identify `add-auth` and `fix-logging` as active changes
- **AND** MUST NOT list `2026-01-15-old-change` as an active change

#### Scenario: No active changes exist
- **GIVEN** `openspec/changes/` is empty or contains only the `archive/` subdirectory
- **WHEN** the skill scans the directory
- **THEN** the skill MUST display a message: "No active changes found in openspec/changes/"
- **AND** MUST still display the archived count if `archive/` is present

#### Scenario: openspec/changes/ directory does not exist
- **GIVEN** the current project does not have an `openspec/changes/` directory
- **WHEN** the skill runs
- **THEN** the skill MUST display: "openspec/changes/ not found. This project may not have SDD initialized. Run /project-setup to initialize."
- **AND** MUST NOT crash or produce an unhandled error

---

### Requirement: Artifact completion check per active change

For each active change, the skill MUST check the presence of each known SDD artifact file and report which phases have been completed.

The artifact files to check are, in phase order:
1. `exploration.md` (explore phase)
2. `proposal.md` (propose phase)
3. `specs/` directory containing at least one `spec.md` (spec phase)
4. `design.md` (design phase)
5. `tasks.md` (tasks phase)
6. `verify-report.md` (verify phase)

#### Scenario: Change has proposal and tasks but no design
- **GIVEN** `openspec/changes/my-change/` contains `proposal.md` and `tasks.md` but not `design.md`
- **WHEN** the skill evaluates this change
- **THEN** the output MUST show `proposal.md` as present and `design.md` as absent
- **AND** MUST show `tasks.md` as present

#### Scenario: Change has specs directory but it is empty
- **GIVEN** `openspec/changes/my-change/specs/` exists but contains no `spec.md` files
- **WHEN** the skill evaluates the spec phase for this change
- **THEN** the skill MUST treat the spec phase as NOT complete
- **AND** MUST mark the spec artifact as absent in the output

#### Scenario: Change directory exists but is empty
- **GIVEN** `openspec/changes/my-change/` exists with no artifact files
- **WHEN** the skill evaluates this change
- **THEN** all artifact slots MUST be shown as absent
- **AND** the current phase MUST be displayed as "not started"

---

### Requirement: Readable tabular output

The skill MUST present results as a human-readable table or structured list. Each row MUST represent one active change. Columns MUST indicate presence or absence of each artifact.

#### Scenario: Standard output format
- **GIVEN** two active changes with different completion levels
- **WHEN** the skill renders output
- **THEN** the output MUST include a header row naming each artifact column
- **AND** each change row MUST use a clear present/absent indicator (e.g. `[x]` / `[ ]` or `yes`/`no` or equivalent)
- **AND** each change row MUST include the change name

#### Scenario: Current phase inference
- **GIVEN** a change has `proposal.md` and `design.md` present but `tasks.md` absent
- **WHEN** the skill renders the row for that change
- **THEN** the output MUST indicate the inferred current phase as "tasks" (the next missing phase)

---

### Requirement: Archived count summary

The skill MUST display a footer line showing the total number of archived changes found under `openspec/changes/archive/`.

#### Scenario: Archive directory has entries
- **GIVEN** `openspec/changes/archive/` contains three subdirectories
- **WHEN** the skill completes its scan
- **THEN** the output MUST include a line such as: "Archived changes: 3"

#### Scenario: Archive directory is absent or empty
- **GIVEN** `openspec/changes/archive/` does not exist or is empty
- **WHEN** the skill completes its scan
- **THEN** the output MUST include: "Archived changes: 0"

---

### Requirement: Filesystem-only reporting

The skill MUST report only what exists on the filesystem at the time of invocation. It MUST NOT consult git history, git status, or any external state to determine change status.

#### Scenario: File exists on disk but is not committed to git
- **GIVEN** `openspec/changes/my-change/proposal.md` exists on disk but has never been committed
- **WHEN** the skill checks for this artifact
- **THEN** the skill MUST report the artifact as present
- **AND** MUST NOT check git status for this determination

#### Scenario: Output includes filesystem-only disclaimer
- **GIVEN** the skill renders its output
- **WHEN** the footer is displayed
- **THEN** the output MUST include a note such as: "Status reflects filesystem state only — not git history."
