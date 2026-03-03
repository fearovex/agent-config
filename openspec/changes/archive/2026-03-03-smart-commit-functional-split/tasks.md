# Task Plan: smart-commit-functional-split

Date: 2026-03-03
Design: openspec/changes/smart-commit-functional-split/design.md

## Progress: 11/11 tasks

---

## Phase 1: Frontmatter and Triggers (baseline preservation)

- [x] 1.1 Modify `skills/smart-commit/SKILL.md` — update the `description:` field in YAML frontmatter to include the new grouping capability (extend existing text; do not change any other frontmatter key)
- [x] 1.2 Modify `skills/smart-commit/SKILL.md` — verify the `**Triggers**` / `## When to Use` section remains unchanged and still satisfies the `procedural` format contract (Triggers, Process, Rules all present)

---

## Phase 2: Grouping Step (Step 1b — new core logic)

- [x] 2.1 Modify `skills/smart-commit/SKILL.md` — insert **Step 1b — Group staged files** immediately after Step 1, containing the priority-ordered grouping heuristic in full:
  - Rule 1 (Test files): paths matching `*.test.*`, `*.spec.*`, `_test.*`, `*_test.*` → group `test` (applied first, regardless of directory)
  - Rule 2 (Config/infra): root-level files matching `*.json`, `*.yaml`, `*.yml`, `*.toml`, `*.sh`, `*.env*` → group `chore`
  - Rule 3 (Docs): paths under `docs/`, root-level `*.md`, `README*` → group `docs`
  - Rule 4 (Directory prefix): remaining files grouped by their first path segment (e.g., `skills/smart-commit/SKILL.md` → group `skills`)
  - Fallback: files matching none of the above (e.g., root-level `foo.rb`) → group `misc`
  - No staged file may appear in more than one group
- [x] 2.2 Modify `skills/smart-commit/SKILL.md` — append the single-group fast-path decision in Step 1b: "If grouping produces exactly one group → skip the multi-commit plan and fall through to Step 2 unchanged."
- [x] 2.3 Modify `skills/smart-commit/SKILL.md` — append the multi-group branch in Step 1b: "If grouping produces two or more groups → proceed to Step 1c (multi-commit plan) before executing any commit."

---

## Phase 3: Multi-Commit Plan Presentation (Step 1c — new)

- [x] 3.1 Modify `skills/smart-commit/SKILL.md` — insert **Step 1c — Present multi-commit plan** immediately after Step 1b, specifying:
  - Run Steps 2 and 3 independently for each group (using `git diff --cached -- <files…>` scoped to that group's file list) to generate each group's proposed commit message and detect issues
  - Collect all ERROR-severity findings across all groups before displaying the plan; if any ERROR is found in any group → block the entire plan, print all errors, and stop
  - Display the full plan block (using the format defined in design.md) showing total commit count, per-commit sequence number, file list, and proposed message
  - Display any WARNINGs in the plan summary (non-blocking)
  - Present the plan-level confirmation: `Proceed with all commits? [commit all / step-by-step / abort]`
  - On `abort` → print `Commit plan aborted. Staged area is unchanged.` and stop; no `git commit` is executed

---

## Phase 4: Sequential Commit Execution (Step 5 extension)

- [x] 4.1 Modify `skills/smart-commit/SKILL.md` — extend **Step 5 — Execute commit** to handle the multi-group path:
  - **"commit all"** path: iterate through groups in plan order; for each group execute `git commit` with its proposed message (including `Co-Authored-By` trailer) and print the resulting hash; no intermediate prompt between groups
  - **"step-by-step"** path: before each group's commit, print the per-commit confirmation block (sequence, files, proposed message) and prompt `Proceed? [y / edit message / skip / abort remaining]`; apply user choice before proceeding to next group
    - `edit message` → prompt for replacement message; use it verbatim for that commit only
    - `skip` → leave that group's files staged; move to next group
    - `abort remaining` → stop after current group; print partial-execution summary (SR-09)
- [x] 4.2 Modify `skills/smart-commit/SKILL.md` — add the **partial-execution summary** output block at the end of Step 5 for the multi-group path (triggered on mid-sequence abort or when all groups complete):
  - When all succeed: `N of N commits executed` + list each hash and its message
  - When partial: `M of N commits executed` + list executed hashes; then list remaining un-committed groups with their files and proposed messages under `"Not committed — staged area still contains these files:"`

---

## Phase 5: Rules Section Update

- [x] 5.1 Modify `skills/smart-commit/SKILL.md` — add the following rules to the `## Rules` section (appended, without removing existing rules):
  - "When staged files span two or more functional groups, present the full multi-commit plan before executing any commit"
  - "ERROR conditions in any group block the entire multi-commit plan — no partial execution allowed when ERRORs are present"
  - "Every commit in a multi-commit sequence MUST include the `Co-Authored-By` trailer"
  - "The grouping heuristic is applied in priority order: test → config/infra → docs → directory prefix → misc fallback; no file may appear in more than one group"
  - "The single-group fast-path preserves exact backward compatibility — no behavior change when all staged files resolve to one group"

---

## Phase 6: Verification Checklist Preparation

- [x] 6.1 Create `openspec/changes/smart-commit-functional-split/verify-report.md` — template with the six success criteria from the proposal as unchecked items (to be checked during sdd-verify):
  - [ ] When staged files span two or more functional directories, `smart-commit` proposes separate commits per group
  - [ ] When all staged files share a single functional area, `smart-commit` behaves identically to the current version
  - [ ] The user can review, edit, or abort each proposed commit message independently before it executes
  - [ ] No files are silently omitted: every staged file appears in exactly one proposed group
  - [ ] The skill continues to block on ERROR conditions (secrets, `.env` files) per existing rules
  - [ ] The updated `SKILL.md` passes `format: procedural` section-contract validation (Triggers, Process, Rules present)
- [x] 6.2 Modify `ai-context/changelog-ai.md` — append a log entry for this session: change name, date, summary of what was modified, and reference to verify-report.md

---

## Implementation Notes

- This change touches ONLY `skills/smart-commit/SKILL.md`. The hook (`hooks/smart-commit-context.js`) and `settings.json` are read-only with respect to this change.
- Phase 2, 3, and 4 tasks are all edits to the same file. Implement them in document order (Step 1b first, then Step 1c, then Step 5 extension) to avoid structural conflicts.
- The `git diff --cached -- <files…>` scoped diff call (Phase 3, task 3.1) is the key mechanism enabling per-group message generation — ensure it is explicitly stated in the SKILL.md prose so the implementer does not use the full `git diff --cached` for per-group analysis.
- The `Co-Authored-By` trailer (SR-08) must appear in every `git commit -m` heredoc in Step 5 — both the existing single-commit path and every iteration of the multi-group loop.
- After implementation, run `install.sh` to deploy the updated skill to `~/.claude/skills/smart-commit/SKILL.md` before running manual verification scenarios.
- The canonical test target is the Audiio V3 project (`D:/Proyectos/Audiio/audiio_v3_1`) as specified in `openspec/config.yaml`.

## Blockers

None.
