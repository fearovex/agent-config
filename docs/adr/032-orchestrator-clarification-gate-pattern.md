# ADR-032: Orchestrator Clarification Gate Pattern

## Status

Proposed

## Context

The orchestrator's intent classification system (ADR 029) defaults ambiguous single-word or bare-verb inputs to the Question class, avoiding false positives but creating poor UX: the user's actual intent is unclear, the orchestrator guesses, and the user must re-ask with more specificity. This doubles the interaction count for ambiguous inputs like "auth" (could mean "fix the auth system", "show me how auth works", or "what is auth?") or "refactor" (could mean "refactor some code" or "teach me refactoring patterns").

The Classification Decision Table currently has no path between "not clear change/exploration intent" and "default to Question"—leaving a gap where user intent can be silently misdirected. Proposal 2026-03-14-add-clarification-gate-for-ambiguous-inputs identifies this gap and proposes a **clarification gate**: intercept ambiguous inputs and ask the user to pick from 3 options before classifying.

## Decision

We will insert a new pre-processing step into the orchestrator's Classification Decision Table, positioned **before the final default Question case**. The clarification gate detects ambiguous inputs (single-word commands, bare change verbs without targets) and prompts the user with exactly 3 numbered options aligned to the top 3 intent classes (Change Request, Exploration, Question). The user responds with a digit (1/2/3) or clarifies in text; the orchestrator then routes based on the chosen or inferred intent.

The gate is implemented as procedural logic inline in CLAUDE.md using regex-based pattern matching and text parsing—no new skill is required. The clarification prompt is a fixed template asking users to pick from 3 options or provide text. Routing logic after clarification parses numeric replies and falls back to keyword detection in text input.

## Consequences

**Positive:**

- **Fewer misdirected SDD cycles**: Users get a chance to clarify intent before defaulting to Question or recommending /sdd-ff; "what did you mean?" interactions are prevented.
- **Faster resolution**: Single clarification prompt is faster than: unclear response → user re-asks → correct routing.
- **Better UX for ambiguous inputs**: Single-word commands and bare verbs now trigger a useful prompt instead of a silent (incorrect) default.
- **Clear audit trail**: Clarifications are recorded in the conversation, making the user's actual intent explicit and traceable.
- **No new architectural layers**: Gate is inline procedural logic in CLAUDE.md, consistent with the existing orchestrator pattern (ADR 029).

**Negative:**

- **Extra prompt for ambiguous inputs**: Users encountering single-word commands will see a clarification prompt every time (no session-level caching). Most users will learn the pattern quickly; this is acceptable.
- **Regex maintenance burden**: Ambiguity pattern is defined as a regex and additional heuristics. If new ambiguous patterns emerge (e.g., multi-word abbreviations), the regex and rules must be updated.
- **Fallback ambiguity in clarification text**: If a user replies with "maybe fix something" or "could be several things", the orchestrator defaults to Question (safe but might miss intent). The user can re-submit with clearer text.
- **Minor performance cost**: Every free-form message triggers a regex match. Negligible at typical message rates (~milliseconds per message).

---

**Cross-reference:** This ADR extends ADR 029 (Orchestrator Always-On Intent Classification) with a targeted pre-processing gate and directly addresses ADR 031 (Orchestrator Classification Edge Cases Pattern) by providing the mechanism to handle ambiguous edge cases.
