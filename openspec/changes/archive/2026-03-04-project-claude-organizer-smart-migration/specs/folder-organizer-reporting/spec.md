# Delta Spec: folder-organizer-reporting

Change: project-claude-organizer-smart-migration
Date: 2026-03-04
Base: openspec/specs/folder-organizer-reporting/spec.md

---

## ADDED — New requirements

### Requirement: report MUST include a "Legacy migrations" subsection when LEGACY_MIGRATIONS is non-empty

After the apply step completes, `claude-organizer-report.md` MUST include a `### Legacy migrations`
subsection under `## Plan Executed`. This subsection MUST be present if and only if
`LEGACY_MIGRATIONS` was non-empty for that run.

The subsection MUST document, for each legacy category processed:
- Category name (e.g., `commands/`, `docs/`, `system/`)
- Per-file outcome from the strategy that was applied:
  - Confirmed and applied: outcome line per file (e.g., `auth.md — copied to ai-context/features/auth.md`)
  - Skipped due to existing destination: `<filename> — skipped (destination exists)`
  - Skipped due to scaffold already present: `<filename> — scaffold skipped (proposal.md already exists)`
  - Advisory only (delegate strategy): `<filename> — advisory: invoke /skill-create <suggested-name>`
  - Non-qualifying (delegate strategy): `<filename> — non-qualifying — recommend archival`
  - Category skipped by user: `<category> — skipped by user (no files written)`

The subsection MUST also include a footer note stating that all source files were preserved.

#### Scenario: report documents delegate advisory outcomes for commands/

- **GIVEN** the `commands/` category was confirmed and processed
- **AND** `deploy.md` was qualifying (advisory generated) and `notes.md` was non-qualifying
- **WHEN** the report is written in Step 6
- **THEN** the `### Legacy migrations` subsection contains an entry for `commands/`
- **AND** it lists `deploy.md — advisory: invoke /skill-create deploy`
- **AND** it lists `notes.md — non-qualifying — recommend archival`
- **AND** it notes that no files were created by this step

#### Scenario: report documents copy outcomes for docs/

- **GIVEN** the `docs/` category was confirmed
- **AND** `auth.md` was copied to `ai-context/features/auth.md`
- **AND** `payments.md` was skipped because `ai-context/features/payments.md` already existed
- **WHEN** the report is written
- **THEN** the subsection contains an entry for `docs/`
- **AND** it lists `auth.md — copied to ai-context/features/auth.md`
- **AND** it lists `payments.md — skipped (destination exists)`

#### Scenario: report documents append outcomes for system/

- **GIVEN** the `system/` category was confirmed
- **AND** `architecture.md` was appended to `ai-context/architecture.md` with a labeled separator
- **WHEN** the report is written
- **THEN** the subsection entry for `system/` lists:
  `architecture.md — appended to ai-context/architecture.md (separator added)`

#### Scenario: report documents scaffold outcomes for requirements/

- **GIVEN** the `requirements/` category was confirmed
- **AND** `auth-requirements.md` produced a scaffold at `openspec/changes/<date>-auth-requirements/proposal.md`
- **WHEN** the report is written
- **THEN** the subsection entry for `requirements/` lists:
  `auth-requirements.md — scaffolded to openspec/changes/<date>-auth-requirements/proposal.md`

#### Scenario: report documents user-choice outcomes for sops/

- **GIVEN** the `sops/` category was confirmed
- **AND** `deployment-sop.md` was routed to Option A (appended to ai-context/conventions.md)
- **AND** `onboarding-sop.md` was routed to Option B (copied to docs/sops/onboarding-sop.md)
- **WHEN** the report is written
- **THEN** the subsection entry for `sops/` lists:
  `deployment-sop.md — appended to ai-context/conventions.md`
  `onboarding-sop.md — copied to docs/sops/onboarding-sop.md`

#### Scenario: report documents user-skipped categories

