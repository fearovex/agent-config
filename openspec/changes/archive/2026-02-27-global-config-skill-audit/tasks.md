# Task Plan: global-config-skill-audit

Date: 2026-02-27
Design: openspec/changes/global-config-skill-audit/design.md

## Progress: 7/7 tasks

## Phase 1: Extend Phase A Script

- [x] 1.1 Modify `skills/project-audit/SKILL.md` — locate the Rule 8 Phase A Bash script template and insert the `LOCAL_SKILLS_DIR` detection block immediately after the `SYNC_SH_EXISTS` assignment line and before the `ORPHANED_CHANGES` block:
  ```sh
  # Global-config detection for LOCAL_SKILLS_DIR
  if [ "$INSTALL_SH_EXISTS" = "1" ] && [ "$SYNC_SH_EXISTS" = "1" ]; then
    LOCAL_SKILLS_DIR="skills"
  elif grep -q 'Claude Code SDD meta-system' "$PROJECT/openspec/config.yaml" 2>/dev/null; then
    LOCAL_SKILLS_DIR="skills"
  else
    LOCAL_SKILLS_DIR=".claude/skills"
  fi
  echo "LOCAL_SKILLS_DIR=$LOCAL_SKILLS_DIR"
  ```

- [x] 1.2 Modify `skills/project-audit/SKILL.md` — add `LOCAL_SKILLS_DIR` to the Phase A output key schema table (the section that documents which keys the script emits), inserting: `LOCAL_SKILLS_DIR — string: "skills" (global-config detected) or ".claude/skills" (standard project)`

## Phase 2: Update Dimension 9

- [x] 2.1 Modify `skills/project-audit/SKILL.md` — update the D9-1 skip condition block to replace the hardcoded `.claude/skills/` path check with `$LOCAL_SKILLS_DIR`. The updated skip condition prose must read:
  > Check whether `$LOCAL_SKILLS_DIR` exists in the target project. If it does NOT exist: No [value of $LOCAL_SKILLS_DIR] directory found — Dimension 9 skipped. No score deduction. Do not add `skill_quality_actions` to FIX_MANIFEST. If it exists, proceed with D9-2 through D9-5 for each subdirectory found.

- [x] 2.2 Modify `skills/project-audit/SKILL.md` — update the D9 report output format section's local skills directory header line to read:
  > **Local skills directory**: [value of $LOCAL_SKILLS_DIR] — [N skills found | not found — skipped]

## Phase 3: Update Dimension 10

- [x] 3.1 Modify `skills/project-audit/SKILL.md` — update the D10 Source 1 heuristic block to replace the `.claude/skills/` path reference with `$LOCAL_SKILLS_DIR`. The updated block must read:
  ```
  # Source 1: non-SDD skills in $LOCAL_SKILLS_DIR
  if $LOCAL_SKILLS_DIR exists:
      for each subdirectory name in $LOCAL_SKILLS_DIR:
          if name does NOT start with: sdd-, project-, memory-, skill-:
              add to heuristic_sources as type=skill
  ```

- [x] 3.2 Modify `skills/project-audit/SKILL.md` — update the D10-a PASS condition for `convention=skill` to replace `.claude/skills/<feature_name>/SKILL.md` with `$LOCAL_SKILLS_DIR/<feature_name>/SKILL.md`:
  > If convention=skill: PASS (✅) if `$LOCAL_SKILLS_DIR/<feature_name>/SKILL.md` exists; FAIL (⚠️) otherwise

## Phase 4: Deploy and Verify

- [x] 4.1 Run `bash install.sh` from `C:/Users/juanp/claude-config` to deploy the updated `skills/project-audit/SKILL.md` to `~/.claude/skills/project-audit/SKILL.md`. Confirm exit code 0 and that `~/.claude/skills/project-audit/SKILL.md` timestamp is newer than before.

- [x] 4.2 Run `/project-audit` against `C:/Users/juanp/claude-config` and confirm:
  - D9 section is present and lists at least one skill (not "Dimension 9 skipped")
  - D10 section is present and lists at least one feature (not "Dimension 10 skipped")
  - Audit score is >= the pre-change score
  Create `openspec/changes/global-config-skill-audit/verify-report.md` documenting the results.

---

## Implementation Notes

- All seven tasks target a single file: `skills/project-audit/SKILL.md`. Tasks 1.1 through 3.2 are sequential edits to different sections of that file; they must be applied in order to avoid merge conflicts between nearby sections.
- The `LOCAL_SKILLS_DIR` block in Task 1.1 MUST be inserted after `SYNC_SH_EXISTS` is already assigned in the script — the block depends on that variable being present in the same script scope.
- Tasks 4.1 and 4.2 are post-edit deployment steps. Task 4.2 cannot be performed until Task 4.1 completes successfully.
- D10-d (registry alignment reads root CLAUDE.md) requires no change — it is already correct for global-config repos per the design.
- The circular detection scenario for D9 (local skills are the global catalog) is documented expected behavior: all `skills/` entries will show a matching `~/.claude/skills/` counterpart and default to `keep` disposition.

## Blockers

None.
