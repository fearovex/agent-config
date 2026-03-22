# Technical Design: 2026-03-21-orchestrator-mandatory-new-session

Date: 2026-03-22
Proposal: openspec/changes/2026-03-21-orchestrator-mandatory-new-session/proposal.md

## General Approach

Replace Rule 6's opt-in explicit-language trigger with a two-branch context-aware heuristic evaluated at Change Request classification time. The heuristic reads the session's prior message count: significant prior context (≥5 messages) → create proposal.md with context summary + recommend new session; clean session → proceed inline with sdd-ff. Separately, replace the command-as-gate pattern at sdd-ff Step 4 with a natural-language confirmation prompt, demoting the slash command to an informational reference.

All three changes are text-only edits in existing files (CLAUDE.md, spec, SKILL.md). No new files, no new skills, no data migration.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|----------------------|---------------|
| Heuristic threshold | ~5 prior messages (orchestrator judgment) | Hard-coded exact count, token count | No in-session memory for exact count; orchestrator judgment is consistent with other advisory behaviors in this system. Conservative threshold reduces false positives. |
| Proposal creation placement | At orchestrator recommendation step (Rule 6 branch), not inside sdd-ff | Always inside sdd-ff, never in orchestrator | Rule 6 applies when sdd-ff has NOT been run yet. The point of a cross-session handoff is precisely to capture context BEFORE the user opens a new session. |
| Natural language gate pattern | "Continue with implementation? Reply **yes** to proceed." with command as optional reference | Remove command reference entirely, keep command-only | Commands remain accessible for power users; natural language reduces friction for new users. Maintains backward compatibility. |
| New spec REQs placement | Append to existing `openspec/specs/orchestrator-behavior/spec.md` | New domain, separate spec file | The behavior is logically part of orchestrator routing — same domain as existing REQs. Avoids spec fragmentation. |
| /memory-update offer | Inline in Rule 6 alongside proposal creation | Separate rule, separate heuristic | Co-located with the handoff action so the offer is contextually obvious and not missed. |

## Data Flow

```
User sends free-form message
        ↓
Orchestrator classifies: Change Request
        ↓
Pre-flight Gates (Gate 1, Gate 2) — advisory
        ↓
Scope Estimation Heuristic
        ↓
[Rule 6 Branch] Context-aware heuristic:
  ┌─ Significant prior context (≥5 msgs)? ──Yes──► Create proposal.md
  │                                                   │
  │                                                   ▼
  │                                            Display proposal path
  │                                                   │
  │                                                   ▼
  │                                     Recommend: "Open new chat, run /sdd-ff <slug>"
  │                                                   │
  │                                                   ▼
  │                                         Offer /memory-update
  │
  └─ Clean session (< 5 msgs)? ──────No───► Recommend /sdd-ff <slug> directly
                                             (proposal.md created inside sdd-ff Step 0)

sdd-ff Step 4 (after phases complete):
  OLD: "Ready to implement? Run: /sdd-apply [slug]"
  NEW: "Continue with implementation? Reply yes to proceed.
        (Manual: /sdd-apply [slug])"
        ↓
  WAIT for user reply
  If yes → delegate to sdd-apply sub-agent
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `CLAUDE.md` | Modify | Rule 6 rewritten: remove opt-in trigger text; add two-branch context-aware heuristic with proposal creation + /memory-update offer |
| `openspec/specs/orchestrator-behavior/spec.md` | Modify | Append 2 new Requirements: (1) Context-aware session handoff heuristic; (2) Natural language confirmation gate for sdd-ff Step 4 |
| `skills/sdd-ff/SKILL.md` | Modify | Step 4 confirmation prompt reworded: "Continue with implementation? Reply **yes** to proceed." with command as optional reference |

## Interfaces and Contracts

No new interfaces. Changes are behavioral rule text changes, not code contracts.

**Rule 6 replacement text (CLAUDE.md):**

```
### 6. Cross-session ff handoff
- When the orchestrator recommends /sdd-ff after significant prior context (~5+ messages exchanged
  or other topics discussed in the session):
  1. Create openspec/changes/<slug>/proposal.md immediately with: problem statement, target files,
     key decisions from conversation, constraints
  2. Display the proposal path
  3. Recommend: "Open a new chat and run /sdd-ff <slug> — the proposal has the context."
  4. Offer /memory-update before the session ends
- When the session is clean (change request is the first or near-first message):
  - Recommend /sdd-ff <slug> directly — proposal.md will be created inside sdd-ff as designed
- Rationale: preserves context window quality and cycle independence; a clean session needs no jump
```

**sdd-ff Step 4 confirmation replacement:**

```
Continue with implementation? Reply **yes** to proceed.
(Manual: /sdd-apply [inferred-slug])
```

**New spec REQs (orchestrator-behavior/spec.md additions):**

```
REQ: Context-aware session handoff heuristic
REQ: Natural language confirmation gate at sdd-ff Step 4
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual | Rule 6 heuristic fires correctly in a session with 5+ messages before a change request | Human verification in Claude Code session |
| Manual | Clean session (first-message change request) skips new-session recommendation | Human verification |
| Manual | sdd-ff Step 4 shows natural language confirmation, accepts "yes" to proceed | Human verification |
| Audit | `/project-audit` passes after apply — CLAUDE.md, spec, and SKILL.md are in sync | /project-audit |

No automated tests — the project's testing layer is `/project-audit` (integration audit). No code to unit test.

## Migration Plan

No data migration required.

Rule 6 change is backwards-compatible: the new heuristic is advisory and context-sensitive. Sessions that previously relied on explicit "new session" language still work — clean sessions simply proceed inline instead.

The sdd-ff Step 4 change is additive: the command reference remains, only the primary prompt wording changes.

## Open Questions

None.