- **GIVEN** the `plans/` category was presented to the user with a per-category confirmation gate
- **AND** the user responded `no` to the `plans/` category
- **WHEN** the report is written
- **THEN** the subsection contains an entry: `plans/ — skipped by user (no files written)`

#### Scenario: Legacy migrations subsection is absent when LEGACY_MIGRATIONS was empty

- **GIVEN** no legacy pattern was detected for the run (LEGACY_MIGRATIONS is empty)
- **WHEN** the report is written
- **THEN** no `### Legacy migrations` subsection appears under `## Plan Executed`
- **AND** the report structure remains identical to the pre-change format

---

### Requirement: report summary line MUST include legacy migration counts

The one-line `Summary:` field in the report header MUST be extended to include a count of
legacy migration outcomes when `LEGACY_MIGRATIONS` was non-empty.

The extended format MUST be:
`<N> items created, <N> documentation file(s) copied, <N> legacy migration(s) applied, <N> unexpected item(s) flagged, <N> already correct`

Categories with a count of zero MAY be omitted from the summary line.

#### Scenario: summary line counts legacy migrations when applied

- **GIVEN** 2 legacy migration categories were processed and applied (e.g., `docs/` with 3 files, `system/` with 1 file)
- **WHEN** the report is written
- **THEN** the `Summary:` line includes `4 legacy migration(s) applied`

#### Scenario: summary line omits legacy count when none were applied

- **GIVEN** `LEGACY_MIGRATIONS` was empty for the run
- **WHEN** the report is written
- **THEN** the `Summary:` line does NOT include a "legacy migration(s) applied" count

---

## MODIFIED — Modified requirements

### Requirement: Recommended Next Steps section MUST include legacy-specific guidance when applicable

*(Before: Recommended Next Steps only addressed unexpected items, stub files, and canonical alignment.)*

When the report documents legacy migration outcomes, the `## Recommended Next Steps` section
MUST include conditional guidance specific to the migration strategies that were applied:

- If `commands/` delegate advisories were produced: include a recommendation to review the advisory list and invoke `/skill-create` for qualifying files
- If `section-distribute` strategy was applied to `project.md` or `readme.md`: include a recommendation to review the distributed sections in the destination ai-context/ files
- If append strategy was applied to `system/`: include a recommendation to review the appended content in the destination file and merge/deduplicate manually if needed
- If scaffold strategy produced proposal scaffolds from `requirements/`: include a recommendation to populate the scaffold proposals before running `/sdd-apply`
- If `sops/` was processed: include a recommendation to verify the conventions section or sops/ directory was correctly populated

#### Scenario: commands/ advisory in report triggers skill-create recommendation

- **GIVEN** the report documents one or more `commands/` advisory outcomes
- **WHEN** the report's `## Recommended Next Steps` section is read
- **THEN** it contains a recommendation: "Review the commands/ advisory list above — invoke /skill-create <name> for each qualifying file to scaffold a new skill"

#### Scenario: system/ append in report triggers manual-review recommendation

- **GIVEN** the report documents that content was appended to an ai-context/ file
- **WHEN** the `## Recommended Next Steps` section is read
- **THEN** it contains: "Review the appended content in the ai-context/ destination file(s) — merge or deduplicate manually if the appended section overlaps with existing content"

---

## Rules (additions)

- The `### Legacy migrations` subsection MUST be placed after the existing `### Documentation copied to ai-context/` subsection (if present) and before `### Unexpected items (not modified)`
- Each legacy category MUST appear as a distinct sub-entry within the subsection, even if only one file was processed
- The source-preservation footer note MUST state: "All source files in legacy categories were preserved — no files were deleted or moved"
- The summary line extension MUST count individual file operations (not categories) when reporting "legacy migration(s) applied"
- Advisory-only outcomes from the `delegate` strategy MUST NOT be counted in the "legacy migration(s) applied" summary count — they are guidance, not file writes
