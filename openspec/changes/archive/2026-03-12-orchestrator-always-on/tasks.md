# Task Plan: orchestrator-always-on

Date: 2026-03-12
Design: openspec/changes/2026-03-12-orchestrator-always-on/design.md

## Progress: 9/10 tasks

## Phase 1: Preparation

- [x] 1.1 Determine the next available ADR number by reviewing `docs/adr/README.md` and any existing ADR files in `docs/adr/` ✓
- [x] 1.2 Review `docs/templates/adr-template.md` to understand the Nygard format (Status, Context, Decision, Consequences) ✓

## Phase 2: CLAUDE.md Modifications

- [x] 2.1 Modify `CLAUDE.md` — add new section `## Always-On Orchestrator — Intent Classification` immediately after `## Identity and Purpose` section ✓
  - Includes: Intent classes table (Change Request, Exploration, Question, Meta-Command)
  - Includes: Keyword-based classification rules with examples for each class
  - Includes: Routing actions for each intent (recommend SDD command vs. answer directly vs. execute slash command)
  - Includes: "Never write implementation code inline" rule statement
  - Includes: Note that project-local CLAUDE.md can override/disable the behavior

- [x] 2.2 Modify `CLAUDE.md` — update the `## How I Execute Commands` section to reference intent classification as Step 0 ✓
  - Add note: "Before executing any command, the orchestrator classifies user intent (see Always-On Orchestrator section above)"

## Phase 3: ADR Creation

- [x] 3.1 Create `docs/adr/029-orchestrator-always-on-intent-classification.md` ✓
  - Status: Accepted
  - Context: Explains the problem (SDD is opt-in, free-form requests bypass SDD discipline)
  - Decision: Always-on intent classification via keyword-matching heuristics in CLAUDE.md
  - Consequences: Orchestrator becomes context-aware; users see SDD recommendations proactively; keyword-based classification may need tuning based on feedback
  - Alternatives: Reactive post-response check (rejected); guided hybrid (deferred); ML-based classification (out of scope)

## Phase 4: Documentation Updates

- [x] 4.1 Modify `docs/adr/README.md` — updated ADR-029 status to Accepted ✓

## Phase 5: Validation and Completion

- [ ] 5.1 Run `/project-audit` to verify no new audit findings are introduced and score is >= previous baseline
- [x] 5.2 Review the modified CLAUDE.md section to confirm all intent classes are documented with clear examples ✓
- [x] 5.3 Verify the new ADR follows Nygard format and is findable via `docs/adr/README.md` index ✓

---

## Implementation Notes

- Intent classification uses **keyword-based heuristics only** — no LLM classification, no function-calling schemas
- Keywords are case-insensitive and checked via simple substring/token matching
- The four intent classes have clear priority: Meta-Command > Change Request > Exploration > Question (checked in that order)
- Change Requests trigger a **recommendation** (non-blocking) of `/sdd-ff` or `/sdd-new`; Explorations can auto-launch `sdd-explore` via Task tool
- The Always-On section should be placed early in CLAUDE.md (right after "Identity and Purpose") so it is the first behavioral instruction read
- Classification rules in CLAUDE.md should include at least 2–3 examples per intent class showing both positive matches and negative cases (ambiguities)

## Blockers

None.
