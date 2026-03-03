# Technical Design: smart-commit-auto-stage

Date: 2026-03-03
Proposal: openspec/changes/smart-commit-auto-stage/proposal.md

## General Approach

Replace the `git diff --cached` guard in Step 1 of `skills/smart-commit/SKILL.md` with a full working-tree scan via `git status --porcelain`. Each detected file is tagged with a `staging-status` value (`staged`, `unstaged`, or `untracked`). The tag flows through grouping unchanged, is surfaced in the multi-commit plan display, and is used at commit time to issue `git add` only for files the user has confirmed — leaving rejected and skipped groups completely untouched. The existing grouping heuristic (Step 1b) is not modified.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Working-tree detection command | `git status --porcelain` (replaces `git diff --cached --stat` guard) | `git status --short`, manual `git ls-files` calls | `--porcelain` is stable across git versions, machine-parseable, and returns a two-column status code that distinguishes staged (index column), unstaged (worktree column), and untracked (`??`) in a single pass |
| Staging-status model | Three-value tag per file: `staged`, `unstaged`, `untracked` | Boolean `needs-staging` flag | Three values allow precise display annotations and correct `git add` decisions; a boolean would conflate `unstaged` and `untracked`, which have different implications for the user |
| Scope of auto-staging | Per confirmed group, immediately before `git commit` | Stage all detected files upfront before plan display; stage all at once after plan confirmation | Staging at commit time ensures rejected/skipped groups are never touched; upfront staging would require cleanup on abort; batch-after-plan does not allow abort-remaining to preserve state for later groups |
| Halt condition | No files detected by `git status --porcelain` (completely clean working tree) | Keep the "no staged files" halt (old behavior); halt on any non-staged file | Clean-tree halt is the only unambiguous case where smart-commit has nothing to do; old halt breaks the feature; halting on unstaged-only would regress the primary use case |
| `git add` scope within a group | Only files tagged `unstaged` or `untracked` in the confirmed group | `git add .` per group; re-add all files including already-staged | Scoped add is surgically correct; `git add .` could introduce unintended files; re-adding already-staged files is a no-op but introduces risk if index was partially modified externally |
| Single-group fast-path auto-staging | Print "Auto-staging N file(s): <list>" before `git add`, then proceed | Silent auto-stage; abort prompt | One-line announcement gives the user last-second visibility without introducing a confirmation gate that would break the fast-path contract (SR-03) |
| Rename entry parsing | Split `R old -> new` on arrow, include both paths in group | Include only new path; include only old path | Both paths are needed: the old path must be staged for removal, the new path for addition; omitting either produces an incomplete commit |

## Data Flow

```
User invokes /commit
       │
       ▼
Step 1: git status --porcelain
       │
       ├─ No output → "Nothing to commit. Working tree is clean." → STOP
       │
       └─ Files detected
              │
              ▼
       Parse porcelain output → assign staging-status tag per file
         [XY path] or [XY old -> new]
         - X=A/M/R/D, Y=' ' → staged
         - X=' ', Y=M/D      → unstaged
         - XY=??             → untracked
         - X=R               → rename: split paths, both tagged staged
              │
              ▼
Step 1b: Apply grouping heuristic (UNCHANGED)
         test → chore → docs → directory-prefix → misc
         Each file assigned to exactly one group
         staging-status tag travels with the file
              │
              ├─ 1 group → single-group fast-path
              │    │
              │    ▼
              │  Any unstaged/untracked in group?
              │    ├─ Yes → print "Auto-staging N file(s): <list>"
              │    │         git add <unstaged/untracked files>
              │    └─ No  → no add needed
              │    │
              │    └─→ Step 2 (message gen) → Step 3 (issue detect) →
              │         Step 4 (summary + confirm) → Step 5 (git commit)
              │
              └─ 2+ groups → multi-group branch
                   │
                   ▼
         Step 1c: Generate message + detect issues per group (scoped diff)
                   │
                   ├─ Any ERRORs → display all ERRORs → STOP
                   │
                   └─ No ERRORs → Display multi-commit plan
                         (file list with staging-status annotation per file)
                         │
                         ▼
                    [commit all / step-by-step / abort]
                         │
                    ┌────┴────┐
                    │         │
                  abort    confirm path
                    │         │
                    ▼         ▼
              No changes  For each confirmed group:
                          1. git add <unstaged/untracked files in group>
                          2. git commit -m "<message>"
                          3. Print hash
                          (skipped groups: no git add, no git commit)
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/smart-commit/SKILL.md` | Modify | Step 1: replace `git diff --cached` guard with `git status --porcelain` scan + staging-status tagging; Step 1b: add staging-status tag to file records (grouping rules unchanged); Step 1c: add staging-status annotation to plan display; Step 5: add `git add` calls for unstaged/untracked files before each confirmed group's `git commit`; `## Rules`: remove "only staged files in scope" rule, add selective auto-staging rules |
| `openspec/specs/smart-commit/spec.md` | Modify | Add requirements SR-10 (full working-tree detection), SR-11 (staging-status annotation in plan), SR-12 (selective auto-staging per confirmed group), SR-13 (skip-preserves-state invariant), each with at least two scenarios |

