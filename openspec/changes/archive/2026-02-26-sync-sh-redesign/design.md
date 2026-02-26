# Technical Design: sync-sh-redesign

Date: 2026-02-26
Proposal: openspec/changes/sync-sh-redesign/proposal.md

## General Approach

Replace the body of `sync.sh` with a minimal script that copies only `~/.claude/memory/` into `repo/memory/`, then adds documenting header comments to both scripts. Update three documentation files (`ai-context/architecture.md`, `ai-context/conventions.md`, `CLAUDE.md`) to correct the mental model from bidirectional sync to the correct two-workflow model. No logic changes to `install.sh` beyond the header comment.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Scope of sync.sh rewrite | Remove all dirs except `memory/`; keep the `sync_dir` helper for the single call | Remove `sync_dir` helper and inline a direct `cp -r` | Keeping the helper preserves the existing pattern and makes the "only memory" intent explicit through what is NOT called; also easier to extend safely if a second dir is ever added |
| Header block placement | Multi-line comment block at top of each script, above `set -e` | Inline comments scattered through the body | A single block at the top is the first thing a developer reads; it conveys intent before they see any code |
| Header block content for sync.sh | State the single responsibility, list dirs that are EXCLUDED and why, name the correct workflow pair | List only what it does | Knowing what it intentionally does NOT do prevents a future contributor from "fixing" the perceived omission |
| `install.sh` changes | Header comment only, zero logic changes | Also add `--delete` / cleanup logic | The proposal explicitly excludes logic changes to `install.sh`; behavioral parity is preserved |
| CLAUDE.md Tech Stack table row | Change `sync.sh` description from `~/claude-config → ~/.claude/` to `~/.claude/memory/ → repo/memory/` | No change | The table is the canonical one-line description of each tool; it currently states the wrong direction |
| CLAUDE.md Sync discipline rule | Rewrite rule 4 to describe the two-workflow model | Delete the rule | The rule still has value; it just needs to describe the correct behavior |
| CLAUDE.md SDD meta-cycle line | Keep `sync.sh` in the cycle but add a parenthetical `(memory only)` | Remove sync.sh from the meta-cycle | The cycle is correct; only the implied scope of sync.sh needs clarification |
| architecture.md diagram | Replace the single bidirectional sync arrow with per-directory direction markers; add `memory/` as the only `~/.claude/ → repo` arrow | Redraw as a table | ASCII diagram with per-row arrows is the existing pattern in the file; keeping it consistent is better |
| conventions.md sync section | Replace the single-sentence instructions with the two-workflow model (Workflow A and Workflow B) | Add a warning footnote only | The existing single-sentence model is incorrect for Workflow A; a full replacement is needed to avoid ambiguity |

## Data Flow

### Current (broken) model

```
Developer edits skill in repo
         |
         v
   Developer runs sync.sh
         |
         v  (DANGER: overwrites repo edits with stale ~/.claude/ copies)
   repo/ ← mirrors all of ~/.claude/
         |
         v
   git commit
```

### Correct model after this change

