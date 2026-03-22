# Task Plan: 2026-03-21-orchestrator-natural-language

Date: 2026-03-22
Design: openspec/changes/2026-03-21-orchestrator-natural-language/design.md

## Progress: 7/7 tasks

## Phase 1: Communication Persona Section in CLAUDE.md

- [x] 1.1 Add `## Communication Persona` section to `CLAUDE.md` after the `## Teaching Principles` section and before `## Plan Mode Rules`, containing the subsection heading `### Tone Profile` with at least 4 tone adjectives (warm, direct, confident, pedagogical) and their contrasts (not robotic, not bureaucratic, not mechanical, not impersonal)
  Files: `CLAUDE.md` (MODIFY)
  Acceptance: Section `## Communication Persona` exists; `### Tone Profile` subsection contains >= 4 adjective-contrast pairs; section is positioned between Teaching Principles and Plan Mode Rules

- [x] 1.2 Add `### Response Voice by Intent Class` subsection inside `## Communication Persona` in `CLAUDE.md` with natural prose response templates for all 4 intent classes: Change Request, Exploration, Question, and Ambiguous
  Files: `CLAUDE.md` (MODIFY)
  Acceptance: Subsection exists with prose examples for all 4 classes; no table format used; examples model the desired natural voice

- [x] 1.3 Add `### Forbidden Mechanical Phrases` subsection inside `## Communication Persona` in `CLAUDE.md` with a deny-list table (Forbidden → Use Instead) containing at least 5 items including "Rule 7 confirmation required", "Routing to sdd-ff", "Pre-flight check triggered", "I classify this as...", "Auto-launching sdd-explore"
  Files: `CLAUDE.md` (MODIFY)
  Acceptance: Subsection exists with >= 5 forbidden phrases; each has a natural alternative; table format with Forbidden and Use Instead columns

- [x] 1.4 Add `### Adaptive Formality` subsection inside `## Communication Persona` in `CLAUDE.md` with a concrete mirror-register rule: casual input receives casual response, formal input receives formal response, unclear register defaults to neutral-warm
  Files: `CLAUDE.md` (MODIFY)
  Acceptance: Subsection exists with concrete instruction (not vague guideline); mentions both casual and formal scenarios; states the neutral-warm default

## Phase 2: Session Banner Rewrite

- [x] 2.1 Replace the existing `### Orchestrator Session Banner` blockquote in `CLAUDE.md` with a warm, welcoming version that introduces the orchestrator as a collaborative partner, describes all 4 intent classes in user-facing language, and preserves the information that the SDD Orchestrator is active
  Files: `CLAUDE.md` (MODIFY)
  Acceptance: Banner is rewritten; no longer uses spec-style "routes requests" or "intent classification is enabled"; still communicates all 4 capabilities (changes, explorations, questions, commands); mentions `/orchestrator-status` optionally

## Phase 3: Master Spec Update

- [x] 3.1 Merge delta spec requirements from `openspec/changes/2026-03-21-orchestrator-natural-language/specs/orchestrator-behavior/spec.md` into the master spec at `openspec/specs/orchestrator-behavior/spec.md` — append all new requirements (Communication Persona section, tone, forbidden phrases, intent signal preservation, adaptive formality, session banner rewrite) and the rules block
  Files: `openspec/specs/orchestrator-behavior/spec.md` (MODIFY)
  Acceptance: All 6 requirements from delta spec are present in master spec; existing requirements are unchanged; rules block appended

## Phase 4: Cleanup

- [x] 4.1 Update `ai-context/architecture.md` — add entry #28 documenting the Communication Persona presentation layer decision (additive, wraps existing classification, no routing changes)
  Files: `ai-context/architecture.md` (MODIFY)
  Acceptance: New numbered entry exists summarizing the architectural decision; references the change name and CLAUDE.md section

---

## Implementation Notes

- The `## Communication Persona` section is a **presentation layer only** — it must not alter any routing logic, classification keywords, or the phase DAG
- The `**Intent classification: X**` signal format must remain exactly as-is — persona rules shape prose after the signal, never the signal itself
- Forbidden phrases apply to orchestrator responses only — sub-agent responses are not constrained
- Response voice examples should be natural prose, not rigid scripts — they model the desired voice
- The session banner replacement is in-place (one banner replaces the old one, no duplication)
- The delta spec at `openspec/changes/2026-03-21-orchestrator-natural-language/specs/orchestrator-behavior/spec.md` is the authoritative source for what gets merged into the master spec

## Blockers

None.
