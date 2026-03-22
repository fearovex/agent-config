# Delta Spec: Skills Catalog Format

Change: 2026-03-22-slim-orchestrator-context
Date: 2026-03-22
Base: openspec/specs/skills-catalog-format/spec.md

## ADDED — New requirements

### Requirement: Skills Registry section in CLAUDE.md MUST use compact path-only format

The `## Skills Registry` section in CLAUDE.md MUST use a compact format that lists skill paths only, without inline descriptions. Descriptions are available in each skill's YAML frontmatter and need not be duplicated in CLAUDE.md.

#### Scenario: Registry entries contain path only — no description

- **GIVEN** a reader opens the global CLAUDE.md
- **WHEN** they examine the Skills Registry section
- **THEN** each entry MUST contain only the skill path (e.g., `~/.claude/skills/sdd-ff/SKILL.md`)
- **AND** entries MUST NOT include inline descriptions or one-line summaries after the path
- **AND** the section MUST group skills by category (SDD Orchestrator, SDD Phases, Meta-tools, Technology, etc.)

#### Scenario: Registry is under 3,000 characters

- **GIVEN** the Skills Registry section uses the compact format
- **WHEN** its character count is measured
- **THEN** it MUST be under 3,000 characters (down from approximately 6,000 characters in the verbose format)

#### Scenario: All skills previously listed remain listed

- **GIVEN** the Skills Registry is condensed to compact format
- **WHEN** a reader compares the new registry against the previous verbose registry
- **THEN** every skill path that was listed in the verbose version MUST still be listed in the compact version
- **AND** no skill MUST be silently dropped during condensation

#### Scenario: Skill descriptions remain accessible via SKILL.md frontmatter

- **GIVEN** the registry no longer includes inline descriptions
- **WHEN** a reader or agent needs the description of a specific skill
- **THEN** they MUST be able to find it by reading the skill's SKILL.md YAML frontmatter `description:` field
- **AND** this is a documented convention (discoverable, not assumed)

---

### Requirement: Available Commands section in CLAUDE.md MUST use condensed single-line format

The `## Available Commands` section in CLAUDE.md MUST use a condensed format where each command occupies a single line with command name and brief action description only.

#### Scenario: Each command entry is a single line

- **GIVEN** a reader opens the global CLAUDE.md
- **WHEN** they examine the Available Commands section
- **THEN** each command MUST be on a single line in a table row
- **AND** each entry MUST contain only the command name and a brief action (no multi-sentence descriptions)

#### Scenario: Available Commands section is under 1,500 characters

- **GIVEN** the Available Commands section uses the condensed format
- **WHEN** its character count is measured
- **THEN** it MUST be under 1,500 characters (down from approximately 2,400 characters)

#### Scenario: All commands previously listed remain listed

- **GIVEN** the Available Commands section is condensed
- **WHEN** a reader compares the new section against the previous version
- **THEN** every command that was listed MUST still be listed
- **AND** no command MUST be silently dropped during condensation
