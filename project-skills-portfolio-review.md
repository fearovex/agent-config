# Project Skills Portfolio Review

Date: 2026-03-06
Repository: `claude-config`
Scope: `skills/project-*/SKILL.md`
Method: Static review of live skill definitions, archived change history in `openspec/changes/archive/`, and maintenance churn visible in `ai-context/changelog-ai.md`.

## Executive Summary

The `project-*` portfolio should be kept as a group. Each skill still represents a distinct operational moment in the lifecycle of a Claude-configured project: bootstrap, diagnosis, audit, analysis, repair, update, and folder reorganization.

The current problem is not portfolio bloat. The problem is uneven maintenance cost.

Three skills now carry disproportionate complexity and should be rewritten around a narrower contract:

- `project-audit`
- `project-fix`
- `project-claude-organizer`

No immediate merge is recommended. The boundaries are still useful. Merging now would mostly hide complexity instead of removing it.

## Decision Matrix

| Skill | Recommendation | Role | Overlap Assessment | Maintenance Cost | Decision Rationale |
|---|---|---|---|---|---|
| `project-setup` | **KEEP** | Bootstrap a project into the SDD + memory model | Low overlap with `project-onboard`; setup creates, onboard diagnoses | Low to medium | It owns the initial scaffolding moment and remains easy to understand. Its value is stable and its scope is legible. |
| `project-onboard` | **KEEP** | Diagnose current state and recommend the next command sequence | Low overlap with `project-setup` and `project-audit`; it routes, it does not mutate or score | Low | This is the entry-point skill for humans who do not know what to run next. The deterministic case model is useful and distinct. |
| `project-audit` | **REWRITE** | Produce the canonical health diagnosis and the `audit-report.md` spec consumed by `project-fix` | Necessary adjacency to `project-fix`, but not a merge candidate | High | It is strategically central, but it keeps absorbing new dimensions, exceptions, and validation rules. The skill still matters, but its contract is becoming too broad and too expensive to evolve safely. |
| `project-analyze` | **KEEP** | Pure observation layer for structure, stack, conventions, and drift | Low overlap with `project-audit`; the observe-vs-score split is valid | Medium | This skill created a healthy separation of concerns. It should remain read-only and feed other tools rather than be folded back into audit logic. |
| `project-fix` | **REWRITE** | Apply the changes specified by `audit-report.md` | Tight coupling with `project-audit`, but still a distinct apply-phase role | High | It is necessary, but it is accumulating handler-specific logic and format exceptions. The command should stay, but the internal action model should be simplified. |
| `project-update` | **KEEP** | Refresh project configuration and memory docs without full bootstrap | Moderate adjacency to `project-setup` and `project-claude-organizer`, but different intent | Medium | It fills the ongoing maintenance gap between one-time setup and corrective repair. The boundary is still valid. |
| `project-claude-organizer` | **REWRITE** | Reorganize a project's `.claude/` folder into the canonical structure | Some adjacency to `project-update` and `project-fix`, but specialized enough to stay standalone | Very high | It has become the highest-churn and most behavior-dense `project-*` skill. It still solves a real migration problem, but the current scope is too ambitious for a stable meta-tool. |

## Skill-by-Skill Assessment

### `project-setup` — KEEP

`project-setup` still has a clean purpose: it establishes the baseline artifacts a project needs to participate in the SDD system. It is not trying to diagnose partial states, recover drift, or reorganize legacy content. That separation matters.

It should remain the one skill that answers: "How do I create the expected project shape from scratch?"

### `project-onboard` — KEEP

`project-onboard` is a routing skill, not a transformation skill. That is a good product boundary. It converts ambiguous project state into a concrete next-command sequence.

Its main value is usability, not raw capability. Removing or merging it would make the rest of the system harder to enter, especially for repos that are in an in-between state.

### `project-audit` — REWRITE

`project-audit` is still one of the most important skills in the repo, but it now carries too many responsibilities:

