# Spec: smart-commit

Last updated: 2026-03-03
Created by change: smart-commit-functional-split

---

## Requirements

### Requirement: SR-01 — Staged file grouping

The skill MUST group staged files into functional clusters before generating commit messages. Grouping MUST apply the following heuristic in priority order:

1. **Test files** (`*.test.*`, `*.spec.*`, `_test.*`, `*_test.go`, `*.test.ts`, `*.spec.ts`, etc.) form their own group regardless of directory.
2. **Config/infra files** — root-level config files matching `*.json`, `*.yaml`, `*.toml`, `*.sh`, `*.env*` — form a `chore` group.
3. **Docs files** — files under `docs/`, root-level `*.md`, `README*` — form a `docs` group.
4. **Directory prefix** — remaining files sharing a common top-level directory form one group per directory (e.g., all files under `skills/smart-commit/` become one group; all files under `hooks/` become another).

No staged file MUST be assigned to more than one group. Every staged file MUST appear in exactly one group.

#### Scenario: Mixed staged set — skills and docs
- **GIVEN** staged files: `skills/smart-commit/SKILL.md`, `skills/sdd-apply/SKILL.md`, `docs/adr/012-foo.md`
- **WHEN** the skill runs grouping
- **THEN** two groups are produced: one `skills` group containing the two skill files, one `docs` group containing the ADR file
- **AND** no file is omitted

#### Scenario: Test file isolation
- **GIVEN** staged files: `src/auth/auth.service.ts`, `src/auth/auth.service.spec.ts`
- **WHEN** the skill runs grouping
- **THEN** two groups are produced: one for `src/auth/auth.service.ts` (directory prefix `src`) and one for `src/auth/auth.service.spec.ts` (test group)
- **AND** the test file does NOT merge into the `src` directory group

#### Scenario: Root-level config group
- **GIVEN** staged files: `settings.json`, `install.sh`, `skills/react-19/SKILL.md`
- **WHEN** the skill runs grouping
- **THEN** two groups are produced: one `chore` group containing `settings.json` and `install.sh`, one `skills` directory group containing `skills/react-19/SKILL.md`

#### Scenario: Single file staged
- **GIVEN** exactly one file is staged: `skills/smart-commit/SKILL.md`
- **WHEN** the skill runs grouping
- **THEN** one group is produced
- **AND** the skill falls through to the single-commit fast-path (SR-03)

---

### Requirement: SR-02 — Per-group commit message generation

For each group produced by SR-01, the skill MUST generate an independent conventional commit message (`type(scope): summary` + optional bullet body) using only the diff of files in that group.

The `type` and `scope` MUST be derived from the files in the group:
- `type`: derived from the nature of changes within the group (same derivation table as the existing Step 2)
- `scope`: the shared top-level directory or functional label of the group (e.g., `skills`, `docs`, `hooks`, `chore`)

#### Scenario: Independent message per group
- **GIVEN** two groups: group A with `skills/smart-commit/SKILL.md` (modified), group B with `docs/adr/012-foo.md` (new)
- **WHEN** commit messages are generated
- **THEN** group A produces `feat(skills): ...` or `refactor(skills): ...` based on its diff content
- **AND** group B produces `docs(adr): ...` based on its diff content
- **AND** each message body references only the files in its own group

#### Scenario: Chore group type assignment
- **GIVEN** a group containing only `settings.json` and `install.sh` (both modified)
- **WHEN** the commit message is generated for this group
- **THEN** the type is `chore` and the scope reflects the config/infra nature (e.g., `chore(config): ...`)

---

### Requirement: SR-03 — Single-group fast-path

When grouping produces exactly one group, the skill MUST fall through to the existing single-commit flow with no behavioral change: the user sees one summary and one confirmation prompt, and a single commit is executed.

#### Scenario: All files in one directory
- **GIVEN** staged files: `skills/react-19/SKILL.md`, `skills/react-19/examples/form.tsx`
- **WHEN** the skill runs
- **THEN** one group is produced (directory prefix `skills`)
- **AND** the user sees the existing single-commit summary format (not the multi-commit plan)
- **AND** exactly one commit is executed

#### Scenario: Single file — identical to current behavior
- **GIVEN** one staged file
- **WHEN** the skill runs
- **THEN** behavior is identical to the pre-change version of the skill

---

### Requirement: SR-04 — Multi-commit plan presentation

When grouping produces two or more groups, the skill MUST present a multi-commit plan to the user **before executing any commit**. The plan MUST list all proposed commits with their order, group contents, and proposed message. The user MUST be able to review, edit, or abort before any commit fires.

The plan MUST include:
- Total number of commits proposed
- For each commit: its sequence number, the files in the group, and the proposed commit message

#### Scenario: Multi-commit plan display
- **GIVEN** three groups are produced from staged files
- **WHEN** the skill presents the plan
- **THEN** the output shows "3 commits planned" followed by three numbered entries
- **AND** each entry shows: sequence number, file list for the group, proposed commit message
- **AND** no `git commit` command has been executed at this point

#### Scenario: Plan shown before first commit
- **GIVEN** staged files spanning two functional areas
- **WHEN** the skill runs
- **THEN** the full multi-commit plan is printed BEFORE the first `git commit` call
- **AND** the user receives a confirmation prompt for the plan as a whole OR per-commit

---

### Requirement: SR-05 — Sequential commit execution with per-step confirmation

The skill MUST execute commits one at a time, in the order presented in the plan. After presenting the multi-commit plan, the skill MUST offer two confirmation paths:

- **"commit all"**: execute all commits sequentially without individual confirmation between them
- **"step-by-step"**: confirm each commit individually before executing it

