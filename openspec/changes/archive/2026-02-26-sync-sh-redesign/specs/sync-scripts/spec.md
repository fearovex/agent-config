# Spec: sync-scripts

Change: sync-sh-redesign
Date: 2026-02-26

## Requirements

### Requirement: sync.sh MUST only sync memory/ from ~/.claude/ to repo

`sync.sh` MUST copy exclusively `~/.claude/memory/` into `<repo>/memory/`.
It MUST NOT read, copy, or reference any other directory or file under `~/.claude/`
(including `skills/`, `CLAUDE.md`, `settings.json`, `hooks/`, `openspec/`, or `ai-context/`).

#### Scenario: Developer runs sync.sh after editing a skill in the repo

- **GIVEN** a developer has edited a file under `<repo>/skills/` and has NOT yet run `install.sh`
- **WHEN** they run `sync.sh`
- **THEN** no file under `<repo>/skills/` is overwritten or modified
- **AND** no file under `<repo>/CLAUDE.md`, `<repo>/settings.json`, `<repo>/hooks/`, `<repo>/openspec/`, or `<repo>/ai-context/` is overwritten or modified

#### Scenario: sync.sh copies memory/ correctly

- **GIVEN** `~/.claude/memory/MEMORY.md` exists and contains content written by Claude Code during a session
- **WHEN** the developer runs `sync.sh`
- **THEN** `<repo>/memory/MEMORY.md` is created or overwritten with the contents of `~/.claude/memory/MEMORY.md`
- **AND** the script exits with status 0

#### Scenario: sync.sh runs when ~/.claude/memory/ does not exist

- **GIVEN** `~/.claude/memory/` does not exist (e.g., on a fresh install before any session)
- **WHEN** the developer runs `sync.sh`
- **THEN** the script MUST NOT exit with a non-zero error status that stops the developer's workflow
- **AND** the script SHOULD print an informative message indicating that `~/.claude/memory/` was not found and no sync was performed

#### Scenario: sync.sh is run before install.sh on a new machine

- **GIVEN** the developer has not yet run `install.sh` on the current machine
- **GIVEN** `~/.claude/memory/` does not exist
- **WHEN** they run `sync.sh`
- **THEN** no repo files are modified or deleted
- **AND** the script completes without error

---

### Requirement: sync.sh MUST have a header block documenting its scope and data-flow direction

`sync.sh` MUST include a comment block at the top of the file that:
- States the direction of data flow (`~/.claude/memory/` → repo)
- States explicitly which directories it does NOT sync and why
- Reminds the developer that `skills/`, `CLAUDE.md`, `hooks/`, `openspec/`, and `ai-context/` are repo-authoritative

#### Scenario: Developer reads sync.sh to understand what it does

- **GIVEN** a developer opens `sync.sh` in any text editor
- **WHEN** they read the first section of the file
- **THEN** they can determine without running the script that it syncs only `memory/`
- **AND** they can determine which directories are NOT synced by this script

---

### Requirement: install.sh behavior MUST remain unchanged

`install.sh` MUST continue to copy all managed directories from the repo into `~/.claude/`
(including `CLAUDE.md`, `skills/`, `settings.json`, `hooks/`, `openspec/`, and `ai-context/`).
No behavioral change is permitted.

#### Scenario: Developer runs install.sh after pulling repo changes

- **GIVEN** the developer has pulled new commits to the repo that update files under `skills/`
- **WHEN** they run `install.sh`
- **THEN** the updated skill files are copied to `~/.claude/skills/`
- **AND** all other managed directories are also copied as before

#### Scenario: install.sh does not sync memory/ back to repo

- **GIVEN** `~/.claude/memory/MEMORY.md` contains content from a previous session
- **WHEN** the developer runs `install.sh`
- **THEN** `<repo>/memory/MEMORY.md` is NOT modified by `install.sh`
- **AND** `install.sh` does not perform any operation on `<repo>/memory/`

---

### Requirement: install.sh MUST have a header block documenting its scope and data-flow direction

`install.sh` MUST include a comment block at the top of the file that:
- States the direction of data flow (repo → `~/.claude/`)
- Lists each directory it copies and its purpose
- Notes that `memory/` is NOT copied by `install.sh` (it flows the other direction via `sync.sh`)

#### Scenario: Developer reads install.sh to understand what it does

- **GIVEN** a developer opens `install.sh` in any text editor
- **WHEN** they read the first section of the file
- **THEN** they can determine without running the script that it copies from repo to `~/.claude/`
- **AND** they can see which specific directories are installed
- **AND** they can see that `memory/` is out of scope for this script