```
Workflow A — config changes (skills, CLAUDE.md, hooks, openspec, ai-context):

   Developer edits files in repo/
         |
         v
   bash install.sh      (repo/ → ~/.claude/, all directories)
         |
         v
   git add + git commit


Workflow B — memory capture (MEMORY.md written by Claude Code during any session):

   Claude Code writes ~/.claude/memory/MEMORY.md during session
         |
         v
   bash sync.sh         (only: ~/.claude/memory/ → repo/memory/)
         |
         v
   git add memory/ + git commit


Directory authority map:

   CLAUDE.md     repo/ ──install──► ~/.claude/     (repo is source of truth)
   settings.json repo/ ──install──► ~/.claude/     (repo is source of truth)
   skills/       repo/ ──install──► ~/.claude/     (repo is source of truth)
   hooks/        repo/ ──install──► ~/.claude/     (repo is source of truth)
   openspec/     repo/ ──install──► ~/.claude/     (repo is source of truth)
   ai-context/   repo/ ──install──► ~/.claude/     (repo is source of truth)
   memory/       ~/.claude/ ──sync──► repo/        (runtime is source of truth)
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `sync.sh` | Modify | Replace header comment; remove `cp` calls for `CLAUDE.md` and `settings.json`; remove four `sync_dir` calls (skills, hooks, openspec, ai-context); keep only `sync_dir "$CLAUDE_DIR/memory" "$REPO_DIR/memory"`; update final echo messages |
| `install.sh` | Modify (comment only) | Replace single-line header with a multi-line block documenting: direction (repo → `~/.claude/`), which directories are covered, and a note that `memory/` is the only dir that flows the reverse direction via `sync.sh` |
| `ai-context/architecture.md` | Modify | Replace the two-layer architecture ASCII diagram and the "Changes flow" sentence; add per-directory direction markers; remove the bidirectional `←sync─` arrow; add a note that only `memory/` flows `~/.claude/ → repo`; update "Key architectural decisions" item 5 |
| `ai-context/conventions.md` | Modify | Replace the `install.sh / sync.sh usage` section with a two-workflow description (Workflow A and Workflow B); remove the blanket "run sync.sh before committing" instruction from the Git conventions bullet |
| `CLAUDE.md` | Modify | (1) Tech Stack table: fix `sync.sh` row description; (2) Sync discipline rule 4: rewrite to describe the two-workflow model; (3) SDD meta-cycle line: add `(memory only)` qualifier after `sync.sh`; (4) Plan Mode "After apply" step: clarify that sync.sh captures memory only, not skills |

## Interfaces and Contracts

This change involves no code interfaces. The behavioral contract of `sync.sh` changes as follows:

```
# BEFORE
sync.sh contract:
  Reads:  ~/.claude/{CLAUDE.md, settings.json, memory/, skills/, hooks/, openspec/, ai-context/}
  Writes: repo/{CLAUDE.md, settings.json, memory/, skills/, hooks/, openspec/, ai-context/}
  Side effect: silently overwrites any repo edits with ~/.claude/ versions

# AFTER
sync.sh contract:
  Reads:  ~/.claude/memory/
  Writes: repo/memory/
  Side effect: none (memory/ is never edited in repo directly)
```

`install.sh` contract is unchanged — it remains a full repo → `~/.claude/` mirror.

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual | Run `sync.sh` after editing a skill file in repo — confirm the skill file is NOT overwritten | Manual inspection with `git diff` |
| Manual | Run `sync.sh` — confirm `repo/memory/MEMORY.md` reflects `~/.claude/memory/MEMORY.md` contents | Manual inspection |
| Manual | Run `install.sh` — confirm all dirs including `memory/` are copied to `~/.claude/` | Manual inspection |
| Audit | Run `/project-audit` — confirm score >= score before this change | `project-audit` skill |

No automated tests exist in this repo. Verification is by manual inspection and audit score.

## Migration Plan

No data migration required. `sync.sh` is a read-copy script; rewriting it does not alter any existing files in the repo or in `~/.claude/`. The `memory/` directory already exists in the repo (`memory/MEMORY.md` confirmed present).

## Specific Content Changes

### sync.sh — complete rewrite

New header block replaces lines 1-3:
```bash
#!/usr/bin/env bash
# sync.sh — Captures ~/.claude/memory/ into the repo for committing.
#
# DIRECTION: ~/.claude/memory/ → repo/memory/   (one direction only)
# SCOPE:     memory/ ONLY
#
# This script intentionally does NOT sync:
#   skills/, hooks/, openspec/, ai-context/, CLAUDE.md, settings.json
# Those directories are repo-authoritative. The correct flow for them is:
#   edit in repo → bash install.sh → git commit
#
# Use this script (Workflow B) only to capture MEMORY.md written by Claude Code:
#   bash sync.sh → git add memory/ → git commit
```

Lines to remove: the two `cp` calls (CLAUDE.md, settings.json) and four `sync_dir` calls (skills, hooks, openspec, ai-context).

Final echo block updated to:
```bash
echo ""
echo "Done. memory/ synced from ~/.claude/memory/"
echo "Review with: git diff memory/"
echo "Commit with: git add memory/ && git commit -m 'chore: sync memory'"
```

### install.sh — header comment only

New header block replaces lines 1-3:
```bash
#!/usr/bin/env bash
# install.sh — Deploys repo content to ~/.claude/ (one direction only).
#
# DIRECTION: repo/ → ~/.claude/   (one direction only)
# SCOPE:     all directories (CLAUDE.md, settings.json, skills/, hooks/,
#            openspec/, ai-context/, memory/)
#
# This is the authoritative restore script for a new machine or after a reset.
# The reverse direction (capturing runtime changes) applies ONLY to memory/:
#   bash sync.sh  ← use this to capture ~/.claude/memory/ back to the repo
```

### ai-context/architecture.md — Two-layer architecture section

Replace the current diagram and "Changes flow" sentence with:

```
## Two-layer architecture

