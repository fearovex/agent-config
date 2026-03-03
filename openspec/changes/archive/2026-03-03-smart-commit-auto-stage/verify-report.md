# Verify Report: smart-commit-auto-stage

Date: 2026-03-03
Verifier: sdd-verify sub-agent
Artifacts verified:
- `skills/smart-commit/SKILL.md`
- `openspec/specs/smart-commit/spec.md`
- `ai-context/changelog-ai.md` (task 3.2)

---

## Checklist

### 1. Completeness — Task Closure

- [x] 1.1 Step 1 replaces `git diff --cached` guard with `git status --porcelain` scan + staging-status tagging
- [x] 1.2 Step 1b prose updated: "detected file" replaces "staged file"; staging-status tag travels through grouping; single-group fast-path auto-staging announcement added
- [x] 1.3 Step 1c plan display updated: `Files:` line annotates each file with `[staged]`, `[unstaged]`, or `[untracked]`; abort text updated to "Commit plan aborted. No files were staged. Working tree is unchanged."
- [x] 1.4 Step 5 multi-group "commit all" path inserts `git add` precondition (step 0) before `git commit`; "step-by-step" `y` and `edit message` branches also include the `git add` precondition; `skip` and `abort remaining` branches explicitly state no `git add` is issued
- [x] 1.5 Partial-execution summary "Not committed" block uses "files remain in original state"; per-file staging-status annotation present in the uncommitted block
- [x] 1.6 Rules section: old "Only staged files" rule removed; three replacement rules added (full working-tree detection, selective auto-staging per confirmed group, no staging for skipped/aborted groups)
- [x] 1.7 Anti-patterns section: "Don't commit when nothing is staged" anti-pattern removed; replacement "Don't stage files that were not confirmed" anti-pattern added
- [x] 2.1 Master spec `openspec/specs/smart-commit/spec.md` updated: SR-10 through SR-13 appended; SR-01 and SR-07 scope-extension modifications appended; SR-01 through SR-09 original entries untouched
- [x] 3.1 YAML frontmatter `description:` updated to "Analyzes staged and unstaged files from the full working tree"; `metadata.version` bumped to `"1.1"`

**Result: 9/9 tasks closed.** Completeness criterion met.

---

### 2. Correctness — Key Behavioral Changes

#### SR-10 through SR-13 implemented

- [x] **SR-10** — `git status --porcelain` is the detection command in Step 1; three categories (staged, unstaged, untracked) are parsed; staging-status tags are assigned per the XY column rules; rename entries split on `" -> "` with both paths tagged `staged`; clean-tree halt message is "Nothing to commit. Working tree is clean."

  Verified at SKILL.md lines 35–55: `git status --porcelain` call present; XY parsing logic for all three categories; rename handling for `X = R`; clean-tree halt condition and stop instruction.

- [x] **SR-11** — Plan display annotates each file with its staging-status marker before any `git add` or `git commit`; example in SKILL.md shows `file-a.md [staged]`, `file-b.md [unstaged]`, `skills/smart-commit/SKILL.md [untracked]`; note in Step 1c explicitly states annotation must appear before any `git add` or `git commit`.

  Verified at SKILL.md lines 99–122: display block and the annotation note are present.

- [x] **SR-12** — "commit all" path (SKILL.md line 218): step 0 issues `git add <file>` for each file tagged `unstaged` or `untracked`, skips `staged` files. "step-by-step" `y` branch (line 243): same precondition before `git commit`. "step-by-step" `edit message` branch (line 244): same precondition. `skip` branch (line 245): "no `git add` is issued for this group". `abort remaining` branch (line 246): "no `git add` is issued for remaining groups".

- [x] **SR-13** — Skip-preserves-state invariant is enforced: `skip` branch leaves files in original state; `abort remaining` stops processing without issuing `git add`; partial-execution summary (SKILL.md lines 258–271) lists uncommitted groups with file details and staging-status markers.

#### SR-01 and SR-07 scope extensions

- [x] **SR-01 scope extension** — Step 1b first sentence reads: "Using the file paths collected in Step 1, apply the following grouping heuristic..." (i.e., all detected files, not only staged); the "No detected file may appear in more than one group / Every detected file must appear in exactly one group" language replaces the old staged-only wording (SKILL.md line 78).

- [x] **SR-07 scope extension** — Rules section entry: "Detect files from the full working tree via `git status --porcelain`; assign each file a staging-status tag (`staged`, `unstaged`, `untracked`) during Step 1" (line 320). The old `git diff --cached` source-of-truth reference does not appear in the Rules section.

#### Old rule removed

- [x] The rule "Only staged files (`git diff --cached`) are in scope — never auto-stage unstaged files or untracked files" is absent from the Rules section. The three replacement rules (lines 320–322) are present in its place.

#### Anti-pattern updated

- [x] The anti-pattern "Don't commit when nothing is staged / Always verify `git diff --cached --stat` before generating a message" is absent. The replacement anti-pattern "Don't stage files that were not confirmed / Issue `git add` only for groups the user explicitly confirmed; never batch-stage all detected files upfront before the plan confirmation" is present (SKILL.md lines 296–298).

---

### 3. Coherence — Data Flow Integrity

- [x] **Step 1 uses `git status --porcelain`**: Confirmed. `git diff --cached --stat` guard is gone; `git status --porcelain` is the first command in Step 1 (SKILL.md line 35).

