# Task Plan: sync-sh-redesign

Date: 2026-02-26
Design: openspec/changes/sync-sh-redesign/design.md

## Progress: 9/9 tasks

## Phase 1: Script Changes

- [x] 1.1 Modify `sync.sh` — replace the header comment block (lines 1-3) with the multi-line block documenting direction (`~/.claude/memory/ → repo/memory/`), scope (`memory/` only), excluded directories, and the correct workflow pair; remove all `cp` calls for `CLAUDE.md` and `settings.json`; remove all four `sync_dir` calls for `skills/`, `hooks/`, `openspec/`, and `ai-context/`; keep only `sync_dir "$CLAUDE_DIR/memory" "$REPO_DIR/memory"`; replace the final echo block with the four-line version from the design (Done. memory/ synced... / Review with: git diff memory/ / Commit with: git add memory/ && git commit...) ✓
- [x] 1.2 Modify `install.sh` — replace lines 1-3 with the nine-line header block documenting direction (repo → `~/.claude/`), scope (all directories), which dirs are covered, and the note that `memory/` flows the reverse direction via `sync.sh`; make no other changes to the file body ✓

## Phase 2: Documentation — ai-context

- [x] 2.1 Modify `ai-context/architecture.md` — replace the two-layer architecture ASCII diagram and its accompanying "Changes flow" sentence with the per-directory direction diagram from the design (seven rows with `──install──►` arrows and one `◄──sync────` arrow for `memory/`); add the two-workflow summary lines below the diagram (`install.sh: repo/ → ~/.claude/ / sync.sh: ~/.claude/memory/ → repo/memory/`) ✓
- [x] 2.2 Modify `ai-context/architecture.md` — update Key architectural decision item 5: replace "The reverse is `sync.sh`. Never mix directions." with the full two-sentence replacement from the design that clarifies `sync.sh` is one-way for `memory/` only and all other directories are repo-authoritative ✓
- [x] 2.3 Modify `ai-context/conventions.md` — in the Git conventions section replace the single bullet "Always run `sync.sh` before committing to capture `~/.claude/` state" with the two-bullet replacement from the design (Workflow B bullet for memory capture + Workflow A bullet for config changes) ✓
- [x] 2.4 Modify `ai-context/conventions.md` — replace the entire `install.sh / sync.sh usage` section with the two-workflow description (Workflow A and Workflow B) from the design; ensure no instruction instructs running `sync.sh` to capture skills or CLAUDE.md ✓

## Phase 3: Documentation — CLAUDE.md

- [x] 3.1 Modify `CLAUDE.md` — update Tech Stack table row for `sync.sh`: change description from `~/claude-config → ~/.claude/` to `~/.claude/memory/ → repo/memory/ only` ✓
- [x] 3.2 Modify `CLAUDE.md` — rewrite Sync discipline rule 4: replace the two existing bullets with the three-bullet replacement from the design (run sync.sh for memory only / config changes use install.sh / never run sync.sh expecting skills or CLAUDE.md capture) ✓
- [x] 3.3 Modify `CLAUDE.md` — update SDD meta-cycle line: change `sync.sh` to `install.sh` in the cycle line; update Plan Mode "After apply" step: replace `` `sync.sh` `` with `` `install.sh` (deploy config) `` ✓

---

## Implementation Notes

- Tasks 1.1 and 1.2 are independent of each other and can be done in either order.
- Tasks 2.1 and 2.2 both modify `ai-context/architecture.md` — they must be done sequentially (2.1 first, then 2.2) to avoid conflicts.
- Tasks 2.3 and 2.4 both modify `ai-context/conventions.md` — they must be done sequentially (2.3 first, then 2.4).
- Task 3.3 contains two sub-changes in the same file (meta-cycle line and Plan Mode step) — they should be applied together in a single edit pass.
- `CLAUDE.md` exists at both `C:/Users/juanp/claude-config/CLAUDE.md` (repo) and `C:/Users/juanp/.claude/CLAUDE.md` (runtime). After task 3.x completes, run `bash install.sh` to propagate the change to the runtime copy — this is not a separate task, it is part of the standard Workflow A commit flow.
- `sync.sh` must handle the case where `~/.claude/memory/` does not exist gracefully (per spec scenario "sync.sh runs when ~/.claude/memory/ does not exist") — verify the rewritten script guards against this or adds an existence check before the `sync_dir` call.

## Blockers

None.
