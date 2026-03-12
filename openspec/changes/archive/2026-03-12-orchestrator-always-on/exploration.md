# Exploration: Orchestrator Always-On Behavior

> Investigation of the feasibility and impact of adding automatic intent classification to the orchestrator layer.

## Current State

**Orchestrator activation mechanism:**
- User invokes slash commands (`/sdd-ff`, `/project-audit`, etc.)
- Orchestrator reads the corresponding SKILL.md and delegates to sub-agents
- Free-form requests ("fix this", "review this") are handled directly by Claude without SDD discipline
- The SDD system is opt-in via explicit commands

**Architecture foundation:**
- `CLAUDE.md` at the user level defines orchestrator behavior, delegation patterns, and the SDD phase DAG
- SDD phases are delegated to sub-agents via Task tool — orchestrator never executes implementation work
- All SDD phase skills load project context as Step 0 (stack.md, architecture.md, conventions.md, project CLAUDE.md)
- Skills are stored in global catalog (`~/.claude/skills/`) and can be overridden project-locally (`.claude/skills/`)

**Current delegation model:**
- The orchestrator (CLAUDE.md) acts as a hub
- Each slash command maps to a SKILL.md entry point
- Sub-agents read their skill file and execute in isolation
- Communication between phases is via file artifacts (exploration.md, proposal.md, design.md, tasks.md)

## Affected Areas

| Area | Impact | Notes |
|------|--------|-------|
| **CLAUDE.md** | High | Must add intent classification logic before responding to any user message |
| **Session start behavior** | Medium | Orchestrator must classify every user message, not just those starting with `/` |
| **Skill invocation** | Low | No changes to individual skill files; skill resolution remains the same |
| **Sub-agent contracts** | None | Sub-agents continue to work as-is; they don't need to know about intent classification |
| **Project-specific behavior** | Low | Project CLAUDE.md can override or refine intent classification; architecture supports this |
| **Code generation responsibility** | Medium | Orchestrator must enforce "never inline code" rule — impacts response structure |

## Analyzed Approaches

### Approach A: "Full Always-On with Always-Classify"

**Description**: Every user message is classified before any response is generated. Based on the classification, the orchestrator either:
1. Delegates to an SDD phase (via Task tool or slash command recommendation)
2. Answers directly (for questions/explanations)

**Pros**:
- Maximally consistent — SDD discipline applied to all change requests
- Clear intent-to-action mapping in CLAUDE.md
- Enforces the "no inline code" rule at the orchestrator level
- Aligns user behavior with SDD system design
- Provides a learning opportunity — users see which commands apply to their requests

**Cons**:
- Requires adding 50–100 lines to CLAUDE.md (intent classification rules)
- May feel heavy-handed for simple questions or quick explanations
- Classification rules must be heuristic-based (keyword matching) — edge cases will exist
- If rules are too strict, users will bypass the orchestrator (defeating the purpose)
- Requires careful tuning to avoid over-classification (e.g., "explain this" should not trigger explore)

**Estimated effort**: Medium (documentation + careful rule design)
**Risk**: Medium (over-classifying requests, user frustration if too restrictive)

---

### Approach B: "Reactive Always-On"

**Description**: The orchestrator remains mostly unchanged. Instead, add a **post-response check**: after generating a response, evaluate whether inline code or implementation was written. If yes, flag it as "violating SDD discipline" and suggest the appropriate SDD phase.

**Pros**:
- Lower friction — doesn't block normal conversation
- Simpler to implement — fewer rules in CLAUDE.md
- Avoids false-positive classifications
- Can be retrofitted to existing CLAUDE.md

**Cons**:
- Reactive, not proactive — damage already done (code written inline)
- User sees the violation only after the fact
- Less effective at teaching SDD discipline
- Requires post-response analysis (slower, more expensive in token cost)
- Inconsistent behavior — some messages trigger SDD, others don't

**Estimated effort**: Low (simpler rules)
**Risk**: Low (but less effective at the goal)

