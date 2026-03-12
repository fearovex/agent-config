# Proposal: orchestrator-always-on

Date: 2026-03-12
Status: Draft

## Intent

Implement always-on intent classification in the orchestrator layer to automatically route user requests to appropriate SDD phases, ensuring consistent SDD discipline across all change requests without requiring explicit slash commands.

## Motivation

Currently, the SDD system is opt-in via explicit commands (`/sdd-ff`, `/sdd-propose`, etc.). Free-form requests ("fix this", "add this feature", "improve this") are handled directly by Claude without SDD discipline, violating the design principle that all code changes should be specification-driven.

The orchestrator reads CLAUDE.md at session start and delegates to sub-agents for each command. Adding proactive intent classification will:
- Maximize consistency of SDD discipline across all work
- Teach users which SDD phases apply to their requests
- Enforce the "never inline code" rule at the orchestrator level
- Align free-form requests with the SDD system's philosophy

The exploration phase has identified that **Approach A (Full Always-On with Always-Classify)** is the recommended solution: every user message is classified before any response is generated, and routing is determined based on the classification.

## Scope

### Included

- Add a new section to CLAUDE.md: **"Always-On Orchestrator — Intent Classification"**
- Define 4 intent classes with keyword-based heuristics:
  1. **Change Request** — contains "add", "create", "fix", "improve", "implement", "refactor", "enhance", "update", "delete", "remove" → recommend `/sdd-ff`
  2. **Exploration** — contains "explore", "investigate", "research", "understand", "analyze" → recommend `/sdd-explore`
  3. **Question** — "how do I?", "explain", "what is?", "why does?" → answer directly
  4. **Meta-Command** — starts with "/" → execute the slash command
- Document the mapping rules with clear keyword-based heuristics and classification examples
- Update the "How I Execute Commands" section to mention intent classification as Step 0
- Create architecture decision record (ADR 030 or next available) documenting this architectural decision
- Update `docs/adr/README.md` with the new ADR entry

### Excluded (explicitly out of scope)

- Modification to individual skill files — skills remain unchanged
- Changes to skill resolution algorithm — skill resolution rules remain as-is
- Automatic code generation or execution — the "never inline code" rule is reinforced, not relaxed
- Natural language processing or ML-based classification — keyword-matching heuristics only
- Automatic `/sdd-apply` execution — change requests are routed to propose, not auto-applied
- Breaking changes to existing commands — all existing commands continue to work as documented

## Proposed Approach

### Intent Classification Algorithm

The orchestrator will classify each user message using keyword-based heuristics:

```
1. Extract tokens from user message (lowercase, split on whitespace)
2. Check against intent patterns (case-insensitive keyword matching):
   - Meta-Command: message starts with "/" → execute immediately
   - Change Request: contains any of "add", "create", "remove", "delete", "modify", "fix", "improve", "refactor", "enhance", "implement", "update"
   - Exploration: contains any of "explore", "investigate", "research", "understand", "analyze", "study"
   - Question: default fallback
3. Route based on classification:
   - Change Request → suggest "/sdd-ff <description>" with user confirmation
   - Exploration → suggest "/sdd-explore <topic>" with user confirmation
   - Meta-Command → execute the slash command immediately
   - Question → answer directly, without SDD routing
```

### CLAUDE.md Changes

Add a new section **"Always-On Orchestrator — Intent Classification"** to CLAUDE.md with:

1. **Intent Classes table** mapping intent → trigger keywords → routing
2. **Classification examples** showing each intent in action
3. **Rules for Always-On behavior**:
   - Classification runs before ANY response is generated
   - For Change Requests and Explorations, the suggestion is non-blocking
   - For Questions, no SDD routing is suggested
   - For Meta-Commands, the orchestrator delegates immediately
   - Prioritize in order: Meta-Command > Change Request > Exploration > Question
4. Update "How I Execute Commands" section to note that intent classification is Step 0

### ADR Creation

Create `docs/adr/030-orchestrator-always-on-intent-classification.md` documenting:
- Decision: Implement proactive intent classification in the orchestrator
- Rationale: Consistency, teaching, alignment with SDD philosophy
- Consequences: Orchestrator behavior becomes context-aware; every message is classified; users see recommendations for SDD phases
- Alternatives considered: Reactive post-response check (rejected); guided hybrid (deferred)

## Affected Areas

| Area/Module | Type of Change | Impact |
|------------|----------------|---------|
| CLAUDE.md orchestrator logic | Modified | High — adds intent classification as Step 0 before any response |
| Session start behavior | Modified | Medium — orchestrator now classifies every message, not just `/` commands |
| Individual skill files | None | Low — no skill modifications required |
| Sub-agent contracts | None | None — sub-agents work unchanged |
| Project CLAUDE.md overrides | Enhanced | Low — project configs can override classification rules |
| ADR index (docs/adr/README.md) | Modified | Low — add reference to new ADR 030 |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Over-classification of ambiguous requests | High | Medium | Carefully tune keyword heuristics; include "Question" as default fallback; iterate rules based on feedback |
| Users bypass the orchestrator due to too-strict rules | Medium | High | Make classification rules visible and clear in CLAUDE.md; allow project CLAUDE.md to override; make suggestions non-blocking |
| Keyword collisions (e.g., "How to fix this pattern?" is a Question, not a Change Request) | Medium | Medium | Look for contextual keywords like "how to", "explain", "understand" to disambiguate |
| Inconsistent behavior across sessions due to rule mistuning | Low | Medium | Document rules clearly; create test cases; verify with `/project-audit` |

## Rollback Plan

If the always-on behavior causes issues:

1. Remove the "Always-On Orchestrator — Intent Classification" section from CLAUDE.md
2. Restore CLAUDE.md to commit `59f8c9a` (git reset --hard)
3. Run `bash install.sh` to redeploy
4. Delete `docs/adr/030-orchestrator-always-on-intent-classification.md`
5. Update `docs/adr/README.md` to remove the ADR 030 reference
6. Commit: `git commit -m "revert: orchestrator always-on feature"`

Rollback is a single file restoration + install + commit.

## Dependencies

- CLAUDE.md must exist and be readable (always present)
- `docs/templates/adr-template.md` should exist (optional but recommended)
- `docs/adr/README.md` must be kept in sync if a new ADR is created
- No external tool or runtime dependencies

## Success Criteria

- [ ] Intent classification logic is documented in CLAUDE.md with 4 intent classes and keyword heuristics
- [ ] Classification rules include examples for each intent class
- [ ] An ADR (030 or next) is created with Status, Context, Decision, and Consequences sections
- [ ] `docs/adr/README.md` is updated with the new ADR entry (number, title, status)
- [ ] The "How I Execute Commands" section is updated to note intent classification as Step 0
- [ ] `/project-audit` audit score is >= previous score after apply and archive

## Effort Estimate

**Low to Medium (2–3 hours)**

- CLAUDE.md edits: ~1 hour (writing and refining classification rules)
- ADR creation: ~30 minutes (documenting decision)
- Testing and validation: ~30 minutes (`/project-audit` verification)
- Total: 2–2.5 hours
