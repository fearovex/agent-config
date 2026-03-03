# Spec: folder-audit-execution

Change: claude-folder-audit
Date: 2026-03-03

## Overview

This spec describes the observable behavior of the `claude-folder-audit` skill when it
executes its 5 audit checks against the `~/.claude/` runtime folder. It covers mode
detection, path normalization, all 5 checks, and the read-only constraint.

---

## Requirements

### Requirement: skill MUST detect its execution mode before running any check

When `/claude-folder-audit` is invoked, the skill MUST determine whether it is running
in **global-config mode** (cwd is the `claude-config` meta-repo) or **global mode**
(any other location). The detected mode MUST be stated at the top of the generated report.

In global-config mode the source repo and `~/.claude/` are the same logical system
post-install; the skill MUST document this overlap and still run all 5 checks.

#### Scenario: global-config mode detected by presence of install.sh and skills/ at root

- **GIVEN** the current working directory contains both `install.sh` and a `skills/` directory
  at the root level
- **WHEN** the skill executes its mode-detection step
- **THEN** it sets the execution mode to `global-config`
- **AND** it records `source_root = <cwd>` and `runtime_root = ~/.claude/` (normalized)
- **AND** the generated report header states "Mode: global-config"

#### Scenario: global mode detected when cwd lacks install.sh or skills/

- **GIVEN** the current working directory does NOT contain both `install.sh` and `skills/` at root
- **WHEN** the skill executes its mode-detection step
- **THEN** it sets the execution mode to `global`
- **AND** it records `runtime_root = ~/.claude/` (normalized)
- **AND** the generated report header states "Mode: global"

---

### Requirement: skill MUST normalize OS-specific home paths at startup

The skill MUST expand `~` to the actual home directory path before any filesystem
reads. On Windows the home directory is `%USERPROFILE%`; on Unix/macOS it is `$HOME`.
All displayed paths in the report MUST use forward slashes.

#### Scenario: tilde is expanded to the actual home directory on Windows

- **GIVEN** the runtime OS is Windows 11
- **AND** `%USERPROFILE%` resolves to `C:\Users\juanp`
- **WHEN** the skill normalizes the runtime root path
- **THEN** `~/.claude/` is expanded to `C:/Users/juanp/.claude/` (forward slashes)
- **AND** all subsequent file reads use this expanded path

#### Scenario: tilde is expanded on Unix / macOS

- **GIVEN** the runtime OS is Unix or macOS
- **AND** `$HOME` resolves to `/home/juanp`
- **WHEN** the skill normalizes the runtime root path
- **THEN** `~/.claude/` is expanded to `/home/juanp/.claude/`

#### Scenario: path normalization failure is treated as a HIGH finding

- **GIVEN** neither `$HOME` nor `%USERPROFILE%` resolves to a valid path
- **WHEN** the skill attempts to expand the runtime root
- **THEN** it records a HIGH finding: "Cannot resolve home directory — path normalization failed"
- **AND** it halts further checks and writes a minimal report containing only that finding

---

### Requirement: Check 1 — runtime structure validation

The skill MUST verify that the required top-level directories exist inside `~/.claude/`.
Required directories: `skills/`, `openspec/`, `ai-context/`, `memory/`, `hooks/`.

#### Scenario: all required directories are present — no finding

- **GIVEN** `~/.claude/skills/`, `~/.claude/openspec/`, `~/.claude/ai-context/`,
  `~/.claude/memory/`, and `~/.claude/hooks/` all exist
- **WHEN** Check 1 runs
- **THEN** no finding is recorded for this check

#### Scenario: a required directory is absent — HIGH finding

- **GIVEN** one or more of the required directories does not exist in `~/.claude/`
- **WHEN** Check 1 runs
- **THEN** a HIGH finding is recorded for each missing directory:
  "Required directory missing: ~/.claude/<dir>/"
- **AND** the remediation hint reads: "Run install.sh from the claude-config repo"

#### Scenario: CLAUDE.md file absent from runtime root — HIGH finding

- **GIVEN** `~/.claude/CLAUDE.md` does not exist
- **WHEN** Check 1 runs
- **THEN** a HIGH finding is recorded: "CLAUDE.md missing from ~/.claude/"
- **AND** the remediation hint reads: "Run install.sh from the claude-config repo"

---

