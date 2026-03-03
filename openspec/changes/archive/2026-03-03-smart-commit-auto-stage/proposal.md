# Proposal: smart-commit-auto-stage

Date: 2026-03-03
Status: Draft

## Intent

Eliminate the mandatory `git add` prerequisite by having smart-commit detect all modified and untracked files from the full working tree, group them, present an interactive staging+commit plan, and auto-stage only the groups the user confirms.

## Motivation

Currently, smart-commit halts with "No staged files found" if the user runs it before staging. This forces a manual `git add` step that is conceptually redundant: the user already knows they want to commit their work, and the skill already knows how to group and commit. The friction is unnecessary.

Beyond convenience, the existing design contains a subtle correctness gap: a user who selects a subset of staged files for multi-group commit cannot un-stage the groups they skip. With auto-staging, groups the user rejects are never staged in the first place, so no cleanup is needed.

The change also aligns smart-commit with the way developers actually work — iterate on a feature, then commit in one gesture with intelligent grouping — without breaking the existing single-commit or multi-commit flows.

## Scope

### Included

- Replace Step 1 "Read staged state" with a new Step 1 that reads the full working tree state via `git status --porcelain` and collects three file categories: already-staged (A/M/R/D in index column), unstaged modified (M/D in worktree column), and untracked (?? prefix).
- Apply the existing grouping heuristic (test → chore → docs → directory prefix → misc) to ALL detected files regardless of their staging status.
- Enhance the multi-commit plan display (Step 1c) to show each file's staging status: a visual marker that distinguishes already-staged files from unstaged/untracked files within each group.
- Change the commit execution step (Step 5) to run `git add <files>` for any unstaged/untracked files in each group before executing `git commit` — but only for groups the user has confirmed.
- Preserve the single-group fast-path: if all detected files resolve to one group, skip the plan display and fall through to the single-commit flow (with auto-staging applied silently before commit).
- Groups the user skips or rejects at the plan level are never staged: their files remain in their original state.
- Update the master spec (`openspec/specs/smart-commit/spec.md`) with new requirements SR-10 through SR-13 covering full working-tree detection, status annotation, selective auto-staging, and skip-preserves-state invariant.
- Update `skills/smart-commit/SKILL.md` to implement the new Step 1 and Step 5 behavior.

### Excluded (explicitly out of scope)

- Interactive per-file selection within a group (the unit of confirmation remains the group, not individual files).
- `git add -p` (patch/hunk-level staging) — that is a separate, independent feature.
- Auto-stashing or resetting worktree state on abort — the skill remains non-destructive after any abort.
- Detecting deleted files not yet staged (`git rm`) — deleted files already show up in `git status --porcelain` and will be handled by the same logic as other unstaged changes; no special behavior needed.
- Changes to the commit message generation algorithm (Step 2) or issue detection rules (Step 3) — those are unchanged.
- Changes to any other skill outside `smart-commit`.

## Proposed Approach

Step 1 is rewritten to call `git status --porcelain` instead of (or in addition to) `git diff --cached --stat`. The porcelain output provides two-column status codes that distinguish staged, unstaged, and untracked files. The grouping heuristic operates on the union of all detected paths.

For each file, a staging-status tag is stored alongside the path (values: `staged`, `unstaged`, `untracked`). This tag flows through grouping and is used in two places:

1. Plan display — each file line is annotated so the user can see at a glance what will be staged by accepting the group.
2. Commit execution — before each group's `git commit`, the skill issues `git add <path>...` for every file in the group tagged `unstaged` or `untracked`. Files already tagged `staged` are left as-is.

For groups the user rejects (skip / abort remaining), no `git add` is ever issued — their files stay untouched.

The single-group fast-path is preserved with one addition: if the single group contains any unstaged or untracked files, the skill announces "Auto-staging N file(s)" before the `git add` call, then proceeds identically to the current flow.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/smart-commit/SKILL.md` | Modified (Step 1, Step 1c, Step 5) | High — core skill behavior changes |
| `openspec/specs/smart-commit/spec.md` | Modified (new requirements SR-10 to SR-13) | Medium — spec grows; existing requirements unchanged |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| User accidentally stages files they did not intend to commit | Medium | Medium | Plan display clearly marks unstaged/untracked files before any staging occurs; user must confirm each group |
| Partially-staged state after an abort leaves the index in an unexpected shape | Low | Low | Skill stages files only for confirmed groups; aborted groups are never touched; partial-execution summary tells the user exactly which files were staged and committed |
| `git status --porcelain` parsing edge cases (spaces in filenames, rename pairs `R old -> new`) | Low | Medium | Rename entries are split on the arrow to extract both old and new paths; both are included in the group to ensure no file is omitted |
| Single-group fast-path silently stages files the user has not reviewed | Low | Medium | The skill prints "Auto-staging N file(s): <list>" before issuing `git add`, giving the user one last chance to abort |

## Rollback Plan

This change affects two files: `skills/smart-commit/SKILL.md` and `openspec/specs/smart-commit/spec.md`.

To revert:
1. `git log --oneline skills/smart-commit/SKILL.md` to find the commit hash before this change.
2. `git checkout <hash> -- skills/smart-commit/SKILL.md` to restore the previous version.
3. `git checkout <hash> -- openspec/specs/smart-commit/spec.md` to restore the previous spec.
4. Run `install.sh` to re-deploy the reverted skill to `~/.claude/`.
5. Commit the revert: `git commit -m "revert(smart-commit): roll back auto-stage change"`.

No database migrations, no external state changes, no side effects outside these two files.

## Dependencies

- The existing `skills/smart-commit/SKILL.md` must be at version 1.0 (the post-functional-split version that implements SR-01 through SR-09). This proposal targets that version.
- `install.sh` must be run after apply to deploy the updated skill to `~/.claude/skills/smart-commit/`.
- No other skills, hooks, or configuration files need to change.

## Success Criteria

- [ ] Running `/commit` (or "smart commit") in a repository with only unstaged/untracked files no longer prints "No staged files found" — it proceeds to group detection and plan presentation.
- [ ] The multi-commit plan display annotates each file with its staging status (staged vs. unstaged/untracked).
- [ ] For each confirmed group, `git add <files>` is issued for unstaged/untracked files before `git commit`; already-staged files are not re-added.
- [ ] For each skipped/aborted group, no `git add` is issued and the files remain in their original state.
- [ ] The single-group fast-path still produces exactly one commit with no multi-commit plan UI, even when the single group contains unstaged or untracked files.
- [ ] All existing SR-01 through SR-09 scenarios in the spec still pass (no regression).
- [ ] The new requirements SR-10 through SR-13 are present in `openspec/specs/smart-commit/spec.md` with at least two scenarios each.

## Effort Estimate

Medium (1–2 days) — the logic changes are concentrated in Step 1 and Step 5 of SKILL.md, plus spec additions. No new infrastructure is required.
