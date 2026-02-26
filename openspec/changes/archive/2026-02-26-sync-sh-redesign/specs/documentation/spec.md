# Spec: documentation

Change: sync-sh-redesign
Date: 2026-02-26

## Requirements

### Requirement: architecture.md MUST accurately describe unidirectional data flow

`ai-context/architecture.md` MUST describe the correct mental model:
- `install.sh` is one-way: repo → `~/.claude/`, covering `CLAUDE.md`, `skills/`, `settings.json`, `hooks/`, `openspec/`, and `ai-context/`
- `sync.sh` is one-way: `~/.claude/memory/` → repo, covering ONLY `memory/`
- The diagram or description MUST NOT suggest a full bidirectional sync arrow between the repo and `~/.claude/`
- `architecture.md` MUST NOT state or imply that "Claude modifies `~/.claude/`" as a valid flow for skills, CLAUDE.md, hooks, openspec, or ai-context

#### Scenario: A new contributor reads architecture.md to understand the sync model

- **GIVEN** a developer opens `ai-context/architecture.md`
- **WHEN** they read the architecture section describing the two-layer structure
- **THEN** they understand that `skills/`, `CLAUDE.md`, `settings.json`, `hooks/`, `openspec/`, and `ai-context/` are repo-authoritative and flow only from repo → `~/.claude/`
- **AND** they understand that `memory/` is the only directory that flows `~/.claude/` → repo
- **AND** the description contains no statement that running `sync.sh` will capture skill or CLAUDE.md changes

#### Scenario: architecture.md does not mention the old bidirectional model

- **GIVEN** the updated `ai-context/architecture.md`
- **WHEN** a developer searches it for the phrase "Claude modifies" or any diagram arrow from `~/.claude/` back to the repo for non-memory directories
- **THEN** no such reference exists

---

### Requirement: conventions.md MUST state the correct sync.sh workflow

`ai-context/conventions.md` MUST NOT instruct developers to run `sync.sh` to "capture `~/.claude/` state" for the full repo.
It MUST state that `sync.sh` captures only `memory/` and MUST describe the corrected pre-commit workflow.

#### Scenario: Developer reads the install.sh / sync.sh usage section before committing

- **GIVEN** a developer opens `ai-context/conventions.md` and reads the `install.sh / sync.sh usage` section
- **WHEN** they follow the instructions
- **THEN** they understand `sync.sh` only captures `~/.claude/memory/` → repo
- **AND** they understand that `skills/`, `CLAUDE.md`, `hooks/`, `openspec/`, and `ai-context/` do NOT need to be synced before committing (they are edited in the repo directly)
- **AND** they understand when it IS appropriate to run `sync.sh` (only when they want to persist Claude Code's memory notes)

#### Scenario: conventions.md SDD workflow references sync.sh correctly

- **GIVEN** the SDD workflow section in `conventions.md` (the minimum cycle description)
- **WHEN** a developer reads it
- **THEN** any reference to `sync.sh` in the workflow step does not imply it captures skill or CLAUDE.md changes
- **AND** if the workflow includes `sync.sh`, it is contextually accurate (i.e., only for memory)

---

### Requirement: CLAUDE.md MUST NOT reference the incorrect sync model

Both `<repo>/CLAUDE.md` and the globally installed `~/.claude/CLAUDE.md` MUST NOT contain references to the old model where running `sync.sh` before committing captures a full `~/.claude/` state.
If `CLAUDE.md` references `sync.sh`, the reference MUST be consistent with the new behavior (memory only).

#### Scenario: Developer reads the CLAUDE.md SDD meta-cycle line before committing

- **GIVEN** a developer reads the SDD meta-cycle section in `CLAUDE.md` which currently reads:
  `/sdd-ff <change> → review → /sdd-apply → sync.sh → git commit`
- **WHEN** they follow the workflow
- **THEN** they understand that the `sync.sh` step in that workflow applies only to capturing `memory/` updates
- **AND** there is no implication that `sync.sh` is needed to preserve skill or CLAUDE.md edits

#### Scenario: grep search for old sync model in CLAUDE.md

- **GIVEN** the updated `CLAUDE.md`
- **WHEN** a developer searches for phrases such as "sync.sh before committing to capture" or "full mirror"
- **THEN** no such phrase exists in the file
