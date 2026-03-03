# Closure: smart-commit-auto-stage

Start date: 2026-03-03
Close date: 2026-03-03

## Summary

Extended `skills/smart-commit/SKILL.md` to detect files from the full working tree (staged, unstaged, and untracked) via `git status --porcelain`, replacing the old `git diff --cached` guard that blocked execution when no files were pre-staged. Auto-staging is now applied selectively per confirmed group immediately before each `git commit`, leaving skipped or aborted groups completely untouched.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| smart-commit | Added SR-10 | Full working-tree detection via `git status --porcelain`; three file categories (staged, unstaged, untracked); clean-tree halt condition; rename entry parsing |
| smart-commit | Added SR-11 | Staging-status annotation in plan display; three visual markers before any `git add` fires |
| smart-commit | Added SR-12 | Selective auto-staging per confirmed group; `git add` only for unstaged/untracked; no redundant add for already-staged files |
| smart-commit | Added SR-13 | Skip-preserves-state invariant; skipped/aborted groups receive no `git add`, no `git commit`; partial-execution summary surfaces uncommitted groups |
| smart-commit | Modified SR-01 | Grouping heuristic scope extended to all files detected by SR-10 (not only pre-staged files) |
| smart-commit | Modified SR-07 | No-silent-omissions invariant scope extended to full working tree (source of truth is `git status --porcelain`, not `git diff --cached`) |

## Modified Code Files

- `skills/smart-commit/SKILL.md` — Step 1 rewritten (full working-tree scan via `git status --porcelain`; three-category parsing; staging-status tag per file); Step 1b updated (staging-status tag travels with file through grouping); Step 1c updated (plan display annotates each file with `[staged]`, `[unstaged]`, or `[untracked]` before any `git add`); Step 5 updated (per-group `git add` precondition for confirmed groups; skip/abort branches explicitly issue no `git add`); Rules section updated (old "only staged files" rule removed; three replacement rules added); Anti-patterns section updated (old "don't commit when nothing staged" removed; replacement "don't stage files not confirmed" added); YAML `description` and `metadata.version` updated to 1.1
- `openspec/specs/smart-commit/spec.md` — SR-10 through SR-13 appended; SR-01 and SR-07 modification blocks appended

## Key Decisions Made

- **Detection command**: `git status --porcelain` replaces `git diff --cached --stat` as the working-tree scan command — stable, machine-parseable, single-pass for all three file categories
- **Three-value staging-status model**: `staged` / `unstaged` / `untracked` (not a boolean flag) — preserves precise annotation in the plan display and correct `git add` decisions
- **Per-group, just-in-time staging**: `git add` fires immediately before each confirmed group's `git commit`, never upfront — ensures rejected groups are never touched and no cleanup is needed on abort
- **Halt condition**: clean-tree halt fires only when `git status --porcelain` returns empty output — the only unambiguous case with nothing to commit
- **Rename entry handling**: `R old -> new` entries split on arrow; both paths included in group to prevent silent file omissions

## Lessons Learned

- None — the cycle executed cleanly with 0 critical defects and 0 warnings. The two minor observations in the verify report are documentation-only gaps (SR-09 prose not updated to match new wording; `git diff --cached` retained for content analysis of staged files is an acknowledged known limitation).

## User Docs Reviewed

N/A — pre-dates this requirement (verify-report.md does not contain the user-docs review checkbox). This change does not add, remove, or rename skills, does not change onboarding workflows, and does not introduce new commands — no update to `scenarios.md`, `quick-reference.md`, or `onboarding.md` is needed.
