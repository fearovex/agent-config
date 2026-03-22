# ADR-043: Context-Aware Session Handoff Convention

## Status

Proposed

## Context

Rule 6 (Cross-session ff handoff) activates only when the user explicitly writes "new session", "next chat", or "context reset". This opt-in trigger misses the common case where users don't know or forget to signal a session boundary. When the orchestrator recommends `/sdd-ff` after a long conversation, the context that informed the recommendation gets lost — the next session starts blind with only a slug. The real goal is preserving context window quality and cycle independence, not enforcing a ritual. A clean session (first message is the change request) does not need a session jump; a session with significant prior discussion does. The previous explicit-trigger design was confirmed as a scoping decision in the 2026-03-18 context-handoff change (ADR-037), which deliberately excluded always-on behavior. This ADR reverses that exclusion with a context-aware heuristic.

## Decision

We will replace Rule 6's explicit-language opt-in trigger with a two-branch context-aware heuristic. When the orchestrator detects significant prior context (~5+ messages exchanged or other topics discussed), it creates `proposal.md` immediately with the conversation context, displays the proposal path, recommends opening a new session, and offers `/memory-update`. When the session is clean (change request is the first or near-first message), the orchestrator recommends `/sdd-ff <slug>` directly without a session jump. This replaces the 2026-03-18 convention documented in ADR-037.

## Consequences

**Positive:**

- Users who don't know Rule 6 now get context preservation automatically without needing to trigger it explicitly
- Clean sessions are not burdened with unnecessary session jumps — the heuristic is context-sensitive
- The proposal.md is created with rich context from the current session before it is lost

**Negative:**

- The ~5-message threshold is a judgment call, not an exact count — imprecise in edge cases (acceptable: false negatives are harmless, false positives create an orphaned proposal.md which is also harmless)
- Replaces ADR-037's explicit-trigger convention — sessions that relied on the opt-in pattern will no longer receive the recommendation unless context is detected
