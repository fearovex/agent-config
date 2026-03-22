# Proposal: Context-Aware Session Handoff

Date: 2026-03-21
Status: Draft

## Intent

Replace Rule 6's opt-in trigger with a context-aware heuristic that automatically creates `proposal.md` and recommends a new session when the orchestrator detects significant prior context in the current session.

## Motivation

Rule 6 (Cross-session ff handoff) currently activates only when the user explicitly states "new session", "next chat", or "context compaction." This is opt-in and users who don't know the rule skip it entirely.

The real problem is not that every cycle must begin in a new session — it is that when the orchestrator recommends `/sdd-ff` after a long conversation, the context that informed the recommendation gets lost. The next session starts blind, with a slug but no background.

The new session recommendation exists to preserve context window quality and cycle independence — not as a ritual. A clean session (first message is the change request) does not need the jump. A session with prior discussion does.

## Supersedes

### REPLACED

| Old | New | Reason |
|-----|-----|--------|
| Rule 6 opt-in trigger (explicit user language: "new session", "next chat", "context reset") | Context-aware heuristic (significant prior context detection) | The opt-in trigger misses the common case where users don't know or forget to signal a new session |

### CONTRADICTED

- **Rule 6 scope (2026-03-18 context-handoff change)**: the 2026-03-18 change explicitly excluded always-on behavior as out of scope, citing "over-application in same-session cycles." This proposal intentionally reverses that scoping decision by replacing the opt-in trigger with a context-aware heuristic. The earlier exclusion is superseded; this is a deliberate design reversal documented here.

## Scope

### Included

- Rule 6 rewrite in `CLAUDE.md` — replace opt-in trigger with context-aware heuristic
- New REQs in `openspec/specs/orchestrator-behavior/spec.md` for session handoff behavior
- Natural language confirmation gates in `skills/sdd-ff/SKILL.md` (phase transition prompts)
- `/memory-update` offer when a proposal is created before session handoff

### Excluded (explicitly out of scope)

- "One Cycle Per Session" hard block — not reliably enforceable without in-session memory; advisory via existing Gate 1 is sufficient
- Automatic `proposal.md` creation at the orchestrator recommendation step (before user confirmation) — creation stays inside `sdd-ff` context extraction sub-step
- Changes to `ai-context/architecture.md` — session boundary pattern documentation is deferred

## Proposed Approach

Replace Rule 6's explicit trigger with a two-branch heuristic:

**Signal: session has significant prior context** (more than ~5 messages exchanged, or other topics discussed):
1. Create `openspec/changes/<slug>/proposal.md` immediately, capturing problem, files, constraints, decisions
2. Display the proposal path
3. Recommend new session: "Open a new chat and run `/sdd-ff <slug>` — the proposal has the context."
4. Offer `/memory-update` before session ends

**If session is clean (little or no prior context):**
1. Create `proposal.md` inside `sdd-ff` as already designed (context extraction sub-step)
2. Proceed with `/sdd-ff` in the same session — no jump needed

Additionally, replace command-as-gate confirmation patterns with natural language gates:
- Old: "Ready? Run: `/sdd-apply <slug>`"
- New: "Continue with implementation? Reply **yes** to proceed." *(Manual: `/sdd-apply <slug>`)*

## Affected Areas

| Area/Module | Type of Change | Impact |
| ----------- | -------------- | ------ |
| `CLAUDE.md` Rule 6 | Modified | High — core orchestrator behavior change |
| `openspec/specs/orchestrator-behavior/spec.md` | Modified (new REQs) | Medium |
| `skills/sdd-ff/SKILL.md` | Modified (confirmation prompts) | Low–Medium |

## Risks

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| Heuristic "significant context" detection is imprecise (no exact message count available) | Medium | Low | Use conservative threshold (~5 messages); false negatives (missing a case) are acceptable — heuristic is advisory, not blocking |
| Orphaned proposals if user never runs `/sdd-ff` | Low | Low | sdd-archive cleans up completed cycles; orphaned proposals are harmless |
| Natural language confirmation breaks existing command-only workflow | Low | Low | Commands remain available as secondary reference; not removed, only demoted |

## Rollback Plan

1. Revert `CLAUDE.md` Rule 6 to the opt-in trigger text (restore from git: the 2026-03-18 context-handoff wording)
2. Revert new REQs added to `openspec/specs/orchestrator-behavior/spec.md`
3. Revert `skills/sdd-ff/SKILL.md` confirmation prompt changes
4. Git command: `git revert <commit-hash>` or `git checkout <commit-hash> -- CLAUDE.md openspec/specs/orchestrator-behavior/spec.md skills/sdd-ff/SKILL.md`

## Dependencies

- The `sdd-ff` context extraction sub-step (Step 0) must already handle `proposal.md` creation when context patterns are detected — this is already implemented and confirmed in exploration
- No external dependencies

## Success Criteria

- [ ] Rule 6 in `CLAUDE.md` replaced with context-aware heuristic (two-branch: significant context → new session + proposal; clean session → proceed inline)
- [ ] Orchestrator creates `proposal.md` with conversation context when session has significant prior context
- [ ] Clean sessions (first-message change request) proceed without new-session recommendation
- [ ] Phase transition confirmations in `sdd-ff/SKILL.md` use natural language with command as optional reference
- [ ] `/memory-update` offer added when a proposal is created before session handoff

## Effort Estimate

Low (hours) — Rule 6 is a text change in CLAUDE.md; orchestrator-behavior spec adds 1–2 REQs; sdd-ff confirmation prompt update is a wording change.

## Context

Recorded from conversation at 2026-03-21:

### Explicit Intents

- **Context-aware over always-on**: original proposal was "always new session" — this was refined to "only when session has significant prior context" after recognizing that clean sessions don't benefit from a jump
- **Natural language confirmations**: discussed in same session as a companion improvement; commands should be secondary references, not primary gates

### Provisional Notes

- **Heuristic threshold (~5 messages)**: provisional — the exact count is not enforceable without memory; the heuristic relies on orchestrator judgment. If too noisy in practice, threshold can be raised.
