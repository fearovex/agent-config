# Spec: skill-guidance

Change: audit-and-analyze-capabilities
Date: 2026-02-28

## Requirements

### Requirement: CLAUDE.md contains a "When to use which" guidance section for ai-context/ skills

`CLAUDE.md` MUST contain a clearly titled guidance section that distinguishes the purpose and appropriate use case of `/project-analyze`, `/memory-update`, `/project-update`, and `/memory-init`. This section MUST be located in or near the Project Memory area of `CLAUDE.md`.

#### Scenario: Guidance section exists in CLAUDE.md

- **GIVEN** `CLAUDE.md` is read
- **WHEN** the user searches for guidance on which ai-context/ skill to use
- **THEN** a section titled "Skill Overlap -- When to Use Which" (or equivalent) is present
- **AND** the section is located in or adjacent to the "Project Memory" section
- **AND** the section describes each of the four skills with a one-line purpose statement

#### Scenario: Guidance section distinguishes /project-analyze from /memory-update

- **GIVEN** the "When to use which" guidance section is read
- **WHEN** the entries for `/project-analyze` and `/memory-update` are compared
- **THEN** `/project-analyze` is described as a full codebase re-scan that produces a fresh snapshot and updates `[auto-updated]` sections
- **AND** `/memory-update` is described as a session-aware tool that records what happened during the current session into ai-context/
- **AND** the distinction makes clear that `/project-analyze` observes the codebase while `/memory-update` records session-specific decisions and changes

#### Scenario: Guidance section explains /memory-init as first-time setup

- **GIVEN** the "When to use which" guidance section is read
- **WHEN** the entry for `/memory-init` is examined
- **THEN** it is described as the first-time initializer that creates all 5 core ai-context/ files from scratch
- **AND** it explicitly states that `/memory-init` SHOULD be run before `/project-analyze` on a project with no ai-context/ directory

#### Scenario: Guidance section explains /project-update as config sync

- **GIVEN** the "When to use which" guidance section is read
- **WHEN** the entry for `/project-update` is examined
- **THEN** it is described as a configuration synchronization tool that updates CLAUDE.md and stack.md to match the current global catalog and project dependencies
- **AND** it does NOT describe `/project-update` as a replacement for either `/project-analyze` or `/memory-update`

#### Scenario: Guidance section documents that project-analyze complements memory-manager

- **GIVEN** the "When to use which" guidance section is read
- **WHEN** the relationship between the skills is examined
- **THEN** the section explicitly states that `project-analyze` complements `memory-manager` but does not replace it
- **AND** this statement is consistent with the Out of Scope item 5 in `openspec/specs/project-analysis/spec.md`

#### Scenario: Guidance section is concise and references skill names

- **GIVEN** the "When to use which" guidance section is read
- **WHEN** its length and content style are assessed
- **THEN** the section is no longer than 20 lines of markdown
- **AND** it references skills by command name (e.g., `/project-analyze`) rather than by file path or line number
- **AND** it does NOT duplicate content already present in the Meta-tools command table