### Requirement: Check 2 — skill deployment completeness

For every skill directory found in the source repo's `skills/` folder, the skill MUST
verify that a corresponding directory exists in `~/.claude/skills/`. A skill is considered
deployed if its directory exists; the presence of `SKILL.md` inside it is MUST be verified too.

#### Scenario: all source skills are deployed — no finding

- **GIVEN** every directory under `skills/` (source) has a matching directory under
  `~/.claude/skills/`
- **AND** every matched directory contains a `SKILL.md` file
- **WHEN** Check 2 runs
- **THEN** no finding is recorded for this check

#### Scenario: a source skill directory is absent from runtime — HIGH finding

- **GIVEN** `skills/<name>/` exists in the source repo
- **AND** `~/.claude/skills/<name>/` does NOT exist
- **WHEN** Check 2 runs
- **THEN** a HIGH finding is recorded: "Skill '<name>' present in source but not deployed to ~/.claude/skills/"
- **AND** the remediation hint reads: "Run install.sh from the claude-config repo"

#### Scenario: a deployed skill directory is missing SKILL.md — MEDIUM finding

- **GIVEN** `~/.claude/skills/<name>/` exists
- **AND** `~/.claude/skills/<name>/SKILL.md` does NOT exist
- **WHEN** Check 2 runs
- **THEN** a MEDIUM finding is recorded: "Deployed skill '<name>' has no SKILL.md — directory may be empty or corrupt"
- **AND** the remediation hint reads: "Run install.sh to restore the skill file"

#### Scenario: Check 2 is skipped in global mode with no source repo detected

- **GIVEN** execution mode is `global`
- **AND** no source `skills/` directory is readable from the cwd
- **WHEN** Check 2 runs
- **THEN** it records an INFO note: "Source repo not detected — skill deployment completeness check skipped"
- **AND** no HIGH or MEDIUM findings are generated for this check

---

### Requirement: Check 3 — installation drift detection

The skill MUST compare the source repo's modification time with the runtime
`~/.claude/` directory's modification time to detect likely out-of-sync state.
Because no `.installed-at` metadata file currently exists, mtime is used as a proxy.
This check is explicitly imprecise; findings are capped at MEDIUM severity.

#### Scenario: source repo is newer than runtime — MEDIUM drift finding

- **GIVEN** the source repo root directory's mtime is more recent than `~/.claude/`'s mtime
- **WHEN** Check 3 runs
- **THEN** a MEDIUM finding is recorded: "Possible installation drift — source repo appears newer than ~/.claude/ (mtime proxy)"
- **AND** the finding includes both timestamps in ISO 8601 format
- **AND** the remediation hint reads: "Run install.sh to re-sync runtime with source repo"

#### Scenario: runtime is newer or equal — no finding

- **GIVEN** `~/.claude/`'s mtime is equal to or more recent than the source repo root's mtime
- **WHEN** Check 3 runs
- **THEN** no finding is recorded for this check

#### Scenario: mtime comparison fails due to filesystem access error — INFO finding

- **GIVEN** the mtime of either the source repo root or `~/.claude/` cannot be read
- **WHEN** Check 3 runs
- **THEN** an INFO finding is recorded: "Could not read directory mtime for drift comparison — check skipped"
- **AND** no MEDIUM or HIGH finding is generated for this check

#### Scenario: Check 3 is skipped in global mode — INFO note

- **GIVEN** execution mode is `global`
- **AND** no source repo root is detected
- **WHEN** Check 3 runs
- **THEN** an INFO note is recorded: "No source repo detected — drift check skipped"

---

### Requirement: Check 4 — orphaned artifact detection

The skill MUST identify files and directories in `~/.claude/` that are not traceable
to the source repo. An artifact is orphaned if its name matches none of the expected
top-level items derived from the source repo contents plus the known runtime-only
artifacts (`CLAUDE.md`, `settings.json`, `claude-folder-audit-report.md`,
`.installed-at` if introduced in future).

#### Scenario: no orphaned artifacts found — no finding

- **GIVEN** every file and directory directly under `~/.claude/` matches an expected
  source repo item or known runtime-only artifact
- **WHEN** Check 4 runs
- **THEN** no finding is recorded for this check

#### Scenario: unexpected file found at runtime root — MEDIUM finding

