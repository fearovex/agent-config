# Closure: batch-audit-bash-calls

Start date: 2026-02-26
Close date: 2026-02-26

## Summary

Consolidated the 20+ individual Bash calls in the `project-audit` skill into a single batched discovery script, and added `Bash` to the global `permissions.allow` list in `settings.json` to eliminate mid-run approval prompts.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| audit-execution | Created | New master spec describing batched Bash discovery behavior for project-audit (≤3 Bash calls per run, key=value output format, no per-dimension ad-hoc shell calls) |
| global-permissions | Created | New master spec describing the Bash pre-approval entry in settings.json |

## Modified Code Files

- `skills/project-audit/SKILL.md` — added Execution Rules section with batched discovery script template and key schema
- `settings.json` — added `"Bash"` to `permissions.allow` array

## Key Decisions Made

- Bash is pre-approved globally (no command or path restrictions), consistent with how Read/Glob/Grep are pre-approved; read-only discipline is enforced by SKILL.md convention, not by permission scoping
- The discovery script uses `key=value` output format for deterministic parsing
- Maximum 3 Bash calls per audit run is the enforced ceiling

## Lessons Learned

- The batching reduced tool calls from 20+ per audit run to 1-2 Bash calls, with the remaining analysis done via pre-approved Read/Glob/Grep tools
- Score baseline on claude-config is 94/100 during the active change; expected to normalize to 96+ after archiving

## User Docs Reviewed

NO — this change affects internal skill execution mechanics only; it does not add, remove, or rename any user-facing commands or onboarding workflows.