- structural validation
- documentation validation
- skill quality checks
- feature-doc heuristics
- internal coherence checks
- special handling for global-config repositories
- artifact production for `project-fix`

This has produced a pattern of incremental append-only growth. The result is powerful, but brittle.

The recommendation is not to deprecate it. The recommendation is to rewrite it around a smaller core:

- a stable audit execution model
- a clearer separation between scored checks, informational checks, and transitional compatibility checks
- a more modular dimension layout so new rules do not constantly enlarge one monolithic skill body

### `project-analyze` — KEEP

`project-analyze` is one of the healthier design decisions in the portfolio. It externalized descriptive analysis instead of forcing `project-audit` to do both interpretation and judgment in the same step.

That boundary should be protected. If anything changes here, it should be light refinement, not consolidation into another skill.

### `project-fix` — REWRITE

`project-fix` remains necessary because the `audit -> fix -> audit` loop is one of the strongest patterns in the whole meta-system. The problem is implementation density.

Its behavior is increasingly driven by a growing `FIX_MANIFEST` schema and a long list of action handlers. That makes the command operationally valuable but increasingly difficult to reason about.

The rewrite should preserve the command and the audit-consumer role, while shrinking the action vocabulary and making each handler more predictable.

### `project-update` — KEEP

`project-update` still has a valid role between setup and repair. It handles freshness and controlled migration without assuming the repo is either brand-new or broken.

The skill is somewhat adjacent to `project-setup` and `project-claude-organizer`, but the user intent is different:

- `project-setup` creates
- `project-update` refreshes
- `project-claude-organizer` reorganizes legacy layout

That distinction is good enough to preserve.

### `project-claude-organizer` — REWRITE

`project-claude-organizer` is the clearest high-cost skill in the portfolio. The archived change history shows repeated expansion:

- documentation-candidate detection
- legacy-directory intelligence
- per-strategy migration handlers
- commands scaffolding
- skills audit logic
- post-migration cleanup paths

This is a lot of policy for one skill. The feature is still relevant, but the current scope is too wide.

The rewrite should reduce it to a safer and more durable core:

- classify
- propose dry-run plan
- apply only a narrow set of additive migrations
- push exotic cases back to explicit user choice instead of encoding them all as first-class behavior

## Overlap Review

### `project-setup` vs `project-onboard`

Keep both. One creates baseline structure. The other decides what to do next from the current state. Those are complementary, not redundant.

### `project-audit` vs `project-analyze`

Keep both. The observe-vs-judge split is one of the healthiest boundaries in this portfolio. The problem is not overlap; the problem is that `project-audit` still grows too easily.

### `project-audit` vs `project-fix`

Keep both, but treat them as one product pair. They should evolve together, but they should not be merged. A spec-producing skill and an apply-phase skill are distinct enough to preserve.

### `project-update` vs `project-claude-organizer`

Keep both, but narrow the organizer. `project-update` is about freshness and synchronization. `project-claude-organizer` is about structural migration. The overlap is tolerable; the complexity of the organizer is the real issue.

## Portfolio Recommendation

Recommended disposition for the current `project-*` portfolio:

- Keep: `project-setup`, `project-onboard`, `project-analyze`, `project-update`
- Rewrite: `project-audit`, `project-fix`, `project-claude-organizer`
- Merge: none
- Deprecate: none, for now

If the portfolio must be reduced later, `project-claude-organizer` is the first candidate to revisit for deprecation or extreme narrowing. It is the most specialized skill and the one with the steepest maintenance curve.

## Suggested Next Move

The highest-leverage next step is not another broad audit. It is a design pass for the three rewrite candidates:

1. `project-audit` — define a smaller dimension model and compatibility policy.
2. `project-fix` — define a reduced action taxonomy and clearer handler boundaries.
3. `project-claude-organizer` — define a minimal safe scope and move edge-case migrations out of the core path.