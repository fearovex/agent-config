# Delta Spec: folder-audit-execution

Change: claude-folder-audit-project-mode
Date: 2026-03-03
Base: openspec/specs/folder-audit-execution/spec.md

## MODIFIED — Modified requirements

### Requirement: skill MUST detect its execution mode before running any check
*(Before: two modes only — `global-config` and `global`)*

The skill MUST determine its execution mode from a three-branch priority evaluation.
Mode priority order (highest to lowest):

1. `global-config` — both `install.sh` AND `skills/` directory are present at CWD root
2. `project` — a `.claude/` directory is present at CWD root (and condition 1 is false)
3. `global` — all other locations

The detected mode MUST be stated at the top of the generated report.

#### Scenario: global-config mode — unchanged behavior, highest priority

- **GIVEN** the current working directory contains both `install.sh` and a `skills/` directory at root
- **WHEN** the skill executes its mode-detection step
- **THEN** it sets the execution mode to `global-config`
- **AND** the detected mode is unaffected by whether a `.claude/` directory is also present at CWD

#### Scenario: project mode detected when .claude/ exists at CWD and global-config conditions are absent

- **GIVEN** the current working directory does NOT satisfy `global-config` conditions (i.e., does not have both `install.sh` and `skills/` at root)
- **AND** a `.claude/` directory exists at the current working directory root
- **WHEN** the skill executes its mode-detection step
- **THEN** it sets the execution mode to `project`
- **AND** it records `project_root = <cwd>` and `project_claude_dir = <cwd>/.claude/`
- **AND** the generated report header states "Mode: project"

#### Scenario: global mode — unchanged behavior, lowest priority

- **GIVEN** the current working directory does NOT satisfy `global-config` conditions
- **AND** no `.claude/` directory exists at the current working directory root
- **WHEN** the skill executes its mode-detection step
- **THEN** it sets the execution mode to `global`
- **AND** it records `runtime_root = ~/.claude/` (normalized)
- **AND** the generated report header states "Mode: global"

#### Scenario: .claude/ present at CWD in the claude-config repo — global-config wins

- **GIVEN** both `install.sh` and `skills/` are present at CWD root
- **AND** a `.claude/` directory also exists at CWD (e.g., runtime audit artifact)
- **WHEN** the skill executes its mode-detection step
- **THEN** it sets the execution mode to `global-config` (NOT `project`)
- **AND** the report header states "Mode: global-config"

---

## ADDED — New requirements

### Requirement: project mode — Check P1 — CLAUDE.md presence and Skills Registry

In `project` mode, the skill MUST verify that `.claude/CLAUDE.md` exists in the project
root AND that it contains a Skills Registry section (identified by the heading
`## Skills Registry` or the presence of a `~/.claude/skills/` or `.claude/skills/` path pattern).

#### Scenario: .claude/CLAUDE.md is present and contains a Skills Registry section — no finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` exists at the project root
- **AND** the file contains a line matching `## Skills Registry` or at least one path pattern `~/.claude/skills/` or `.claude/skills/`
- **WHEN** Check P1 runs
- **THEN** no finding is recorded for this check

#### Scenario: .claude/CLAUDE.md is absent — HIGH finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` does NOT exist at the project root
- **WHEN** Check P1 runs
- **THEN** a HIGH finding is recorded: "Missing .claude/CLAUDE.md — project Claude configuration not found"
- **AND** the remediation hint reads: "Run /project-setup or create .claude/CLAUDE.md and register skills"

#### Scenario: .claude/CLAUDE.md exists but has no Skills Registry section — HIGH finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` exists
- **AND** the file contains no `## Skills Registry` heading and no `~/.claude/skills/` or `.claude/skills/` path patterns
- **WHEN** Check P1 runs
- **THEN** a HIGH finding is recorded: "Skills Registry section not found in .claude/CLAUDE.md"
- **AND** the remediation hint reads: "Add a ## Skills Registry section to .claude/CLAUDE.md and register all skills used by this project"

---

### Requirement: project mode — Check P2 — global-path skill registrations reachability

In `project` mode, the skill MUST read all global-path skill registrations from
`.claude/CLAUDE.md` (path pattern: `~/.claude/skills/<name>/SKILL.md`) and verify that
each referenced `SKILL.md` is actually present at the expanded runtime path.

#### Scenario: all globally-registered skills are present at runtime — no finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` lists one or more global-path skill entries (`~/.claude/skills/<name>/SKILL.md`)
- **AND** each referenced `SKILL.md` exists at the expanded path on disk
- **WHEN** Check P2 runs
- **THEN** no finding is recorded for this check

