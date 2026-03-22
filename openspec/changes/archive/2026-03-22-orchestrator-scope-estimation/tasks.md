# Task Plan: orchestrator-scope-estimation

Date: 2026-03-22
Design: openspec/changes/2026-03-21-orchestrator-scope-estimation/design.md

## Progress: 9/9 tasks

## Phase 1: Foundation — Scope Estimation Heuristic Section

- [x] 1.1 Add new `### Scope Estimation Heuristic` subsection in `CLAUDE.md` under `## Always-On Orchestrator — Intent Classification`, after the `### Classification Decision Table` subsection. Content: three tier definitions (Trivial, Moderate, Complex), keyword signal lists per tier (Trivial: typo, typos, spelling, wording, comment, comments, whitespace, formatting, punctuation, doc fix, documentation fix, readme, rename; Complex: rearchitect, redesign, overhaul, rewrite, multi-domain, cross-cutting, system-wide, migration, migrate, breaking change, backwards-incompatible, multiple files, across modules, all services), routing behavior per tier, constraints (Trivial requires ALL conditions; Complex requires ANY signal; Moderate is default/residual), and classification examples
  Files: `CLAUDE.md` (MODIFY)

## Phase 2: Integration — Decision Table and Rule Updates

- [x] 2.1 Modify the Classification Decision Table's `Change Request` branch in `CLAUDE.md` to add a scope estimation cross-reference line after intent classification and before routing. The line should indicate: "After classifying as Change Request, apply Scope Estimation Heuristic (see below) to determine tier before selecting routing action."
  Files: `CLAUDE.md` (MODIFY)

- [x] 2.2 Modify Unbreakable Rule 1 in `CLAUDE.md` to add a parenthetical exception clause for Trivial tier: the rule text should acknowledge that Trivial-tier inline apply (when user explicitly chooses it and all scope signals are unambiguously trivial) is a formal exception to the "never write code inline" prohibition
  Files: `CLAUDE.md` (MODIFY)

- [x] 2.3 Modify the Orchestrator Session Banner in `CLAUDE.md` to add a brief mention of scope-aware routing (e.g., "Change Requests are scope-estimated into Trivial/Moderate/Complex tiers for proportional routing")
  Files: `CLAUDE.md` (MODIFY)

## Phase 3: Response Signal — Tier Visibility

- [x] 3.1 Update the `### Orchestrator Response Signal` subsection in `CLAUDE.md` to document that Change Request signals MAY include a scope tier suffix: `**Intent classification: Change Request (Trivial)**`, `**Intent classification: Change Request (Complex)**`, while Moderate omits the suffix (preserving existing format)
  Files: `CLAUDE.md` (MODIFY)

## Phase 4: Master Spec — Scope Estimation Requirements

- [x] 4.1 Merge the delta spec at `openspec/changes/2026-03-21-orchestrator-scope-estimation/specs/orchestrator-behavior/spec.md` into the master spec at `openspec/specs/orchestrator-behavior/spec.md`. Add the ADDED requirements (scope estimation heuristic, three scope tiers, dedicated CLAUDE.md section, scope tier visibility). Apply the MODIFIED requirements (Trivial tier exception to inline code prohibition, Unbreakable Rule 1 exception clause)
  Files: `openspec/specs/orchestrator-behavior/spec.md` (MODIFY)

## Phase 5: Spec Index Update

- [x] 5.1 Verify the `orchestrator-behavior` entry in `openspec/specs/index.yaml` has keywords that cover scope estimation. If the existing keywords do not include scope-related terms, add `scope-estimation` and `scope-tier` to the keywords array for the `orchestrator-behavior` domain entry
  Files: `openspec/specs/index.yaml` (MODIFY — only if keywords need updating)

## Phase 6: Cleanup and Documentation

- [x] 6.1 Update `ai-context/architecture.md` — add a new numbered architectural decision entry documenting the scope estimation heuristic: three tiers, keyword-based detection, Trivial bypass as formal Rule 1 exception, default-Moderate safety net
  Files: `ai-context/architecture.md` (MODIFY)

- [x] 6.2 Update `ai-context/changelog-ai.md` — add entry for orchestrator-scope-estimation change with date, summary of what was added (scope estimation heuristic, three tiers, Rule 1 exception, master spec update)
  Files: `ai-context/changelog-ai.md` (MODIFY)

---

## Implementation Notes

- The `### Scope Estimation Heuristic` subsection follows the same structural pattern as `### Ambiguity Detection Heuristics` — separate subsection referenced from the decision table.
- Trivial tier is restrictive (ALL conditions must match); Complex is permissive (ANY signal triggers). This asymmetry is deliberate — false-trivial is more dangerous than false-complex.
- The Trivial inline apply bypass is artifact-free: no proposal.md, no spec, no design, no tasks, no verify-report. Git history is the only traceability.
- Moderate tier has no keyword list — it is the residual class when neither Trivial nor Complex signals match.
- The scope estimation step runs AFTER intent classification (Change Request confirmed) and BEFORE routing action selection.
- Signal keyword lists must not exceed 15 entries each per the delta spec.

## Blockers

None.
