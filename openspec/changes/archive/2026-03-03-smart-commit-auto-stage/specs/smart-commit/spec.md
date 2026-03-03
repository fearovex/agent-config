# Delta Spec: smart-commit

Change: smart-commit-auto-stage
Date: 2026-03-03
Base: openspec/specs/smart-commit/spec.md

---

## ADDED — New requirements

### Requirement: SR-10 — Full working-tree detection

The skill MUST detect files to commit from the full working tree, not only the git index.
When the skill is invoked, it MUST call `git status --porcelain` and collect all three
file categories:

- **staged**: files with a non-space status code in the index column (A, M, R, D in column 1)
- **unstaged**: files with a non-space status code only in the worktree column (M or D in column 2, space in column 1)
- **untracked**: files with the `??` prefix

Every file in all three categories MUST be included in the grouping step (SR-01).
If none of the three categories contain any files, the skill MUST halt with a clear message
("Nothing to commit — working tree is clean") and exit without running any further step.

For rename entries (`R old -> new` format), the skill MUST split the entry and include
both the old path and the new path so no file is silently omitted.

#### Scenario: Unstaged-only working tree — proceeds normally

- **GIVEN** a repository where no files are staged, but two files have unstaged modifications: `skills/react-19/SKILL.md` and `docs/adr/012-foo.md`
- **WHEN** the skill is invoked
- **THEN** both files are collected with staging-status `unstaged`
- **AND** the skill proceeds to grouping and plan presentation (does NOT print "No staged files found")

#### Scenario: Untracked-only working tree — proceeds normally

- **GIVEN** a repository where no files are staged or modified, but one new file `skills/new-skill/SKILL.md` is untracked
- **WHEN** the skill is invoked
- **THEN** the file is collected with staging-status `untracked`
- **AND** the skill proceeds to grouping and plan presentation

#### Scenario: Mixed staged and unstaged files — all collected

- **GIVEN** staged files: `hooks/pre-commit.sh`; unstaged files: `skills/smart-commit/SKILL.md`; untracked files: `docs/adr/013-bar.md`
- **WHEN** `git status --porcelain` is parsed
- **THEN** all three files are collected with their respective staging-status tags
- **AND** all three are passed to the grouping step

#### Scenario: Truly clean working tree — halts cleanly

- **GIVEN** a repository with no staged, unstaged, or untracked files
- **WHEN** the skill is invoked
- **THEN** the skill prints "Nothing to commit — working tree is clean"
- **AND** exits without executing any further step

#### Scenario: Rename entry — both paths collected

- **GIVEN** `git status --porcelain` reports `R  old-name.md -> new-name.md` (a staged rename)
- **WHEN** the skill parses the output
- **THEN** both `old-name.md` and `new-name.md` are included in the collected file set
- **AND** neither path is silently omitted

---

### Requirement: SR-11 — Staging-status annotation in plan display

When the multi-commit plan is presented (SR-04), each file line MUST include a visual
marker that identifies its staging-status. The markers MUST visually distinguish three states:

- Already staged files — e.g., `[staged]` or a `+` prefix
- Unstaged modified files — e.g., `[unstaged]` or a `~` prefix
- Untracked new files — e.g., `[untracked]` or a `?` prefix

The annotation MUST appear before any `git add` or `git commit` is issued, so the user
can review exactly which files will be staged as a result of confirming a group.

#### Scenario: Plan display shows staging-status per file

- **GIVEN** a group containing one staged file `hooks/pre-commit.sh` and one unstaged file `skills/smart-commit/SKILL.md`
- **WHEN** the multi-commit plan is displayed
- **THEN** `hooks/pre-commit.sh` is annotated as already staged
- **AND** `skills/smart-commit/SKILL.md` is annotated as unstaged (will be staged on confirm)
- **AND** no `git add` has been issued at this point

#### Scenario: Untracked file annotated distinctly from unstaged

- **GIVEN** a group containing one untracked file `docs/adr/013-new.md` and one unstaged file `src/utils.ts`
- **WHEN** the plan is displayed
- **THEN** `docs/adr/013-new.md` carries the untracked marker
- **AND** `src/utils.ts` carries the unstaged marker
- **AND** both markers are visually distinguishable from each other and from the staged marker

#### Scenario: Single-group fast-path — annotation shown before auto-staging

- **GIVEN** a single group containing only unstaged or untracked files (SR-03 fast-path applies)
- **WHEN** the skill announces the group before committing
- **THEN** the file list and their staging-status markers are printed BEFORE the `git add` call
- **AND** the announcement includes "Auto-staging N file(s):" followed by the annotated file list

---

### Requirement: SR-12 — Selective auto-staging on confirmed groups only

For each group the user confirms (in both "commit all" and "step-by-step" modes), the skill
MUST issue `git add <path>...` for every file in that group tagged `unstaged` or `untracked`
immediately before the `git commit` call for that group. Files already tagged `staged` MUST
NOT be re-added (no redundant `git add`).

