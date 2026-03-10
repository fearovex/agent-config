# Closure: sdd-verify-enforcement

Start date: 2026-03-10
Close date: 2026-03-10

## Summary

Added mandatory `## Tool Execution` section and evidence-based `[x]` criteria rule to `sdd-verify`, introduced `verify_commands` config key for custom verification commands, and removed the `/commit` suggestion from `sdd-apply` in favor of `/sdd-verify` as the sole next-step pointer.

## Modified Specs

| Domain | Action | Change |
| ------ | ------ | ------ |
| sdd-verify-execution | Added | 3 new requirements: Tool execution section mandate, [x] evidence rule, verify_commands config key |
| sdd-verify-execution | Modified | Spec Compliance Matrix — UNTESTED now applies when runner exists but no test covers scenario |
| sdd-apply-execution | Added | 1 new requirement: final output MUST NOT suggest /commit |

## Modified Code Files

- `skills/sdd-verify/SKILL.md` — Step 6: verify_commands logic; Step 10: Tool Execution mandate + evidence rule; Rules: two new rules
- `skills/sdd-apply/SKILL.md` — Output to Orchestrator: removed /commit suggestion, replaced with /sdd-verify pointer
- `openspec/config.yaml` — Added verify_commands documentation block (commented)
- `ai-context/changelog-ai.md` — Recorded change
- `ai-context/architecture.md` — Added sdd-verify evidence gate decision

## Key Decisions Made

- `verify_commands` key follows the same pattern as `diagnosis_commands` (same level, same semantics: non-destructive list of strings). When present, overrides auto-detection entirely — not additive.
- `## Tool Execution` section placement: after `## Detail: Testing`, before coverage — follows the logical step order of sdd-verify.
- `[x]` evidence rule enforced via prose in SKILL.md Rules + inline instruction at Step 10, not as a hard code guard (consistent with how all other SDD constraints are enforced).
- sdd-apply commit suggestion fully removed (not disclaimered) to eliminate the temptation entirely.

## Lessons Learned

No blockers or deviations encountered. All 7 tasks completed cleanly. The change is purely textual (SKILL.md + config.yaml), requiring no schema migration and no install.sh beyond the normal deploy.

## User Docs Reviewed

N/A — change does not affect user-facing workflows (no new commands, no renamed skills, no onboarding workflow changes).
