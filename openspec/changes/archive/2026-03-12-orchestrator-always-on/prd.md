---
title: Always-On Orchestrator with Intent Classification
status: Draft
author: Claude Code
date: 2026-03-12
related-change: openspec/changes/2026-03-12-orchestrator-always-on/
---

# PRD: Always-On Orchestrator with Intent Classification

## Problem Statement

The SDD system is currently opt-in: users must remember and type explicit slash commands (`/sdd-ff`, `/project-audit`, etc.) to trigger structured development workflows. Free-form requests ("add a feature", "fix this bug", "improve this") are handled as direct responses without SDD discipline, consistency, or specification-driven oversight. This means changes bypass the specification phase and skill catalog, violating the core SDD principle that all code changes should be specification-driven.

## Target Users

- **Primary**: Developers and teams using Claude Code to manage complex projects with SDD discipline. They benefit from proactive guidance to the appropriate SDD phase.
- **Secondary**: New users learning the SDD system. Always-on classification serves as a teaching mechanism, showing which SDD commands apply to their natural-language requests.

## User Stories

### Must Have

- As a developer, I want Claude to recognize when I'm making a change request and recommend the appropriate SDD phase, so that I don't have to remember the exact slash command.
- As a developer, I want Claude to never write implementation code inline for change requests, so that all changes follow the SDD specification phase first.
- As a developer, I want to ask questions and get direct answers without being routed to an SDD phase, so that simple explanations don't trigger unnecessary bureaucracy.
- As a new user, I want Claude to show me which SDD command applies to my request, so that I learn the SDD discipline progressively.

### Should Have

- As a developer, I want to see clear classification rules in CLAUDE.md so that I understand when Claude will recommend an SDD phase.
- As a project lead, I want to override classification rules in my project's CLAUDE.md, so that the always-on behavior can be customized per project.
- As an architect, I want an ADR documenting this decision so that future collaborators understand the rationale and trade-offs.

### Could Have

- As a developer, I want Claude to auto-execute `/sdd-ff` for certain common change patterns, so that trivial changes are fast-tracked.
- As a developer, I want classification to use NLP or semantic analysis for better accuracy, so that edge cases are handled more gracefully.

### Won't Have

- As a developer, I want automatic code generation or `/sdd-apply` execution, so that I always review the specification before implementation. — OUT OF SCOPE: intentionally deferred to maintain human oversight.
- As a user, I want classification to be ML-based or context-aware across sessions, so that the behavior is predictable and auditable. — OUT OF SCOPE: keyword-based heuristics are sufficient for v1.

## Non-Functional Requirements

- Intent classification must be deterministic and keyword-based (no ML or randomization)
- Classification rules must be documented and visible in CLAUDE.md (auditable, not a black box)
- The always-on behavior must not break existing slash commands or project-specific CLAUDE.md overrides
- No new external dependencies introduced; implementation uses only Markdown documentation
- All changes must be reversible (rollback plan documented in proposal.md)
- Classification must complete in < 100 ms (negligible overhead)

## Acceptance Criteria

- [ ] CLAUDE.md contains an "Always-On Orchestrator — Intent Classification" section with 4 intent classes
- [ ] Intent classification rules are documented with clear keyword heuristics and examples
- [ ] Classification rules cover Change Requests, Explorations, Questions, and Meta-Commands
- [ ] An ADR (030 or next available) documents the architectural decision with Context, Decision, and Consequences
- [ ] `docs/adr/README.md` is updated with the new ADR entry
- [ ] The "How I Execute Commands" section mentions intent classification as Step 0
- [ ] `/project-audit` score is >= previous score after implementation and archive
- [ ] Rollback plan is concrete and tested (can restore from git history in < 5 minutes)

## Notes

- This PRD feeds into the SDD proposal at `openspec/changes/2026-03-12-orchestrator-always-on/proposal.md`
- The exploration phase (see exploration.md) evaluated three approaches and recommends Approach A (Always-Classify)
- Classification is intentionally simple (keyword-based) to remain deterministic and auditable
- Rules can be iterated and refined based on real-world usage feedback
