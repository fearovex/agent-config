# Delta Spec: sdd-archive-execution

Change: 2026-03-14-specs-search-optimization
Date: 2026-03-14
Base: openspec/specs/sdd-archive-execution/spec.md

---

## ADDED — New requirements

### Requirement: sdd-archive maintains the spec index when a new domain spec is created

When the `sdd-archive` skill merges delta specs and the operation creates a new domain directory
under `openspec/specs/` (i.e., the domain did not previously exist in the master spec store),
`sdd-archive` MUST append a new entry to `openspec/specs/index.yaml`.

The appended entry MUST conform to the index schema:
- `domain`: the new directory name
- `summary`: a one-line description derived from the spec content (MUST NOT be left blank)
- `keywords`: 3–8 terms derived from the spec's domain vocabulary and requirement language
- `related`: zero or more related domain names (omit the field if no clear relations exist)

If `openspec/specs/index.yaml` does not exist (e.g., the change pre-dates this feature),
`sdd-archive` MUST create a minimal `index.yaml` with the standard file header, the `domains:`
root key, and the new domain as the first (and only) entry — then continue as if the file existed.

This index maintenance step MUST be non-blocking: a failure to append (parse error, write error)
MUST NOT prevent the archive from completing or set `status: failed`.

#### Scenario: Archive creates a new domain and appends an index entry

- **GIVEN** the delta spec being merged introduces a new domain `spec-index`
- **AND** `openspec/specs/index.yaml` already exists with N entries
- **WHEN** `sdd-archive` completes the spec merge (Step 3) for this change
- **THEN** `openspec/specs/index.yaml` MUST be updated with a new entry for `spec-index`
- **AND** the entry MUST contain `domain`, `summary`, and `keywords` fields
- **AND** the total entry count in the index MUST be N + 1

#### Scenario: Archive merges delta into existing domain — index is not modified

- **GIVEN** the delta spec updates an existing domain `sdd-archive-execution`
- **AND** `openspec/specs/index.yaml` exists
- **WHEN** `sdd-archive` merges the delta
- **THEN** the existing `sdd-archive-execution` entry in `index.yaml` MUST NOT be changed
- **AND** no new entry is appended
- **AND** the index entry count remains the same

#### Scenario: index.yaml is absent — sdd-archive creates a minimal index.yaml

- **GIVEN** the delta spec introduces a new domain
- **AND** `openspec/specs/index.yaml` does not exist
- **WHEN** `sdd-archive` completes the spec merge
- **THEN** `sdd-archive` MUST create `openspec/specs/index.yaml` with the standard file header and `domains:` root key
- **AND** the new domain MUST be written as the first (and only) entry in the file
- **AND** the archive completes with `status: ok`

#### Scenario: Index append failure does not block archive

- **GIVEN** `openspec/specs/index.yaml` exists but cannot be written (permissions error)
- **AND** the delta introduces a new domain
- **WHEN** `sdd-archive` attempts to append the new index entry
- **THEN** it MUST log a WARNING-level note that the index could not be updated
- **AND** the archive MUST still complete successfully
- **AND** `status` MUST be `ok` or `warning`, NEVER `failed` due to this step alone

#### Scenario: Appended entry keywords are derived from spec content

- **GIVEN** a new domain spec covers behavioral contracts for "spec-index" with requirements
  about YAML structure, keyword scoring, and fallback selection
- **WHEN** `sdd-archive` authors the index entry for this domain
- **THEN** the `keywords` list MUST include terms from the spec's subject area
  (e.g., `index`, `spec`, `yaml`, `keywords`, `search`, `selection`, `fallback`)
- **AND** MUST NOT include generic filler terms (`misc`, `other`, `general`, `stuff`)
- **AND** MUST contain between 3 and 8 keyword strings
