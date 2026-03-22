# Proposal: orchestrator-scope-estimation

Date: 2026-03-22
Status: Draft

## Intent

Introduce a Scope Estimation Heuristic that classifies Change Requests into Trivial, Moderate, or Complex tiers before routing, so the SDD response is proportional to the actual change risk.

## Motivation

Every Change Request currently routes to `/sdd-ff` regardless of scope. A typo fix in a doc and a multi-domain architectural refactor receive identical treatment. This creates unnecessary friction for trivial changes (full SDD cycle for a one-word fix) and undersells the SDD cycle for complex ones (same recommendation for a cross-domain migration as for a localized bug fix). The orchestrator has no heuristic for estimating change scope before routing.

The recently added Teaching Principles (why-framing) already calibrate the *explanation* to the change — scope estimation calibrates the *routing* itself.

## Supersedes

### CONTRADICTED

- **Unbreakable Rule 1 ("I NEVER write implementation code inline")**: This proposal introduces a Trivial tier where the orchestrator can apply changes directly (inline apply) without sub-agent delegation or SDD artifacts.
  Resolution: **Formal exception** — Rule 1 will be updated to acknowledge the Trivial tier as an explicit carve-out. "Inline apply" means the orchestrator applies the change directly only when scope signals are unambiguously trivial. For ambiguous cases, the default remains Moderate and the SDD cycle is recommended. This is not a silent violation — it is a deliberate refinement of Rule 1.

## Scope

### Included

- New `## Scope Estimation Heuristic` section in CLAUDE.md with three tier definitions (Trivial, Moderate, Complex)
- Detection heuristic keyword lists for Trivial and Complex signals
- Routing behavior specification per tier (Trivial: offer inline apply OR sdd-ff; Moderate: recommend sdd-ff; Complex: recommend sdd-new)
- Update to Classification Decision Table's Change Request branch to reference scope estimation
- Update to Unbreakable Rule 1 to add formal Trivial tier exception clause
- New REQ entries in `openspec/specs/orchestrator-behavior/spec.md` for scope tiers and routing

### Excluded (explicitly out of scope)

- Scope estimation for non-Change-Request intents (Exploration, Question) — not applicable
- Creating a separate skill for scope estimation — over-engineering per exploration Approach C rejection
- Automated scope detection from file diffs or AST analysis — heuristic is keyword-based only
- Artifact creation for Trivial tier changes (no proposal.md, no verify-report.md) — Trivial bypass is artifact-free
- Changes to sdd-orchestration/spec.md — scope estimation is orchestrator-behavior, not sdd-ff/sdd-new mechanics

## Proposed Approach

Add a new CLAUDE.md section (`## Scope Estimation Heuristic`) that defines three tiers with keyword-based detection signals — following the same structural pattern as the existing Ambiguity Detection Heuristics subsection. The Classification Decision Table's Change Request branch will add a single cross-reference line: after classifying as Change Request, apply scope estimation and route based on the resulting tier. Unbreakable Rule 1 will gain a parenthetical exception clause acknowledging Trivial tier inline apply.

This is **Approach B** from the exploration — separate section with reference from the decision table. It keeps the decision table readable and makes tier definitions easy to find and modify independently.

## Affected Areas

| Area/Module | Type of Change | Impact |
| ----------- | -------------- | ------ |
| `CLAUDE.md` — Classification Decision Table | Modified | High |
| `CLAUDE.md` — New Scope Estimation Heuristic section | New | High |
| `CLAUDE.md` — Unbreakable Rule 1 | Modified | Medium |
| `openspec/specs/orchestrator-behavior/spec.md` | Modified (new REQs) | High |

