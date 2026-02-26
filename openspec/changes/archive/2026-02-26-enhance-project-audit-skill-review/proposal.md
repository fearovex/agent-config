# Proposal: enhance-project-audit-skill-review

Date: 2026-02-26
Status: Draft

## Intent

Extend `project-audit` with a new Dimension 9 that audits project-local `.claude/skills/` quality against the global catalog, add corresponding fix handlers to `project-fix`, and document the external project onboarding workflow in `ai-context/` — closing three gaps that block large-scale SDD migration of external projects.

## Motivation

The user is preparing to migrate multiple external projects to SDD. The current toolchain has three concrete gaps that will produce incorrect or incomplete audit results and leave users without guidance:

**Gap A — project-audit ignores local skill quality.**
When an external project is onboarded, it may have a `.claude/skills/` directory populated with skills that:
- Duplicate skills already present in the global `~/.claude/skills/` catalog (redundant maintenance burden)
- Are missing required structural sections (trigger, process, rules) — making them non-functional
- Reference outdated technology stack versions or deprecated patterns irrelevant to the project
- Use non-English content, violating the global unbreakable rule

None of these issues are currently detected by `project-audit`. The audit can return a passing score for a project whose local skills are structurally broken or redundant.

**Gap B — No tool exists to rationalize local skills against the global catalog.**
There is no `/skill-cleaner` or equivalent mechanism that compares local project skills against the global catalog and recommends one of four dispositions: move to global, delete, keep, or update. This means the user must manually audit every skill in every migrated project.

**Gap C — No documented onboarding workflow exists.**
The correct sequence for onboarding an existing project to SDD is:
```
/project-setup → /memory-init → /project-audit → /project-fix
```
This sequence is not written down in any ai-context/ file, no skill references it, and new projects (or new team members) have no canonical reference for where to begin.

These three gaps compound each other: a new project gets audited, receives a false-positive score, and the user has no map to follow for the onboarding sequence.

## Scope

### Included

- **New Dimension 9 in `project-audit/SKILL.md`**: "Project Skills Quality" — audits `.claude/skills/` in the target project against:
  - Duplication: does the same skill name exist in `~/.claude/skills/`? (signals a possible redundant copy)
  - Structural completeness: does each local SKILL.md have trigger, process, and rules sections?
  - Language compliance: does each local SKILL.md contain non-English prose headings or body text?
  - Stack relevance: are there skills that reference technologies not present in the project stack?
  - Disposition recommendation: for each skill — keep, update, delete, or move-to-global

- **New fix handlers in `project-fix/SKILL.md`**: Phase handling for Dimension 9 findings:
  - Delete confirmed duplicates (after user confirmation)
  - Add missing structural sections (stub the section with a placeholder, do not fabricate content)
  - Flag irrelevant skills for user review (report only, no auto-delete)
  - Record all actions in `ai-context/changelog-ai.md`

- **Onboarding workflow document**: Add `ai-context/onboarding.md` to the `ai-context/` layer of `claude-config` with the canonical external project onboarding sequence, including prerequisites, step-by-step commands, what each step produces, and how to verify the result.

- **Update `ai-context/architecture.md`**: Add `onboarding.md` to the memory layer artifact table.

- **Update `CLAUDE.md` Skills Registry**: Add `onboarding.md` to the memory layer documentation, if needed.

- **Update `openspec/config.yaml`**: Add `onboarding.md` to `required_artifacts_per_change` only if the workflow document introduces new verification requirements (evaluate at design phase).

### Excluded (explicitly out of scope)

- **`/skill-cleaner` as a standalone new skill**: A new skill would require a full SDD cycle of its own and adds surface area. The disposition recommendations are sufficient for this iteration — they are surfaced in the audit report and handled by project-fix. A dedicated `/skill-cleaner` command is deferred.
- **Auto-translation of non-English skills**: Dimension 9 flags language violations but does not auto-translate. Translation is a content decision that requires human review.
- **Auto-migration of local skills to the global catalog**: Moving a skill to `~/.claude/skills/` changes the global catalog, which is out of scope for a per-project fix operation. The fix handler will only mark the skill for review; actual promotion requires a separate `/sdd-ff` on claude-config itself.
- **Modifying external project files outside `.claude/`**: project-fix only operates within `.claude/` — source code, README files, and non-Claude config are not touched.
- **Scoring changes for Dimension 9**: The new dimension is additive. Its findings generate action items but do not deduct from the existing 100-point score in the first iteration. Score integration can be addressed in a follow-on change once the dimension is validated in practice.

## Proposed Approach

**project-audit — Dimension 9 algorithm:**

1. Detect whether `.claude/skills/` exists in the target project. If absent, skip with a note (not all projects have local skills).
2. For each subdirectory in `.claude/skills/`:
   a. Check disk vs global catalog: does `~/.claude/skills/<name>/SKILL.md` also exist?
   b. Read the local `SKILL.md`. Check for the three required sections: trigger definition (`**Triggers**` line or `## Triggers`), process section (`## Process` or `### Step`), rules section (`## Rules` or `## Execution rules`).
   c. Scan for non-English prose using the same heuristic already defined in D4e of the current audit.
   d. Extract tech references (framework names, version strings) and cross-check against `ai-context/stack.md` or `package.json`.
   e. Emit a disposition recommendation: `keep | update | delete | move-to-global`.