---

### Approach C: "Guided Hybrid"

**Description**: Add a classification step that proposes (but does not mandate) the SDD phase. For change/feature/bug requests, the response is:

```
I notice this looks like a [change type]. Would you like to:
1. Run `/sdd-ff <description>` for a fast-forward cycle, or
2. Have me handle this directly?
```

Then respect the user's choice.

**Pros**:
- Gives users agency — they can opt in or out
- Teaches SDD discipline without forcing it
- Reduces frustration from over-classification
- Easier to refine rules (false positives less harmful)
- Bridges the gap between explicit commands and always-on automation

**Cons**:
- Adds a confirmation step to every potential change request (verbose)
- Users may always choose option 2 (defeating the purpose)
- Requires more sophisticated classification to avoid spamming "did you mean SDD?" prompts
- Still requires careful rule tuning

**Estimated effort**: Medium (classification + user-facing messaging)
**Risk**: Medium (users ignore the guidance)

---

## Recommendation

**Approach A: Full Always-On with Always-Classify**

**Reasoning:**
1. The proposal explicitly requests "orchestrator always-on behavior" — this implies proactive, not reactive
2. The SDD system's value is highest when applied consistently across all work
3. CLAUDE.md is designed to be read at session start; adding classification rules there is in-band
4. The intent classification rules are straightforward (keyword-based) and can be tuned iteratively
5. The architecture already supports delegation — no structural changes needed
6. The "never inline code" rule is a design principle that should be explicit

**Implementation strategy:**
1. Add a new section to CLAUDE.md: **"Always-On Orchestrator — Intent Classification"**
2. Define 4 intent classes: Change Request, Exploration, Question, Meta-Command
3. Document the mapping rules with clear examples
4. Update the "How I Execute Commands" section to mention intent classification as Step 0
5. Add a Rule: "Before responding to any user message, I classify the intent and route accordingly"
6. Create an ADR documenting this architectural decision (ADR 029 or similar)

---

## Identified Risks

- **Over-classification risk**: Keywords like "fix" or "add" appear in questions too ("How to fix this pattern?"). Mitigation: Refine rules through feedback; use larger keyword sets with context.
- **User bypass risk**: If classification feels wrong, users may switch to other tools. Mitigation: Make the classification rules visible in CLAUDE.md; allow projects to override via project CLAUDE.md.
- **Implementation code leakage**: Even with classification, sub-agents might write code inline. Mitigation: Enforce the Quality Gate in `sdd-apply` (already done); non-blocking but visible.
- **Backwards compatibility**: Existing projects may have different CLAUDE.md expectations. Mitigation: Technique is backwards-compatible — global CLAUDE.md provides the rules; project CLAUDE.md can override.
- **Scope creep in rules**: The mapping table could grow large and complex. Mitigation: Start with 4 intent classes; keep rules simple and keyword-based; split into sub-cases only if needed.

---

## Open Questions

1. **Exact classification algorithm**: Should classification be based on regex keywords, NLP, or hybrid? (Proposed: simple keyword matching, refined iteratively)
2. **When to recommend vs. when to auto-execute**: Should `/sdd-ff` be auto-recommended or auto-executed? (Proposed: recommend + wait for confirmation, to preserve user agency)
3. **Project-specific overrides**: How should project CLAUDE.md refine the global classification rules? (Proposed: full override capability documented in Skill Resolution)
4. **Backward compatibility**: Should the global CLAUDE.md change be additive or require breaking updates in projects? (Proposed: additive — new section, no changes to existing commands)

---

## Ready for Proposal

**YES**

This change is well-scoped, aligns with the SDD system's philosophy, and is architecturally feasible. The proposal provides clear success criteria, and the implementation requires only documentation changes to CLAUDE.md plus an optional ADR. No code changes, no new skills, no breaking changes to existing commands.

Next step: `/sdd-propose` will refine the classification rules and write a detailed spec for the Always-On Orchestrator behavior.
