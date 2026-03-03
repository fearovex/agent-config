# Technical Design: smart-commit-functional-split

Date: 2026-03-03
Proposal: openspec/changes/smart-commit-functional-split/proposal.md

## General Approach

The change inserts a new **Step 1b — Group staged files** between the existing Step 1 (read staged state) and Step 2 (analyze changes) in `skills/smart-commit/SKILL.md`. A priority-ordered grouping heuristic clusters staged files into functional groups. When only one group is produced, execution falls through unchanged to the existing single-commit flow. When multiple groups are produced, a multi-commit plan is presented to the user for review before any commit fires, then commits are executed sequentially — one per group — each reusing the existing message-generation and issue-detection logic from Steps 2–3.

No new files, no external dependencies, and no changes to the hook or settings.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Grouping heuristic placement | New Step 1b in SKILL.md procedural flow | Pre-processing in hook; separate grouper skill | Keeps all commit logic in one skill file; the hook is context-injection only and must not gain commit logic. A separate grouper skill would add indirection for a self-contained behavioral change. |
| Grouping algorithm | Priority-ordered heuristic (test files → docs → config/infra → directory prefix) | ML-based clustering; git-infer-topic | No external dependencies allowed; the priority ordering produces deterministic, reviewable groups that match conventional commit conventions (test, docs, chore types have clear boundaries before falling back to directory). This is a convention — not architecture-wide — so no ADR is required. |
| Multi-commit presentation format | Numbered plan block shown in full before any commit fires | Interactive picker; one-by-one prompt per file | Text-based format is consistent with the existing Step 4 summary block. The full plan up-front allows the user to abort before any side effect. Matches the existing "No TUI" constraint from the proposal. |
| Sequential commit execution | One `git commit` per group, in plan order | Batch commit with --allow-empty; single commit with co-authors | Git requires linear history; semantic grouping is the stated goal. A single commit would defeat the purpose. Batch with --allow-empty adds noise. Sequential execution is the minimum correct solution. |
| Single-group fast-path | Fall through to existing Steps 2–5 unchanged | Always run multi-commit path | Preserves exact backward compatibility for the common case (focused change). No behavior change for single-group staged sets, which eliminates regression risk for the typical workflow. |
| Abort semantics | Full abort before first commit; per-commit abort after first fires | Atomic rollback of all commits | Once the first commit fires it is in git history — rollback is out of scope per the proposal. The plan must be shown in full before the first commit so the user can abort cleanly. After that, each remaining commit can be individually aborted, leaving the already-committed groups intact. |

## Data Flow

```
git diff --cached --stat
        │
        ▼
  Step 1b — Group staged files
        │
        ├─── Single group ─────────────────────────────────────────────────┐
        │                                                                   │
        ▼                                                                   │
  Multi-commit plan                                                         │
  (present ALL groups before firing)                                        │
        │                                                                   │
        │  User: abort? → stop                                              │
        │  User: proceed / edit? → continue                                 │
        ▼                                                                   ▼
  For each group (sequential):                               Step 2 — Analyze changes
    Step 2 — Analyze (group diff)                           Step 3 — Detect issues
    Step 3 — Detect issues (group diff)                     Step 4 — Present summary
    Step 4 — Present group summary + confirm                Step 5 — Execute commit
    Step 5 — Execute commit
        │
        ▼
  Report: all commits fired + hashes
```

### Grouping heuristic — priority order

```
Input: list of staged file paths from git diff --cached --stat

Rule 1 (Test files):
  paths matching *.test.*, *.spec.*, _test.* → group: "test"

Rule 2 (Docs):
  paths under docs/ OR *.md at root OR README* → group: "docs"

Rule 3 (Config/infra):
  root-level files matching *.json, *.yaml, *.yml, *.toml, *.sh, *.env* → group: "chore"

Rule 4 (Directory prefix):
  remaining files grouped by their top-level directory segment
  (e.g., skills/smart-commit/... → group: "skills/smart-commit")

Degenerate case:
  root-level files not matching Rules 1–3 → group: "root"

Single-group result → fall through to existing Step 2 unchanged
Multiple groups      → proceed to multi-commit plan
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/smart-commit/SKILL.md` | Modify | Insert Step 1b (group staged files); extend Step 2 to operate on per-group diffs; extend Step 4 to present multi-commit plan; extend Step 5 to execute sequentially per group; update Rules section |

No other files require modification. The hook (`hooks/smart-commit-context.js`) and `settings.json` are read-only with respect to this change.

## Interfaces and Contracts

The grouping step produces an internal data structure (represented here as pseudo-schema for specification clarity — this is a SKILL.md procedural skill, not code):

```
GroupedStaged {
  groups: [
    {
      label: string          // e.g. "skills/smart-commit", "docs", "test", "chore"
      files: string[]        // absolute or repo-relative paths
      diff: string           // output of: git diff --cached -- <files...>
      stat: string           // output of: git diff --cached --stat -- <files...>
    }
  ]
  single_group: boolean      // true when groups.length === 1
}
```

### Multi-commit plan presentation format

```
## Smart Commit Plan (N commits)

────────────────────────────────────
Commit 1 of N — [label]
Files: file-a.md, file-b.md
Proposed message:
  docs(adr): add ADR-012 for smart-commit grouping
────────────────────────────────────
Commit 2 of N — [label]
Files: skills/smart-commit/SKILL.md
Proposed message:
  feat(smart-commit): add functional grouping step
────────────────────────────────────

Issues detected across all groups:
  ⛔ ERROR in commit 2: ...   (if any — blocks that group)
  ⚠️  WARNING in commit 1: ...

Proceed with all commits? [y / review each / abort]
```

### Per-commit confirmation (when user chooses "review each")

```
## Commit N of M — [label]

**Files:** file-a.md, file-b.md
**Proposed message:**
──────────────────────────────
type(scope): description
- bullet 1
──────────────────────────────

Proceed? [y / edit message / skip / abort remaining]
```

`skip` leaves that group's files in the staging area without committing them.
`abort remaining` stops after the current group, leaving subsequent groups staged.

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual — single group | Stage files all in one directory; verify single-commit path fires unchanged | git + Claude |
| Manual — two groups | Stage files from `skills/` and `docs/`; verify two proposed commits | git + Claude |
| Manual — test group isolation | Stage a `*.spec.md` alongside feature files; verify test group is separated | git + Claude |
| Manual — error blocking | Stage a `.env` file alongside normal files; verify the group containing it is blocked, others proceed | git + Claude |
| Manual — abort mid-sequence | Stage 3 groups; fire first commit, then abort; verify first commit is in history and remaining files are staged | git + Claude |
| Manual — edit message | Stage 2 groups; choose "review each"; edit one message; verify the edited message is used verbatim | git + Claude |

No automated test framework applies (SKILL.md is procedural prose, not code). All testing is manual scenario-based.

## Migration Plan

No data migration required. The change modifies only `skills/smart-commit/SKILL.md`. Any project already using smart-commit will get the new grouping behavior automatically after `install.sh` is run. Single-group staged sets trigger the fast-path and are behaviorally identical to the current version.

## Open Questions

None.
