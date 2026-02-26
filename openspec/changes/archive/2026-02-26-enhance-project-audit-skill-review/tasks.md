# Task Plan: enhance-project-audit-skill-review

Date: 2026-02-26
Design: openspec/changes/enhance-project-audit-skill-review/design.md

## Progress: 12/14 tasks

---

## Phase 1: Audit Extension — Dimension 9 in project-audit/SKILL.md

- [x] 1.1 Modify `skills/project-audit/SKILL.md` — append the `### Dimension 9 — Project Skills Quality` section header and its D9-1 sub-check: detect whether `.claude/skills/` exists in the target project; if absent, emit the skip note `No .claude/skills/ directory found — Dimension 9 skipped.` and proceed without score deduction
- [x] 1.2 Modify `skills/project-audit/SKILL.md` — append the D9-2 sub-check: for each subdirectory in `.claude/skills/`, perform an exact directory-name match against `~/.claude/skills/<name>/`; if matched, assign candidate disposition `delete` or `move-to-global`; if catalog is unreadable, emit `Global catalog unreadable — duplicate check skipped` at INFO level and assign disposition `keep`
- [x] 1.3 Modify `skills/project-audit/SKILL.md` — append the D9-3 sub-check: read each local `SKILL.md` and search for (a) `**Triggers**` or `## Triggers`, (b) `## Process` or `### Step`, (c) `## Rules` or `## Execution rules`; list any missing sections per skill, assign disposition `update`, and flag `add_missing_section` action; handle the edge case where no `SKILL.md` exists in the directory
- [x] 1.4 Modify `skills/project-audit/SKILL.md` — append the D9-4 sub-check: apply the D4e language-compliance heuristic (reference by name, do not duplicate) to each local `SKILL.md` body text outside fenced code blocks; non-English prose found → disposition `update`, action `flag_language_violation`, INFO only
- [x] 1.5 Modify `skills/project-audit/SKILL.md` — append the D9-5 sub-check: extract tech references from local `SKILL.md` trigger/title; if a technology is absent from BOTH `ai-context/stack.md` AND `package.json`/`pyproject.toml`, emit an INFO-level `flag_irrelevant` action; skip the check entirely if neither stack source is found and note `Stack relevance check skipped — no stack source found`
- [x] 1.6 Modify `skills/project-audit/SKILL.md` — append the D9 report-format block: (a) the `## Dimension 9 — Project Skills Quality` section template matching the format specified in design.md (table with columns Skill / Duplicate of global / Structural complete / Language OK / Stack relevant / Disposition), (b) the `skill_quality_actions` key definition added to the FIX_MANIFEST format block, (c) a D9 row in the score table with value `N/A` (no deduction in iteration 1)

## Phase 2: Fix Handler Extension — Phase 5 in project-fix/SKILL.md

- [x] 2.1 Modify `skills/project-fix/SKILL.md` — append the `#### Phase 5 — Dimension 9 Corrections (Project Skills Quality)` header and the manifest-parsing logic: read `skill_quality_actions` from FIX_MANIFEST; if the key is absent or the list is empty, skip Phase 5 silently; otherwise present the Phase 5 checkpoint to the user: `Phase 5 — Skill Quality Actions: [N] pending. Proceed? [Y/n]`
- [x] 2.2 Modify `skills/project-fix/SKILL.md` — append the `delete_duplicate` handler: display local path and global counterpart, prompt `Delete local copy? [y/N]`, on `y` delete `.claude/skills/<name>/` recursively, on `N` mark `skipped (user declined)`, if directory no longer exists mark `skipped (already deleted)`; log all outcomes to `ai-context/changelog-ai.md`
- [x] 2.3 Modify `skills/project-fix/SKILL.md` — append the `add_missing_section` handler: for each missing section in the action entry, check idempotency (section already present → mark `skipped (section already present)`), if file missing → mark `failed (file not found)` and notify user; otherwise append the appropriate stub (Triggers / Process / Rules) as specified in the design and spec, preserving all existing content; log to `ai-context/changelog-ai.md`
- [x] 2.4 Modify `skills/project-fix/SKILL.md` — append the `flag_irrelevant` handler: insert the comment block `<!-- AUDIT: skill may be irrelevant to current stack — review and remove if not needed -->` as the first line of the target `SKILL.md`; check idempotency (comment already present → mark `skipped (already flagged)`); no user confirmation required; log to `ai-context/changelog-ai.md`. Append the `flag_language_violation` handler: record in `ai-context/changelog-ai.md`, notify user that manual translation is required, do NOT modify the SKILL.md file. Append the `move-to-global` informational message: emit `Manual action required — see proposal for promotion workflow` with no automated action

## Phase 3: Documentation and Memory Layer Updates

- [x] 3.1 Create `ai-context/onboarding.md` — new file containing: (a) `Last verified: 2026-02-26` field, (b) prerequisites section with four concrete verifiable checks (Claude Code installed, global skills present at `~/.claude/skills/sdd-*/SKILL.md`, target project accessible, `install.sh` run at least once), (c) the canonical four-step onboarding sequence (`/project-setup → /memory-init → /project-audit → /project-fix`) with one-sentence description and at least one verifiable success criterion per step, (d) at least one documented failure mode per step with a recovery action
- [x] 3.2 Modify `ai-context/architecture.md` — add a row for `onboarding.md` to the "Communication between skills via artifacts" table with description `Canonical external project onboarding sequence`; add atomically with task 3.1 (both must be applied in the same implementation batch)

## Phase 4: Integration Verification

- [ ] 4.1 Run `/project-audit` on `claude-config` itself after applying all changes — verify score is >= 96/100; verify Dimension 9 either emits the skip note (no `.claude/skills/` in root) or produces no blocking findings; verify the audit-report.md file is updated at `C:/Users/juanp/claude-config/.claude/audit-report.md`
- [ ] 4.2 Run `sync.sh` — verify it completes without errors and that `~/.claude/skills/project-audit/SKILL.md`, `~/.claude/skills/project-fix/SKILL.md`, and `~/.claude/ai-context/onboarding.md` reflect all changes

---

## Implementation Notes

- All modifications to `skills/project-audit/SKILL.md` and `skills/project-fix/SKILL.md` are append-only — existing content must not be reordered or removed
- Dimension 9 MUST follow the identical structural pattern of D1–D8 in project-audit/SKILL.md; read those existing dimensions before appending to match formatting exactly
- Phase 5 in project-fix/SKILL.md MUST follow the Phase 1–4 checkpoint pattern; read those existing phases before appending to match formatting exactly
- The D4e language heuristic in project-audit/SKILL.md is referenced by name in D9 — do NOT copy-paste its implementation into D9
- The D9 score table row MUST display `N/A` (not a numeric value) to prevent any score impact in iteration 1
- The `add_missing_section` handler MUST be idempotent: re-running project-fix a second time on the same file must not add a duplicate stub section
- Tasks 3.1 and 3.2 must be applied atomically — do not create `onboarding.md` without also updating `architecture.md` in the same pass
- The `move-to-global` disposition in Phase 5 has no automated handler; an explicit informational message is required so users are not left without guidance

## Blockers

None. All dependent artifacts (design.md, specs/) are complete. The current project-audit score of 96/100 satisfies the pre-condition stated in the proposal dependencies.
