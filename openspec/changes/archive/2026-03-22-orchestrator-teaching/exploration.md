# Exploration: Orchestrator Teaching Personality Mode

## Handoff Context

- **Decision**: The orchestrator communicates decisions imperatively but never explains why they exist. Users follow SDD commands without building mental models.
- **Goal**: Add a `## Teaching Principles` section to CLAUDE.md defining 5 concrete teaching behaviors (why-framing, educational gates, error reformulation, post-cycle reflection, progressive disclosure).
- **Targets**: `CLAUDE.md`, `skills/sdd-ff/SKILL.md`, `openspec/specs/orchestrator-behavior/spec.md`
- **Constraints**: Do NOT change intent classification logic or routing rules. Teaching content must be concise (1 sentence max for "why" framing). Must not slow down expert users.

## Current State

### CLAUDE.md — Orchestrator behavior

The orchestrator currently has:
- **Intent classification table** with four classes (Meta-Command, Change Request, Exploration, Question) — pure routing logic, no explanatory content.
- **Unbreakable Rules** (7 rules) — stated as imperatives with no rationale attached.
- **Classification Decision Table** — deterministic routing, no "why" annotations.
- No `## Teaching Principles` section exists.
- No mechanism for new-user detection or progressive disclosure.

### sdd-ff/SKILL.md — Post-cycle summary (Step 4)

Step 4 presents a structured summary:
```
Phase results:
  explore  : [status] — [one-line summary]
  ...
Artifacts created:
  [file list]
Ready to implement? Run: /sdd-apply [slug]
```

This is purely mechanical — a file list and status codes. No narrative explaining what the cycle produced or what risks it mitigates.

### Error handling in sdd-ff

When a sub-agent returns `blocked` or `failed`, sdd-ff says: "stop and report to user." No reformulation into a learning message. Warnings are "surfaced" but with no educational framing.

### Confirmation gates

- **Contradiction gate** (Step 0): Presents UNCERTAIN contradictions with Yes/No/Review options. No explanation of why contradictions matter.
- **Rule 7** (removal confirmation): Confirms removal intent. No educational framing about why removal is risky.

### New-user detection

`ai-context/changelog-ai.md` exists and could serve as a signal for new users (0 archived changes = new project). No current mechanism uses this.

## Branch Diff

Files modified in current branch relevant to this change:
- CLAUDE.md (modified)
- skills/sdd-ff/SKILL.md (modified)
- openspec/specs/sdd-orchestration/spec.md (modified)
- openspec/specs/orchestrator-behavior/spec.md (not in diff — but is a target)
- openspec/changes/2026-03-21-orchestrator-teaching-personality/proposal.md (untracked)

Note: Multiple companion orchestrator changes are also in-flight (mandatory-new-session, scope-estimation, natural-language, action-control-gates). This change is declared as "Cycle 1 of 5" — it defines the teaching voice before the others are implemented.

## Prior Attempts

Prior archived changes related to this topic:
- 2026-03-14-orchestrator-visibility: COMPLETED — added session banner, intent classification signals, and `/orchestrator-status` skill. Related but focused on visibility, not teaching.
- 2026-03-12-orchestrator-always-on: COMPLETED — added intent classification. Established the routing behavior this change aims to annotate with "why" explanations.
- 2026-03-14-orchestrator-classification-edge-cases: COMPLETED — edge case handling for classification.

No prior attempts at a teaching personality specifically.

## Contradiction Analysis

No contradictions detected.

The proposal explicitly states "Do NOT change the intent classification logic or routing rules" — this is purely additive content layered on top of existing behavior. No existing spec requirement is challenged.

## Affected Areas

| File/Module | Impact | Notes |
| ----------- | ------ | ----- |
| `CLAUDE.md` | HIGH | New `## Teaching Principles` section; modifications to intent classification response templates to include "why" sentence |
| `skills/sdd-ff/SKILL.md` | MEDIUM | Step 4 post-cycle summary enhanced with narrative paragraph |
| `openspec/specs/orchestrator-behavior/spec.md` | MEDIUM | New requirements for teaching behavior in classification responses |
| `skills/sdd-ff/SKILL.md` (error handling) | LOW | Error reformulation pattern added to blocked/failed reporting |

## Analyzed Approaches

### Approach A: Inline teaching in CLAUDE.md only

**Description**: Add `## Teaching Principles` section to CLAUDE.md with 5 rules. Modify the Classification Decision Table response templates to include a "why" sentence. Modify the sdd-ff Step 4 summary format. All changes are inline text in existing files.

**Pros**: Minimal file count. Teaching principles are loaded at session start (always available). No new skills or architectural layers.
**Cons**: CLAUDE.md is already very long. Adding more inline content increases context consumption.
**Estimated effort**: Low
**Risk**: Low

### Approach B: Separate teaching skill

**Description**: Create a `skills/orchestrator-teaching/SKILL.md` that defines teaching behaviors and is loaded by the orchestrator on demand.

**Pros**: Keeps CLAUDE.md lean. Teaching behavior is modular and can be disabled per-project.
**Cons**: Adds a new skill that must be loaded at session start for every session — overhead. Teaching must be always-on, not on-demand. Creates indirection for something that should be embedded in orchestrator behavior.
**Estimated effort**: Medium
**Risk**: Medium — teaching may not fire if skill is not loaded

### Approach C: Hybrid — principles in CLAUDE.md, templates in sdd-ff

**Description**: Place the 5 teaching principles as concise rules in CLAUDE.md. Implement the specific output format changes (post-cycle narrative, error reformulation) directly in sdd-ff/SKILL.md.

**Pros**: Principles are always loaded (CLAUDE.md). Implementation details are in the skill that uses them (sdd-ff). Clean separation of "what" vs "how".
**Cons**: Slightly more files modified than Approach A, but each change is smaller and scoped.
**Estimated effort**: Low
**Risk**: Low

## Recommendation

**Approach C (Hybrid)** is recommended. It matches the existing architecture pattern: CLAUDE.md defines behavioral principles, skills implement them. The teaching principles section belongs in CLAUDE.md (always loaded, cross-cutting). The concrete output format changes (post-cycle narrative, error reformulation) belong in sdd-ff/SKILL.md (phase-specific).

## Identified Risks

- **CLAUDE.md length**: Adding a new section increases context consumption. Mitigation: keep teaching principles to 5 concise rules (no more than 15 lines total).
- **Expert user friction**: Teaching content could slow down experienced users. Mitigation: the proposal already constrains "why" sentences to 1 sentence max. Post-cycle narrative is 1 paragraph max.
- **Companion change conflicts**: 4 other orchestrator changes are in-flight. Mitigation: this change is purely additive (new section, no deletions). It defines the voice, so it should land first as proposed.

## Open Questions

- Should the new-user detection heuristic (success criterion 5) use `ai-context/changelog-ai.md` archived-change count, or `openspec/changes/archive/` directory listing? The proposal mentions changelog-ai.md but the archive directory is the actual source of truth.
- Should error reformulation apply to all SDD phase skills or just sdd-ff? The proposal targets sdd-ff only, which seems appropriate since sdd-ff is the orchestrator that surfaces errors to users.

## Ready for Proposal

Yes — the change is well-defined, purely additive, and has a pre-seeded proposal with clear success criteria. The recommended approach (Hybrid) aligns with existing architecture patterns.
