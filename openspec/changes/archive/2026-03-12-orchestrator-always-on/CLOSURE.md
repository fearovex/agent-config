# Closure: 2026-03-12-orchestrator-always-on

Start date: 2026-03-12
Close date: 2026-03-12

## Summary

Implemented always-on intent classification in the orchestrator layer to automatically route user requests to appropriate SDD phases. Added a dedicated section to CLAUDE.md documenting four intent classes (Meta-Command, Change Request, Exploration, Question) with keyword-based routing rules. Created ADR-029 to document the architectural decision.

## Modified Specs

| Domain | Action | Description |
| --- | --- | --- |
| orchestrator-behavior | Created | New master spec documenting intent classification behavior, four intent classes with routing rules, and the "never write implementation code inline" requirement |

## Modified Code Files

- `CLAUDE.md` — Added `## Always-On Orchestrator — Intent Classification` section with routing table, decision tree, examples, unbreakable rules, and project-level override mechanism
- `docs/adr/029-orchestrator-always-on-intent-classification.md` — New ADR documenting the architectural decision, context, and consequences
- `docs/adr/README.md` — Updated ADR index table with entry [029]

## Key Decisions Made

1. **Intent classification runs inline in CLAUDE.md** — No new skill created. Classification is a global cross-cutting concern that must run before any skill resolution, and the rules are simple enough (4 categories) for a decision table.

2. **Placement in CLAUDE.md** — Section positioned immediately after `## Identity and Purpose` (line 12) to ensure the always-on gate is the first behavioral instruction encountered.

3. **Change Request handling** — Orchestrator recommends `/sdd-ff <slug>` or `/sdd-new` to the user (no auto-launch) to preserve user control and align with existing "ask for approval" principle.

4. **Exploration handling** — Orchestrator auto-launches `sdd-explore` via Task tool (no user gate) because exploration is read-only and non-destructive.

5. **Questions bypass SDD** — Direct questions, explanations, and system queries are answered directly without SDD delegation.

6. **Ambiguous requests** — Default to Question classification and append an SDD hint: "If you'd like me to implement this, I can start with `/sdd-ff <slug>`."

7. **Project-level overrides** — Project CLAUDE.md can disable intent classification with `intent_classification: disabled` or restrict to specific intent classes with `enabled_classes: [...]`.

## Lessons Learned

- Intent classification at the message level is a powerful cross-cutting architectural change that affects every user interaction. Placing it in CLAUDE.md (loaded at session start) ensures it applies globally without adding skill resolution overhead.
- Keyword-based heuristics work well for the four intent classes, but edge cases (e.g., "how to fix this" — is it a question or change request?) require clear default handling and project-level override options.
- The verification report identified three warnings (incomplete tasks, no behavioral tests, no deployment confirmation via tool execution). These are non-blocking but should be addressed in future sessions by running `/project-audit` and `install.sh` to confirm the always-on behavior is live in the runtime environment.

## User Docs Reviewed

YES — No user-facing workflow changes were required for this change. The always-on classification is transparent to users; they can continue using slash commands or free-form requests as before. The CLAUDE.md update documents the new behavior for users who read the global instructions, but this is not part of the user-facing scenarios.md or quick-reference.md.

