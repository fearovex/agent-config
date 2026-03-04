# Spec: folder-organizer-reporting

Change: project-claude-folder-organizer
Date: 2026-03-04

## Overview

This spec describes the observable structure and content contract of the report produced
by the `project-claude-organizer` skill. It covers: the report file location, required
sections, content per section, runtime-artifact classification, and the architecture.md
artifact table update.

---

## Requirements

### Requirement: report MUST be written to a fixed, predictable path inside the project .claude/

After a successful apply (or after a no-op run confirming a clean state), the skill MUST
write a report to `PROJECT_CLAUDE_DIR/claude-organizer-report.md`. The report MUST be
overwritten on every run (not appended).

#### Scenario: report path is PROJECT_CLAUDE_DIR/claude-organizer-report.md

- **GIVEN** the skill has completed execution (apply or no-op)
- **WHEN** the report is written
- **THEN** the file `<cwd>/.claude/claude-organizer-report.md` is created or overwritten
- **AND** no report file is written to `~/.claude/` or anywhere else

#### Scenario: report is overwritten on re-run

- **GIVEN** a `claude-organizer-report.md` already exists from a previous run
- **WHEN** the skill runs again and completes execution
- **THEN** the existing file is overwritten with the new report content
- **AND** no content from the previous run persists in the new report

#### Scenario: skill emits the report path to the user

- **GIVEN** the skill has finished writing the report
- **WHEN** skill execution concludes
- **THEN** the skill emits a message: "Report written to: <cwd>/.claude/claude-organizer-report.md"
- **AND** the path shown is the expanded absolute path (no tilde or relative segments)

---

### Requirement: report MUST contain a structured header with run metadata

The report MUST begin with a header block containing: run date, project root path, and a
one-line summary of the actions taken.

#### Scenario: report header is present and complete

- **GIVEN** the skill has completed execution
- **WHEN** the report is read
- **THEN** the report begins with a section containing:
  - `Run date:` in ISO 8601 format (YYYY-MM-DD)
  - `Project root:` — the expanded absolute path to CWD
  - `Target:` — the expanded absolute path to `PROJECT_CLAUDE_DIR`
  - `Summary:` — a one-line description, e.g., "3 items created, 1 unexpected item flagged, 4 items already correct" or "No changes needed — .claude/ is already canonical"

---

### Requirement: report MUST contain a Plan section listing all three item categories

The report MUST include a section that documents what the plan found and what action was
taken for each category: missing items (created), unexpected items (flagged), and already-
correct items (unchanged).

#### Scenario: report Plan section covers all three categories

- **GIVEN** the plan found 2 missing items, 1 unexpected item, and 3 already-correct items
- **WHEN** the report is read
- **THEN** the report contains a `## Plan Executed` section (or equivalent) with:
  - A "Created" subsection listing the 2 items that were created
  - An "Unexpected items (not modified)" subsection listing the 1 unexpected item with a warning note
  - An "Already correct" subsection listing the 3 items

#### Scenario: report Plan section reflects a no-op run

- **GIVEN** the enumeration found all items present and no unexpected items
- **WHEN** the report is read
- **THEN** the `## Plan Executed` section states: "No changes were needed — all expected items were already present"
- **AND** it lists the items that were verified as correct

#### Scenario: report documents unexpected items with a warning note

- **GIVEN** the plan found `commands/` as an unexpected item
- **WHEN** the report is read
- **THEN** the report lists `commands/` under "Unexpected items (not modified)"
- **AND** includes a note: "This item is not part of the canonical SDD .claude/ structure. Review manually — it was NOT deleted or moved."

---

### Requirement: report MUST include a stub content description for any files created

When the skill creates a stub file (e.g., `CLAUDE.md`), the report MUST document what
content was placed in the stub so the user knows what was added.

#### Scenario: created CLAUDE.md stub is documented in the report

- **GIVEN** the skill created a stub `CLAUDE.md` at `PROJECT_CLAUDE_DIR/CLAUDE.md`
- **WHEN** the report is read
- **THEN** the report contains a note: "CLAUDE.md stub created with a ## Skills Registry section heading"
- **AND** it advises: "Populate this file with project-specific SDD configuration"

---

### Requirement: report MUST conclude with a recommended next steps section

The report MUST end with a "## Recommended Next Steps" section. If unexpected items were
found, the first recommendation MUST advise the user to review them manually. If the state
is clean post-apply, the section MUST confirm the project is structurally aligned.

#### Scenario: unexpected items present — review recommendation is first

- **GIVEN** the report documents one or more unexpected items
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the first item is: "Review the unexpected item(s) listed above — if intentional, document them in .claude/CLAUDE.md; if not, remove them manually"