claude-config (repo)          ~/.claude/ (runtime)
      │                              │
      ├── CLAUDE.md    ──install──►  ├── CLAUDE.md       ← Claude reads at session start
      ├── settings.json ─install──►  ├── settings.json   ← Claude Code config
      ├── skills/      ──install──►  ├── skills/         ← Claude reads on demand
      ├── hooks/       ──install──►  ├── hooks/          ← Event hooks
      ├── openspec/    ──install──►  ├── openspec/       ← SDD artifacts
      ├── ai-context/  ──install──►  ├── ai-context/     ← Project memory
      └── memory/      ◄──sync────   └── memory/        ← Claude writes during sessions

install.sh: repo/ → ~/.claude/  (all directories, one direction)
sync.sh:    ~/.claude/memory/ → repo/memory/  (memory only, one direction)
```

Remove the sentence: "Changes flow: **edit in repo → sync → commit** OR **Claude modifies `~/.claude/` → sync → commit**"

Replace with:
```
Two workflows:
- Workflow A (config changes): edit in repo → bash install.sh → git commit
- Workflow B (memory capture): Claude writes ~/.claude/memory/ → bash sync.sh → git commit
```

Also update Key architectural decision #5:
- Before: "**install.sh is one-way** — repo → `~/.claude/`. The reverse is `sync.sh`. Never mix directions."
- After: "**install.sh is one-way** — repo → `~/.claude/` for all directories. `sync.sh` is also one-way but in the reverse direction for `memory/` only. All other directories are repo-authoritative and never flow from `~/.claude/` to repo."

### ai-context/conventions.md — Git conventions + install.sh/sync.sh sections

In the Git conventions section, replace:
```
- Always run `sync.sh` before committing to capture `~/.claude/` state
```
With:
```
- Run `sync.sh` before committing ONLY when capturing memory (Workflow B: `~/.claude/memory/` → repo)
- For config changes (skills, CLAUDE.md, hooks, etc.) run `install.sh` after editing in repo, then commit
```

Replace the entire `install.sh / sync.sh usage` section with:
```
## install.sh / sync.sh usage

Two distinct workflows — do NOT mix them:

**Workflow A — config changes** (skills, CLAUDE.md, hooks, openspec, ai-context):
1. Edit files in the repo
2. `bash install.sh` — deploys repo → `~/.claude/`
3. `git add + git commit`

**Workflow B — memory capture** (MEMORY.md written by Claude Code during sessions):
1. Claude Code writes `~/.claude/memory/MEMORY.md` automatically
2. `bash sync.sh` — copies `~/.claude/memory/` → `repo/memory/`
3. `git add memory/ && git commit`

Never run `sync.sh` after editing skills or CLAUDE.md in the repo — it only touches `memory/` and
will not overwrite your edits, but running it at the wrong time adds no value and may confuse the diff.
```

### CLAUDE.md — four targeted changes

1. Tech Stack table row (line 22):
   - Before: `| Sync | sync.sh (~/claude-config → ~/.claude/) |`
   - After:  `| Sync | sync.sh (~/.claude/memory/ → repo/memory/ only) |`

2. Sync discipline rule 4 (lines 56-57):
   - Before:
     ```
     - Always run sync.sh before committing
     - Never edit ~/.claude/ directly without syncing back to the repo
     ```
   - After:
     ```
     - Run sync.sh before committing ONLY to capture memory/ (Workflow B)
     - For config changes (skills, CLAUDE.md, hooks): edit in repo → install.sh → commit (Workflow A)
     - Never run sync.sh expecting it to capture skills or CLAUDE.md — it only syncs memory/
     ```

3. SDD meta-cycle line (line 38):
   - Before: `/sdd-ff <change>  →  review  →  /sdd-apply  →  sync.sh  →  git commit`
   - After:  `/sdd-ff <change>  →  review  →  /sdd-apply  →  install.sh  →  git commit`
   - Note: The meta-cycle for config changes is Workflow A (install.sh), not sync.sh. sync.sh is only for memory capture.

4. Plan Mode "After apply" step (line 77):
   - Before: `- Run \`sync.sh\` and \`git commit\` before archiving`
   - After:  `- Run \`install.sh\` (deploy config) and \`git commit\` before archiving`

## Open Questions

None. The scope is fully defined by the proposal and the current code is straightforward.