3. Emit findings as a new `## Dimension 9 — Project Skills Quality` section in the audit report, and include actionable items in `FIX_MANIFEST` under a new `skill_quality_actions` key.

**project-fix — Dimension 9 handlers:**

The skill reads `skill_quality_actions` from `FIX_MANIFEST` and handles each type:
- `delete_duplicate`: presents the duplicate to the user with the global counterpart path, asks for confirmation, then deletes.
- `add_missing_section`: appends a stub section (e.g., `## Rules\n\n> TODO: define constraints`) to the local SKILL.md.
- `flag_irrelevant`: adds a comment block at the top of the SKILL.md — `<!-- AUDIT: skill may be irrelevant to current stack -->` — and logs in changelog.
- Records all actions in `ai-context/changelog-ai.md`.

**Onboarding document:**

A new `ai-context/onboarding.md` file documenting the canonical sequence, prerequisites, what each command produces, success criteria per step, and common failure modes. This file is read-only documentation — it is not consumed by any skill programmatically.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/project-audit/SKILL.md` | Modified — new Dimension 9 section added | Medium |
| `skills/project-fix/SKILL.md` | Modified — new Phase 5 (Dimension 9 handlers) added | Medium |
| `ai-context/onboarding.md` | New file | Low |
| `ai-context/architecture.md` | Modified — add onboarding.md to artifact table | Low |
| `CLAUDE.md` | Modified — add onboarding.md to memory layer docs (if applicable) | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Dimension 9 generates false positives (flags a local skill as duplicate when it is intentionally customized) | Medium | Medium | The disposition is a recommendation, not auto-delete. User confirmation required before any deletion. |
| Stack relevance check is too strict and flags valid skills | Medium | Low | Use a conservative heuristic — only flag skills that reference a technology not present in stack.md AND not present in package.json/pyproject.toml. Emit as INFO, not WARNING. |
| FIX_MANIFEST `skill_quality_actions` key breaks existing project-fix parsers | Low | Low | The key is additive. Existing FIX_MANIFEST consumers only read `required_actions`, `missing_global_skills`, `orphaned_changes`, `violations`. Adding a new top-level key does not break those consumers. |
| onboarding.md becomes stale as skills evolve | Medium | Low | Add a "Last verified" date field to onboarding.md. Flag for update in changelog-ai.md whenever a referenced skill changes. |

## Rollback Plan

All changes are additive modifications to two existing SKILL.md files and the creation of one new file:

1. **Revert `skills/project-audit/SKILL.md`**: Remove the `### Dimension 9` section and associated scoring table row. The file had a clean state in git before this change — `git checkout HEAD~1 -- skills/project-audit/SKILL.md`.
2. **Revert `skills/project-fix/SKILL.md`**: Remove the `#### Phase 5` section. Same git rollback pattern.
3. **Delete `ai-context/onboarding.md`**: `rm ai-context/onboarding.md`.
4. **Revert `ai-context/architecture.md`**: Remove the onboarding.md row from the artifact table.
5. Run `sync.sh` and `install.sh` after revert to propagate changes to `~/.claude/`.

No database migrations, no dependency changes, no external system calls. Rollback is a pure file operation.

## Dependencies

- The current `project-audit` score must be >= 96/100 before starting (confirmed: score is 96/100 as of 2026-02-25).
- The existing D4e language-compliance heuristic in `project-audit/SKILL.md` must be reused (not duplicated) in Dimension 9. The design phase must confirm the exact heuristic text to reference.
- `project-fix` Phase 4 (Low corrections) must already be functional — Phase 5 will follow the same confirmation-before-action pattern.
- `ai-context/architecture.md` must be updated atomically with `onboarding.md` creation so the artifact table never goes out of sync.

## Success Criteria

- [ ] Running `/project-audit` on a project that has a `.claude/skills/` directory with at least one duplicate of a global skill produces a Dimension 9 section in the report listing that skill with disposition `delete` or `move-to-global`.
- [ ] Running `/project-audit` on a project whose local SKILL.md is missing a `## Rules` section produces a Dimension 9 finding with disposition `update` and an action item in `FIX_MANIFEST.skill_quality_actions`.
- [ ] Running `/project-fix` on a report containing `skill_quality_actions.delete_duplicate` prompts the user for confirmation and, upon approval, deletes the local skill directory and records the action in `changelog-ai.md`.
- [ ] Running `/project-fix` on a report containing `skill_quality_actions.add_missing_section` adds the stub section to the local SKILL.md without overwriting existing content.
- [ ] `ai-context/onboarding.md` exists in the repo and documents the four-step onboarding sequence with at least one verifiable success criterion per step.
- [ ] `/project-audit` run on `claude-config` itself after applying this change returns a score >= 96/100.
- [ ] `sync.sh` completes without errors after all changes are applied.

## Effort Estimate

Medium (1-2 days) — two existing SKILL.md files require careful surgical edits, one new documentation file, and integration testing against the Audiio V3 test project to validate Dimension 9 detects real issues.