- [x] **Staging-status tags flow through grouping**: Step 1b explicitly states "Each file's `staging-status` tag (assigned in Step 1) travels unchanged through the grouping step and is preserved in the group record." (SKILL.md line 59).

- [x] **`git add` fires per confirmed group in Step 5**: Both "commit all" (line 218) and "step-by-step" `y`/`edit message` branches (lines 243–244) issue `git add` for `unstaged` or `untracked` files immediately before `git commit`. The per-group, sequential nature is preserved (not batched upfront).

- [x] **Abort/skip branches have no `git add`**: `skip` branch (line 245): "no `git add` is issued for this group". `abort remaining` (line 246): "no `git add` is issued for remaining groups". Plan-level `abort` (line 134): "no `git add` or `git commit` is executed". All three abort/skip paths are covered.

- [x] **Single-group fast-path coherence**: If single group contains `unstaged` or `untracked` files, the skill prints "Auto-staging N file(s): <list>" then issues `git add` before Step 2. The announcement precedes the `git add` call, satisfying SR-11's annotation-before-staging requirement for the fast-path (SKILL.md line 80–81).

- [x] **Clean-tree halt is unambiguous**: The halt fires only when `git status --porcelain` returns empty output — the only case where the working tree is truly clean. No premature halt on "no staged files only".

---

## Spec Compliance Matrix

Cross-reference of all delta spec scenarios against SKILL.md implementation.

| SR | Scenario | Status | Evidence in SKILL.md |
|----|----------|--------|----------------------|
| SR-10 | Unstaged-only working tree — proceeds normally | PASS | Step 1 parses `X=' ', Y=M/D/T` → `unstaged`; no halt on zero staged files |
| SR-10 | Untracked-only working tree — proceeds normally | PASS | Step 1 parses `XY=??` → `untracked`; proceeds to Step 1b |
| SR-10 | Mixed staged and unstaged files — all collected | PASS | All three XY parse paths produce tagged file records passed to Step 1b |
| SR-10 | Truly clean working tree — halts cleanly | PASS | Empty `git status --porcelain` → "Nothing to commit. Working tree is clean." → stop (lines 52–55) |
| SR-10 | Rename entry — both paths collected | PASS | `X=R` branch splits on `" -> "`, both paths tagged `staged` (lines 48–49) |
| SR-11 | Plan display shows staging-status per file | PASS | `Files:` example shows `[staged]` and `[unstaged]` markers; note on lines 99–102 requires annotation before any `git add` |
| SR-11 | Untracked file annotated distinctly from unstaged | PASS | Three distinct markers shown in plan example: `[staged]`, `[unstaged]`, `[untracked]` (lines 108–115) |
| SR-11 | Single-group fast-path — annotation shown before auto-staging | PASS | Fast-path prints "Auto-staging N file(s): <list>" before issuing `git add` (line 80) |
| SR-12 | Confirmed group — unstaged files are staged before commit | PASS | Step 5 "commit all" step 0 issues `git add <file>` for `unstaged`/`untracked` only (line 218) |
| SR-12 | Skipped group — no staging occurs | PASS | `skip` branch: "no `git add` is issued for this group" (line 245) |
| SR-12 | Commit-all mode — each group staged just before its commit | PASS | Per-group iteration: step 0 (`git add`) then step 1 (`git commit`) — sequential, not batched (lines 217–222) |
| SR-12 | Abort after first commit — second group untouched | PASS | `abort remaining` stops after current group, no `git add` for remaining groups (line 246) |
| SR-13 | Skip in step-by-step mode — files untouched | PASS | `skip` leaves files in original state; partial summary lists uncommitted groups with staging-status (lines 258–271) |
| SR-13 | Full abort — all uncommitted files in original state | PASS | Plan-level `abort` (line 134): no `git add`, no `git commit`, "Working tree is unchanged" |
| SR-13 | Partial abort after commits — committed groups done, skipped groups intact | PASS | `abort remaining` does not issue `git add` for remaining groups; partial summary shows committed hashes + uncommitted block with file states |
| SR-01 (ext) | Unstaged file routed by heuristic correctly | PASS | Step 1b heuristic applies to all detected files from Step 1; rule priority is unchanged |
| SR-07 (ext) | Full working-tree count preserved | PASS | "No detected file may appear in more than one group. Every detected file must appear in exactly one group." (line 78) |

**Matrix result: 17/17 scenarios PASS.**

---

## Minor Observations (non-blocking)

1. **SR-09 partial-execution summary wording**: The original SR-09 scenario (master spec line 215) says "not committed — stage is still in place for these files." The updated SKILL.md uses "Not committed — files remain in original state" which is semantically richer and correct for the new behavior (files may not be staged at all). The master spec SR-09 wording was not updated to match. This is a documentation gap, not a functional defect — the SKILL.md behavior is correct. Recommend updating SR-09 prose in a follow-up change.

2. **`git diff --cached` retained for content analysis**: Step 1 still runs `git diff --cached` for content analysis (message generation and issue detection). This is intentional per the design (scoped diff for staged changes). For unstaged/untracked files, the scoped diff in Step 1c will return empty output — the design document acknowledges this is a known limitation (testing strategy notes manual verification required). Not a defect, but worth noting in ai-context/known-issues.md if it becomes a gap in practice.

---

## Verdict

**PASS** — All 9 tasks closed, all 17 spec scenarios pass, all behavioral constraints verified.

- Critical defects: **0**
- Warnings: **0**
- Minor observations (non-blocking): **2**

Ready to proceed to `/sdd-archive`.
