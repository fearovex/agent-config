# Technical Design: Add Clarification Gate for Ambiguous Inputs

**Date**: 2026-03-14
**Proposal**: openspec/changes/2026-03-14-add-clarification-gate-for-ambiguous-inputs/proposal.md

---

## General Approach

Insert a new **ambiguity detection and clarification gate** before the default Question classification in the orchestrator's decision flow (CLAUDE.md Classification Decision Table). When an input matches the ambiguity pattern (single-word commands, noun-only, or verb without target), ask a focused 3-option question to disambiguate intent, then route to the correct class. Non-ambiguous inputs pass through unchanged. The gate is procedural logic inserted into CLAUDE.md — no new skill is required.

---

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|----------------------|----------------|
| **Gate location** | Insert into Classification Decision Table section of CLAUDE.md as a new `ELSE IF` branch before the final default `ELSE` clause | Create a new skill file (sdd-clarify) or a hook | Gate is pure routing logic, not implementation work. Procedural logic belongs in CLAUDE.md inline. A new skill would introduce unnecessary indirection for a simple disambiguation prompt. |
| **Trigger pattern detection** | Pattern: input matches `[0-9]|^[a-z-]+$` (single word, no spaces, no special chars) OR is a bare change verb without context ("refactor", "build" with no target) | Heuristic ML-style confidence scoring | Regex is transparent, deterministic, and fast. Confidence scoring is opaque and harder to tune. The proposal examples are all single words or unscoped verbs — exact pattern matching covers all observed cases. |
| **Clarification prompt structure** | 3 numbered options (1: Change, 2: Exploration, 3: Question) with optional text input fallback ("or clarify in your own words") | 2 options, or Yes/No format, or free-text only | 3 options align to the top 3 intent classes (Meta-Command is not ambiguous — it starts with /). Numbered options make it fast to respond. Fallback text input allows edge cases like "fix and explain". |
| **Routing after clarification** | Parse user's numeric choice (1/2/3) or detect intent verb in text input; proceed with standard routing | Loop indefinitely until valid choice | Single parse attempt is sufficient. If the user enters invalid text, treat it as a Question (safest default). Re-prompting creates bad UX. |
| **Session persistence** | No caching of clarifications within a session — ask every time | Cache per-session (remember user chose "1" for "auth" previously) | Simplicity. Caching adds state management overhead. Most users will learn the pattern quickly. Single-word ambiguity is relatively rare in real usage. |
| **Performance impact** | No impact on non-ambiguous inputs — gate check is string-length + regex test (O(1) per character) | Pre-check all inputs against a supervised list | Regex is efficient. Supervised list grows without limit and requires manual maintenance. |

---

## Data Flow

```
User message
    ↓
Start classification
    ↓
Is message a Meta-Command (starts with /)?
    ├─ YES → Execute skill immediately
    ├─ NO → Continue
    ↓
Does message contain change intent?
    ├─ YES → Recommend /sdd-ff
    ├─ NO → Continue
    ↓
Does message contain investigative intent?
    ├─ YES → Auto-launch sdd-explore
    ├─ NO → Continue
    ↓
[NEW GATE] Is message ambiguous? (single-word, bare verb, etc.)
    ├─ YES → Present clarification prompt (3 options)
    │         ↓
    │         Receive user choice (1/2/3 or text)
    │         ↓
    │         Proceed with chosen intent class
    ├─ NO → Continue
    ↓
Default to Question — answer directly
```

---

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `CLAUDE.md` | Modify | Add ambiguity detection pattern description, clarification prompt template, and route branch before final `ELSE` in Classification Decision Table |
| `ai-context/conventions.md` | Modify | Add note about ambiguous input handling to the CLAUDE.md section for reference |

---

## Interfaces and Contracts

### Ambiguous Input Pattern Specification

**Regex pattern for detection:**
```
^[a-z0-9-]+$
```

**Additional rules (checked after regex match):**
1. Input length: 1–50 characters (reasonable word/command length)
2. No leading/trailing whitespace (trimmed before test)
3. Bare change verbs without target: `"refactor"`, `"build"`, `"fix"` (single word matching verb keywords)

**Classification of ambiguous vs. clear:**

