# Exploration: Orchestrator Natural Language Communication

## Handoff Context

- **Decision trigger**: User feedback that the orchestrator sounds like a state machine — mechanical, procedural, impersonal.
- **Goal**: Add a `## Communication Persona` section to CLAUDE.md that defines tone, natural response templates per intent class, forbidden mechanical phrases, adaptive formality, and a rewritten session banner.
- **Success criteria**: Persona section added, response templates for all 4 intent classes, forbidden-phrases list, adaptive formality rule, natural session banner.
- **Explore targets**: `CLAUDE.md` (orchestrator sections), `openspec/specs/orchestrator-behavior/spec.md`.
- **Constraints**: Preserve `**Intent classification: X**` signal. Do NOT remove the Classification Decision Table. Communication changes must not affect routing logic.
- **Execution order**: Cycle 3 of 5 — runs after scope estimation (Cycle 2), uses teaching tone from Cycle 1.

## Current State

### CLAUDE.md — Orchestrator Communication Surface

The orchestrator's communication is currently defined across several sections in CLAUDE.md:

1. **Identity and Purpose** (lines 1–8): Two sentences — "expert development assistant" with two roles. Purely functional, no personality.

2. **Session Banner** (lines 18–26): Formatted as a blockquote with bullet points. Uses technical language: "classifies your intent", "scope-estimated into Trivial/Moderate/Complex tiers", "launches `sdd-explore` via Task". Informative but reads like a spec, not a greeting.

3. **Response Signal** (lines 30–48): Defines `**Intent classification: X**` format. The signal itself is a technical marker — the proposal explicitly preserves this.

4. **Classification Decision Table** (lines 91–200+): Pure IF/ELSE pseudocode with ✓/✗ example tables. This is the routing spec — the proposal explicitly preserves this.

5. **Teaching Principles** (lines 383–407): Recently added (Cycle 1 — `2026-03-22-orchestrator-teaching`). Defines why-framing, educational gates, error reformulation, post-cycle reflection, and progressive disclosure. These are behavioral annotations but do NOT define tone or voice.

6. **Unbreakable Rules** (lines ~310–382): Rule 7 uses mechanical phrasing ("Apply Rule 7: acknowledge removal/replacement intent"). The proposal wants to wrap these with natural language.

### Key Observation

There is currently **no section** in CLAUDE.md that defines:
- How the orchestrator should sound (tone, voice, register)
- What phrases to avoid (mechanical/robotic language)
- How to adapt formality to the user's style
- Natural-language templates for each intent class response

The Teaching Principles (Cycle 1) define *what* to communicate (risk sentences, consequence explanations) but not *how* to communicate it. The Communication Persona is the complementary "how" layer.

### orchestrator-behavior spec

The master spec at `openspec/specs/orchestrator-behavior/spec.md` defines intent classification requirements, routing rules, visibility signals, clarification gate, scope estimation, and teaching principles. One existing requirement (line 460) mentions "natural language" for the clarification prompt. No broader communication/tone requirements exist.

## Branch Diff

Files modified in current branch relevant to this change:
- CLAUDE.md (modified) — already contains Cycle 1 (teaching) and Cycle 2 (scope estimation) changes
- openspec/specs/orchestrator-behavior/spec.md (modified) — already extended with teaching and scope estimation requirements

## Prior Attempts

Prior archived changes related to this topic:
- 2026-03-22-orchestrator-teaching: COMPLETED (verify-report present) — added Teaching Principles section (behavioral annotations). This is the "what to communicate" companion; the current change adds the "how to communicate" layer.
- 2026-03-14-orchestrator-visibility: COMPLETED (verify-report present) — added session banner, response signals, `/orchestrator-status`. Established the visibility framework that this change will soften in tone.
- 2026-03-12-orchestrator-always-on: COMPLETED (verify-report present) — established intent classification. Created the mechanical Classification Decision Table that this change wraps with natural prose.

## Contradiction Analysis

No contradictions detected.

The proposal explicitly preserves:
- The `**Intent classification: X**` signal (transparency mechanism)
- The Classification Decision Table (routing spec)
- All routing logic (unchanged)

The persona layer is purely additive — it defines how the orchestrator phrases its responses around the existing classification and routing machinery, without modifying the machinery itself.

## Affected Areas

| File/Module | Impact | Notes |
| ----------- | ------ | ----- |
| `CLAUDE.md` | Medium | New `## Communication Persona` section; Session Banner rewrite; no routing logic changes |
| `openspec/specs/orchestrator-behavior/spec.md` | Low | New communication requirements (tone, forbidden phrases, adaptive formality) |

## Analyzed Approaches

### Approach A: Standalone Communication Persona section

**Description**: Add a new `## Communication Persona` section between Teaching Principles and Plan Mode Rules. Contains: tone profile, per-intent-class response templates (prose, not tables), forbidden mechanical phrases list, adaptive formality rule. Rewrite the Session Banner in-place to be warmer. Leave all other sections untouched.

**Pros**:
- Clean separation — persona is its own section, easy to find and modify
- Teaching Principles (what to say) and Communication Persona (how to say it) are adjacent but distinct
- Session Banner rewrite is localized — one blockquote to change
- No risk to routing logic

**Cons**:
- Adds ~40-60 lines to CLAUDE.md
- Orchestrator must mentally compose Teaching Principles + Communication Persona at response time

**Estimated effort**: Low
**Risk**: Low

### Approach B: Merge persona rules into existing sections

**Description**: Instead of a standalone section, embed tone directives into the Identity and Purpose section, embed response templates into the Intent Classes and Routing table footnotes, embed forbidden phrases into Unbreakable Rules.

**Pros**:
- No new section — keeps CLAUDE.md section count stable
- Tone rules are co-located with the behavior they modify

**Cons**:
- Scatters communication rules across multiple sections — hard to maintain
- Mixes structural concerns (routing) with presentational concerns (tone)
- Higher risk of accidentally modifying routing logic while editing tone

**Estimated effort**: Medium
**Risk**: Medium

## Recommendation

**Approach A — Standalone Communication Persona section.** Clean separation keeps the routing spec untouched and makes the persona layer easy to audit, modify, or disable. Adjacent placement to Teaching Principles creates a natural reading order: Teaching Principles defines *what* information to include, Communication Persona defines *how* to deliver it.

Placement: between `## Teaching Principles` and `## Plan Mode Rules` (after line ~409).

## Identified Risks

- **Token budget**: Adding ~40-60 lines to an already large CLAUDE.md. Mitigation: keep the persona section concise — rules, not essays.
- **Instruction conflict**: If persona templates contradict the Classification Decision Table examples, the orchestrator may produce inconsistent responses. Mitigation: persona templates should reference the Decision Table, not duplicate its examples.
- **Enforcement drift**: Soft tone rules are harder to audit than hard routing rules. Mitigation: define a short forbidden-phrases list that `/project-audit` could theoretically check.

## Open Questions

- Should the forbidden-phrases list be exhaustive or representative (top 5-10 examples)?
- Should adaptive formality be a hard rule or a soft guideline?

## Ready for Proposal

Yes — the change is well-scoped, purely additive, and the prior cycles (teaching, scope estimation) provide the foundation. The proposal.md already exists with clear success criteria.