## Interfaces and Contracts

**Staging-status tag** — an internal label attached to each file record during Step 1 parsing:

```
staging-status ::= "staged" | "unstaged" | "untracked"
```

Derivation from `git status --porcelain` two-column code `XY`:

```
XY = "??"             → untracked
X in {A,M,R,D,C}
  Y = " " or "?"      → staged
X = " "
  Y in {M,D,T}        → unstaged
X in {A,M,R,D,C}
  Y in {M,D,T}        → staged  (index change takes precedence for staging decision;
                                  worktree modification noted but file is already staged)
Rename entries R:     → parse "old -> new"; both paths tagged staged
```

**Porcelain parsing rules:**

```
line format:  "XY path"          (standard)
              "XY old -> new"    (rename/copy, only when X=R or X=C)

path extraction:
  - standard:  path = line[3:]
  - rename:    old = segment before " -> "; new = segment after " -> "
               include both paths; both receive staging-status = staged
```

**Auto-staging precondition** (enforced in Step 5 before `git commit`):

```
for each file in confirmed_group:
  if staging-status in {unstaged, untracked}:
    git add <file>
  // staged files: no action
```

**Halt condition (new)**:

```
if git status --porcelain returns empty output:
  print: "Nothing to commit. Working tree is clean."
  stop
```

**Old halt condition (removed)**:

```
// REMOVED: if git diff --cached --stat returns empty: halt with "No staged files found"
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual / interactive | Full flow: run `/commit` with only unstaged changes; verify grouping, plan display with annotations, auto-staging per confirmed group, skipped groups remain untouched | Manual git repo session |
| Manual / interactive | Single-group fast-path with mix of staged + unstaged files; verify "Auto-staging N file(s)" announcement and single commit result | Manual git repo session |
| Manual / interactive | Multi-group "commit all" path with staged + unstaged files across groups; verify all groups committed and only confirmed files were staged | Manual git repo session |
| Manual / interactive | Step-by-step with skip: confirm group 1, skip group 2, confirm group 3; verify group 2 files remain unstaged | Manual git repo session |
| Manual / interactive | Abort at plan level; verify no files were staged and no commits executed | Manual git repo session |
| Manual / interactive | Untracked files only in working tree; verify they are detected, grouped, annotated, and staged+committed on confirmation | Manual git repo session |
| Manual / interactive | Mix of already-staged and unstaged files in same group; verify already-staged files are not re-added | Manual git repo session |
| Manual / interactive | Rename (`git mv`) entry in porcelain output; verify both old and new paths appear in group and commit succeeds | Manual git repo session |
| Regression | All SR-01 through SR-09 scenarios: same staged-only inputs produce identical outcomes (grouping, message format, ERROR blocking, plan display, commit execution) | Manual git repo session |

## Migration Plan

No data migration required.

This change modifies the runtime behavior of `skills/smart-commit/SKILL.md` only. No database, no schema, no external state. The only deployment action needed after apply is running `install.sh` to copy the updated skill to `~/.claude/skills/smart-commit/`.

## Open Questions

None.
