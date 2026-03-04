# Task Plan: project-claude-organizer-smart-migration

Date: 2026-03-04
Design: openspec/changes/project-claude-organizer-smart-migration/design.md

## Progress: 22/22 tasks

---

## Phase 1: Step 3b — Classification Layer Structure

Insert the new Step 3b block into `skills/project-claude-organizer/SKILL.md` immediately after the
existing DOCUMENTATION_CANDIDATES classification at the end of Step 3. This phase establishes the
container structure and the LEGACY_PATTERN_TABLE before any pattern-specific content.

- [x] 1.1 Modify `skills/project-claude-organizer/SKILL.md` — insert Step 3b heading, purpose
  paragraph, and `LEGACY_MIGRATIONS` collection initialization block immediately after the Step 3
  DOCUMENTATION_CANDIDATES sub-section and before the `---` separator that begins Step 4.
  The block MUST declare: `LEGACY_MIGRATIONS = []` and state that items reclassified here are
  removed from `UNEXPECTED`.

- [x] 1.2 Modify `skills/project-claude-organizer/SKILL.md` — insert the `LEGACY_PATTERN_TABLE`
  reference table in Step 3b listing all 8 known patterns with columns: Pattern name | Match
  condition | Migration strategy | Destination summary. This table is the quick-scan index; detail
  for each pattern follows in Phase 2.

- [x] 1.3 Modify `skills/project-claude-organizer/SKILL.md` — insert the Step 3b classification
  loop description: "For each item in `UNEXPECTED`: match item name (case-insensitive) against
  LEGACY_PATTERN_TABLE → on hit: add entry to `LEGACY_MIGRATIONS` (source, destination(s),
  strategy, confirmation_required=true), remove from `UNEXPECTED` → on miss: item stays in
  `UNEXPECTED` (review manually behavior unchanged)." Include the explicit rule that only
  top-level items are evaluated (no subdirectory recursion).

---

## Phase 2: Pattern-Specific Migration Entries (Step 3b Detail)

Add the per-pattern detail blocks within Step 3b — one sub-section per legacy pattern. Each
sub-section describes match condition, strategy, destinations, and any content-analysis
requirements.

- [x] 2.1 Modify `skills/project-claude-organizer/SKILL.md` — add Step 3b detail block for
  `commands/` pattern: match = directory named `commands`, strategy = `delegate` (SKILL_ADVISORY),
  destination = advisory only (no write), content_analysis = true (read each `.md` at immediate
  level, apply 4 qualifying markers from skill-orchestration spec: step-numbered sections, trigger
  patterns, `## Process`/`## Steps`/`## How to`/`## Instructions` headings, filename-stem keyword
  match). Note that no files are auto-created.

- [x] 2.2 Modify `skills/project-claude-organizer/SKILL.md` — add Step 3b detail block for
  `docs/` pattern: match = directory named `docs`, strategy = `copy`, destination =
  `PROJECT_ROOT/ai-context/features/<name>.md` for each `*.md` file at the immediate `docs/` level;
  skip if destination exists.

- [x] 2.3 Modify `skills/project-claude-organizer/SKILL.md` — add Step 3b detail block for
  `system/` pattern: match = directory named `system`, strategy = `append`, routing =
  `architecture.md` → `ai-context/architecture.md`, `database.md` + `api-overview.md` →
  `ai-context/stack.md`; merge strategy = append under labeled section separator
  `<!-- appended from .claude/system/<filename> YYYY-MM-DD -->`.

- [x] 2.4 Modify `skills/project-claude-organizer/SKILL.md` — add Step 3b detail block for
  `plans/` pattern: match = directory named `plans`, strategy = `copy`, routing = active plans →
  `openspec/changes/<plan-name>/`, archived plans → `openspec/changes/archive/<plan-name>/`;
  active vs. archived distinction is determined per-item with user confirmation at apply time
  (per the design open question resolution).

- [x] 2.5 Modify `skills/project-claude-organizer/SKILL.md` — add Step 3b detail block for
  `requirements/` pattern: match = directory named `requirements`, strategy = `scaffold`,
  destination = `openspec/changes/<YYYY-MM-DD>-<slug>/proposal.md` per file where `<slug>` is
  derived from the filename stem; idempotent — skip if destination already exists.

