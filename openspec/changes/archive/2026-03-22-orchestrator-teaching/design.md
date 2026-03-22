# Technical Design: 2026-03-21-orchestrator-teaching

Date: 2026-03-21
Proposal: openspec/changes/2026-03-21-orchestrator-teaching/proposal.md

## General Approach

Add a teaching personality layer to the orchestrator through two insertion points: (1) a new `## Teaching Principles` section in CLAUDE.md defining 5 concise behavioral rules that apply cross-cutting to all orchestrator responses, and (2) concrete output format changes in `skills/sdd-ff/SKILL.md` for post-cycle narrative and error reformulation. The teaching content is purely additive — no existing routing logic, classification rules, or sub-agent execution patterns are modified. The orchestrator-behavior master spec gains new requirements to make the teaching behaviors verifiable.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
| -------- | ------ | ---------------------- | ------------- |
| Teaching principles placement | New `## Teaching Principles` section in CLAUDE.md between `## Unbreakable Rules` and `## Plan Mode Rules` | Separate skill file (`skills/orchestrator-teaching/SKILL.md`); inline within existing sections | CLAUDE.md is always loaded at session start — teaching principles must be cross-cutting and always-on. A separate skill would require explicit loading and could be missed. Placing between Unbreakable Rules and Plan Mode Rules keeps behavioral directives grouped together. |
| New-user detection source | `openspec/changes/archive/` directory listing (count of subdirectories) | `ai-context/changelog-ai.md` archived-change count | The archive directory is the actual source of truth for completed SDD cycles. changelog-ai.md is a log that may have entries for non-SDD work. Directory listing is a simple `ls` check with no parsing required. |
| Error reformulation scope | sdd-ff only (blocked/failed status handling in Step 0, Step 1, Step 2, Step 3) | All SDD phase skills | sdd-ff is the orchestrator that surfaces sub-agent errors to users. Phase skills return structured status codes — they do not communicate directly with users. Expanding to other skills would add complexity with no user-facing benefit. |
| Why-framing injection point | Change Request classification response template in CLAUDE.md Classification Decision Table | Separate teaching annotation step after classification | The why-sentence must appear in the same response as the SDD recommendation. Adding it to the existing template is the simplest approach — no new processing step needed. |
| Post-cycle narrative placement | New paragraph in sdd-ff Step 4 summary template, after the artifacts list and before the "Ready to implement?" prompt | Separate Step 5 | A new step would break the existing step numbering. Adding a paragraph within Step 4 is minimal and keeps the summary self-contained. |

## Data Flow

```
User message
    ↓
Orchestrator — Intent Classification (CLAUDE.md)
    ↓ (Change Request detected)
Classification response + WHY-SENTENCE  ← Teaching Principle 1 (why-framing)
    ↓
User confirms → /sdd-ff
    ↓
sdd-ff Step 0 — explore
    ↓ (if blocked/failed)
ERROR REFORMULATION message  ← Teaching Principle 3 (error reformulation)
    ↓ (if ok/warning)
sdd-ff Steps 1-3 — propose, spec+design, tasks
    ↓ (any blocked/failed)
ERROR REFORMULATION message  ← Teaching Principle 3
    ↓ (all ok)
sdd-ff Step 4 — Summary
    ↓
Phase results + artifacts + NARRATIVE PARAGRAPH  ← Teaching Principle 4 (post-cycle reflection)
    ↓
"Ready to implement?"

NEW-USER DETECTION (cross-cutting):
  At first SDD-routed response in session:
    Check openspec/changes/archive/ → count subdirs
    If count == 0 → prepend brief SDD context note  ← Teaching Principle 5

EDUCATIONAL GATES (inline at existing confirmation points):
  Rule 7 removal confirmation → add consequence sentence  ← Teaching Principle 2
  Contradiction gate → add consequence sentence  ← Teaching Principle 2
```

## File Change Matrix

| File | Action | What is added/modified |
| ---- | ------ | ---------------------- |
| `CLAUDE.md` | Modify | New `## Teaching Principles` section (~15 lines) inserted between `## Unbreakable Rules` and `## Plan Mode Rules`; why-sentence added to Change Request classification response template |
| `skills/sdd-ff/SKILL.md` | Modify | Post-cycle narrative paragraph added to Step 4 summary template; error reformulation pattern added to blocked/failed handling after Steps 0, 1, 2, 3 |
| `openspec/specs/orchestrator-behavior/spec.md` | Modify | New requirements for: why-framing in Change Request responses, educational gate prompts, new-user detection heuristic |

## Interfaces and Contracts

No new interfaces or DTOs. All changes are text template modifications within existing files.

**Teaching Principles section contract** (CLAUDE.md):

```markdown
## Teaching Principles

1. **Why-framing**: [1 sentence rule]
2. **Educational gates**: [1 sentence rule]
3. **Error reformulation**: [1 sentence rule]
4. **Post-cycle reflection**: [1 sentence rule]
5. **Progressive disclosure**: [1 sentence rule]
```

**Why-sentence template** (Change Request classification):

```
I recommend `/sdd-ff <slug>` — [1 sentence explaining what risk the SDD cycle prevents for this specific change].
```

**Error reformulation template** (sdd-ff blocked/failed):

```
⚠️ [Phase] returned [status]: [original summary]
This happened because [cause]. To prevent this in future cycles, [prevention guidance].
```

**Post-cycle narrative template** (sdd-ff Step 4):

```
This cycle [1-paragraph narrative: what was produced, what architectural decisions were captured,
and what risks the structured approach mitigated that ad-hoc implementation would have missed].
```

**New-user detection logic**:

```
IF openspec/changes/archive/ does not exist OR contains 0 subdirectories:
  → Prepend to first SDD-routed response:
    "This appears to be your first SDD cycle in this project. The SDD workflow
     (explore → propose → spec → design → tasks → apply → verify → archive)
     ensures changes are specified before implemented, reducing rework and
     preserving architectural intent."
  → This note appears once per session (first SDD-routed response only).
```

## Testing Strategy

| Layer | What to test | Tool |
| ----- | ------------ | ---- |
| Manual | CLAUDE.md Teaching Principles section exists with 5 rules | Visual inspection |
| Manual | Change Request response includes why-sentence | Trigger a Change Request in a new session |
| Manual | sdd-ff error reformulation fires on blocked/failed | Simulate a blocked sub-agent |
| Manual | sdd-ff Step 4 includes narrative paragraph | Run a complete sdd-ff cycle |
| Structural | `/project-audit` score >= previous | `/project-audit` |

## Migration Plan

No data migration required.

## Open Questions

None. The two open questions from exploration have been resolved in the Technical Decisions table:
- New-user detection source: resolved to `openspec/changes/archive/` directory listing.
- Error reformulation scope: resolved to sdd-ff only.
