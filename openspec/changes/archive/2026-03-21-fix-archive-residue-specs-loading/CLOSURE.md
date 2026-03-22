# Closure: 2026-03-21-fix-archive-residue-specs-loading

Start date: 2026-03-21
Close date: 2026-03-21

## Summary

Fixed three interconnected SDD system reliability gaps: (1) sdd-archive Step 4 now verifies source directory deletion with a two-branch check (bash + MCP fallback) and reports WARNING with recovery instructions if deletion fails; (2) all 7 SDD phase skills implement index-first spec discovery (keyword scoring via index.yaml, directory fallback, hard cap at 3); (3) sdd-ff implements a post-explore contradiction gate that fires on UNCERTAIN contradictions before proposing.

## Modified Specs

| Domain                   | Action   | Change                                                              |
| ------------------------ | -------- | ------------------------------------------------------------------- |
| sdd-archive-execution    | Modified | Added Step 4 deletion verification requirement with two-branch logic |
| sdd-orchestration        | Modified | Added post-explore contradiction gate requirement (ADR 023 impl)     |
| spec-context-discovery   | Created  | New master spec: index-first spec discovery algorithm for all 7 phase skills |

## Modified Code Files

- `~/.claude/skills/sdd-archive/SKILL.md` — Step 4: two-branch deletion verification block
- `~/.claude/skills/sdd-explore/SKILL.md` — Step 0c: index-first spec loading algorithm
- `~/.claude/skills/sdd-propose/SKILL.md` — Step 0c: index-first spec loading algorithm
- `~/.claude/skills/sdd-spec/SKILL.md` — Step 0c: index-first spec loading algorithm
- `~/.claude/skills/sdd-design/SKILL.md` — Step 0c: index-first spec loading algorithm
- `~/.claude/skills/sdd-tasks/SKILL.md` — Step 0c: index-first spec loading algorithm
- `~/.claude/skills/sdd-apply/SKILL.md` — Step 0c: index-first spec loading algorithm
- `~/.claude/skills/sdd-verify/SKILL.md` — Step 0c: index-first spec loading algorithm
- `~/.claude/skills/sdd-ff/SKILL.md` — Step 2a contradiction gate sub-step
- `~/.claude/skills/project-setup/SKILL.md` — Step 5: index.yaml scaffolding
- `CLAUDE.md` / `openspec/config.yaml` — documentation updates
- `openspec/specs/index.yaml` — new entry for spec-context-discovery

## Key Decisions Made

1. **Deletion verification uses two-branch logic**: Branch A uses bash `test -d` result string; Branch B uses `mcp__filesystem__list_directory` failure/success (not exit code). Ensures platform tolerance on Windows + Git Bash.
2. **Verification is non-blocking**: Deletion failure sets `status: warning`, never `status: failed`. Archive proceeds to Step 5 regardless.
3. **Index-first algorithm is identical across all 7 phase skills**: Consistency enforced by applying the same algorithm block. EXACT keyword match scores 1.0; STEM match scores 0.5; hard cap at 3 domains.
4. **Contradiction gate only fires on UNCERTAIN**: CERTAIN contradictions are informational. Pre-existing exploration.md bypasses the gate (user already decided in a prior session).
5. **User options at the gate are Yes/No/Review** (not 1/2 binary as originally designed). This is a UX improvement; behavioral contract is preserved.

## Lessons Learned

- The gate prompt option naming deviated from design.md (Yes/No/Review vs. 1/2). The deviation is beneficial UX but worth updating future specs to use canonical wording.
- Three interdependent changes were delivered in a single SDD cycle; phased apply strategy (Phase 1 → 2 → 3) allowed verification after each phase and was effective.
- User docs checkbox ([ ]) was left unchecked at archive time — change adds new behaviors (contradiction gate prompt, deletion verification warnings) that may benefit from user-facing documentation. Not blocking.

## User Docs Reviewed

NO — change does not directly affect user-facing workflow narratives, but new behaviors (contradiction gate and deletion verification WARNING) may warrant updates to ai-context/scenarios.md in a future session.
