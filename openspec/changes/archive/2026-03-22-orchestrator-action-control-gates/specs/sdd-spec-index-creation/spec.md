# Spec: sdd-spec index.yaml Creation

Change: 2026-03-21-orchestrator-action-control-gates
Date: 2026-03-22

## Requirements

### Requirement: sdd-spec MUST create index.yaml if absent when writing the first domain spec

When the `sdd-spec` skill writes a spec for a domain and `openspec/specs/index.yaml` does not yet exist, it MUST create an empty-but-valid `index.yaml` with a `domains: []` stub before completing. This ensures the spec drift advisory (Pre-flight Check) has a populated index to match against after the first spec is archived.

**Creation rules:**
- Trigger: `sdd-spec` writes any spec file AND `openspec/specs/index.yaml` does not exist
- Action: create `openspec/specs/index.yaml` with the canonical header comment block and `domains: []`
- This creation is a **side effect of writing the first spec** — it is not a separate step
- If `index.yaml` already exists: skip creation silently (idempotent)
- The new file MUST use the canonical comment header (consistent with the existing index.yaml format in established projects)

#### Scenario: First spec written — index.yaml does not exist

- **GIVEN** `openspec/specs/index.yaml` does not exist
- **AND** `sdd-spec` is writing the first spec for domain `auth`
- **WHEN** the spec file `openspec/changes/<change>/specs/auth/spec.md` is created
- **THEN** `sdd-spec` MUST also create `openspec/specs/index.yaml` with `domains: []`
- **AND** the created file MUST include the canonical header comment explaining its purpose
- **AND** the spec writing MUST NOT be blocked or delayed by this side effect

#### Scenario: Subsequent spec written — index.yaml already exists

- **GIVEN** `openspec/specs/index.yaml` already exists with one or more domain entries
- **AND** `sdd-spec` is writing a spec for domain `payments`
- **WHEN** the spec file is created
- **THEN** `sdd-spec` MUST NOT overwrite or modify `index.yaml`
- **AND** it MUST proceed normally

#### Scenario: index.yaml creation failure is non-blocking

- **GIVEN** `openspec/specs/index.yaml` does not exist
- **AND** an I/O error occurs when attempting to create it
- **WHEN** `sdd-spec` attempts the creation
- **THEN** the spec writing MUST still complete successfully
- **AND** `sdd-spec` MUST log a WARNING that index.yaml creation failed, but MUST NOT return `status: failed` or `status: blocked` due to this failure

#### Scenario: Canonical header format

- **GIVEN** `openspec/specs/index.yaml` is being created for the first time by `sdd-spec`
- **WHEN** the file is written
- **THEN** it MUST contain a comment block explaining: its purpose, who maintains it, the selection algorithm reference, and the migration trigger note
- **AND** the `domains:` key MUST be present (value `[]` is acceptable as the initial state)
