# Closure: 2026-03-22-slim-orchestrator-context

Start date: 2026-03-22
Close date: 2026-03-22

## Summary

Reduced the always-loaded orchestrator context from ~88k characters to ~20k by extracting presentation-layer content (session banner, teaching principles, communication persona) into a dedicated `skills/orchestrator-persona/SKILL.md` skill, condensing the Skills Registry and Commands sections, eliminating global/project CLAUDE.md duplication, and establishing budget governance (ADR-041).

## Modified Specs

| Domain | Action | Change |
| ------ | ------ | ------ |
| orchestrator-behavior | Modified | Added inline-vs-skill boundary requirements, persona skill loading scenario, budget governance requirements |
| project-audit-core | Modified | Added Dimension 14 — Budget Compliance (INFO severity) |
| skills-catalog-format | Modified | Updated compact path-only registry format requirements |

## Modified Code Files

- `CLAUDE.md` — refactored to ~19,863 chars; removed Teaching Principles, Communication Persona, Session Banner, Fast-Forward, Apply Strategy, Phase DAG, How I Execute Commands sections; added persona loading instruction and budget governance comment block; condensed Skills Registry and Commands sections
- `skills/orchestrator-persona/SKILL.md` — new skill (6,857 chars) containing session banner, teaching principles (5), and communication persona
- `skills/project-audit/SKILL.md` — added Dimension 14 (Budget Compliance, INFO severity)
- `docs/adr/041-slim-orchestrator-context.md` — new ADR documenting inline-vs-skill boundary and budget governance
- `docs/adr/README.md` — added ADR-041 row
- `ai-context/architecture.md` — added decision 29 for slim orchestrator context
- `ai-context/conventions.md` — documented inline-vs-skill boundary (line 102)
- `openspec/specs/orchestrator-behavior/spec.md` — merged delta specs (persona loading, inline-vs-skill boundary, budget governance requirements)

## Key Decisions Made

- **Inline-vs-skill boundary**: Classification-critical content (Decision Table, Scope Estimation, Ambiguity Heuristics) stays inline in CLAUDE.md. Presentation-layer content (session banner, communication persona, teaching principles) moves to `skills/orchestrator-persona/SKILL.md`, loaded on first free-form response per session.
- **Budget governance** (ADR-041): Global CLAUDE.md capped at 20,000 chars; project CLAUDE.md at 5,000 chars; new orchestrator skills at 8,000 chars.
- **Project CLAUDE.md slim**: Project-local CLAUDE.md should contain only project-specific overrides (tech stack, project memory pointers, deviations) — not a full duplicate of the global config.

## Lessons Learned

All 22 tasks completed with PASS verification. The budget governance comment block approach (embedded in CLAUDE.md as a comment) provides persistent visibility without consuming significant context budget. The condensed Skills Registry (path-only, no inline descriptions) and pipe-delimited Commands section achieved significant character reduction while preserving navigability.

## User Docs Reviewed

N/A — pre-dates this requirement (checkbox absent from verify-report).
