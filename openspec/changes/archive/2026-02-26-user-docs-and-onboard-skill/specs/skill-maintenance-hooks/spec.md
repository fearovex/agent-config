# Spec: Skill Maintenance Hooks

Change: user-docs-and-onboard-skill
Date: 2026-02-26

## Requirements

### Requirement: project-audit D2 checks existence and freshness of user docs

`skills/project-audit/SKILL.md` MUST be modified to add two new sub-checks to Dimension 2 (D2). The first sub-check verifies that `ai-context/scenarios.md` exists. The second sub-check verifies that `ai-context/quick-reference.md` exists. Both sub-checks MUST also verify that the `Last verified:` date field is present and not older than 90 days. Findings MUST be emitted at LOW severity. Missing files MUST emit a LOW finding; a missing or malformed date field MUST emit a LOW finding with message "Last verified field not found" rather than an error.

#### Scenario: Both user docs exist with fresh dates — no D2 finding

- **GIVEN** `ai-context/scenarios.md` and `ai-context/quick-reference.md` both exist
- **AND** both files have a `Last verified:` date within the last 90 days
- **WHEN** `/project-audit` is run
- **THEN** the D2 section of the audit report contains no LOW findings for these two files
- **AND** the audit score is not reduced by these sub-checks

#### Scenario: scenarios.md is missing — LOW finding emitted

- **GIVEN** `ai-context/scenarios.md` does not exist in the project
- **WHEN** `/project-audit` is run
- **THEN** the D2 section of the audit report contains a LOW finding stating that `ai-context/scenarios.md` is absent
- **AND** the finding includes a remediation hint (e.g., "create via /project-onboard or manually")

#### Scenario: quick-reference.md is missing — LOW finding emitted

- **GIVEN** `ai-context/quick-reference.md` does not exist in the project
- **WHEN** `/project-audit` is run
- **THEN** the D2 section of the audit report contains a LOW finding stating that `ai-context/quick-reference.md` is absent
- **AND** the finding includes a remediation hint

#### Scenario: scenarios.md exists but Last verified date is stale (> 90 days)

- **GIVEN** `ai-context/scenarios.md` exists
- **AND** the `Last verified:` date in the file is more than 90 days before today
- **WHEN** `/project-audit` is run
- **THEN** the D2 section contains a LOW finding stating that `scenarios.md` is stale
- **AND** the finding specifies the age of the last verification date in days

#### Scenario: scenarios.md exists but Last verified field is absent or malformed

- **GIVEN** `ai-context/scenarios.md` exists
- **AND** the file does not contain a `Last verified: YYYY-MM-DD` line in its first 10 lines, OR the date is not a valid ISO 8601 date
- **WHEN** `/project-audit` is run
- **THEN** the D2 section contains a LOW finding with message "Last verified field not found or malformed in scenarios.md"
- **AND** the audit does NOT raise an error or halt execution

#### Scenario: New D2 sub-checks do not deduct from the 100-point audit score

- **GIVEN** `ai-context/scenarios.md` and `ai-context/quick-reference.md` are both absent
- **WHEN** `/project-audit` is run
- **THEN** the two LOW findings appear in the audit report
- **AND** the numeric D2 score is NOT reduced by these sub-checks (LOW severity is informational only, not point-deducting in this iteration)

---

### Requirement: sdd-archive verify-report template includes a user-docs review checkbox

`skills/sdd-archive/SKILL.md` MUST be modified to add one checkbox item to its verify-report template. The item MUST read: `[ ] Review user docs (scenarios.md / quick-reference.md / onboarding.md) if this change affects user-facing workflows`. This checkbox is additive and MUST NOT block the archive operation if left unchecked.

#### Scenario: New checkbox appears in verify-report for newly archived changes

- **GIVEN** `skills/sdd-archive/SKILL.md` has been updated with the new checkbox
- **WHEN** a developer runs `/sdd-archive <some-change>` on a new change
- **THEN** the generated `verify-report.md` for that change contains the user-docs review checkbox
- **AND** the checkbox appears in the verify-report template section of the skill output

#### Scenario: Unchecked user-docs checkbox does not block archive

- **GIVEN** the verify-report for a change has the user-docs checkbox unchecked (`[ ]`)
- **AND** at least one other checkbox in the verify-report IS checked
- **WHEN** `/sdd-archive` processes the report
- **THEN** the archive operation proceeds and completes
- **AND** the unchecked user-docs checkbox is noted in the archive output as a reminder but is not a blocker

#### Scenario: Existing archived changes are not retroactively affected

- **GIVEN** previously archived changes exist in `openspec/changes/archive/`
- **AND** their `verify-report.md` files do not contain the user-docs checkbox
- **WHEN** `/project-audit` or any other skill reads those archived verify-reports
- **THEN** no error or missing-checkbox finding is emitted for those historical reports
- **AND** the new checkbox requirement applies only to changes archived after this skill update is applied

---

### Requirement: project-update detects and surfaces stale user docs

`skills/project-update/SKILL.md` MUST be modified to add a stale-doc detection step. This step MUST read the `Last verified:` date field from `ai-context/scenarios.md`, `ai-context/quick-reference.md`, and `ai-context/onboarding.md`. If any file's date is more than 90 days old, the skill MUST surface a prompt offering to regenerate that document. Regeneration MUST be offered as an opt-in action — the skill MUST NOT overwrite the file without explicit user confirmation.

#### Scenario: All docs are fresh — no stale-doc prompt

- **GIVEN** `ai-context/scenarios.md`, `ai-context/quick-reference.md`, and `ai-context/onboarding.md` all have `Last verified:` dates within 90 days
- **WHEN** `/project-update` is run
- **THEN** the stale-doc detection step completes silently with no prompt to the user about these files
- **AND** the update proceeds to its other tasks without interruption

#### Scenario: One doc is stale — offer is made, not forced

- **GIVEN** `ai-context/scenarios.md` has a `Last verified:` date older than 90 days
- **WHEN** `/project-update` is run
- **THEN** the skill surfaces a message stating that `scenarios.md` was last verified N days ago
- **AND** it offers to regenerate it (e.g., "Regenerate scenarios.md? [y/N]")
- **AND** if the user declines, the file is left unchanged and the update continues

#### Scenario: Regeneration overwrites only on explicit confirmation

- **GIVEN** `ai-context/scenarios.md` is stale and the user has confirmed regeneration
- **WHEN** `/project-update` regenerates the file
- **THEN** the file is overwritten with fresh content
- **AND** the `Last verified:` date is updated to today's date
- **AND** no other ai-context files are modified by this regeneration step

#### Scenario: Missing Last verified field is treated as stale

- **GIVEN** `ai-context/onboarding.md` exists but does not contain a `Last verified:` date line
- **WHEN** `/project-update` runs the stale-doc detection step
- **THEN** the skill treats the file as infinitely stale (or stale from epoch)
- **AND** it offers to regenerate it
- **AND** it does NOT raise an error or halt

#### Scenario: Missing user-doc file is skipped gracefully

- **GIVEN** `ai-context/scenarios.md` does not exist
- **WHEN** `/project-update` runs the stale-doc detection step
- **THEN** the skill skips the freshness check for that file (cannot check a file that does not exist)
- **AND** it MUST NOT emit an error for the missing file (the audit skill handles existence checks separately)
- **AND** the update continues normally