- **GIVEN** a file or directory exists directly under `~/.claude/` that does not match
  any source repo item or known runtime-only artifact
- **WHEN** Check 4 runs
- **THEN** a MEDIUM finding is recorded for each unexpected item:
  "Unexpected item in ~/.claude/: <name> — possible manual edit or stale artifact"
- **AND** the remediation hint reads: "Review manually; run install.sh if this file should not exist; do NOT delete without inspection"
- **AND** the severity is capped at MEDIUM regardless of how many unexpected items exist

#### Scenario: openspec/changes/ items in runtime are reported as work-in-progress, not orphans

- **GIVEN** `~/.claude/openspec/changes/` contains subdirectories not present in the source repo
- **WHEN** Check 4 runs
- **THEN** these are NOT classified as orphaned artifacts
- **AND** they are reported as an INFO note: "Work-in-progress SDD change directories found in runtime openspec/changes/"

---

### Requirement: Check 5 — scope tier compliance

The skill MUST detect skills duplicated across the global tier (`~/.claude/skills/`) and
project-local tier (`.claude/skills/` relative to the cwd). It MUST also detect any
project-local skills that are missing from the source repo.

#### Scenario: a skill exists in both global and project-local tiers — LOW finding

- **GIVEN** `~/.claude/skills/<name>/` exists (global tier)
- **AND** `.claude/skills/<name>/` exists relative to the current working directory (project-local tier)
- **WHEN** Check 5 runs
- **THEN** a LOW finding is recorded: "Skill '<name>' exists in both global (~/.claude/skills/) and project-local (.claude/skills/) tiers"
- **AND** the finding notes: "This is expected for intentional global overrides; verify the intended tier is active"
- **AND** the remediation hint reads: "Confirm which tier is authoritative for this project; consult ADR 008"

#### Scenario: no project-local .claude/skills/ directory exists — Check 5 partial skip

- **GIVEN** no `.claude/skills/` directory exists relative to the current working directory
- **WHEN** Check 5 runs
- **THEN** the skill records an INFO note: "No project-local .claude/skills/ found — scope tier compliance check skipped for project-local tier"
- **AND** only the global tier contents are listed (no findings generated)

#### Scenario: project-local skill not present in source repo skills/ — MEDIUM finding

- **GIVEN** `.claude/skills/<name>/` exists in the project-local tier
- **AND** `skills/<name>/` does NOT exist in the source repo (global catalog)
- **WHEN** Check 5 runs
- **THEN** a MEDIUM finding is recorded: "Project-local skill '<name>' has no counterpart in the global catalog (skills/)"
- **AND** the remediation hint reads: "If this is intentional, register the skill in CLAUDE.md; if not, consider adding it to skills/"

---

### Requirement: the skill MUST NOT create, modify, or delete any file other than the report

The `claude-folder-audit` skill is strictly read-only during its audit execution phase.
The only file write permitted is the report output to `~/.claude/claude-folder-audit-report.md`.

#### Scenario: skill execution creates no files except the report

- **GIVEN** the skill is invoked and completes all 5 checks successfully
- **WHEN** execution finishes
- **THEN** the only file written is `~/.claude/claude-folder-audit-report.md`
- **AND** no source repo file, no `~/.claude/` skill, no `CLAUDE.md`, and no other
  runtime file is modified or deleted

#### Scenario: report file overwrites previous run on re-execution

- **GIVEN** `~/.claude/claude-folder-audit-report.md` already exists from a previous run
- **WHEN** the skill is run again
- **THEN** the existing report is overwritten (not appended)
- **AND** the new report contains only findings from the current run

---

## Rules

- The skill MUST run all 5 checks even if earlier checks produce HIGH findings; it MUST NOT abort early
- Severity caps: drift check (Check 3) findings MUST NOT exceed MEDIUM; manual overrides (Check 4)
  MUST NOT exceed MEDIUM
- The skill MUST document all detected limitations inline in the report (mtime proxy, no .installed-at, etc.)
- Mode detection MUST run before any check; if mode cannot be determined, default to `global` mode
- The skill MUST NOT emit any finding that recommends deleting a file in `~/.claude/` without human review
- On Windows, all path operations MUST use the expanded `%USERPROFILE%` value; tilde expansion
  MUST NOT rely on shell interpretation (use explicit env var lookup)