## Risks

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| False trivial classification (seemingly trivial change has wide impact) | Low | High | Default is Moderate; Trivial only triggers on very specific low-risk signals AND single-file scope |
| Signal keyword lists grow unbounded over time | Medium | Low | Cap at 10-15 signals per tier; default-Moderate rule is safety net |
| Rule 1 exception creep (Trivial bypass used to justify skipping SDD for non-trivial changes) | Low | High | Trivial signals are restrictive ("typo", "comment", "wording"); ambiguous scope always defaults to Moderate |
| Scope tier shown in response signal increases cognitive load | Low | Low | Design phase decides whether to include tier in signal or keep it implicit |

## Rollback Plan

1. Revert the CLAUDE.md changes: remove `## Scope Estimation Heuristic` section, remove the cross-reference line from Classification Decision Table, remove the Rule 1 exception clause.
2. Revert `openspec/specs/orchestrator-behavior/spec.md` new REQ entries.
3. Run `install.sh` to deploy the reverted config.
4. All changes are in two files only — rollback is a targeted `git revert` of the apply commit.

## Dependencies

- Teaching Principles change (2026-03-22-orchestrator-teaching) should be archived first — this change builds on the teaching structure. Listed as Cycle 2 of 5 in execution order.
- No external dependencies.

## Success Criteria

- [ ] CLAUDE.md contains `## Scope Estimation Heuristic` section with Trivial, Moderate, and Complex tier definitions
- [ ] Each tier has explicit detection signals (keyword lists) and routing behavior
- [ ] Trivial tier offers bypass option (inline apply OR sdd-ff — user chooses)
- [ ] Complex tier routes to `/sdd-new` instead of `/sdd-ff`
- [ ] Default (ambiguous scope) is Moderate — never Trivial
- [ ] Classification Decision Table's Change Request branch references scope estimation
- [ ] Unbreakable Rule 1 updated with formal Trivial tier exception clause
- [ ] `openspec/specs/orchestrator-behavior/spec.md` has new requirements for scope tiers
- [ ] `/project-audit` score >= previous after apply

## Effort Estimate

Medium (1-2 days) — two files to modify, no code, but careful wording needed for Rule 1 exception and tier boundary definitions.

## Decisions

### Contradiction Confirmation
Date: 2026-03-22T00:00:00Z
User answer: Confirmed — proceeding with change as described.
Items confirmed:
- Trivial tier bypass vs. Unbreakable Rule 1: The Trivial tier constitutes a **formal exception** to Rule 1. The rule will be updated as part of this change to acknowledge that the AI can skip the SDD cycle for genuinely trivial changes (typo, doc fix, comment). This is not a silent violation — it is an explicit refinement of Rule 1. "Inline apply" means the orchestrator applies the change directly (without a sub-agent delegation) only when scope signals are unambiguously trivial. For ambiguous cases, the default remains Moderate and the SDD cycle is recommended.

## Contradiction Resolution

### Unbreakable Rule 1 — Trivial tier inline apply

**Prior context**: Rule 1 states "I NEVER write implementation code, specs, or designs inline in response to a Change Request — I ALWAYS recommend an SDD command or delegate to a sub-agent."
**This proposal**: Trivial tier allows the orchestrator to apply changes directly without SDD artifacts or sub-agent delegation.
**Resolution approach**: Contract superseded — Rule 1 gains a formal exception clause acknowledging Trivial tier inline apply. The exception is narrow: only when all scope signals are unambiguously trivial (typo, doc fix, comment, wording, single-file rename). Ambiguous cases default to Moderate and follow standard SDD routing.

## Context

Recorded from conversation at 2026-03-22T00:00Z:

### Explicit Intents

- **Trivial bypass is a formal exception**: User confirmed that Trivial tier constitutes a formal exception to Rule 1, not a violation. Rule 1 will be explicitly updated.
- **Inline apply means orchestrator-direct**: "Inline apply" means the orchestrator applies trivial changes directly — no sub-agent, no SDD artifacts — only when scope signals are unambiguously trivial.
- **Default remains Moderate**: For any ambiguity in scope estimation, the default tier is Moderate and the full SDD cycle is recommended.

## Execution Order

**Cycle 2 of 5** — run after teaching personality (Cycle 1) is archived.
