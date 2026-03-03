# Proposal: smart-commit-functional-split

Date: 2026-03-03
Status: Draft

## Intent

Extend the `smart-commit` skill to analyze staged files by functional area and propose separate, semantically grouped commits instead of always committing everything as a single block.

## Motivation

The current `smart-commit` skill commits all staged files in one shot. This works for small, focused changes but creates two problems in practice:

1. **Semantic pollution**: files from unrelated features or layers end up in the same commit, making history harder to read and bisect harder to apply.
2. **Silent omissions**: when a developer stages a large mixed set, some files get lumped under an incorrect type or scope, or — worse — are left out because there is no grouping logic to surface them as a distinct unit.

The user explicitly identified this gap: files are sometimes left out of commits, and the skill provides no grouping logic to surface them as separate, intentional units.

Git best practice is one logical change per commit. The skill should enforce this by detecting functional groups in the staged set and proposing one commit per group, not one commit for everything.

## Scope

### Included

- Add a **file grouping step** in `smart-commit` that clusters staged files by functional area (directory, conventional prefix, file type) before generating commit messages.
- Generate one **proposed commit per group**, each with its own `type(scope): summary` and bullet body.
- Present a **multi-commit plan** to the user for review before executing any commit.
- Execute commits **sequentially** in the order presented, confirming with the user after each one or offering a "commit all" path.
- Handle the **edge case** where all staged files belong to a single functional group — in that case, the existing single-commit flow is preserved unchanged.

### Excluded (explicitly out of scope)

- Auto-staging unstaged or untracked files — the skill only operates on `git diff --cached`, as today.
- Reordering or amending commits after they are executed — this is a separate responsibility.
- Interactive rebase or squash logic — out of scope for this change.
- Any UI beyond the existing text-based summary format — no TUI or interactive picker.
- Parallelizing commit execution — commits must be sequential (git requires a linear history).

## Proposed Approach

The grouping logic runs between the current Step 1 (read staged state) and Step 2 (analyze changes). A new **Step 1b — Group staged files** is inserted:

1. Parse the file list from `git diff --cached --stat`.
2. Apply a grouping heuristic in priority order:
   - **Directory prefix**: files sharing a common top-level directory (e.g., `skills/smart-commit/`, `docs/adr/`) belong to the same group.
   - **Conventional suffix**: test files (`*.test.*`, `*.spec.*`, `_test.*`) form their own group regardless of directory.
   - **Config/infra files**: root-level config files (`*.json`, `*.yaml`, `*.toml`, `*.sh`, `*.env*`) form a `chore` group.
   - **Docs files**: files under `docs/`, `*.md` at root, `README*` form a `docs` group.
3. If the result is a single group, fall through to the existing single-commit flow (no behavior change).
4. If the result is multiple groups, present a multi-commit plan and execute sequentially.

This approach requires no external dependencies and no changes to the underlying `git commit` command format. The conventional commit message generation per group reuses the existing Step 2 logic applied independently to each group's diff.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/smart-commit/SKILL.md` | Modified | High — core skill logic changes |
| `hooks/smart-commit-context.js` | None expected | Low — hook provides context, not commit logic |
| `openspec/specs/smart-commit/spec.md` | New (created by sdd-spec) | Medium — formalizes expected behavior |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Grouping heuristic produces too many groups for simple changes | Medium | Medium | Single-group fast-path preserves existing behavior; user reviews plan before any commit fires |
| Multi-commit flow is harder to abort mid-way | Low | Medium | Present full plan upfront; offer "abort all" at every confirmation step |
| Grouping logic misidentifies file ownership (e.g., a root-level file that belongs to a feature) | Medium | Low | User reviews each proposed message before confirmation; edit-message option is preserved per commit |
| Sequential commits create a partial state if the user aborts mid-sequence | Low | Medium | Document clearly in the plan which commits have fired and which are pending; user can manually commit the rest |

## Rollback Plan

The change affects only `skills/smart-commit/SKILL.md`. To revert:

1. `git log --oneline skills/smart-commit/SKILL.md` — identify the commit before this change.
2. `git checkout <commit-hash> -- skills/smart-commit/SKILL.md` — restore the prior version.
3. Run `install.sh` to redeploy `~/.claude/skills/smart-commit/SKILL.md`.
4. Verify with a test commit in any project.

No database migrations, no API changes, no dependency updates — rollback is a single file restore.

## Dependencies

- No external dependencies.
- The existing `smart-commit` skill at `skills/smart-commit/SKILL.md` must be read as baseline before writing the new version.
- `sdd-spec` and `sdd-design` phases should run before `sdd-apply` to define the grouping algorithm precisely.

## Success Criteria

- [ ] When staged files span two or more functional directories, `smart-commit` proposes separate commits per group (one message per group, presented before any commit fires).
- [ ] When all staged files share a single functional area, `smart-commit` behaves identically to the current version (single commit, same format).
- [ ] The user can review, edit, or abort each proposed commit message independently before it executes.
- [ ] No files are silently omitted: every staged file appears in exactly one proposed group.
- [ ] The skill continues to block on ERROR conditions (secrets, `.env` files) per existing rules.
- [ ] The updated `SKILL.md` passes `format: procedural` section-contract validation (Triggers, Process, Rules present).

## Effort Estimate

Medium (1–2 days) — the logic is contained within one SKILL.md file, but requires careful specification of the grouping heuristic and thorough testing across mixed-change scenarios.