#### Scenario: a globally-registered skill's SKILL.md is absent from the runtime path — HIGH finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` lists `~/.claude/skills/<name>/SKILL.md`
- **AND** the file `~/.claude/skills/<name>/SKILL.md` does NOT exist at the expanded path
- **WHEN** Check P2 runs
- **THEN** a HIGH finding is recorded: "Global skill '<name>' registered in .claude/CLAUDE.md is not deployed at ~/.claude/skills/<name>/SKILL.md"
- **AND** the remediation hint reads: "Run install.sh from the claude-config repo to deploy missing global skills"

#### Scenario: .claude/CLAUDE.md has no global-path registrations — P2 skipped with INFO note

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` contains no `~/.claude/skills/` path patterns
- **WHEN** Check P2 runs
- **THEN** an INFO note is recorded: "No global-path skill registrations found in .claude/CLAUDE.md — Check P2 skipped"
- **AND** no HIGH or MEDIUM finding is generated

#### Scenario: P2 is skipped when P1 recorded that CLAUDE.md is absent — INFO note

- **GIVEN** execution mode is `project`
- **AND** Check P1 recorded a HIGH finding for missing `.claude/CLAUDE.md`
- **WHEN** Check P2 runs
- **THEN** an INFO note is recorded: "Check P2 skipped — .claude/CLAUDE.md not found (see P1 finding)"
- **AND** no HIGH or MEDIUM finding is generated

---

### Requirement: project mode — Check P3 — local-path skill registrations reachability

In `project` mode, the skill MUST read all local-path skill registrations from
`.claude/CLAUDE.md` (path pattern: `.claude/skills/<name>/SKILL.md`) and verify that
each referenced `SKILL.md` exists on disk relative to CWD.

#### Scenario: all locally-registered skills have their SKILL.md on disk — no finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` lists one or more local-path skill entries (`.claude/skills/<name>/SKILL.md`)
- **AND** each referenced `SKILL.md` exists at `<cwd>/.claude/skills/<name>/SKILL.md`
- **WHEN** Check P3 runs
- **THEN** no finding is recorded for this check

#### Scenario: a locally-registered skill's SKILL.md is absent from disk — HIGH finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` lists `.claude/skills/<name>/SKILL.md`
- **AND** the file does NOT exist at `<cwd>/.claude/skills/<name>/SKILL.md`
- **WHEN** Check P3 runs
- **THEN** a HIGH finding is recorded: "Local skill '<name>' registered in .claude/CLAUDE.md is missing on disk at .claude/skills/<name>/SKILL.md"
- **AND** the remediation hint reads: "Create the skill file at .claude/skills/<name>/SKILL.md or remove the registration from .claude/CLAUDE.md"

#### Scenario: .claude/CLAUDE.md has no local-path registrations — P3 skipped with INFO note

- **GIVEN** execution mode is `project`
- **AND** `.claude/CLAUDE.md` contains no `.claude/skills/` path patterns
- **WHEN** Check P3 runs
- **THEN** an INFO note is recorded: "No local-path skill registrations found in .claude/CLAUDE.md — Check P3 skipped"
- **AND** no HIGH or MEDIUM finding is generated

#### Scenario: P3 is skipped when P1 recorded that CLAUDE.md is absent — INFO note

- **GIVEN** execution mode is `project`
- **AND** Check P1 recorded a HIGH finding for missing `.claude/CLAUDE.md`
- **WHEN** Check P3 runs
- **THEN** an INFO note is recorded: "Check P3 skipped — .claude/CLAUDE.md not found (see P1 finding)"
- **AND** no HIGH or MEDIUM finding is generated

---

### Requirement: project mode — Check P4 — orphaned local skills detection

In `project` mode, the skill MUST enumerate all SKILL.md files found under
`.claude/skills/*/SKILL.md` (relative to CWD) and verify that each is registered
in `.claude/CLAUDE.md`. A local skill present on disk but absent from the registry
is an orphaned skill.

#### Scenario: all local skills on disk are registered in CLAUDE.md — no finding

- **GIVEN** execution mode is `project`
- **AND** one or more `SKILL.md` files exist under `.claude/skills/`
- **AND** every skill directory name has a corresponding path entry in `.claude/CLAUDE.md`
- **WHEN** Check P4 runs
- **THEN** no finding is recorded for this check