For groups the user skips or aborts, the skill MUST NOT issue any `git add` — those files
MUST remain in their original state.

#### Scenario: Confirmed group — unstaged files are staged before commit

- **GIVEN** a group with one staged file `hooks/pre-commit.sh` and one unstaged file `skills/smart-commit/SKILL.md`, and the user confirms the group
- **WHEN** execution proceeds
- **THEN** `git add skills/smart-commit/SKILL.md` is issued (and only that file)
- **AND** no `git add hooks/pre-commit.sh` is issued (it is already staged)
- **AND** `git commit` is called immediately after with both files in the commit

#### Scenario: Skipped group — no staging occurs

- **GIVEN** a multi-commit plan where group A is confirmed and group B (containing two unstaged files) is skipped
- **WHEN** execution completes
- **THEN** group B's files are NOT staged (no `git add` was issued for them)
- **AND** group B's files remain in their original unstaged state in the working tree

#### Scenario: Commit-all mode — each group staged just before its commit

- **GIVEN** "commit all" chosen for a plan with two groups, each containing unstaged files
- **WHEN** execution proceeds
- **THEN** group 1's unstaged files are staged immediately before group 1's `git commit`
- **AND** group 2's unstaged files are staged immediately before group 2's `git commit`
- **AND** the staging is never batched (all at once) — it is per-group and sequential

#### Scenario: Abort after first commit — second group untouched

- **GIVEN** step-by-step mode, group 1 confirmed and committed (unstaged files staged), user aborts before group 2
- **WHEN** abort occurs
- **THEN** group 2's files remain in their original state
- **AND** no `git add` was issued for group 2

---

### Requirement: SR-13 — Skip-preserves-state invariant

Skipping or aborting a group MUST leave the repository in the same state as if that group
had never been considered by the skill. Specifically:

- No `git add` is issued for any file in the skipped/aborted group
- No `git commit` is issued for the skipped/aborted group
- The files in the skipped group retain whatever staging-status they had when the skill was invoked (staged files remain staged; unstaged/untracked files remain unstaged/untracked)

This invariant MUST hold regardless of how many groups have already been committed before the skip/abort.

The skill MUST surface the skipped groups in the post-execution summary so the user knows
which files were NOT committed and can act on them manually.

#### Scenario: Skip in step-by-step mode — files untouched

- **GIVEN** a 3-group plan, user commits group 1, skips group 2 (which had two unstaged files), commits group 3
- **WHEN** execution completes
- **THEN** group 2's two files are still unstaged (not staged, not committed)
- **AND** the final summary explicitly lists group 2 as "skipped — not committed"
- **AND** the final summary shows the files in group 2 and their current state

#### Scenario: Full abort — all uncommitted files in original state

- **GIVEN** a 3-group plan where the user aborts entirely at the plan review stage (before any commit)
- **WHEN** abort occurs
- **THEN** no `git add` was issued for any file
- **AND** no `git commit` was issued
- **AND** the working tree and index are identical to the state before the skill was invoked

#### Scenario: Partial abort after commits — committed groups done, skipped groups intact

- **GIVEN** a 3-group plan where groups 1 and 2 are committed successfully and the user aborts before group 3
- **WHEN** abort occurs
- **THEN** groups 1 and 2 are in git history (SR-09 applies)
- **AND** group 3's files retain whatever staging-status they had before the skill ran
- **AND** the summary lists group 3 as "not committed" with file details

---

## MODIFIED — Modified requirements

### Requirement: SR-01 — Staged file grouping *(title unchanged, scope extended)*

The grouping heuristic defined in SR-01 MUST apply to ALL files detected by SR-10,
not only files that were already staged at invocation time. The input to the grouping
step is the full union of staged, unstaged, and untracked files collected by SR-10.

*(Before: grouping applied only to files in `git diff --cached --stat`; the new behavior
expands the input set while keeping the heuristic rules identical.)*

#### Scenario: Unstaged file routed by heuristic correctly *(modified)*

- **GIVEN** unstaged files: `skills/react-19/SKILL.md` (directory prefix `skills`), `settings.json` (root config)
- **WHEN** the skill runs grouping
- **THEN** `skills/react-19/SKILL.md` is placed in the `skills` directory group
- **AND** `settings.json` is placed in the `chore` group
- **AND** the grouping result is identical to what would have been produced had the same files been staged

### Requirement: SR-07 — No silent file omissions *(scope extended)*

SR-07's "every file MUST appear in exactly one group" invariant now applies to all files
detected by SR-10 (staged + unstaged + untracked), not only staged files.

*(Before: SR-07 referenced `git diff --cached --stat` as the source of truth for file counts.
The new source of truth is the output of `git status --porcelain` parsed per SR-10.)*

#### Scenario: Full working-tree count preserved *(modified)*

- **GIVEN** N files total across staged, unstaged, and untracked categories (as reported by `git status --porcelain`)
- **WHEN** grouping is complete
- **THEN** the total count of files across all groups equals N
- **AND** each file path appears in exactly one group