| Input | Classification | Reason |
|-------|---|---|
| `"auth"` | Ambiguous | Single noun, no verb, no context |
| `"refactor"` | Ambiguous | Change verb without target |
| `"fix the auth bug"` | Clear | Change verb + target → Change Request |
| `"review the auth module"` | Clear | Investigative verb → Exploration |
| `"what is auth?"` | Clear | Interrogative form + ? → Question |
| `"auth module audit"` | Clear | Multiple words, pattern broken |
| `"/sdd-ff fix-bug"` | Clear | Starts with / → Meta-Command (bypass gate) |

### Clarification Prompt Template

```
I'm not sure what you'd like me to do with "[INPUT]".
Are you looking to:
  1. Make a change (fix, add, update, etc.) — I'll recommend /sdd-ff
  2. Explore or review something — I'll analyze and explain
  3. Learn or ask a question — I'll answer directly

Just reply with 1, 2, 3, or clarify in your own words.
```

### Response Routing After Clarification

**Parse logic (in order):**
1. If user replies with exactly `1` → treat as Change Request → recommend `/sdd-ff <inferred-slug>`
2. If user replies with exactly `2` → treat as Exploration → auto-launch `sdd-explore` via Task
3. If user replies with exactly `3` → treat as Question → answer directly
4. If user provides text input (not a single digit):
   - Check text for change intent keywords (`fix`, `add`, `implement`, etc.) → Change Request
   - Check text for investigative keywords (`review`, `analyze`, `show me`, etc.) → Exploration
   - Otherwise → Question (safe default)

---

## Testing Strategy

| Layer | What to test | Method |
|-------|---|---|
| Pattern matching | Single-word inputs trigger gate; multi-word inputs bypass it | Manual input testing in chat (e.g., type `"auth"`, observe prompt) |
| Prompt clarity | User can understand the 3 options and respond correctly | User feedback; observe response time to clarification prompt |
| Routing accuracy | Each choice (1, 2, 3) routes to correct class | Manual testing: type `1` and verify `/sdd-ff` recommendation appears; type `2` and verify exploration task launches; type `3` and verify question answer is provided |
| Edge cases | Invalid input (e.g., `"4"`, empty text, symbols) defaults gracefully | Type invalid input; observe fallback to Question classification |
| Non-ambiguous pass-through | Clear inputs bypass gate without delay | Type `"fix the login bug"` and verify immediate Change Request routing (no clarification prompt) |
| Performance | No measurable latency added to decision flow | Regex test on typical inputs (<100ms total) |

---

## Migration Plan

No data migration required. The change is purely procedural — no database, schema, or existing configuration is affected. The gate is additive (inserted before existing default behavior) and backward-compatible.

**Deployment steps:**
1. Update CLAUDE.md with the new gate branch in the Classification Decision Table
2. Run `/project-audit` to verify the change does not introduce new structural issues
3. Deploy via `install.sh`
4. Test with ambiguous and non-ambiguous inputs to confirm routing behavior

---

## Open Questions

1. **Should we track clarification choices per user session for learning?** Not in V1 — simplicity over analytics. Revisit if usage data shows users repeatedly clarifying the same input.

2. **Should `"refactor"` as a standalone word always trigger the gate, or should we check for existing refactoring-related context?** Always trigger. Context-awareness adds complexity. Single-word inputs are inherently ambiguous.

3. **Should the gate apply to follow-up messages in a conversation?** Yes — the gate checks every free-form message independently. If a user has already clarified earlier, they'll see the prompt again, but that's fine (clarifications are cheap interactions).

4. **What if the user's clarification text itself is ambiguous (e.g., "maybe fix something")?** Treat as Question (safest default). The user can re-submit with clearer intent if needed.

---

## Architectural Coherence

This change **extends** the existing orchestrator-always-on pattern (ADR 029) without modifying the core four-class routing logic. It introduces a **pre-processing step** (ambiguity detection) that narrows the ambiguous Question bucket before defaulting. The change is consistent with:

- **ADR 029** (Orchestrator Always-On): Gate is inline in CLAUDE.md decision flow, same as existing classification
- **ADR 031** (Orchestrator Classification Edge Cases Pattern): Gate directly addresses the ambiguous-input problem flagged in that ADR
- **Unbreakable Rule 1** (Never write code inline): Gate is procedural logic in CLAUDE.md, not implementation code; specs are still written separately via sdd-spec

No skill changes required. No new architectural layers introduced.

---

## Rollback Plan

If the gate causes unexpected issues:
1. Remove the new `ELSE IF` branch from the Classification Decision Table
2. Revert CLAUDE.md to the previous version (git checkout)
3. Run `install.sh` to deploy the revert
4. Behavior returns to original: ambiguous inputs default to Question

---