Between commits in "step-by-step" mode, the skill MUST report which commit just succeeded and which is next.

The skill MUST NOT execute commits in parallel or out of order.

#### Scenario: Commit-all path
- **GIVEN** a multi-commit plan with 2 commits and the user chooses "commit all"
- **WHEN** execution proceeds
- **THEN** commit 1 is executed and confirmed, then commit 2 is executed and confirmed, without any intermediate prompt
- **AND** the final output lists both committed hashes

#### Scenario: Step-by-step — user aborts at second commit
- **GIVEN** a multi-commit plan with 3 commits and the user chooses "step-by-step"
- **WHEN** the user confirms commit 1, then aborts before commit 2
- **THEN** commit 1 has been executed and is in git history
- **AND** commits 2 and 3 have NOT been executed
- **AND** the skill prints the remaining un-committed groups so the user can commit them manually

#### Scenario: Abort before any commit fires
- **GIVEN** a multi-commit plan is presented
- **WHEN** the user chooses "abort" at the plan review stage
- **THEN** no `git commit` is executed
- **AND** the staged area is left unchanged

---

### Requirement: SR-06 — Error blocking applies per-group and halts the entire plan

If the existing issue-detection step (Step 3) detects an ERROR-severity condition in ANY group, the skill MUST block the entire multi-commit plan. No commit MUST be executed until all ERROR conditions are resolved.

#### Scenario: One group has a .env file staged
- **GIVEN** two groups: group A clean, group B contains a staged `.env.local`
- **WHEN** issue detection runs
- **THEN** the entire plan is blocked
- **AND** the skill prints the ERROR message and does NOT proceed with group A's commit either

#### Scenario: WARNING in one group does not block other groups
- **GIVEN** two groups: group A has a `console.log` WARNING, group B is clean
- **WHEN** issue detection runs
- **THEN** the plan is NOT blocked
- **AND** WARNINGs are listed in the plan summary
- **AND** the user is prompted to proceed (same as existing single-commit WARNING behavior)

---

### Requirement: SR-07 — No silent file omissions

Every file present in `git diff --cached --stat` output MUST appear in exactly one group. The skill MUST NOT drop, skip, or ignore any staged file during grouping or plan generation.

#### Scenario: All staged files accounted for
- **GIVEN** N staged files in `git diff --cached --stat`
- **WHEN** grouping is complete
- **THEN** the total count of files across all groups equals N
- **AND** each file path appears in exactly one group

#### Scenario: Ambiguous root-level file (not matching config or docs pattern)
- **GIVEN** a staged file `AGENTS.md` at the root (matches docs pattern `*.md` at root)
- **WHEN** the skill runs grouping
- **THEN** `AGENTS.md` is placed in the `docs` group
- **AND** it is not omitted

#### Scenario: File that matches no heuristic
- **GIVEN** a staged file that does not match test, config, docs, or any known directory prefix (e.g., a file at an unexpected root location like `foo.rb`)
- **WHEN** the skill runs grouping
- **THEN** the file is placed in a fallback group (e.g., `chore` or `misc`)
- **AND** it is not omitted

---

### Requirement: SR-08 — Backward compatibility with existing commit format

All commit messages generated by the skill (both in single-commit and multi-commit paths) MUST continue to use the conventional commits format (`type(scope): summary` + optional bullet body + `Co-Authored-By` trailer) as defined by the current skill.

The `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>` trailer MUST appear in every commit message, including each individual commit in a multi-commit sequence.

#### Scenario: Multi-commit messages follow conventional format
- **GIVEN** a multi-commit plan with 2 commits
- **WHEN** both commits are executed
- **THEN** each `git commit -m` call uses the `type(scope): summary` format
- **AND** each commit message includes the `Co-Authored-By` trailer

#### Scenario: Edit message option preserved per commit
- **GIVEN** step-by-step mode with 2 commits
- **WHEN** the user is prompted before commit 1
- **THEN** the prompt includes an "edit message" option
- **AND** if the user edits, the edited message is used verbatim for that commit only
- **AND** commit 2 uses its own independently generated message

---

### Requirement: SR-09 — Partial-execution state is surfaced clearly

If the user aborts a multi-commit sequence after one or more commits have already executed, the skill MUST clearly report:
- Which commits succeeded (with hash and message)
- Which commits were not executed (with their proposed messages and file lists)

#### Scenario: Partial abort mid-sequence
- **GIVEN** a 3-commit plan where commits 1 and 2 succeed but the user aborts before commit 3
- **WHEN** the abort happens
- **THEN** the skill prints a summary: "2 of 3 commits executed"
- **AND** lists commit 3's proposed message and files as "not committed — stage is still in place for these files"
- **AND** does NOT attempt to undo commits 1 and 2

---

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

### Modification: SR-01 — Staged file grouping *(scope extended by smart-commit-auto-stage)*

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

---

### Modification: SR-07 — No silent file omissions *(scope extended by smart-commit-auto-stage)*

SR-07's "every file MUST appear in exactly one group" invariant now applies to all files
detected by SR-10 (staged + unstaged + untracked), not only staged files.

*(Before: SR-07 referenced `git diff --cached --stat` as the source of truth for file counts.
The new source of truth is the output of `git status --porcelain` parsed per SR-10.)*

#### Scenario: Full working-tree count preserved *(modified)*

- **GIVEN** N files total across staged, unstaged, and untracked categories (as reported by `git status --porcelain`)
- **WHEN** grouping is complete
- **THEN** the total count of files across all groups equals N
- **AND** each file path appears in exactly one group
