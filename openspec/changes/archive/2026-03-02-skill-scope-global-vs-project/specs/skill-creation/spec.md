# Delta Spec: skill-creation

Change: skill-scope-global-vs-project
Date: 2026-03-02
Base: openspec/specs/skill-creation/spec.md

## ADDED — New requirements

### Requirement: skill-creator defaults to project-local placement inside a project context

When `/skill-create <name>` is invoked inside a project context (any directory that is
not the `claude-config` meta-repo), `skill-creator` MUST default the placement prompt
to project-local (`.claude/skills/<name>/SKILL.md`). The global option (`~/.claude/skills/`)
MUST remain fully available as an explicit user choice, but MUST NOT be the pre-selected default.

When invoked inside `claude-config`, the behavior is unchanged: `skill-creator` MUST continue
to default to global placement (`~/.claude/skills/`).

#### Scenario: skill-creator prompts with project-local as the default inside a project

- **GIVEN** the current working directory is a project (not `claude-config`)
- **AND** the project contains an `openspec/` directory or a `.claude/` directory
- **WHEN** the user runs `/skill-create <name>`
- **THEN** `skill-creator` presents the placement options with project-local
  (`.claude/skills/<name>/SKILL.md`) highlighted as the default
- **AND** the user can accept the default with a single confirmation
- **AND** the global option is listed as an alternative that requires explicit selection

#### Scenario: skill-creator accepts explicit global placement inside a project

- **GIVEN** the current working directory is a project (not `claude-config`)
- **WHEN** the user runs `/skill-create <name>` and explicitly selects the global option
- **THEN** the new SKILL.md is written to `~/.claude/skills/<name>/SKILL.md`
- **AND** the CLAUDE.md Skills Registry entry uses `~/.claude/skills/<name>/SKILL.md`

#### Scenario: skill-creator retains global default inside claude-config

- **GIVEN** the current working directory is the `claude-config` meta-repo
  (detected by the presence of `install.sh` and `skills/` at the root)
- **WHEN** the user runs `/skill-create <name>`
- **THEN** `skill-creator` presents the placement options with global
  (`~/.claude/skills/<name>/SKILL.md`) as the default
- **AND** the behavior is identical to the pre-change behavior of `skill-creator`

#### Scenario: skill-creator falls back to prompting when context is ambiguous

- **GIVEN** the current working directory contains neither `openspec/`, `.claude/`,
  `install.sh`, nor a recognizable project structure
- **WHEN** the user runs `/skill-create <name>`
- **THEN** `skill-creator` presents the placement options without a pre-selected default
- **AND** the user must explicitly choose between project-local and global
