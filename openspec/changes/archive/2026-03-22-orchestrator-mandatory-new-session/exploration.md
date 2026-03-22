# Exploration: Mandatory New Session Per SDD Cycle

## Handoff Context

**Decision that triggered the change**: Rule 6 (Cross-session ff handoff) is opt-in — it only activates when the user explicitly states they are moving to a new session. The user has decided that every SDD cycle must begin in its own session, making Rule 6 always-on.

**Goal and success criteria**:
- Rule 6 updated from opt-in to always-on in CLAUDE.md
- New "One Cycle Per Session" rule documented with a block message for second-cycle-in-session attempts
- Mandatory `proposal.md` creation before every `/sdd-ff` recommendation (not just cross-session deferrals)
- Command block message template defined
- `/memory-update` offer added to end of every session that creates a proposal

**Explore targets**:
- `CLAUDE.md` — Rule 6 and overall unbreakable rules section
- `openspec/specs/orchestrator-behavior/spec.md` — existing cross-session requirements
- `skills/sdd-ff/SKILL.md` — current pre-population and context extraction behavior

**Constraints**:
- Do NOT block exploration or questions — only SDD execution is blocked
- Block must be clear with the exact next step (command + new session instruction)
- `proposal.md` creation must be fast, no sub-agent delegation
- This is Cycle 5 of 5 in the orchestrator improvement series — must coexist with teaching tone changes from earlier cycles

---

## Current State

### Rule 6 — as it stands in CLAUDE.md

```
### 6. Cross-session ff handoff
- When user will run `/sdd-ff` in a new session (trigger: "new session", "next chat",
  "context reset", compaction imminent): MUST create `openspec/changes/<slug>/proposal.md`
  first with: decision context, success goal, target files, constraints
- Include proposal path in recommendation; offer `/memory-update`
```

**Key observation**: The trigger is explicit user language ("new session", "next chat", etc.) or a context compaction warning. There is no trigger for the common case: the orchestrator recommends `/sdd-ff` and the user simply starts it in a new session without saying so.

### Rule 5 — Feedback persistence (related)

Feedback sessions require `proposal.md` before any SDD command. This is a partial coverage: it addresses deliberate feedback sessions but not routine change requests.

### sdd-ff pre-population (context extraction sub-step)

The `sdd-ff` skill already has a **context extraction sub-step** in Step 0 that scans the description for removals, replacements, platform constraints, and caution notes, then pre-populates `proposal.md` if any patterns are found. This runs BEFORE the explore launch and is non-blocking.