- [x] 2.6 Modify `skills/project-claude-organizer/SKILL.md` — add Step 3b detail block for
  `sops/` pattern: match = directory named `sops`, strategy = `user-choice`, destinations =
  Option A (`ai-context/conventions.md` append as named section) or Option B
  (`docs/sops/<filename>` copy); user selects per file or globally for the directory.

- [x] 2.7 Modify `skills/project-claude-organizer/SKILL.md` — add Step 3b detail block for
  `templates/` pattern: match = directory named `templates`, strategy = `copy`, destination =
  `docs/templates/<filename>` per file at immediate `templates/` level; skip if destination exists.

- [x] 2.8 Modify `skills/project-claude-organizer/SKILL.md` — add Step 3b detail block for
  `project.md` and `readme.md` patterns: match = root-level `.md` file named `project.md` or
  `readme.md` (case-insensitive), strategy = `section-distribute`, routing heuristic =
  `STACK_HEADING_SIGNALS` → `ai-context/stack.md`, `ARCH_HEADING_SIGNALS` →
  `ai-context/architecture.md`, `ISSUES_HEADING_SIGNALS` → `ai-context/known-issues.md`; each
  mapped section requires per-section user confirmation; append strategy with labeled separator.
  Define the three signal lists as specified in the design:
  - `STACK_HEADING_SIGNALS = ["## Tech Stack", "## Stack", "## Dependencies", "## Tools"]`
  - `ARCH_HEADING_SIGNALS = ["## Architecture", "## System Design", "## Overview"]`
  - `ISSUES_HEADING_SIGNALS = ["## Known Issues", "## Issues", "## Gotchas", "## Limitations"]`

---

## Phase 3: Step 4 — Dry-Run Plan Extension

Extend the existing Step 4 plan format to include a "Legacy migrations" section and update the
plan condition check to account for LEGACY_MIGRATIONS.

