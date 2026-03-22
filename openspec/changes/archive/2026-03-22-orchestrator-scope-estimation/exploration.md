# Exploration: Orchestrator Scope Estimation

## Handoff Context

- **Decision**: Every Change Request currently routes to `/sdd-ff` regardless of scope. Trivial changes (typo, doc fix) get full SDD treatment while complex multi-domain changes get the same as a one-liner.
- **Goal**: Introduce a Scope Estimation Heuristic as a post-classification, pre-routing step for Change Requests, with three tiers: Trivial, Moderate, Complex.
- **Success criteria**: CLAUDE.md contains scope estimation section; Trivial tier offers bypass; Complex tier routes to `/sdd-new`; Classification Decision Table updated.
- **Targets**: `CLAUDE.md` (Classification Decision Table + new section), `openspec/specs/orchestrator-behavior/spec.md`.
- **Constraints**: Default must be Moderate (never Trivial); Trivial bypass must still offer SDD as an option; scope estimation is additive — does not remove existing intent classification logic.

## Current State

### Intent Classification Flow (CLAUDE.md)

The Classification Decision Table currently has this structure:
1. `IF message starts with /` → Meta-Command
2. `ELSE IF message contains change intent` → Change Request → recommend `/sdd-ff` or `/sdd-new`
3. `ELSE IF message contains investigative intent` → Exploration
4. `ELSE IF message matches ambiguity pattern` → Ambiguous → clarification gate
5. `ELSE` → Question

**Change Request routing today**: The Change Request branch recommends `/sdd-ff <inferred-slug>` for all changes, with a note that complex changes may use `/sdd-new`. However, the criteria for "complex" are not formalized — it's left to the orchestrator's judgment. There is no formal scope estimation step.

**Trivial changes today**: A message like "fix typo in README" follows the exact same path as "rearchitect the auth system" — both get routed to `/sdd-ff`.

### Orchestrator Behavior Spec (orchestrator-behavior/spec.md)

The spec defines four intent classes with routing rules. The Change Request scenario (line 50-57) says:
- Route to `sdd-ff` recommendation (default) or `sdd-new` recommendation for complex changes
- The spec already acknowledges the `/sdd-ff` vs `/sdd-new` distinction but provides no heuristic for choosing between them

### SDD Orchestration Spec (sdd-orchestration/spec.md)

Defines sdd-ff and sdd-new mechanics (slug inference, mandatory exploration, model routing). No scope estimation or tier-based routing exists.

### Teaching Principles (CLAUDE.md)

The recently added Teaching Principles section includes "Why-framing" — one sentence explaining what risk the SDD cycle prevents for each Change Request. Scope estimation would complement this by calibrating the response to the actual risk level.

## Branch Diff

Files modified in current branch relevant to this change:
- CLAUDE.md (modified) — contains the Classification Decision Table that needs updating
- openspec/specs/orchestrator-behavior/spec.md (modified) — target for new REQ entries
- openspec/specs/sdd-orchestration/spec.md (modified) — may need scope-aware routing requirements

## Prior Attempts

Prior archived changes related to this topic:
- 2026-03-12-orchestrator-always-on: COMPLETED — established the four intent classes and routing rules
- 2026-03-14-add-clarification-gate-for-ambiguous-inputs: COMPLETED — added the ambiguity gate (H1-H4 heuristics)
- 2026-03-14-orchestrator-visibility: COMPLETED — added intent classification signals
- 2026-03-22-orchestrator-teaching: COMPLETED — added teaching principles and new-user detection

No prior attempt at scope estimation exists.

## Contradiction Analysis

- Item: Trivial tier bypass vs. Unbreakable Rule 1 ("I NEVER write implementation code inline")
  Status: UNCERTAIN — The proposal says Trivial tier offers "inline apply" as an option. Unbreakable Rule 1 says the orchestrator NEVER writes implementation code inline in response to a Change Request. A typo fix is technically implementation code. The question is whether the bypass constitutes a formal exception to Rule 1 or whether "inline apply" means delegating to a sub-agent with a simplified flow.
  Severity: WARNING
  Resolution: Requires user confirmation — does "inline apply" mean (a) the orchestrator writes the change directly, or (b) a lightweight sub-agent applies the change without full SDD artifacts?

- Item: Scope estimation vs. existing `/sdd-new` recommendation language
  Status: CERTAIN — CLAUDE.md already says "recommend `/sdd-new` for complex changes" but with no criteria. The proposal formalizes this with explicit signals. No contradiction — pure refinement.
  Severity: INFO
  Resolution: None needed — additive clarification.

