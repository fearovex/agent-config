# Closure: 2026-03-21-orchestrator-mandatory-new-session

Start date: 2026-03-21
Close date: 2026-03-22

## Summary

Replaced Rule 6's opt-in trigger with a context-aware two-branch heuristic that automatically recommends a new session (and creates `proposal.md`) when the orchestrator detects significant prior context (~5+ messages). Also replaced the sdd-ff Step 4 command-as-gate pattern with a natural language confirmation prompt.

## Modified Specs

| Domain                  | Action   | Change                                                                 |
| ----------------------- | -------- | ---------------------------------------------------------------------- |
| orchestrator-behavior   | Modified | Rule 6 rewritten with Branch A / Branch B context-aware heuristic     |
| orchestrator-behavior   | Added    | Natural language confirmation gates requirement with scenarios         |
| sdd-orchestration       | Modified | sdd-ff Step 4 ask-before-apply gate updated to natural language        |

## Modified Code Files

- `CLAUDE.md` — Rule 6 rewritten (both user-global and project-local copies)
- `skills/sdd-ff/SKILL.md` — Step 4 confirmation prompt updated to natural language
- `openspec/specs/orchestrator-behavior/spec.md` — two new requirements appended
- `openspec/specs/sdd-orchestration/spec.md` — Step 4 gate requirement appended
- `ai-context/changelog-ai.md` — session entry added

## Key Decisions Made

- Heuristic threshold (~5 messages) is advisory, not a hard block — false negatives are acceptable
- Branch A creates `proposal.md` at the orchestrator recommendation step (not inside sdd-ff)
- Branch B delegates proposal creation to sdd-ff's existing context extraction sub-step
- Commands are demoted to secondary references in confirmation gates, not removed
- "One Cycle Per Session" hard block explicitly excluded as not reliably enforceable

## Lessons Learned

The original proposal was "always new session" — refined during exploration to "only when session has significant prior context" to avoid over-applying the pattern in clean sessions. The two-branch design avoids disrupting fast-path workflows while preserving context quality for complex sessions.

## User Docs Reviewed

N/A — pre-dates this requirement
