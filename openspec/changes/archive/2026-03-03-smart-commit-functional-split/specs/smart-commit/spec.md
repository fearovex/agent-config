# Spec: smart-commit

Change: smart-commit-functional-split
Date: 2026-03-03

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