- [x] 3.1 Modify `skills/project-claude-organizer/SKILL.md` — update the Step 4 no-op condition
  check (currently "If `MISSING_REQUIRED` is empty AND `UNEXPECTED` is empty AND
  `DOCUMENTATION_CANDIDATES` is empty") to also require `LEGACY_MIGRATIONS` is empty before
  declaring no reorganization needed.

- [x] 3.2 Modify `skills/project-claude-organizer/SKILL.md` — insert a `Legacy migrations`
  section into the Step 4 plan format template, positioned between the "Documentation to migrate"
  section and the "Unexpected items" section. The section MUST list each entry in
  `LEGACY_MIGRATIONS` with: source path (relative to `PROJECT_CLAUDE_DIR`), proposed
  destination(s), migration strategy label, and a note that source files are never deleted.
  The section MUST be omitted entirely when `LEGACY_MIGRATIONS` is empty (consistent with the
  existing pattern of omitting zero-item categories). Include the note that each category requires
  per-category confirmation in Step 5.7.

---

## Phase 4: Step 5.7 — Apply Logic for Legacy Migrations

Add the new sub-step 5.7 to the Step 5 apply section, immediately after the existing sub-step 5.6.
Implement each of the 8 per-strategy handlers in execution order: delegate → section-distribute →
copy → append → scaffold → user-choice.

- [x] 4.1 Modify `skills/project-claude-organizer/SKILL.md` — add Step 5.7 preamble: "Apply
  legacy migrations (per-category confirmation gates). Process categories in strategy execution
  order: delegate → section-distribute → copy → append → scaffold → user-choice. For each
  category: present full file list and proposed destinations; prompt `Apply <category> migrations?
  (yes/no/all)`; if `no`, skip category entirely and record `<category> — skipped by user (no
  files written)`; if `yes` or `all`, apply strategy."

- [x] 4.2 Modify `skills/project-claude-organizer/SKILL.md` — add Step 5.7.1 (`delegate` —
  `commands/`): read each `.md` file at the immediate `commands/` level (no recursion); apply
  4 qualifying markers; for qualifying files: output advisory "deploy.md — qualifying workflow
  detected. Suggested skill name: <stem>. Suggested format: procedural. To scaffold:
  /skill-create <stem>" — NO file write; for non-qualifying files: record
  "<filename> — non-qualifying — recommend archival" — NO file write; if no `.md` files found:
  output "commands/ — no .md files found at immediate level; nothing to advise". Source files
  are NEVER touched.

- [x] 4.3 Modify `skills/project-claude-organizer/SKILL.md` — add Step 5.7.2
  (`section-distribute` — `project.md`, `readme.md`): read file's section headings; map to
  destination files using heading signal lists; for each mapped section: present section content
  to user and request per-section confirmation before appending; append under labeled separator
  `<!-- appended from .claude/<filename> YYYY-MM-DD -->`; if destination file does not exist,
  create it with the appended content. Source file is NEVER deleted or modified.

- [x] 4.4 Modify `skills/project-claude-organizer/SKILL.md` — add Step 5.7.3 (`copy` — `docs/`
  and `templates/`):
  - `docs/`: copy each `.md` file at immediate `docs/` level to `ai-context/features/<name>.md`;
    ensure `ai-context/features/` directory exists before copy; if destination exists: record
    `<name>.md — skipped (destination exists)`; if destination absent: copy and record
    `<name>.md — copied to ai-context/features/<name>.md`. Source files NEVER deleted.
  - `templates/`: copy each file at immediate `templates/` level to `docs/templates/<filename>`;
    ensure `docs/templates/` directory exists; if destination exists: skip and record; if absent:
    copy and record. Source files NEVER deleted.

- [x] 4.5 Modify `skills/project-claude-organizer/SKILL.md` — add Step 5.7.4 (`append` —
  `system/`): route `architecture.md` → append to `ai-context/architecture.md`; route
  `database.md` and `api-overview.md` → append to `ai-context/stack.md`; each append block
  MUST begin with separator `<!-- appended from .claude/system/<filename> YYYY-MM-DD -->`;
  if destination does not exist: create it with the appended content; record each operation as
  `<filename> — appended to <destination> (separator added)`. Source files NEVER deleted.

- [x] 4.6 Modify `skills/project-claude-organizer/SKILL.md` — add Step 5.7.5 (`scaffold` —
  `requirements/`): for each `.md` file at immediate `requirements/` level: derive `<slug>` from
  filename stem; construct scaffold path `openspec/changes/<YYYY-MM-DD>-<slug>/proposal.md`;
  if path already exists: record `<slug> — scaffold skipped (proposal.md already exists)`;
  if path does not exist: create directory and write minimal scaffold:
  ```
  # Proposal: <slug>

  ## Problem Statement

  <!-- Describe the problem to be solved. -->

  ## Proposed Solution

  <!-- Describe the proposed approach. -->

  ## Success Criteria

  - [ ]
  ```
  Record `<slug> — scaffolded to openspec/changes/<date>-<slug>/proposal.md`. Source files
  NEVER deleted.

- [x] 4.7 Modify `skills/project-claude-organizer/SKILL.md` — add Step 5.7.6 (`user-choice` —
  `sops/`): for each `.md` file at immediate `sops/` level: present choice:
  "Option A: append as a named section in `ai-context/conventions.md`" /
  "Option B: copy to `docs/sops/<filename>`"; user selects per file or can select
  "apply option A to all" / "apply option B to all"; execute selection:
  - Option A: append `## <stem from filename>` section to `ai-context/conventions.md` under
    labeled separator; create `ai-context/conventions.md` if absent.
  - Option B: copy file to `docs/sops/<filename>`; create `docs/sops/` directory if absent;
    skip if destination exists and record.
  Source files NEVER deleted.

- [x] 4.8 Modify `skills/project-claude-organizer/SKILL.md` — add Step 5.7.7 (`copy` — `plans/`):
  for each item at immediate `plans/` level: present item to user and ask "Is this an active plan
  or archived plan? (active/archived)"; route active → `openspec/changes/<plan-name>/`; route
  archived → `openspec/changes/archive/<plan-name>/`; create directory at destination if absent;
  copy item contents to destination directory; if destination directory already exists: record
  `<plan-name> — skipped (destination exists)`; record outcome per item. Source files NEVER
  deleted.

---

## Phase 5: Step 6 — Report Format Extension

Extend the Step 6 report template to include the "Legacy migrations" subsection, extend the
summary line, and add conditional recommended next steps for legacy migration outcomes.

- [x] 5.1 Modify `skills/project-claude-organizer/SKILL.md` — add `### Legacy migrations`
  subsection to the Step 6 report template, positioned after `### Documentation copied to
  ai-context/` (if present) and before `### Unexpected items (not modified)`. The subsection MUST:
  - Document each legacy category processed with per-file outcome lines (applied, skipped,
    advisory, non-qualifying, or user-skipped)
  - Include a footer note: "All source files in legacy categories were preserved — no files were
    deleted or moved"
  - Be omitted entirely when `LEGACY_MIGRATIONS` was empty for the run

- [x] 5.2 Modify `skills/project-claude-organizer/SKILL.md` — extend the Step 6 summary line
  format to include `<N> legacy migration(s) applied` when LEGACY_MIGRATIONS was non-empty. The
  count MUST reflect individual file operations (not categories). Advisory-only outcomes from
  `delegate` strategy MUST NOT be counted. Categories with count zero MAY be omitted.
  New format: `<N> item(s) created, <N> documentation file(s) copied, <N> legacy migration(s)
  applied, <N> unexpected item(s) flagged, <N> already correct`

- [x] 5.3 Modify `skills/project-claude-organizer/SKILL.md` — add conditional guidance items to
  the `## Recommended Next Steps` section template in Step 6 for each applicable legacy strategy:
  - If `commands/` delegate advisories produced: "Review the commands/ advisory list above —
    invoke /skill-create <name> for each qualifying file to scaffold a new skill"
  - If `section-distribute` applied to `project.md`/`readme.md`: "Review the distributed sections
    in the destination ai-context/ files — verify content is correctly placed"
  - If `append` applied to `system/`: "Review the appended content in the ai-context/ destination
    file(s) — merge or deduplicate manually if the appended section overlaps with existing content"
  - If `scaffold` produced proposals from `requirements/`: "Populate the scaffold proposals in
    openspec/changes/ before running /sdd-apply"
  - If `sops/` was processed: "Verify the conventions section or docs/sops/ directory was
    correctly populated"

---

## Phase 6: Post-Apply Cleanup

- [x] 6.1 Run `bash install.sh` from `C:/Users/juanp/claude-config` — deploy the updated
  `skills/project-claude-organizer/SKILL.md` to `~/.claude/skills/project-claude-organizer/SKILL.md`.
  Verify the file exists at the deployed path and its content matches the repo version.

- [x] 6.2 Update `ai-context/changelog-ai.md` — append an entry recording that
  `skills/project-claude-organizer/SKILL.md` was modified to add the Legacy Directory Intelligence
  layer (Step 3b), extend Step 4 dry-run plan, add Step 5.7 migration apply handlers, and extend
  Step 6 report format.

---

## Implementation Notes

- The entire change is confined to one file: `skills/project-claude-organizer/SKILL.md`. No other
  file is created or modified during the apply phase (except `ai-context/changelog-ai.md` in 6.2
  and the install.sh deployment in 6.1).
- The open question from design.md about `plans/` active vs. archived classification is resolved
  as follows: the skill asks the user per item at apply time (Step 5.7.7) — no heuristic, user
  decides.
- The `commands/` qualifying markers (task 4.2) must use exactly the 4 signals from the
  skill-orchestration spec: step-numbered sections, trigger/invocation patterns,
  `## Process`/`## Steps`/`## How to`/`## Instructions` headings, filename-stem keywords.
  No additional heuristics.
- All Step 5.7 sub-steps MUST enforce the additive invariant: source files are NEVER deleted,
  moved, or overwritten under any circumstance.
- The per-category confirmation gate in Step 5.7 supports `all` as a shorthand to confirm all
  remaining categories — this is the design's resolution for not multiplying prompts excessively.
- Phase 2 tasks (2.1–2.8) are independent of each other and can be applied in any order within
  Phase 2, but all must complete before Phase 3.
- Phase 3 task 3.1 (no-op condition update) must be applied before 3.2 (plan format) to ensure
  the guard logic is correct.
- Phase 4 tasks (4.2–4.8) are each independent apply-handler additions; they depend on 4.1
  (preamble) being in place first.

## Blockers

None.
