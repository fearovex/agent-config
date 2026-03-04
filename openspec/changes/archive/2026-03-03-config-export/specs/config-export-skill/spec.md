# Spec: config-export-skill

Change: config-export
Date: 2026-03-03

## Overview

This spec describes the observable behavior of the `config-export` skill — the
entry point, invocation contract, source collection, target selection, dry-run
mode, file writing, idempotency, and summary output. It covers behavior
observable by the user and by the file system, not internal transformation logic
(which is covered in `config-export-targets`).

---

## Requirements

### Requirement: config-export is invocable as a skill from any project with a CLAUDE.md

The skill MUST be registered as `~/.claude/skills/config-export/SKILL.md` and
MUST be listed in the global CLAUDE.md skills registry under "Tools / Platforms".
When a user types `/config-export` in any Claude Code session, Claude MUST read
the SKILL.md and execute the skill's process.

#### Scenario: skill invoked in a project with CLAUDE.md and ai-context/

- **GIVEN** the current working directory contains a `CLAUDE.md` file
- **AND** the directory contains an `ai-context/` folder with at least one
  `*.md` file
- **WHEN** the user runs `/config-export`
- **THEN** the skill presents the available export targets and prompts for
  selection
- **AND** execution proceeds to the dry-run preview step

#### Scenario: skill invoked in a project with CLAUDE.md but no ai-context/

- **GIVEN** the current working directory contains a `CLAUDE.md` file
- **AND** there is no `ai-context/` directory present
- **WHEN** the user runs `/config-export`
- **THEN** the skill emits a WARNING: "ai-context/ not found — export quality
  will be lower; only CLAUDE.md will be used as source"
- **AND** execution continues using only `CLAUDE.md` as the source input
- **AND** the user is NOT blocked from proceeding

#### Scenario: skill invoked in a directory with no CLAUDE.md

- **GIVEN** the current working directory does NOT contain a `CLAUDE.md` file
- **WHEN** the user runs `/config-export`
- **THEN** the skill emits an ERROR: "No CLAUDE.md found in current directory —
  config-export requires at least a CLAUDE.md to export from"
- **AND** execution MUST halt; no files are written

---

### Requirement: config-export collects source inputs before transformation

Before generating any output, the skill MUST collect all available source files
into a structured context bundle. Source files are read in the following priority
order:

1. `CLAUDE.md` (required)
2. `ai-context/stack.md` (if present)
3. `ai-context/architecture.md` (if present)
4. `ai-context/conventions.md` (if present)
5. `ai-context/known-issues.md` (optional, lower priority)

#### Scenario: all source files present

- **GIVEN** the project contains `CLAUDE.md` and all four `ai-context/*.md` files
- **WHEN** the skill collects source inputs
- **THEN** all five files are included in the context bundle passed to the
  transformation step
- **AND** no files are silently skipped

#### Scenario: only CLAUDE.md and two ai-context files present

- **GIVEN** the project contains `CLAUDE.md`, `ai-context/stack.md`, and
  `ai-context/conventions.md` but not `architecture.md` or `known-issues.md`
- **WHEN** the skill collects source inputs
- **THEN** the context bundle contains three files (CLAUDE.md, stack.md,
  conventions.md)
- **AND** the missing files are silently skipped (no error for optional files)

---

### Requirement: config-export presents a target selection step before writing any files

The skill MUST present the available export targets to the user and allow
selection of one or more targets before generating or writing anything.

Available targets in V1:
- **copilot** — `.github/copilot-instructions.md`
- **gemini** — `GEMINI.md`
- **cursor** — `.cursor/rules/` (one `.mdc` file per domain)

#### Scenario: user selects a single target

- **GIVEN** the skill has collected source inputs
- **WHEN** the user selects only "copilot" as the export target
- **THEN** the skill proceeds to generate and preview only the Copilot output
- **AND** no Gemini or Cursor files are generated or written

#### Scenario: user selects all targets

- **GIVEN** the skill has collected source inputs
- **WHEN** the user selects all three targets
- **THEN** the skill proceeds to generate and preview output for all three targets

#### Scenario: user provides target as CLI argument

- **GIVEN** the user invokes `/config-export copilot` with a target name
- **THEN** the skill skips the interactive selection step and proceeds directly
  with the specified target(s)
- **AND** the dry-run preview step still executes before writing

---

