# Technical Design: orchestrator-always-on

Date: 2026-03-12
Proposal: openspec/changes/2026-03-12-orchestrator-always-on/proposal.md

## General Approach

Add an "Always-On Orchestrator" section to CLAUDE.md that defines intent classification rules executed at every conversation turn. The orchestrator classifies each user message into one of four intent categories (change request, exploration, question, slash command) and maps it to the appropriate SDD behavior. No new skills are created — this is a CLAUDE.md-only change that leverages the existing skill catalog and delegation pattern.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
| -------- | ------ | ---------------------- | ------------- |
| Intent classification mechanism | Inline rules in CLAUDE.md (pattern-matching table) | A dedicated `intent-classifier` skill; LLM function-calling schema | CLAUDE.md is loaded at session start unconditionally — no extra file reads needed. A separate skill would add indirection for a cross-cutting concern that must run before any skill resolution. The classification is simple enough (4 categories) that a decision table suffices. |
| Placement in CLAUDE.md | New section between "Identity and Purpose" and "Tech Stack" — early in the file so it is processed before any command-specific instructions | Appending at the end; embedding in "How I Execute Commands" | Early placement ensures the always-on gate is the first behavioral instruction Claude encounters. Placing it inside "How I Execute Commands" would conflate reactive (slash-command) and proactive (intent-classification) behavior. |
| Direct-answer allowlist | Questions, explanations, and system queries bypass SDD delegation entirely | Routing everything through sdd-explore | Over-routing simple questions through sub-agents wastes context and latency. The proposal explicitly requires "questions and explanations are still answered directly." |
| Change-request handling | Orchestrator **recommends** the SDD command to the user (does not auto-launch) | Auto-launching sdd-ff without confirmation | Auto-launching would violate the existing "ask for approval before continuing" principle in the Delegation Pattern. Recommending preserves user control and avoids unintended SDD cycles for ambiguous requests. |
| Exploration-request handling | Orchestrator auto-launches `sdd-explore` via Task tool (no user gate) | Requiring user to type `/sdd-explore` | Exploration is read-only and non-destructive. Auto-launching aligns with the sdd-ff precedent where explore runs as Step 0 without a user prompt. Reduces friction for the most common implicit request type. |
| Architecture: system-wide intent classification introduces a cross-cutting orchestration pattern | Rules-in-CLAUDE.md approach | Separate middleware skill | This is a **global**, **cross-cutting** behavioral change that affects how every user message is processed. It **introduces** a new orchestration layer (intent classification) that did not previously exist. Documenting this as an architectural decision ensures future changes to the classification logic are traceable. |

## Data Flow

```
User message (any turn)
        │
        ▼
┌─────────────────────┐
│  Intent Classifier   │  (inline rules in CLAUDE.md)
│  (always-on gate)    │
└─────────┬───────────┘
          │
    ┌─────┼─────────┬──────────────┐
    ▼     ▼         ▼              ▼
  SLASH   CHANGE    EXPLORE       QUESTION
  CMD     REQUEST   REQUEST
    │     │         │              │
    ▼     ▼         ▼              ▼
  Execute  Recommend  Auto-launch   Answer
  as today /sdd-ff    sdd-explore   directly
           or         via Task
           /sdd-new   tool
```

### Intent classification rules (decision table)

```
IF message matches a slash command (starts with /)
  → SLASH_CMD: execute as today (read skill, delegate)

ELSE IF message implies a code change, bug fix, feature addition,
        refactoring, or any modification to files
  → CHANGE_REQUEST: recommend /sdd-ff <inferred-slug> or /sdd-new

ELSE IF message asks for review, exploration, investigation,
        or understanding of code/architecture
  → EXPLORE_REQUEST: auto-launch sdd-explore via Task tool

ELSE (question, explanation, system query, conversation)
  → QUESTION: answer directly — no SDD delegation
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `CLAUDE.md` | Modify | Add `## Always-On Orchestrator` section after `## Identity and Purpose`. Contains: intent classification rules, mapping table, examples, and the "never write code inline" reinforcement. |

## Interfaces and Contracts

No new interfaces. The change adds behavioral rules to the existing orchestrator contract in CLAUDE.md. The intent classification output is implicit (Claude's internal decision) — it does not produce a file artifact.

The only observable contract change:
- **Before**: user sends free-form message → Claude responds directly
- **After**: user sends free-form message → Claude classifies intent → routes to SDD phase or answers directly

## Testing Strategy

| Layer | What to test | Tool |
| ----- | ------------ | ---- |
| Manual | Send free-form change requests and verify Claude recommends SDD commands | Manual session testing |
| Manual | Send questions/explanations and verify Claude answers directly | Manual session testing |
| Integration | Run `/project-audit` and verify no new audit findings introduced | `/project-audit` |

No automated test infrastructure exists for CLAUDE.md behavioral rules — validation is manual.

## Migration Plan

No data migration required. The change is additive — a new section in CLAUDE.md. Existing slash-command behavior is unchanged. The `install.sh` deployment picks up the change automatically.

## Open Questions

- **Ambiguous requests**: when a user message is genuinely ambiguous (could be a question or a change request), should Claude ask for clarification or default to one category? **Impact**: defaulting to CHANGE_REQUEST would be overly aggressive; defaulting to QUESTION would miss opportunities for SDD discipline. **Recommendation**: default to QUESTION and add a note like "If you'd like me to implement this, I can start with `/sdd-ff <slug>`."