This means `sdd-ff` already creates `proposal.md` in some cases — but only when context patterns are detected, and this happens inside the `/sdd-ff` command, not before it (at the orchestrator's recommendation step).

### orchestrator-behavior spec

The spec covers intent classification routing, scope estimation, and pre-flight checks (Gate 1: active change scan, Gate 2: spec drift advisory). There is no existing requirement for cross-session isolation or mandatory `proposal.md` creation at the orchestrator level. The pre-flight checks are advisory only.

### sdd-orchestration spec

Covers the phase DAG (explore → propose → spec+design → tasks → apply → verify → archive) and user confirmation gates. No session boundary requirements exist.

---

## Branch Diff

Files modified in current branch relevant to this change:
- `CLAUDE.md` (modified + staged) — Rule 6 and orchestrator behavior inline
- `openspec/specs/orchestrator-behavior/spec.md` (modified + staged) — spec domain for orchestrator
- `skills/sdd-ff/SKILL.md` (not modified in branch) — target file for this change
- `ai-context/architecture.md` (modified + staged) — context file
- `ai-context/changelog-ai.md` (modified + staged) — session log

Other changes in branch: `2026-03-22-slim-orchestrator-context` (staged, deleted — being archived), archive changes for orchestrator-natural-language, orchestrator-scope-estimation, orchestrator-teaching cycles. These confirm this is Cycle 5 in a larger orchestrator improvement series.

---

## Prior Attempts

Prior archived changes related to this topic:

- `2026-03-19-2026-03-18-context-handoff-between-sessions`: COMPLETED (verify-report present, PASSED) — Added Rule 6 itself (opt-in cross-session handoff). This is the direct predecessor.
- `2026-03-19-2026-03-19-feedback-sdd-cycle-context-gaps-p6`: COMPLETED (verify-report present, PASSED) — Addressed context gaps in the SDD cycle, including orchestrator spec reading before answering questions.
- `2026-03-01-proposal-prd-and-adr-system`: COMPLETED — Added PRD convention and proposal.md structure.
- `2026-02-28-integrate-memory-into-sdd-cycle`: COMPLETED — Integrated ai-context/ memory loading into SDD phases.

**Pattern**: Rule 6 was designed as an opt-in rule intentionally to avoid over-application. The current change upgrades it to always-on. The 2026-03-18 context-handoff change explicitly scoped OUT always-on behavior ("the rule must define trigger signals precisely to avoid over-application in same-session cycles"). This is a deliberate reversal of that scoping decision.

---

## Contradiction Analysis

Contradictions detected between user intent and existing context:

- Item: Rule 6 trigger scope
  Status: CERTAIN — The 2026-03-18 context-handoff change explicitly excluded always-on behavior as out of scope, citing "over-application in same-session cycles." The current proposal reverses this decision.
  Severity: INFO
  Resolution: This is an intentional design reversal, not a conflict. The proposal documents this explicitly. The earlier scoping decision should be acknowledged in the new proposal but does not block this change.

- Item: "One Cycle Per Session" block behavior vs. Exploration/Question freedom
  Status: UNCERTAIN — The proposal says the block applies only to SDD execution (Change Requests), not exploration or questions. However, the mechanism for detecting "a cycle has already been initiated in this session" is heuristic-based (has a `proposal.md` been created, or has a Task been launched). This heuristic may be unreliable in practice — the orchestrator cannot directly inspect Task launch history from prior turns.
  Severity: WARNING
  Resolution: The detection mechanism needs careful design. The orchestrator has no reliable in-session memory of Task launches. The most reliable signal available is: does `openspec/changes/<slug>/proposal.md` exist with a `session_created` timestamp from today? This limits the block to cases where a proposal was written in-session, which is detectable.

- Item: Mandatory proposal.md creation overhead
  Status: UNCERTAIN — If proposal.md must be created before every `/sdd-ff` recommendation (not just cross-session deferrals), the orchestrator must write a file for every Change Request response. This is a behavioral change: the orchestrator currently recommends `/sdd-ff` without writing any file. Writing files at the recommendation step (before user confirmation) may create orphaned proposals for changes the user never executes.
  Severity: WARNING
  Resolution: Two options: (A) Create proposal.md immediately when recommending `/sdd-ff`, even if user doesn't follow through — orphaned proposals are acceptable overhead. (B) Keep proposal.md creation inside sdd-ff (already done via context extraction sub-step), and upgrade Rule 6 to only activate the "new session" reminder always (not mandatory file creation). Option B is lower overhead and fits existing architecture.

---

## Affected Areas

| File/Module | Impact | Notes |
| ----------- | ------ | ----- |
| `CLAUDE.md` | High | Rule 6 rewrite — opt-in → always-on; new "One Cycle Per Session" rule; block message template |
| `openspec/specs/orchestrator-behavior/spec.md` | Medium | New REQ for session discipline; mandatory proposal.md; block behavior |
| `skills/sdd-ff/SKILL.md` | Low–Medium | Check for pre-existing proposal.md as session marker; already has context extraction |
| `ai-context/architecture.md` | Low | Session boundary pattern should be documented |
| `ai-context/conventions.md` | None | No naming/format changes |

---

## Analyzed Approaches

### Approach A: Full always-on block (strict interpretation)

**Description**: Every Change Request recommendation creates a `proposal.md` immediately. A second Change Request in the same session detects the first `proposal.md` (via `session_created` timestamp from today) and blocks with an explicit message directing the user to a new session.

**Pros**: Fully enforces "one cycle per session" discipline. Consistent with the proposal's intent. The `proposal.md` created at recommendation time gives the next session full context (Rule 6 handoff benefit for every cycle, not just explicit cross-session deferrals).

**Cons**: Orphaned proposals for every Change Request the user doesn't execute. The session detection heuristic (today's timestamp in proposal frontmatter) is fragile — multiple proposals from the same day with different slugs won't block each other correctly. High noise if user makes multiple exploratory Change Request messages before committing to one.

**Estimated effort**: Medium
**Risk**: Medium — heuristic detection may produce false positives or false negatives

### Approach B: Upgrade Rule 6 to always-on + keep proposal.md inside sdd-ff (recommended)

**Description**: Rule 6's trigger changes from "when user explicitly says new session" to "always — every `/sdd-ff` recommendation must include a new-session reminder and proposal.md path." The proposal.md is still created inside `sdd-ff` (context extraction sub-step already does this), not at the orchestrator's recommendation step. Remove the "One Cycle Per Session" block behavior entirely — it's unreliable and adds complexity without clear enforcement value. Instead, the orchestrator's recommendation always ends with: "Create a new session and run: `/sdd-ff <slug>` — I've created `openspec/changes/<slug>/proposal.md` with context."

