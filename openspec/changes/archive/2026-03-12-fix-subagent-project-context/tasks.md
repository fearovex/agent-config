# Task Plan: 2026-03-12-fix-subagent-project-context

Date: 2026-03-12
Design: openspec/changes/2026-03-12-fix-subagent-project-context/design.md

## Progress: 17/17 tasks

## Phase 1: Orchestrator Governance Path Injection + Model Corrections

Update the orchestrator skills to pass the project CLAUDE.md path to all sub-agent prompts, and correct sub-agent model assignments (explore, propose, tasks → sonnet).

- [x] 1.1 Modify `~/.claude/skills/sdd-ff/SKILL.md` — Add `- Project governance: <project-root>/CLAUDE.md` to CONTEXT block in explore sub-agent prompt; change `model: haiku` → `model: sonnet`
- [x] 1.2 Modify `~/.claude/skills/sdd-ff/SKILL.md` — Add `- Project governance: <project-root>/CLAUDE.md` to CONTEXT block in propose sub-agent prompt; change `model: haiku` → `model: sonnet`
- [x] 1.3 Modify `~/.claude/skills/sdd-ff/SKILL.md` — Add `- Project governance: <project-root>/CLAUDE.md` to CONTEXT block in both spec and design parallel sub-agent prompts (2 locations; models already sonnet — no change)
- [x] 1.4 Modify `~/.claude/skills/sdd-ff/SKILL.md` — Add `- Project governance: <project-root>/CLAUDE.md` to CONTEXT block in tasks sub-agent prompt; change `model: haiku` → `model: sonnet`
- [x] 1.5 Modify `~/.claude/skills/sdd-new/SKILL.md` — Add `- Project governance: <project-root>/CLAUDE.md` to CONTEXT block in explore sub-agent prompt; change `model: haiku` → `model: sonnet`
- [x] 1.6 Modify `~/.claude/skills/sdd-new/SKILL.md` — Add `- Project governance: <project-root>/CLAUDE.md` to CONTEXT block in propose sub-agent prompt; change `model: haiku` → `model: sonnet`
- [x] 1.7 Modify `~/.claude/skills/sdd-new/SKILL.md` — Add `- Project governance: <project-root>/CLAUDE.md` to CONTEXT block in both spec and design parallel sub-agent prompts (2 locations; models already sonnet — no change)
- [x] 1.8 Modify `~/.claude/skills/sdd-new/SKILL.md` — Add `- Project governance: <project-root>/CLAUDE.md` to CONTEXT block in tasks sub-agent prompt; change `model: haiku` → `model: sonnet`

## Phase 2: Phase Skills Step 0 Governance Discovery Expansion

Expand Step 0 (or Step 0a for propose/spec/design/tasks) in all seven SDD phase skills to read the full CLAUDE.md and log governance metadata.

- [x] 2.1 Modify `~/.claude/skills/sdd-explore/SKILL.md` — Replace Step 0 item 4 (CLAUDE.md read instruction) with full-file read + governance logging. Extract count of items in Unbreakable Rules, primary language from Tech Stack, and intent classification status. Output single governance log line: `Governance loaded: [N] unbreakable rules, tech stack: [language], intent classification: [enabled|disabled]`. If absent: log INFO note.
- [x] 2.2 Modify `~/.claude/skills/sdd-propose/SKILL.md` — Replace Step 0a item 4 with same governance discovery text as 2.1
- [x] 2.3 Modify `~/.claude/skills/sdd-spec/SKILL.md` — Replace Step 0a item 4 with same governance discovery text as 2.1
- [x] 2.4 Modify `~/.claude/skills/sdd-design/SKILL.md` — Replace Step 0 item 4 with same governance discovery text as 2.1
- [x] 2.5 Modify `~/.claude/skills/sdd-tasks/SKILL.md` — Replace Step 0 item 4 with same governance discovery text as 2.1
- [x] 2.6 Modify `~/.claude/skills/sdd-apply/SKILL.md` — Replace Step 0 (project context load) item 4 with same governance discovery text as 2.1
- [x] 2.7 Modify `~/.claude/skills/sdd-verify/SKILL.md` — Replace Step 0 item 4 with same governance discovery text as 2.1

## Phase 3: Documentation and Contract Updates

Update canonical documentation to reflect the new context injection pattern.

- [x] 3.1 Modify `openspec/agent-execution-contract.md` — Add new row to Input fields table: `Project governance | absolute path | no | Path to the project's CLAUDE.md; absent when orchestrator does not inject it (non-breaking)`
- [x] 3.2 Modify `openspec/agent-execution-contract.md` — Update the example prompt in Input Format section to include the new `- Project governance: <project-root>/CLAUDE.md` CONTEXT field
- [x] 3.3 Modify `docs/sdd-context-injection.md` — Update Step 0 Block Template section to reflect full CLAUDE.md read (item 4 text replacement to match canonical wording from design.md)
- [x] 3.4 Modify `docs/sdd-context-injection.md` — Add "Governance Logging" subsection describing the structured log line format and fallback INFO note

---

## Implementation Notes

**Canonical Step 0 item 4 text (use for all phase skills):**
```markdown
4. Read the full project `CLAUDE.md` (at project root). Extract and log:
   - Count of items listed under `## Unbreakable Rules`
   - Value of the primary language from `## Tech Stack`
   - Whether `intent_classification:` is `disabled` (check for Override section)
   Output a single governance log line:
   `Governance loaded: [N] unbreakable rules, tech stack: [language], intent classification: [enabled|disabled]`
   If CLAUDE.md is absent: log `INFO: project CLAUDE.md not found — governance falls back to global defaults.`
```

**Canonical CONTEXT field (use for all orchestrator invocations):**
```
- Project governance: <absolute-path-to-project-root>/CLAUDE.md
```

**File organization by cluster:**
- Phase 1: 8 tasks spanning 2 files (sdd-ff, sdd-new) — includes governance injection + model corrections
- Phase 2: 7 tasks spanning 7 files (one task per phase skill)
- Phase 3: 4 tasks spanning 2 files (agent-execution-contract, sdd-context-injection)

**Verification checklist per phase:**
- Phase 1: Grep sdd-ff and sdd-new for `- Project governance:` — should appear exactly 5 times in each (explore, propose, spec, design, tasks); grep for `model: sonnet` — should appear for explore, propose, spec, design, tasks (all 5 phases)
- Phase 2: Grep each phase skill Step 0 for "Governance loaded:" — should appear exactly once in the canonical text replacement
- Phase 3: Verify agent-execution-contract.md Input fields table has "Project governance" row; verify example prompt includes governance line; verify sdd-context-injection.md Step 0 template matches canonical text

---

## Blockers

None. All files exist and are within the project scope. Phase 1 must complete before Phase 2 (orchestrators invoke phase skills that depend on governance path injection). Phase 3 can run in parallel with Phase 2 (documentation updates do not block implementation).

---

## Dependencies

| From | To | Reason |
|------|-----|--------|
| Phase 1 (orchestrators) | Phase 2 (phase skills) | Phase skills in Phase 2 assume the `Project governance:` field is present in their invocation prompts |
| Phase 2 (phase skills) | Phase 3 (documentation) | Documentation reflects what the code implements; Phase 2 implementation defines the exact canonical text |
