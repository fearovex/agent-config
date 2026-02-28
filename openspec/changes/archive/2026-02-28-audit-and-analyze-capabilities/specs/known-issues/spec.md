# Spec: known-issues

Change: audit-and-analyze-capabilities
Date: 2026-02-28

## Requirements

### Requirement: ai-context/known-issues.md documents the marker-awareness limitation

`ai-context/known-issues.md` MUST contain an entry describing that `memory-manager` and `project-update` are not aware of `[auto-updated]` markers written by `project-analyze`, and that running them after `project-analyze` could theoretically overwrite marker boundaries.

#### Scenario: Marker-awareness entry exists in known-issues.md

- **GIVEN** `ai-context/known-issues.md` is read
- **WHEN** the entries are examined
- **THEN** an entry with a title referencing "marker-awareness" or "`[auto-updated]` marker conflict" is present
- **AND** the entry identifies `memory-manager` (`/memory-update`) and `project-update` as the skills that are unaware of the markers
- **AND** the entry identifies `project-analyze` as the skill that writes the `[auto-updated]` markers

#### Scenario: Entry describes when the limitation matters

- **GIVEN** the marker-awareness entry in `known-issues.md` is read
- **WHEN** its content is examined
- **THEN** it explains that the conflict is theoretical and has not been observed in practice
- **AND** it describes the specific risk: `memory-manager` or `project-update` could write content that overlaps with `[auto-updated]` section boundaries, creating duplicate or corrupted sections
- **AND** it specifies which files are affected: `ai-context/stack.md`, `ai-context/architecture.md`, `ai-context/conventions.md`

#### Scenario: Entry describes when the limitation does NOT matter

- **GIVEN** the marker-awareness entry in `known-issues.md` is read
- **WHEN** its content is examined
- **THEN** it states that the limitation does NOT matter when:
  - Only one of the three skills is used in a given session
  - The user runs `/project-analyze` last (so its markers are freshly written)
  - The user manually reviews ai-context/ files after running multiple skills

#### Scenario: Entry references the deferred ownership model approach

- **GIVEN** the marker-awareness entry in `known-issues.md` is read
- **WHEN** its content is examined
- **THEN** it references Approach B (per-section ownership model) from the exploration as a potential future solution
- **AND** it states that this approach is deferred until marker conflicts are observed in practice

#### Scenario: Entry does not prescribe a workaround that changes skill behavior

- **GIVEN** the marker-awareness entry in `known-issues.md` is read
- **WHEN** its content is examined
- **THEN** it does NOT instruct the user to modify any skill file
- **AND** it does NOT prescribe running skills in a specific order as a hard requirement
- **AND** any sequencing guidance is phrased as a recommendation, not a rule