## Affected Areas

| File/Module | Impact | Notes |
| ----------- | ------ | ----- |
| `CLAUDE.md` — Classification Decision Table | HIGH | Change Request branch needs a scope estimation sub-step |
| `CLAUDE.md` — New `## Scope Estimation Heuristic` section | HIGH | New section defining tiers, signals, and routing |
| `CLAUDE.md` — Unbreakable Rules | MEDIUM | May need an exception clause for Trivial tier bypass |
| `openspec/specs/orchestrator-behavior/spec.md` | HIGH | New requirements for scope tiers and routing |
| `openspec/specs/sdd-orchestration/spec.md` | LOW | May need a note about scope-aware orchestrator routing |

## Analyzed Approaches

### Approach A: Inline scope estimation in Classification Decision Table

**Description**: Add a sub-step inside the Change Request branch of the Classification Decision Table. After classifying as Change Request, apply scope heuristics (keyword matching) to determine Trivial/Moderate/Complex, then route accordingly.

**Pros**: Self-contained in the existing decision table; no new section needed beyond the heuristic definitions; minimal structural change.

**Cons**: The Classification Decision Table is already long and complex; adding scope estimation inline makes it harder to read; tier definitions and signal lists would be buried.

**Estimated effort**: Medium
**Risk**: Low

### Approach B: Separate `## Scope Estimation Heuristic` section + reference from decision table

**Description**: Create a new CLAUDE.md section defining the three tiers, their detection signals, and routing behavior. The Classification Decision Table's Change Request branch adds a single line: "Apply scope estimation (see ## Scope Estimation Heuristic)" and uses the tier result for routing.

**Pros**: Clean separation of concerns; tier definitions are easy to find and modify; decision table stays readable; matches the proposal's structure.

**Cons**: Adds another CLAUDE.md section (slightly increases file size); requires cross-referencing.

**Estimated effort**: Medium
**Risk**: Low

### Approach C: Scope estimation as a separate skill

**Description**: Create a new `sdd-scope/SKILL.md` skill that the orchestrator invokes before routing.

**Pros**: Full separation; testable independently.

**Cons**: Massive over-engineering — scope estimation is a keyword heuristic, not a complex process; adds latency (sub-agent launch for a simple classification); contradicts the existing pattern where intent classification is inline in CLAUDE.md.

**Estimated effort**: High
**Risk**: Medium (over-engineering risk)

## Recommendation

**Approach B** — Separate section with reference from decision table. This matches the proposal's structure, keeps the Classification Decision Table manageable, and follows the pattern established by the Ambiguity Detection Heuristics (which is also a separate subsection referenced from the decision table).

Key design decisions to make:
1. **Trivial bypass mechanism**: Whether "inline apply" means the orchestrator writes code directly (exception to Rule 1) or launches a lightweight sub-agent. Recommend: the orchestrator offers the choice but if the user picks inline, it delegates to a minimal sub-agent (no full SDD artifacts) — this preserves Rule 1's spirit while reducing friction.
2. **Signal keyword lists**: The proposal provides starter lists; these should be finalized in the spec phase.

## Identified Risks

- **Rule 1 tension**: Trivial tier bypass must not silently violate Unbreakable Rule 1. Mitigation: explicitly define bypass as "offer direct apply OR sdd-ff" where direct apply still uses a sub-agent, just without proposal/spec/design/tasks artifacts.
- **Scope creep in signals**: The keyword lists for Trivial and Complex could grow unbounded. Mitigation: cap at 10-15 signals per tier; use the "default is Moderate" rule as a safety net.
- **False trivial classification**: A seemingly trivial change ("rename this function") could have wide impact. Mitigation: default is Moderate; Trivial only triggers on very specific low-risk signals AND single-file scope.

## Open Questions

- Should the Trivial tier bypass create any artifact (e.g., a minimal `verify-report.md`) for traceability, or is it truly artifact-free?
- Should scope estimation also affect the teaching principle (why-framing sentence)? E.g., Trivial changes get no risk sentence, Complex changes get a longer explanation.
- Should the orchestrator show the estimated scope tier in its response signal (e.g., `**Intent classification: Change Request (Trivial)**`)?

## Ready for Proposal

Yes — the exploration is clear on the approach (Approach B), the main risk (Rule 1 tension with Trivial bypass), and the affected files. The UNCERTAIN contradiction about inline apply should be resolved during the proposal phase or via the contradiction gate.
