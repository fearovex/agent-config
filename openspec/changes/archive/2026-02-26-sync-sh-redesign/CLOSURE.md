# Closure: sync-sh-redesign

Start date: 2026-02-26
Close date: 2026-02-26

## Summary

Rewrote `sync.sh` to sync only `memory/` from `~/.claude/` to the repo, eliminating the footgun where running `sync.sh` overwrote authored repo content with stale runtime copies. Updated `install.sh`, `ai-context/architecture.md`, `ai-context/conventions.md`, and `CLAUDE.md` to document the correct two-workflow mental model.

## Modified Specs

No delta specs were created for this change. The change modified scripts and documentation only — no domain specs with ADDED/MODIFIED/REMOVED sections were produced.

## Modified Code Files

| File | Change |
|------|--------|
| `sync.sh` | Rewrote body: removed all `cp`/`sync_dir` calls except `memory/`; added header block documenting scope and exclusions |
| `install.sh` | Added header block documenting direction and scope (zero logic changes) |
| `ai-context/architecture.md` | Replaced bidirectional sync diagram with per-directory direction markers; added two-workflow summary; updated key decision #5 |
| `ai-context/conventions.md` | Replaced single "run sync.sh before committing" bullet with Workflow A / Workflow B two-workflow description |
| `CLAUDE.md` | Fixed Tech Stack sync.sh row; rewrote Sync discipline rule 4 (3 bullets); changed SDD meta-cycle to use `install.sh`; changed Plan Mode "After apply" to use `install.sh` |

## Key Decisions Made

1. **sync.sh scope is memory/ only** — all other directories (`skills/`, `CLAUDE.md`, `hooks/`, `openspec/`, `ai-context/`) are repo-authoritative and flow only via `install.sh`. `sync.sh` never writes those.

2. **Two-workflow model is canonical** — Workflow A (config changes): edit in repo → `bash install.sh` → `git commit`. Workflow B (memory capture): Claude writes `~/.claude/memory/` → `bash sync.sh` → `git commit`. The SDD meta-cycle for config changes uses Workflow A (install.sh), not sync.sh.

3. **sync_dir helper removed (implementation deviation)** — The design specified keeping the `sync_dir` helper for the single memory call; the implementation used a direct `cp -r` inline instead. The result is functionally equivalent and arguably clearer. Documented as a warning-level deviation in the verify-report; no correctness issue.

4. **install.sh logic left completely unchanged** — behavioral parity was preserved; only a header comment was added. This matches the proposal's explicit exclusion of logic changes to `install.sh`.

## Lessons Learned

- The verify-report identified three out-of-scope gaps (CLAUDE.md Architecture `←sync→` arrow, `ai-context/stack.md` old instruction, `ai-context/conventions.md` SDD workflow line) that remain as documentation inconsistencies. These were intentionally left out of scope but should be addressed in a follow-up pass.
- The design decision to keep `sync_dir` as a helper was overridden during implementation in favor of a simpler direct `cp -r`. When implementation simplifications diverge from documented design decisions, the verify-report correctly flags this as a coherence warning. Future designs should note that documented helper-preservation decisions are easily dropped if the helper adds no value at a single call-site.
- No automated tests exist in this repo. All verification was done by manual code review and `/project-audit`. This is by design but means the Testing dimension will always produce warnings.

## Warnings Left Unresolved (PASS WITH WARNINGS)

1. `sync_dir` helper removed instead of preserved — functionally correct deviation.
2. `CLAUDE.md` Architecture section still has `←sync→` bidirectional-looking arrow (line 28) — out-of-scope gap.
3. `ai-context/stack.md` line 68 still contains old sync model instruction — out-of-scope gap.
4. `ai-context/conventions.md` line 64 SDD workflow summary still references `sync.sh` — out-of-scope gap.
