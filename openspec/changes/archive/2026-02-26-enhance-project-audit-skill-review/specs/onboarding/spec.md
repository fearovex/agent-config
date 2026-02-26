# Spec: onboarding — External Project Onboarding Workflow Document

Change: enhance-project-audit-skill-review
Date: 2026-02-26

## Requirements

### Requirement: OB-1 — Create ai-context/onboarding.md in claude-config

A new file `ai-context/onboarding.md` MUST be created in the `claude-config` repository. This file documents the canonical four-step sequence for onboarding an external project to the SDD system. It is a human-readable reference document, not consumed programmatically by any skill.

#### Scenario: File is created with required content
- **GIVEN** `ai-context/onboarding.md` does not yet exist in the `claude-config` repo
- **WHEN** this change is applied
- **THEN** `ai-context/onboarding.md` exists at the repo root's `ai-context/` directory
- **AND** the file contains the four-step onboarding sequence as documented in OB-2 through OB-4

#### Scenario: File survives sync and install
- **GIVEN** `ai-context/onboarding.md` exists in the repo
- **WHEN** `sync.sh` and then `install.sh` are run
- **THEN** the file is present at `~/.claude/ai-context/onboarding.md`

---

### Requirement: OB-2 — Document the canonical four-step onboarding sequence

`onboarding.md` MUST document the following four commands in order, as the canonical onboarding sequence:

1. `/project-setup` — Deploys SDD structure in the target project
2. `/memory-init` — Generates ai-context/ by reading the project
3. `/project-audit` — Diagnoses configuration quality and produces audit-report.md
4. `/project-fix` — Implements the corrections specified in audit-report.md

#### Scenario: Reader can identify the correct command order
- **GIVEN** a new team member reads `onboarding.md`
- **WHEN** they reach the sequence section
- **THEN** the four commands appear in the correct order (setup → init → audit → fix)
- **AND** each command has a one-sentence description of what it does
- **AND** each command has at least one verifiable success criterion (a specific observable output)

---

### Requirement: OB-3 — Document prerequisites for onboarding

`onboarding.md` MUST include a prerequisites section that lists the conditions that MUST be true before starting the onboarding sequence.

Required prerequisites to document:
- Claude Code must be installed and configured with the global `~/.claude/` runtime
- The global SDD skills must be present (`~/.claude/skills/sdd-*/SKILL.md`)
- The target project must be accessible from the file system (local clone or mounted path)
- `install.sh` must have been run at least once to populate `~/.claude/` from `claude-config`

#### Scenario: Reader can verify prerequisites before starting
- **GIVEN** a new team member reads `onboarding.md`
- **WHEN** they reach the prerequisites section
- **THEN** they can verify each prerequisite independently (e.g., by checking file existence or running a command)
- **AND** each prerequisite has a concrete check (not vague statements like "make sure things work")

---

### Requirement: OB-4 — Document common failure modes per step

`onboarding.md` MUST include at least one documented failure mode per onboarding step, with a recovery action.

#### Scenario: Reader encounters a failure during onboarding
- **GIVEN** a practitioner runs `/project-audit` and gets a score of 0/100 with `openspec/ not found` error
- **WHEN** they consult `onboarding.md`
- **THEN** the document identifies this as a known failure mode for Step 3
- **AND** the recovery action instructs them to verify that `/project-setup` (Step 1) completed successfully

---

### Requirement: OB-5 — Include a "Last verified" date field

`onboarding.md` MUST include a `Last verified:` field near the top of the document with the date the document was last manually confirmed to be accurate. This field enables identification of staleness as skills evolve.

#### Scenario: Last verified field is present
- **GIVEN** `onboarding.md` is created
- **THEN** the file contains a line matching the format: `Last verified: YYYY-MM-DD`
- **AND** the date is set to the date this change was applied (2026-02-26)

---

### Requirement: OB-6 — Update ai-context/architecture.md to reference onboarding.md

`ai-context/architecture.md` MUST be updated to include `onboarding.md` in the memory layer artifact table, so the artifact is discoverable by skills that read architecture.md.

#### Scenario: architecture.md artifact table includes onboarding.md
- **GIVEN** `architecture.md` is updated as part of this change
- **WHEN** the artifact table (or equivalent section) is read
- **THEN** a row for `onboarding.md` appears with description: "Canonical external project onboarding sequence"
- **AND** the row is added alongside the existing ai-context/ file entries

#### Scenario: architecture.md is not duplicated
- **GIVEN** this change is applied twice (idempotency check)
- **WHEN** `ai-context/architecture.md` is read
- **THEN** `onboarding.md` appears exactly once in the artifact table
