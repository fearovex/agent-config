# ADR-014: Smart Commit Auto-Stage — Replaces Staged-Only Guard with Full Working-Tree Detection

## Status

Proposed

## Context

`smart-commit` originally halted with "No staged files found" when the user had not yet run `git add`. This forced a manual staging step that was redundant: the skill already knew how to group and commit changes, and the user's intent to commit their work was clear. The staged-only constraint also created a correctness gap in the multi-commit flow — users who selected a subset of staged groups for commit had no way to un-stage the groups they skipped.

The `git diff --cached --stat` guard that gated all skill behavior needed to be replaced with a command that could enumerate the full working tree — distinguishing already-staged files, unstaged modifications, and untracked files — so that auto-staging could be applied selectively, only for confirmed groups.

## Decision

We will replace the `git diff --cached --stat` empty-output guard in Step 1 of `smart-commit` with a `git status --porcelain` scan of the full working tree. Each detected file is tagged with a `staging-status` value (`staged`, `unstaged`, or `untracked`). The grouping heuristic (Step 1b) is applied to all detected files regardless of staging status. The tag is surfaced in the multi-commit plan display as an annotation. In Step 5, `git add` is issued only for `unstaged` and `untracked` files in each group that the user confirms — groups the user skips or aborts are never staged. The halt condition becomes "working tree is completely clean" (empty `git status --porcelain` output) rather than "nothing staged".

## Consequences

**Positive:**

- Users can invoke `/commit` at any point in their workflow without a prerequisite `git add` step
- Groups the user rejects at the plan level are never staged, eliminating the partial-index cleanup problem present in the previous design
- `git status --porcelain` is stable across git versions and provides richer per-file state than `git diff --cached --stat` in a single pass
- The single-group fast-path is preserved with minimal addition: a one-line "Auto-staging N file(s)" announcement before the `git add` call

**Negative:**

- The skill now touches the git index (stages files) as a side effect of commit confirmation, whereas previously it was index-read-only
- Users must understand that confirming a group stages its unstaged/untracked files immediately — the confirmation is now a staging commitment, not just a commit-message approval
- `git status --porcelain` rename entries (`R old -> new`) require special-case parsing; edge cases (spaces in filenames, copy entries `C`) must be handled explicitly
