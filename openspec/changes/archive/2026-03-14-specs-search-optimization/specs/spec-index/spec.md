# Spec: spec-index

Change: 2026-03-14-specs-search-optimization
Date: 2026-03-14

---

## Overview

This spec defines the observable behavior of `openspec/specs/index.yaml`: its structure, content
contract, correctness invariants, and how sub-agents use it to select spec files for loading.
It also covers the `docs/SPEC-CONTEXT.md` update that documents the index-based selection path.

---

## Requirements

### Requirement: spec-index file existence and structure

`openspec/specs/index.yaml` MUST exist after this change is applied. It MUST contain a top-level
`domains:` key whose value is a YAML sequence of entries — one entry per domain directory
currently present under `openspec/specs/`.

Each entry MUST contain:

- `domain` (string): the directory name exactly as it appears under `openspec/specs/`
- `summary` (string): a single-line description of what behavioral contracts the spec covers
- `keywords` (sequence of strings): 3 to 8 terms that appear in change slugs or topics related
  to this domain

Each entry MAY contain:

- `related` (sequence of strings): names of other domain entries in the index that are frequently
  co-relevant when this domain is matched

#### Scenario: Index file is valid YAML and structurally correct

- **GIVEN** `openspec/specs/index.yaml` has been authored
- **WHEN** a YAML parser reads the file
- **THEN** parsing MUST succeed without errors
- **AND** the top-level key MUST be `domains`
- **AND** its value MUST be a sequence (list)

#### Scenario: Every domain directory has an index entry

- **GIVEN** `openspec/specs/` contains N domain subdirectories
- **WHEN** `openspec/specs/index.yaml` is read
- **THEN** the `domains` sequence MUST contain exactly N entries (one per domain)
- **AND** each entry's `domain` value MUST match a real subdirectory name in `openspec/specs/`
- **AND** no extra entries exist for directories that do not exist

#### Scenario: Each entry has the required fields

- **GIVEN** a sub-agent reads an entry from `openspec/specs/index.yaml`
- **WHEN** it checks the entry fields
- **THEN** `domain` MUST be present and non-empty
- **AND** `summary` MUST be present and non-empty (one line, no newlines)
- **AND** `keywords` MUST be present and contain between 3 and 8 items

#### Scenario: keywords reflect realistic change-slug vocabulary

- **GIVEN** a domain entry has a `keywords` list
- **WHEN** a sub-agent receives a change slug like `add-auth-token-refresh`
- **THEN** at least one keyword in the relevant auth-related domain entry MUST match a stem from
  the slug (e.g., `auth`, `token`)
- **AND** keywords MUST NOT contain abstract filler terms (e.g., `misc`, `other`, `general`)

#### Scenario: related field references only existing index entries

- **GIVEN** a domain entry has a `related` list
- **WHEN** a sub-agent reads the entry
- **THEN** every string value in `related` MUST correspond to a `domain` value of another entry
  in the same `index.yaml`
- **AND** `related` MUST NOT reference directories or domain names that do not appear in the index

---

### Requirement: Sub-agent index-based spec selection

Sub-agents that need background spec context MUST use a two-step selection algorithm when
`openspec/specs/index.yaml` exists:

1. Read `openspec/specs/index.yaml` (one read operation)
2. Score each entry: compute stem overlap between the change slug and the entry's `domain` name,
   `summary` text, and `keywords` list
3. Select the top-scoring entries (up to the existing hard cap of 3)
4. Read the selected `openspec/specs/<domain>/spec.md` files

When `openspec/specs/index.yaml` does not exist, sub-agents MUST fall back to the existing
stem-based directory-name matching algorithm defined in `docs/SPEC-CONTEXT.md`.

#### Scenario: Sub-agent uses index to select spec files with high recall

- **GIVEN** `openspec/specs/index.yaml` exists
- **AND** a change slug is `add-resilience-layer`
- **AND** the index contains an entry for `retry-policy` with keywords `[retry, resilience, backoff, fault-tolerance]`
- **WHEN** a sub-agent runs Step 0c spec context preload
- **THEN** it MUST read `index.yaml` first
- **AND** the `retry-policy` entry MUST be selected because `resilience` appears in its keywords
- **AND** `openspec/specs/retry-policy/spec.md` MUST be read as context
- **AND** this selection MUST occur even though `resilience` does not appear in the directory
  name `retry-policy` (demonstrating vocabulary gap closed by the index)

#### Scenario: Sub-agent falls back to directory-name matching when index is absent

- **GIVEN** `openspec/specs/index.yaml` does not exist
- **WHEN** a sub-agent runs Step 0c spec context preload
- **THEN** it MUST fall back to the stem-based directory-name matching algorithm
- **AND** it MUST NOT produce an error or warning solely because `index.yaml` is absent
- **AND** spec file selection MUST proceed using directory names only

#### Scenario: Index-based selection respects the 3-file hard cap

- **GIVEN** `openspec/specs/index.yaml` exists
- **AND** a change slug matches keywords in 7 domain entries
- **WHEN** a sub-agent runs Step 0c spec context preload
- **THEN** it MUST select at most 3 entries (highest-scoring)
- **AND** it MUST NOT load more than 3 spec files as background for a single phase invocation

#### Scenario: Index read failure is non-blocking

- **GIVEN** `openspec/specs/index.yaml` exists on disk but cannot be read (permissions, parse error)
- **WHEN** a sub-agent attempts to read it during Step 0c
- **THEN** it MUST log an INFO-level note and fall back to directory-name matching
- **AND** phase execution MUST continue without `status: blocked` or `status: failed`

---

### Requirement: SPEC-CONTEXT.md documents index-based selection as the preferred algorithm

`docs/SPEC-CONTEXT.md` MUST be updated to include a section titled "Using the spec index"
that describes the two-step lookup when `index.yaml` is present.

The section MUST document:
- Step 1: Read `openspec/specs/index.yaml`
- Step 2: Select matching domains using keyword scoring (up to the 3-file cap)
- Step 3: Read the selected `spec.md` files
- Fallback: when `index.yaml` is absent, use directory-name stem matching (existing algorithm)

The existing Selection Algorithm section MUST remain intact; the new section is additive.

#### Scenario: SPEC-CONTEXT.md contains the index lookup section after apply

- **GIVEN** the change is applied
- **WHEN** `docs/SPEC-CONTEXT.md` is opened
- **THEN** a section named "Using the spec index" MUST be present
- **AND** it MUST describe both the index-present path and the fallback path
- **AND** the existing "Selection Algorithm (stem-based matching)" section MUST still be present

#### Scenario: SPEC-CONTEXT.md references the index as preferred over directory listing

- **GIVEN** the "Using the spec index" section is read
- **WHEN** a sub-agent author interprets the guidance
- **THEN** the text MUST clearly indicate that the index-based algorithm is preferred when
  `index.yaml` is present
- **AND** directory-name stem matching MUST be described as the fallback, not the primary path
