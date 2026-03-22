# Proposal: Orchestrator Action Control Gates

## Problem Statement

The orchestrator's control mechanisms are declarative but not enforced:

1. **No active-change detection**: recommends `/sdd-ff` without checking if a change is already in flight in `openspec/changes/`
2. **No spec drift check on Change Requests**: Step 8 (Spec-first Q&A) only applies to Questions — a Change Request that contradicts a spec reaches sdd-propose silently
3. **No feedback session auto-detection**: Rule 5 relies on the user explicitly declaring "this is feedback" — there's no heuristic to detect observational/complaint messages
4. **No scope-aware conflict warning**: starting a new cycle while one is incomplete is allowed without warning

## Proposed Solution

Add a **Pre-flight Check** step that runs before routing any Change Request:

### Pre-flight Check Sequence

1. **Active change scan**: read `openspec/changes/*/` (excluding `archive/`). If a change with semantic overlap exists → emit warning: "You have `<change-name>` in progress. Do you want to continue that cycle or start a new one?"
2. **Spec drift check**: run Step 8 keyword matching against the user's change description. If a matching spec exists and the change intent contradicts a requirement → surface: "The spec for `<domain>` says `<REQ-N>`. Your change may conflict. Should I factor this in during sdd-explore?"
3. **Feedback session heuristic**: detect messages matching observational patterns ("el orquestador hace X pero", "noto que", "I noticed that", "when X happens, Y should", "the system should", "this behavior is wrong but I'm not asking to fix it now"). If matched → classify as **Feedback Session** and apply Rule 5 enforcement.

### Enforcement of Rule 5

When Feedback Session is detected (auto or declared):
- Block any SDD phase command recommendation
- Only offer to create `proposal.md` in `openspec/changes/YYYY-MM-DD-<slug>/`
- Display: "This sounds like feedback. I'll record it as a proposal — implementation goes in a separate session. Rule 5 protects you from premature execution."

## Success Criteria

- [ ] Pre-flight check section added to CLAUDE.md
- [ ] Active change scan defined with conflict prompt template
- [ ] Spec drift check extended to Change Requests
- [ ] Feedback session heuristic defined with pattern list
- [ ] Rule 5 enforcement is documented as a blocking gate, not just a prose rule

## Files and Artifacts to Target

- `CLAUDE.md` — Pre-flight Check section, Rule 5 enforcement update
- `openspec/specs/orchestrator-behavior/spec.md` — new REQ entries for pre-flight gates
- `openspec/specs/feedback-session/spec.md` — add auto-detection requirement

## Constraints

- Pre-flight checks must be fast — no heavy file reads; use directory listing + keyword matching only
- Active change scan must NOT block if the in-flight change has a different semantic slug
- Spec drift warning is advisory, not blocking — user can override
- Feedback session detection heuristic must have a high precision threshold to avoid false positives

## Execution Order

**Cycle 4 of 5** — run after natural language (Cycle 3). Most complex and highest risk.
