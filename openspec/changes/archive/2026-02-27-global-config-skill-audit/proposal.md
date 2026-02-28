# Proposal: global-config-skill-audit

Date: 2026-02-27
Status: Draft

## Intent

Update the `project-audit` skill so that Dimensions 9 and 10 correctly audit a global-config repo by treating the root-level `skills/` directory as equivalent to `.claude/skills/` when the project is detected as a global-config repo.

## Motivation

When `/project-audit` runs against the `claude-config` repo itself, Dimensions 9 (Project Skills Quality) and 10 (Feature Docs Coverage) silently skip because their heuristics look exclusively for `.claude/skills/`. In the global-config repo the skill catalog lives at `skills/` (root), not `.claude/skills/`. This means:

- D9 emits "No .claude/skills/ directory found — Dimension 9 skipped." even though 43 skill directories exist and are fully auditable.
- D10 heuristic also finds no `.claude/skills/` and, with no other feature sources, emits "No feature directories detected — Dimension 10 skipped."

Both dimensions carry actionable quality information about the global skill catalog and are left blank every time the tool is run on its own host repo. The global-config repo is a first-class audit target and deserves full-dimension coverage.

## Scope

### Included

- Add global-config repo detection logic to D9's skip condition, substituting `skills/` (root) for `.claude/skills/` when the global-config pattern is confirmed.
- Add global-config repo detection logic to D10's heuristic, substituting `skills/` (root) for `.claude/skills/` in Source 1.
- Update the Phase A discovery script template (Rule 8) to emit a new variable `LOCAL_SKILLS_DIR` that resolves to the effective local skills path (`skills/` vs `.claude/skills/`) so D9 and D10 can consume it without re-running detection logic.
- Document the detection condition and the path substitution in the SKILL.md prose for D9 and D10.

### Excluded (explicitly out of scope)

- No changes to D4 (Skills registry) — D4 already works correctly for global-config repos (it checks the CLAUDE.md registry which already lists the `~/.claude/skills/` paths).
- No changes to D1 through D8 heuristics — those dimensions already have global-config awareness or do not depend on the skills path.
- No changes to any skill other than `project-audit/SKILL.md`.
- No changes to `openspec/config.yaml` — the detection relies on existing fields (`install.sh` + `sync.sh` at root, or `framework: "Claude Code SDD meta-system"` in config.yaml), not on a new config key.

## Proposed Approach

The fix is localized to `~/.claude/skills/project-audit/SKILL.md` (source of truth: `skills/project-audit/SKILL.md` in the repo):

1. **Phase A script extension**: Add a variable `LOCAL_SKILLS_DIR` to the Phase A bash template. Logic:
   ```sh
   if [ "$INSTALL_SH_EXISTS" = "1" ] && [ "$SYNC_SH_EXISTS" = "1" ]; then
     LOCAL_SKILLS_DIR="skills"
   elif grep -q 'Claude Code SDD meta-system' "$PROJECT/openspec/config.yaml" 2>/dev/null; then
     LOCAL_SKILLS_DIR="skills"
   else
     LOCAL_SKILLS_DIR=".claude/skills"
   fi
   echo "LOCAL_SKILLS_DIR=$LOCAL_SKILLS_DIR"
   ```

2. **D9 skip condition update**: Replace the hardcoded `.claude/skills/` path check with `$LOCAL_SKILLS_DIR`. The skip condition becomes: "If `$LOCAL_SKILLS_DIR` does not exist → skip D9."

3. **D10 heuristic Source 1 update**: Replace `if .claude/skills/ exists` with `if $LOCAL_SKILLS_DIR exists` in the Source 1 block of the heuristic algorithm.

4. **D10 check D10-a and D10-d path update**: When `LOCAL_SKILLS_DIR=skills` (global-config), the coverage check for convention=skill should look for `skills/<feature_name>/SKILL.md` instead of `.claude/skills/<feature_name>/SKILL.md`. Similarly, D10-d registry alignment still reads the root CLAUDE.md (already correct for global-config).

The approach requires no new bash calls — `LOCAL_SKILLS_DIR` is emitted by the existing Phase A script block, keeping total bash calls ≤ 3.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/project-audit/SKILL.md` — Phase A script template (Rule 8) | Modified | Medium |
| `skills/project-audit/SKILL.md` — D9 skip condition prose | Modified | Low |
| `skills/project-audit/SKILL.md` — D10 heuristic Source 1 prose | Modified | Low |
| `skills/project-audit/SKILL.md` — D10-a and D10-d path references | Modified | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Phase A script variable `LOCAL_SKILLS_DIR` not propagated correctly to D9/D10 in Phase B | Low | Medium | Explicit variable documentation in the Phase A output key schema; test against claude-config itself |
| D9 duplicate detection against global catalog becomes circular when auditing the global-config repo (local skills ARE the global catalog) | Medium | Low | Document as expected behavior: all skills will show "no global counterpart" or "identical to global" — this is correct since they ARE global. Disposition defaults to `keep`. |
| D10 Source 1 now produces 43 features for the global-config repo; table may be very long | Low | Low | No functional risk; D10 is informational and the table is expected to be large |

## Rollback Plan

The change is isolated to a single file: `skills/project-audit/SKILL.md` in the repo (deployed to `~/.claude/skills/project-audit/SKILL.md` via `install.sh`).

To revert:
1. `git revert HEAD` (or restore the previous version of `skills/project-audit/SKILL.md` from git history)
2. Run `install.sh` to redeploy the previous version to `~/.claude/`
3. Confirm by running `/project-audit` against claude-config: D9 and D10 should again emit "skipped"

## Dependencies

- The existing global-config detection pattern in D1 (Condition A and B) is reused verbatim — no new detection logic is invented.
- `INSTALL_SH_EXISTS` and `SYNC_SH_EXISTS` are already emitted by the Phase A script — the new `LOCAL_SKILLS_DIR` logic depends on them being computed first.

## Success Criteria

- [ ] Running `/project-audit` against `C:/Users/juanp/claude-config` produces D9 output with at least one skill listed (not "skipped").
- [ ] Running `/project-audit` against `C:/Users/juanp/claude-config` produces D10 output with at least one feature detected (not "skipped").
- [ ] Running `/project-audit` against a standard project (e.g., Audiio V3) still produces correct D9 and D10 behavior using `.claude/skills/`.
- [ ] Audit score for claude-config does not decrease after the change (D9 and D10 are informational only — no score impact expected).
- [ ] `install.sh` deploys the updated SKILL.md to `~/.claude/skills/project-audit/SKILL.md` without errors.

## Effort Estimate

Low (hours) — single file change, well-scoped to two prose sections and one bash template block.