**Pros**: Reliable — no session detection heuristic needed. Keeps proposal.md creation inside `sdd-ff` where it already lives. Aligns with the real benefit: context persistence between sessions. Low noise. No orphaned proposals for un-executed cycles.

**Cons**: Doesn't enforce the "one cycle per session" block. User can still run multiple sdd-ff cycles in one session. But this was always true — the block is advisory at best.

**Estimated effort**: Low
**Risk**: Low — minimal changes to sdd-ff; Rule 6 update is a text change to CLAUDE.md

### Approach C: Hybrid — Rule 6 always-on + advisory (not blocking) for second cycles

**Description**: Same as Approach B, but adds an advisory (non-blocking) note when a second Change Request is detected in the same session: "You already have `<slug>` in flight from this session. Consider running `/sdd-ff <new-slug>` in a new session for clean context separation."

**Pros**: Educates without blocking. Preserves user freedom. Reliable detection: Gate 1 (Active Change Scan) already detects active changes — no new mechanism needed.

**Cons**: Adds a message that may feel repetitive if Gate 1 already fires. Slightly more complex than Approach B.

**Estimated effort**: Low
**Risk**: Low

---

## Recommendation

**Approach B** with elements of Approach C.

The core value of this change is: **every `/sdd-ff` recommendation must come with a proposal.md and a new-session reminder** — making context handoff automatic, not opt-in. The block behavior for "second cycles in same session" is not reliably enforceable and should not be the focus.

Concretely:

1. **CLAUDE.md Rule 6**: Remove the opt-in trigger condition. New rule: "Every time the orchestrator recommends `/sdd-ff`, it MUST create `openspec/changes/<slug>/proposal.md` first (with decision context, goal, target files, constraints) AND remind the user to open a new session before running the command."
2. **CLAUDE.md — optional "One Cycle Per Session" advisory**: Reuse Gate 1 (Active Change Scan) to advise when a change is already in flight — no new mechanism. Gate 1 is already non-blocking and advisory. No separate block rule needed.
3. **orchestrator-behavior spec**: Add new REQ for always-on cross-session handoff at recommendation time. Reference proposal.md path in recommendation output.
4. **sdd-ff SKILL.md**: Minor clarification — note that the context extraction sub-step serves the cross-session handoff (Rule 6) and confirm proposal.md creation is non-optional when context patterns are found.
5. **session_created frontmatter**: The proposal suggests adding `session_created: <timestamp>` to proposal.md frontmatter. This is low-cost and useful for audit — include it.

---

## Identified Risks

- **Orphaned proposals**: proposals created at recommendation time and never executed remain in `openspec/changes/`. Low risk — sdd-archive cleans up completed cycles; orphans are harmless files.
- **Rule 6 over-application**: If rule fires for every Change Request, the orchestrator must write a file for every recommendation. This is faster than it sounds (inline write, no sub-agent), but adds I/O to every recommendation. Mitigated by keeping creation inside sdd-ff rather than at the orchestrator level.
- **`session_created` timestamp accuracy**: On Windows, timestamp generation in Markdown frontmatter is straightforward (ISO 8601 from system time). No known risk.
- **Proposal overwrite**: If the user runs `/sdd-ff` for the same slug twice (e.g., collision path), the context extraction sub-step may overwrite the pre-seeded proposal. Mitigated by: sdd-ff already checks for collisions in slug generation; context extraction is additive when proposal already exists.

---

## Open Questions

1. Should the orchestrator create `proposal.md` at the recommendation step (before user confirmation), or only when the user executes `/sdd-ff`? Recommendation: creation inside sdd-ff is sufficient and already implemented — the gap is only the new-session reminder.
2. Should the "One Cycle Per Session" block be enforced or advisory? Recommendation: advisory only, reusing Gate 1.
3. Does the `session_created` timestamp in proposal frontmatter need to follow a specific format? Recommendation: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) for consistency with SDD artifact conventions.

---

## Ready for Proposal

Yes — the terrain is well-understood. The recommended approach (Approach B + advisory) is lower risk and lower overhead than the strict interpretation, while delivering the core benefit: automatic context handoff on every `/sdd-ff` recommendation.

Key design decision for sdd-propose to capture: the "One Cycle Per Session" block is NOT implemented as a hard block — it is advisory via existing Gate 1. The mandatory behavior is the always-on new-session reminder + proposal.md creation, not the session isolation enforcement.