#### Scenario: a local skill on disk is not registered in CLAUDE.md — MEDIUM finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/skills/<name>/SKILL.md` exists on disk
- **AND** there is no `.claude/skills/<name>/` path entry in `.claude/CLAUDE.md`
- **WHEN** Check P4 runs
- **THEN** a MEDIUM finding is recorded: "Local skill '<name>' exists on disk at .claude/skills/<name>/SKILL.md but is not registered in .claude/CLAUDE.md"
- **AND** the remediation hint reads: "Add .claude/skills/<name>/SKILL.md to the Skills Registry in .claude/CLAUDE.md, or remove the skill directory if it is no longer needed"

#### Scenario: no .claude/skills/ directory exists — P4 skipped with INFO note

- **GIVEN** execution mode is `project`
- **AND** no `.claude/skills/` directory exists relative to CWD
- **WHEN** Check P4 runs
- **THEN** an INFO note is recorded: "No .claude/skills/ directory found — Check P4 skipped"
- **AND** no finding is generated

#### Scenario: .claude/skills/ directory is empty — no finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/skills/` directory exists but contains no subdirectories with a `SKILL.md`
- **WHEN** Check P4 runs
- **THEN** an INFO note is recorded: "No local skill files found under .claude/skills/ — nothing to check"
- **AND** no finding is generated

---

### Requirement: project mode — Check P5 — scope tier overlap detection

In `project` mode, the skill MUST detect any skill name that appears in both the
project-local tier (`.claude/skills/<name>/`) and the global tier (`~/.claude/skills/<name>/`).
Such overlap is not an error but SHOULD be flagged as a LOW concern for intentional review.

#### Scenario: a skill name appears in both tiers — LOW finding

- **GIVEN** execution mode is `project`
- **AND** `.claude/skills/<name>/` exists relative to CWD
- **AND** `~/.claude/skills/<name>/` also exists at the global runtime path
- **WHEN** Check P5 runs
- **THEN** a LOW finding is recorded: "Skill '<name>' exists in both project-local (.claude/skills/) and global (~/.claude/skills/) tiers"
- **AND** the finding notes: "Project-local skills shadow global ones; verify which tier is intentional for this project"
- **AND** the remediation hint reads: "Confirm intended tier; consult ADR 008 for the two-tier placement model"

#### Scenario: no overlap between tiers — no finding

- **GIVEN** execution mode is `project`
- **AND** every skill name under `.claude/skills/` is absent from `~/.claude/skills/`
- **WHEN** Check P5 runs
- **THEN** no finding is recorded for this check

#### Scenario: no .claude/skills/ directory — P5 skipped with INFO note

- **GIVEN** execution mode is `project`
- **AND** no `.claude/skills/` directory exists relative to CWD
- **WHEN** Check P5 runs
- **THEN** an INFO note is recorded: "No .claude/skills/ directory found — Check P5 (scope tier overlap) skipped"
- **AND** no finding is generated

#### Scenario: global runtime path ~/.claude/skills/ cannot be read — INFO note

- **GIVEN** execution mode is `project`
- **AND** `~/.claude/skills/` is not accessible (permission error or does not exist)
- **WHEN** Check P5 runs
- **THEN** an INFO note is recorded: "Global tier ~/.claude/skills/ not accessible — P5 scope tier overlap check skipped"
- **AND** no LOW or higher finding is generated

---

### Requirement: project mode — checks MUST all execute even when earlier checks find HIGH issues

In `project` mode, the skill MUST run all 5 checks (P1 through P5) regardless of
findings from earlier checks. The only exception is the explicit skip behavior when P1
detects a missing `.claude/CLAUDE.md` — subsequent checks that depend on parsing
CLAUDE.md MUST record an INFO skip note and continue.

#### Scenario: P1 produces HIGH but P4 and P5 still run against disk state

- **GIVEN** execution mode is `project`
- **AND** Check P1 records a HIGH finding (CLAUDE.md absent or missing Skills Registry)
- **WHEN** all checks complete
- **THEN** Checks P2 and P3 each record an INFO skip note (cannot parse missing CLAUDE.md)
- **AND** Checks P4 and P5 still execute against the `.claude/skills/` directory on disk
- **AND** the report includes output sections for all 5 checks (P1 through P5)

---

## Rules (additions)

- In `project` mode, the skill MUST NOT audit `~/.claude/` (the global runtime); it audits only the project-local `.claude/` and references to `~/.claude/` only for P2 and P5 reachability checks
- All 5 project-mode checks (P1–P5) MUST run to completion; the skill MUST NOT abort after the first HIGH finding
- When `.claude/CLAUDE.md` is absent, P2 and P3 MUST each record an INFO skip note; P4 and P5 MUST still execute against the filesystem
- The severity cap rule from the base spec applies: Check P5 findings MUST NOT exceed LOW severity
- Mode detection MUST remain deterministic: given the same CWD state, the skill MUST always select the same mode
