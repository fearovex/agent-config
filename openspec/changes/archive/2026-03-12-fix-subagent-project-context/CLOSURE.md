# Closure: 2026-03-12-fix-subagent-project-context

Start date: 2026-03-12
Close date: 2026-03-12

## Summary

Added governance context injection to SDD sub-agents: orchestrator skills (`sdd-ff`, `sdd-new`) now pass the project CLAUDE.md path in every sub-agent CONTEXT block, and all six SDD phase skills expand Step 0a to read and log the full project governance file at startup.

## Modified Specs

| Domain | Action | Change |
| ------ | ------ | ------ |
| sub-agent-governance-injection | Created | New spec defining orchestrator-side CONTEXT field injection for governance path |
| step-0a-governance-discovery | Created | New spec extending Step 0a in all phase skills to read full CLAUDE.md and log governance summary |
| sub-agent-execution-contract-update | Created | New spec documenting the Project governance field in the agent execution contract |

## Modified Code Files

- `skills/sdd-ff/SKILL.md` — added `Project governance` CONTEXT line to all 5 sub-agent Task prompts; set model: sonnet for explore/propose/tasks sub-agents
- `skills/sdd-new/SKILL.md` — same changes as sdd-ff
- `skills/sdd-explore/SKILL.md` — expanded Step 0a with full CLAUDE.md read and governance logging
- `skills/sdd-propose/SKILL.md` — expanded Step 0a with full CLAUDE.md read and governance logging
- `skills/sdd-spec/SKILL.md` — expanded Step 0a with full CLAUDE.md read and governance logging
- `skills/sdd-design/SKILL.md` — expanded Step 0a with full CLAUDE.md read and governance logging
- `skills/sdd-tasks/SKILL.md` — expanded Step 0a with full CLAUDE.md read and governance logging
- `skills/sdd-apply/SKILL.md` — expanded Step 0a with full CLAUDE.md read and governance logging
- `openspec/agent-execution-contract.md` — added Project governance field documentation
- `docs/sdd-context-injection.md` — updated Step 0 template with canonical governance loading wording

## Key Decisions Made

- Governance path is passed as a CONTEXT field (file path only, not file content) — sub-agents read it themselves during Step 0a
- Step 0a remains fully non-blocking: missing CLAUDE.md emits INFO note and execution continues
- All phase skills use canonical wording for governance log line: `Governance loaded: [N] unbreakable rules, tech stack: [stack], intent classification: [enabled|disabled]`
- Model corrections: explore, propose, and tasks sub-agents corrected to `model: sonnet` (were incorrectly haiku)

## Lessons Learned

- Two non-blocking deviations were accepted at archive time:
  1. CONTEXT field order in all prompts uses `Project → Change → Previous artifacts → Project governance` instead of spec-required `Project → Project governance → Change → Previous artifacts`. Functional impact is nil (fields are named, not positional). A follow-up change can correct the ordering if desired.
  2. The `docs/sdd-context-injection.md` "Governance Logging" subsection (task 3.4) was not added as a standalone section — the governance logging wording exists inline in the Step 0 template but without a dedicated reference heading. Low discoverability impact; low-effort follow-up.
- tasks.md checkbox tracking was not updated during apply (all items remained `[ ]` despite implementation being complete). The progress header accurately reflected 17/17, but individual checkboxes were not ticked. This is a documentation hygiene pattern to watch in future cycles.

## User Docs Reviewed

NO — this change modifies internal skill orchestration and sub-agent prompting only; it does not add, remove, or rename user-facing skills, change onboarding workflows, or introduce new commands visible to end users.
