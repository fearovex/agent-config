# Proposal: orchestrator-natural-language

Date: 2026-03-22
Status: Draft

## Intent

Define how the orchestrator communicates — tone, voice, and phrasing — so responses feel like a knowledgeable colleague rather than a state machine reading its own spec aloud.

## Motivation

CLAUDE.md is written as a machine specification: IF/ELSE trees, regex patterns, ✓/✗ tables. The orchestrator's responses inherit this mechanical tone — procedural, administrative, and impersonal. Users interact with a powerful reasoning system that sounds like it is narrating its own control flow. The Teaching Principles (Cycle 1) defined *what* information to include in responses; this change defines *how* to deliver it. Without a persona layer, even well-intentioned educational content lands as robotic checklists.

## Supersedes

None — this is a purely additive change.

## Scope

### Included

- New `## Communication Persona` section in CLAUDE.md with tone profile, per-intent-class response templates, forbidden mechanical phrases, and adaptive formality rule
- Rewritten Session Banner in natural, welcoming tone (replacing the current spec-like blockquote)
- New communication requirements in `openspec/specs/orchestrator-behavior/spec.md`

### Excluded (explicitly out of scope)

- Routing logic changes — the Classification Decision Table, intent detection heuristics, and scope estimation are untouched
- Removal of the `**Intent classification: X**` signal — it remains as a transparency marker
- Changes to sub-agent prompts or delegation patterns — this change affects orchestrator-to-user communication only
- Tone guidelines for sub-agent outputs (sdd-explore, sdd-propose, etc.) — future work if needed

## Proposed Approach

Add a standalone `## Communication Persona` section between Teaching Principles and Plan Mode Rules. This section will contain:

1. **Tone profile** — warm, direct, confident, pedagogical. Never robotic or bureaucratic.
2. **Per-intent-class response templates** — natural prose examples for Change Request, Exploration, Question, and Ambiguous responses. These are phrasing guides, not rigid scripts.
3. **Forbidden mechanical phrases** — a short list (5-10 items) of phrases the orchestrator must never use in user-facing responses (e.g., "Rule 7 confirmation required", "Routing to sdd-ff", "Pre-flight check triggered").
4. **Reformulation rules** — how to rephrase mechanical actions as natural communication (e.g., "Apply Rule 7" becomes "Before I recommend the command, I want to confirm...").
5. **Adaptive formality** — match the user's register: casual input gets casual response, formal input gets formal response.
6. **Session Banner rewrite** — replace the current spec-style blockquote with a warm, concise greeting that still communicates the orchestrator's capabilities.

The persona layer wraps existing behavior — it does not modify what the orchestrator does, only how it describes what it is doing.

## Affected Areas

| Area/Module | Type of Change | Impact |
| ----------- | -------------- | ------ |
| CLAUDE.md — Communication Persona section | New | Medium |
| CLAUDE.md — Session Banner | Modified | Low |
| openspec/specs/orchestrator-behavior/spec.md | Modified | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| Token budget increase from ~40-60 new lines in CLAUDE.md | Medium | Low | Keep persona section concise — rules not essays |
| Instruction conflict between persona templates and Decision Table examples | Low | Medium | Persona templates reference the Decision Table, never duplicate its routing examples |
| Enforcement drift — soft tone rules harder to audit than hard routing rules | Medium | Low | Define a concrete forbidden-phrases list that could be mechanically checked |

## Rollback Plan

1. Remove the `## Communication Persona` section from CLAUDE.md
2. Restore the original Session Banner blockquote (available in git history)
3. Remove new communication requirements from `openspec/specs/orchestrator-behavior/spec.md`
4. Run `install.sh` to deploy the reverted CLAUDE.md

## Dependencies

- Cycle 1 (2026-03-22-orchestrator-teaching) must be completed — the Communication Persona builds on Teaching Principles as the "how" companion to the "what" layer. **Status: COMPLETED.**
- Cycle 2 (2026-03-21-orchestrator-scope-estimation) should be completed — scope estimation tier names may appear in response templates. **Status: in progress but non-blocking.**

## Success Criteria

- [ ] `## Communication Persona` section exists in CLAUDE.md between Teaching Principles and Plan Mode Rules
- [ ] Tone profile defined with at least 4 adjectives and their contrasts
- [ ] Response templates provided for all 4 intent classes (Change Request, Exploration, Question, Ambiguous)
- [ ] Forbidden mechanical phrases list contains at least 5 items with natural alternatives
- [ ] Adaptive formality rule defined as a concrete instruction (not a vague guideline)
- [ ] Session Banner rewritten to be welcoming while preserving all functional information
- [ ] New spec requirements added to `openspec/specs/orchestrator-behavior/spec.md` covering tone, forbidden phrases, and adaptive formality
- [ ] No routing logic modified — Classification Decision Table unchanged

## Effort Estimate

Low (hours) — purely additive prose content in two files, no structural changes.
