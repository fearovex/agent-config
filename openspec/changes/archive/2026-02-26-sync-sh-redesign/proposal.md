# Proposal: sync-sh-redesign

Date: 2026-02-26
Status: Draft

## Intent

Rewrite `sync.sh` to only capture `memory/` from `~/.claude/` back to the repo, eliminating the footgun where running `sync.sh` before `install.sh` overwrites authored repo content with stale runtime copies.

## Motivation

The current `sync.sh` performs a full mirror of `~/.claude/` into the repo, covering: `CLAUDE.md`, `settings.json`, `skills/`, `hooks/`, `openspec/`, and `ai-context/`. This design is dangerous because:

1. **Incorrect mental model baked in:** `architecture.md` states "Claude modifies `~/.claude/` → sync → commit" as a valid flow. In practice, Claude Code never modifies `skills/`, `CLAUDE.md`, `hooks/`, or `openspec/` during a session — those are always edited in the repo (the CWD).
2. **Active footgun:** If a developer runs `sync.sh` after making repo edits but before running `install.sh`, `sync.sh` overwrites their repo edits with the older `~/.claude/` versions, silently discarding work.
3. **Only one directory legitimately flows `~/.claude/ → repo`:** `memory/` — specifically `~/.claude/memory/MEMORY.md`, which Claude Code writes automatically during any session from any project. All other content has the repo as its source of truth.
4. **Documentation perpetuates the wrong model:** `conventions.md` instructs to "run `sync.sh` before committing to capture `~/.claude/` state" — this is accurate only for `memory/`, not for the rest.

## Scope

### Included

- Rewrite `sync.sh` to sync ONLY `memory/` (`~/.claude/memory/` → `repo/memory/`)
- Add a clear header block to `sync.sh` documenting the mental model (what flows which direction and why)
- Add a clear header block to `install.sh` documenting the mental model (repo → `~/.claude/`, all directories)
- Update `ai-context/architecture.md` to correctly describe the one-way nature of all directories except `memory/`
- Update `ai-context/conventions.md` to fix the `sync.sh` usage description
- Update `CLAUDE.md` (both repo and global) if it contains references to the old sync behavior

### Excluded (explicitly out of scope)

- Renaming `sync.sh` or `install.sh` — names are referenced in documentation, CLAUDE.md, and muscle memory; renaming adds churn with no benefit
- Adding a `--dry-run` flag or other new features to the scripts — this change is a scope reduction, not a feature addition
- Automating `sync.sh` via a git pre-commit hook — that is a separate concern and a separate change
- Modifying any skill SKILL.md files — skills are not affected by this change
- Changing MCP server registration logic in `install.sh`

## Proposed Approach

Replace the body of `sync.sh` with a minimal script that:
1. Copies only `~/.claude/memory/` → `repo/memory/`
2. Prints a clear explanation of what it does and what it does NOT do
3. Reminds the user that `skills/`, `CLAUDE.md`, `hooks/`, `openspec/`, and `ai-context/` are repo-authoritative and do not need syncing

Update `install.sh` header comments to document the data-flow direction for each directory it copies.

Update `ai-context/architecture.md` to remove the bidirectional sync arrow for all directories except `memory/`, and explicitly state that `skills/`, `CLAUDE.md`, `hooks/`, `openspec/`, and `ai-context/` are one-way (repo → `~/.claude/` only).

Update `ai-context/conventions.md` to replace the current `sync.sh` usage description with the corrected one.

Check `CLAUDE.md` for any references to the old sync model and correct them if found.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `sync.sh` | Modified (scope reduction) | High — changes the behavior of the primary sync tool |
| `install.sh` | Modified (comments/header only) | Low — no behavioral change, documentation only |
| `ai-context/architecture.md` | Modified | Medium — corrects the mental model in the memory layer |
| `ai-context/conventions.md` | Modified | Medium — corrects the sync.sh usage instruction |
| `CLAUDE.md` (repo + global) | Modified if needed | Low — minor reference corrections if any found |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Developer forgets that `memory/` still needs syncing before commit | Medium | Low — memory is supplementary context, not critical content | The new `sync.sh` header will make the single responsibility explicit |
| A future contributor re-adds other directories to `sync.sh` without understanding the model | Low | Medium — could reintroduce the footgun | The header documentation in both scripts will explain the invariant |
| `CLAUDE.md` or `conventions.md` references to sync behavior are missed during update | Low | Low — documentation inconsistency only | Grep search of all files for "sync" references before declaring done |

## Rollback Plan

If the change causes issues:
1. `git revert HEAD` — reverts the commit containing the sync.sh rewrite
2. `bash install.sh` — restores the previous `~/.claude/` state from the reverted repo
3. The old `sync.sh` is preserved in git history at the commit before this change

No data loss is possible: `sync.sh` is a read-copy script (it only reads from `~/.claude/` and copies to the repo). Rolling back the script does not affect `~/.claude/` or any repo content beyond the script itself.

## Dependencies

- No prior SDD changes must be in-flight that modify `sync.sh` or `install.sh`
- The `memory/` directory must exist in the repo (it already does — confirmed via exploration)
- Git working tree must be clean before applying (run `git status` to confirm)

## Success Criteria

- [ ] `sync.sh` contains no references to `skills/`, `CLAUDE.md`, `settings.json`, `hooks/`, `openspec/`, or `ai-context/`
- [ ] Running `sync.sh` after editing a skill in the repo does NOT overwrite the skill with the `~/.claude/` copy
- [ ] Running `sync.sh` DOES copy `~/.claude/memory/` into `repo/memory/` correctly
- [ ] `install.sh` header clearly states the data-flow direction for each directory
- [ ] `ai-context/architecture.md` accurately describes the unidirectional flow for all directories except `memory/`
- [ ] `ai-context/conventions.md` sync.sh usage description matches the new behavior
- [ ] `/project-audit` score on `claude-config` is >= the score before this change

## Effort Estimate

Low (hours) — this is primarily a script simplification and documentation correction with no new logic.