### Requirement: dry-run mode is the default — no files are written without explicit confirmation

Before writing any output file, the skill MUST display the generated content to
the user and request explicit confirmation. This applies to all targets.

#### Scenario: user reviews and confirms dry-run output

- **GIVEN** the skill has generated transformed output for a selected target
- **WHEN** the skill presents the dry-run preview
- **THEN** it shows the full content of each file to be written and its
  destination path
- **AND** it prompts: "Write these files? [y/N]" (default: N)
- **WHEN** the user confirms with "y"
- **THEN** the files are written to their canonical locations

#### Scenario: user cancels at dry-run confirmation

- **GIVEN** the skill has generated transformed output for a selected target
- **WHEN** the skill presents the dry-run preview
- **AND** the user responds with anything other than "y" (or presses Enter
  accepting the default)
- **THEN** no files are written
- **AND** the skill exits cleanly with message: "Export cancelled — no files written"

---

### Requirement: config-export writes output files to canonical locations

When the user confirms the dry-run, the skill MUST write each output file to
its canonical path, creating intermediate directories as needed.

| Target | Canonical output path |
|--------|-----------------------|
| copilot | `.github/copilot-instructions.md` |
| gemini | `GEMINI.md` |
| cursor | `.cursor/rules/<domain>.mdc` (one file per exported domain) |

#### Scenario: writing copilot output when .github/ does not exist

- **GIVEN** the project does not have a `.github/` directory
- **WHEN** the skill writes the copilot export
- **THEN** it creates the `.github/` directory
- **AND** writes `.github/copilot-instructions.md`
- **AND** does not create any other files in `.github/`

#### Scenario: writing cursor output produces at least one .mdc file

- **GIVEN** the user has confirmed the cursor export
- **WHEN** the skill writes the cursor output
- **THEN** it creates `.cursor/rules/` if it does not exist
- **AND** writes at least one `.mdc` file with valid MDC YAML frontmatter
  (see `config-export-targets` spec for MDC format requirements)

---

### Requirement: re-running config-export overwrites existing output files with a warning

If a target output file already exists at its canonical path, the skill MUST
warn the user before overwriting. Silent overwrites are prohibited. Silent
failures (refusing to write without explanation) are also prohibited.

#### Scenario: copilot output file already exists

- **GIVEN** `.github/copilot-instructions.md` already exists in the project
- **WHEN** the skill generates new copilot output and the user confirms the
  dry-run
- **THEN** the skill emits a WARNING before writing: "Overwriting existing file:
  .github/copilot-instructions.md"
- **AND** the file is overwritten with the new content

#### Scenario: re-running produces identical output for an unchanged config

- **GIVEN** the project's CLAUDE.md and ai-context/ files have not changed
  since the last export
- **WHEN** the user runs `/config-export` again and confirms
- **THEN** the output files are overwritten (idempotent behavior — no error
  is thrown because the new content happens to match the existing content)

---

### Requirement: config-export emits a summary after writing files

After writing is complete, the skill MUST print a summary that lists each file
written and reminds the user that exported files are snapshots.

#### Scenario: successful export of two targets

- **GIVEN** the user has confirmed export for copilot and gemini
- **WHEN** writing completes without error
- **THEN** the skill prints a summary listing:
  - `.github/copilot-instructions.md` — written
  - `GEMINI.md` — written
- **AND** the summary includes the note: "Exported files are snapshots. Re-run
  /config-export after significant changes to CLAUDE.md or ai-context/"

---

## Rules

- The skill MUST halt and emit an ERROR if no `CLAUDE.md` is found; it MUST
  NOT write any files in that case
- Dry-run preview MUST precede any file write; there is NO flag to skip dry-run
- The skill MUST NOT modify `CLAUDE.md`, any `ai-context/` file, or any
  `openspec/` artifact — it is read-only with respect to the source files
- Overwrite warnings MUST appear in the dry-run step (before confirmation), not
  after the user has already confirmed
- Directory creation (`.github/`, `.cursor/rules/`) MUST be silent — no output
  for directory creation unless it fails
- The skill MUST NOT export the Claude target (`CLAUDE.md`) — this is
  explicitly deferred to avoid conflict with `project-update`; if a user
  requests a "claude" target, the skill MUST respond with: "The Claude target
  is not supported in V1 — use /project-update to refresh CLAUDE.md"