#### Scenario: stub files created — populate recommendation is included

- **GIVEN** the report documents stub files that were created (e.g., `CLAUDE.md`)
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** it includes: "Populate the created stub files with project-specific content"

#### Scenario: clean state post-apply — healthy confirmation

- **GIVEN** the apply step created all missing items and no unexpected items were found
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the section contains: "Project .claude/ structure is now aligned with the canonical SDD layout"

#### Scenario: no-op run — canonical structure confirmed

- **GIVEN** no changes were needed and the state was already clean
- **WHEN** the report's "## Recommended Next Steps" section is read
- **THEN** the section contains: "No action required — .claude/ is already canonical"

---

### Requirement: report is a runtime artifact and MUST NOT be committed to the project repository

The report file `.claude/claude-organizer-report.md` is a runtime audit artifact. The report
MUST include a footer note advising the user to add this file to `.gitignore`.

#### Scenario: report footer includes a git-exclusion reminder

- **GIVEN** the report has been written to `PROJECT_CLAUDE_DIR/claude-organizer-report.md`
- **WHEN** the report's footer is read
- **THEN** it includes a note: "This file is a runtime artifact. Add .claude/claude-organizer-report.md to .gitignore to prevent accidental commits."

#### Scenario: skill does not modify .gitignore

- **GIVEN** the skill has completed execution
- **WHEN** the project `.gitignore` is checked
- **THEN** the skill has NOT modified `.gitignore` — the suggestion is informational only

---

### Requirement: architecture.md artifact table MUST be updated to document the new report artifact

After `sdd-apply` completes, `ai-context/architecture.md` MUST contain a new row in the
artifact table for `claude-organizer-report.md`.

#### Scenario: architecture.md artifact table contains the new report artifact row

- **GIVEN** `sdd-apply` has completed for this change
- **WHEN** `ai-context/architecture.md` is read
- **THEN** the artifact table contains a row for `claude-organizer-report.md` with:
  - Producer: `project-claude-organizer`
  - Consumer: humans / operators
  - Location: `.claude/claude-organizer-report.md` in the target project (runtime artifact, never committed)

---

### Requirement: report artifact MUST be included in the canonical P8 expected item set

The file `claude-organizer-report.md` MUST be treated as an expected item in `PROJECT_CLAUDE_DIR`
by `claude-folder-audit` Check P8. This prevents false-positive MEDIUM findings after the
organizer has run.

#### Scenario: claude-folder-audit P8 does not flag claude-organizer-report.md as unexpected

- **GIVEN** the project `.claude/` folder contains `claude-organizer-report.md`
- **AND** the file was produced by a previous `/project-claude-organizer` run
- **WHEN** `/claude-folder-audit` runs Check P8
- **THEN** `claude-organizer-report.md` is NOT classified as an unexpected item
- **AND** no MEDIUM finding is raised for its presence

---

---

### Requirement: report MUST include a "Legacy migrations" subsection when LEGACY_MIGRATIONS is non-empty

*(Added in: 2026-03-04 by change "project-claude-organizer-smart-migration")*

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

*(Added in: 2026-03-04 by change "project-claude-organizer-smart-migration")*

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

### Requirement: Recommended Next Steps section MUST include legacy-specific guidance when applicable

*(Modified in: 2026-03-04 by change "project-claude-organizer-smart-migration")*

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

## Rules

- The report MUST be valid Markdown — all sections use `##` headers
- The report MUST be overwritten (not appended) on every run
- The report MUST include the three-category plan summary (created / unexpected / already-correct)
- The report MUST include a footer with a `.gitignore` reminder
- The report MUST NOT suggest or describe any destructive operations (deletion, moves) — it is informational
- The report path MUST always be shown to the user at the end of execution as an expanded absolute path
- `claude-organizer-report.md` MUST be listed in the canonical P8 expected item set (consistent with `claude-folder-audit` SKILL.md)
- The `ai-context/architecture.md` artifact table row MUST be added during `sdd-apply` — it is not optional
- The `### Legacy migrations` subsection MUST be placed after the existing `### Documentation copied to ai-context/` subsection (if present) and before `### Unexpected items (not modified)`
- Each legacy category MUST appear as a distinct sub-entry within the subsection, even if only one file was processed
- The source-preservation footer note MUST state: "All source files in legacy categories were preserved — no files were deleted or moved"
- The summary line extension MUST count individual file operations (not categories) when reporting "legacy migration(s) applied"
- Advisory-only outcomes from the `delegate` strategy MUST NOT be counted in the "legacy migration(s) applied" summary count — they are guidance, not file writes
