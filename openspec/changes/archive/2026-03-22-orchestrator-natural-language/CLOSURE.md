# Closure: orchestrator-natural-language

Start date: 2026-03-22
Close date: 2026-03-22

## Summary

Added a Communication Persona presentation layer to CLAUDE.md that defines the orchestrator's tone (warm, direct, confident, pedagogical), per-intent-class response voice templates, a 9-item forbidden mechanical phrases deny-list, and an adaptive formality mirror-register rule. Rewrote the session banner from spec-style administrative format to a welcoming, natural tone.

## Modified Specs

| Domain               | Action   | Change                                                                                     |
| -------------------- | -------- | ------------------------------------------------------------------------------------------ |
| orchestrator-behavior | Added    | Communication Persona section requirement (tone, forbidden phrases, adaptive formality)     |
| orchestrator-behavior | Added    | Orchestrator tone requirement (warm, direct, confident)                                     |
| orchestrator-behavior | Added    | Forbidden mechanical phrases requirement (9-item deny-list)                                 |
| orchestrator-behavior | Added    | Intent classification signal preservation requirement                                       |
| orchestrator-behavior | Added    | Adaptive formality mirror-register requirement                                              |
| orchestrator-behavior | Modified | Session-start orchestrator banner (rewritten in natural, welcoming tone)                    |
| orchestrator-behavior | Added    | Communication persona rules block (presentation-only, no routing changes)                   |

## Modified Code Files

- `CLAUDE.md` — Added `## Communication Persona` section (Tone Profile, Response Voice by Intent Class, Forbidden Mechanical Phrases, Adaptive Formality subsections); rewrote `### Orchestrator Session Banner` blockquote
- `openspec/specs/orchestrator-behavior/spec.md` — Merged 6 new requirements + rules block; marked original banner requirement as superseded; added 6 validation criteria
- `ai-context/architecture.md` — Added entry #28 documenting the Communication Persona presentation layer decision

## Key Decisions Made

- Communication Persona is a **presentation layer only** — it does not alter routing logic, classification keywords, or the phase DAG
- The `**Intent classification: X**` signal format is preserved unchanged — persona rules shape prose after the signal, never the signal itself
- Forbidden phrases apply to orchestrator responses only — sub-agent responses are unconstrained
- Adaptive formality uses a mirror-register heuristic (casual/formal/neutral-warm default) rather than a fixed tone
- Response voice templates are prose examples (not rigid scripts or tables)
- Session banner is an in-place replacement (one banner replaces the old one, no duplication)

## Lessons Learned

- This change is the "how" companion to the Teaching Principles "what" layer — together they define both the content and delivery of orchestrator responses
- The additive-only approach (no routing changes) made verification straightforward — all scenarios could be checked by structural inspection without behavioral testing

## User Docs Reviewed

NO — change does not affect user-facing workflows (scenarios.md, quick-reference.md, onboarding.md). The Communication Persona is an internal behavioral instruction for the orchestrator, not a user-facing feature change.
