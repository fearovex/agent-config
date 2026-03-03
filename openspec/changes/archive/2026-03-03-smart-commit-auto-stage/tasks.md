# Task Plan: smart-commit-auto-stage

Date: 2026-03-03
Design: openspec/changes/smart-commit-auto-stage/design.md

## Progress: 9/9 tasks

---

## Phase 1: SKILL.md — Core Behavior Changes

Tasks are ordered by document position within `skills/smart-commit/SKILL.md`.

- [x] 1.1 Modify `skills/smart-commit/SKILL.md` — **Step 1 (replace guard)**: remove the `git diff --cached --stat` empty-output halt and its "No staged files found" stop instruction; replace with a `git status --porcelain` call that parses all three file categories (staged, unstaged, untracked) and assigns a `staging-status` tag (`staged` | `unstaged` | `untracked`) to each file; keep the `git diff --cached` and `git log` calls intact; add the new clean-tree halt: if `git status --porcelain` returns empty output, print "Nothing to commit. Working tree is clean." and stop

- [x] 1.2 Modify `skills/smart-commit/SKILL.md` — **Step 1b (staging-status tag flows through grouping)**: update the grouping prose to replace every reference to "staged file" with "detected file"; explicitly state that each file's `staging-status` tag (assigned in Step 1) travels unchanged through the grouping step; update the "No staged file may appear in more than one group / Every staged file must appear in exactly one group" sentences to refer to "detected file"; update the single-group fast-path note to add: "if the single group contains any files tagged `unstaged` or `untracked`, print 'Auto-staging N file(s): \<list\>' then issue `git add \<unstaged/untracked files\>` before proceeding to Step 2"

- [x] 1.3 Modify `skills/smart-commit/SKILL.md` — **Step 1c (staging-status annotation in plan display)**: in the "Display the full plan" block, update the `Files:` line format to show each file annotated with its staging-status marker (`[staged]`, `[unstaged]`, or `[untracked]`); add a note that the annotation MUST appear before any `git add` or `git commit` is issued; update the `abort` outcome text to "Commit plan aborted. No files were staged. Working tree is unchanged."

- [x] 1.4 Modify `skills/smart-commit/SKILL.md` — **Step 5, multi-group "commit all" path**: in the per-group iteration block, insert step 0 before the existing step 1 (`git commit`): "0. For each file in this group tagged `unstaged` or `untracked`, issue `git add \<file\>`; skip files already tagged `staged`"; apply the same insertion to the **step-by-step** path's `y` branch and `edit message` branch; ensure `skip` and `abort remaining` branches explicitly state "no `git add` is issued for this group"

- [x] 1.5 Modify `skills/smart-commit/SKILL.md` — **Step 5, partial-execution summary**: update the "Not committed" block to replace "staged area still contains these files" with "not committed — files remain in original state"; add a per-file staging-status column to the listed files so the user knows the exact state of each uncommitted file

- [x] 1.6 Modify `skills/smart-commit/SKILL.md` — **Rules section**: remove the rule "Only staged files (`git diff --cached`) are in scope — never auto-stage unstaged files or untracked files"; add three replacement rules in its place:
  - "Detect files from the full working tree via `git status --porcelain`; assign each file a staging-status tag (`staged`, `unstaged`, `untracked`) during Step 1"
  - "Auto-stage only the files of a confirmed group — issue `git add \<files\>` for files tagged `unstaged` or `untracked` immediately before that group's `git commit`; never re-add already-staged files"
  - "For skipped or aborted groups, issue no `git add` — their files must remain in the exact state they were in when the skill was invoked"

- [x] 1.7 Modify `skills/smart-commit/SKILL.md` — **Anti-patterns section**: remove the anti-pattern "Don't commit when nothing is staged / Always verify `git diff --cached --stat` before generating a message"; add replacement anti-pattern: "Don't stage files that were not confirmed / Issue `git add` only for groups the user explicitly confirmed; never batch-stage all detected files upfront before the plan confirmation"

---

## Phase 2: Master Spec — SR-10 through SR-13 + Modified SR-01/SR-07

- [x] 2.1 Modify `openspec/specs/smart-commit/spec.md` — append the four new requirements (SR-10, SR-11, SR-12, SR-13) and the two modified requirements (SR-01 scope extension, SR-07 scope extension) exactly as specified in `openspec/changes/smart-commit-auto-stage/specs/smart-commit/spec.md`; each new requirement must have at least two scenarios; the existing SR-01 through SR-09 entries must remain untouched

---

## Phase 3: Cleanup

- [x] 3.1 Modify `skills/smart-commit/SKILL.md` — update the YAML frontmatter `description:` field to reflect the new behavior: replace "Analyzes staged files" with "Analyzes staged and unstaged files from the full working tree"; replace "groups them into functional clusters" with the same wording; replace "Trigger:" line if it still references only staged files; update `metadata.version` from `"1.0"` to `"1.1"`

- [x] 3.2 Update `ai-context/changelog-ai.md` — add a changelog entry for this session: "2026-03-03: smart-commit-auto-stage applied — Step 1 rewritten to use `git status --porcelain`; auto-staging added to Step 5 per confirmed group; SR-10–SR-13 added to master spec; SKILL.md version bumped to 1.1"

---

## Implementation Notes

- All 7 tasks in Phase 1 touch the same file (`skills/smart-commit/SKILL.md`). They MUST be applied in task order (1.1 → 1.7) to avoid overwriting earlier edits.
- Task 1.1 is the only task that changes the halt condition. After 1.1, the skill must never halt on "No staged files found".
- Task 1.2 changes Step 1b wording only — the grouping heuristic rules (Rule 1 through Fallback) are NOT modified.
- Task 1.3 changes only the display format in Step 1c, not the message generation or issue detection logic.
- Task 1.4 is the most structurally significant task: it inserts a `git add` precondition in three places within Step 5 (commit-all loop, step-by-step `y` branch, step-by-step `edit message` branch) and adds explicit no-staging guarantees to two branches (`skip`, `abort remaining`).
- Task 1.6: the removed rule is on line 308 of the current SKILL.md (`Only staged files (git diff --cached) are in scope…`). The three replacement rules must be inserted at the same position in the Rules list.
- Task 2.1 appends to the master spec — it does NOT rewrite or reorder any existing SR-01 through SR-09 content.
- After apply, run `install.sh` to deploy the updated skill to `~/.claude/skills/smart-commit/`.

## Blockers

None.
