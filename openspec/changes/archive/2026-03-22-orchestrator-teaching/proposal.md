# Proposal: 2026-03-21-orchestrator-teaching

Date: 2026-03-21
Status: Draft

## Intent

Add a teaching personality layer to the orchestrator so that users build mental models of SDD discipline rather than blindly following commands.

## Motivation

The orchestrator currently communicates decisions imperatively ("I recommend `/sdd-ff`", "MUST NOT write code inline") without explaining *why* the discipline exists. Sub-agent errors are relayed verbatim. Post-cycle summaries are mechanical file lists. This makes the system powerful but opaque — users follow rules without understanding what risks they mitigate. Teaching the "why" builds trust, reduces repeat mistakes, and accelerates onboarding for new users.

## Supersedes

None — this is a purely additive change. No existing behavior is removed or replaced. Teaching content is layered on top of existing orchestrator routing and SDD phase outputs.

## Scope

### Included

1. New `## Teaching Principles` section in CLAUDE.md with 5 concrete, concise teaching rules
2. Why-framing on every Change Request classification (one sentence explaining what risk the SDD cycle prevents)
3. Educational gate prompts for confirmation gates (Rule 7 removal confirmation, contradiction gate) that state the consequence being avoided
4. Error reformulation pattern in sdd-ff for `blocked`/`failed` sub-agent statuses — reframe as a learning message
5. Post-cycle reflection paragraph in sdd-ff Step 5 summary (narrative paragraph alongside existing file list)
6. New-user detection heuristic: when `ai-context/changelog-ai.md` shows 0 archived changes, prepend brief context note to first SDD-routed responses

### Excluded (explicitly out of scope)

- No changes to intent classification logic or routing rules — teaching is additive annotation, not behavioral change
- No changes to sub-agent execution or artifact formats — teaching applies to orchestrator-level output only
- No interactive tutorial system or multi-step onboarding wizard — teaching is inline, contextual, and concise
- No per-user preference for verbosity level — all users receive the same teaching content (designed to be non-intrusive for experts)

## Proposed Approach

Hybrid approach (Approach C from exploration): teaching principles are defined in CLAUDE.md (always loaded, cross-cutting), while concrete output format changes (post-cycle narrative, error reformulation) are implemented in sdd-ff/SKILL.md (phase-specific). This matches the existing architecture pattern where CLAUDE.md defines behavioral principles and skills implement them.

The 5 teaching principles are:
1. **Why-framing**: Every SDD recommendation includes one sentence (max) explaining the risk it prevents
2. **Educational gates**: Confirmation prompts include the consequence being avoided, not just the action required
3. **Error reformulation**: Blocked/failed statuses are reframed as "This happened because X. To avoid it, Y."
4. **Post-cycle reflection**: sdd-ff Step 5 adds a narrative paragraph (1 paragraph max) summarizing what the cycle produced and what it protects
5. **Progressive disclosure**: New-user detection (0 archived changes in changelog-ai.md) triggers a brief context note on first SDD-routed responses

All teaching content is constrained to be concise (1 sentence for why-framing, 1 paragraph for post-cycle reflection) to avoid slowing down expert users.

## Affected Areas

| Area/Module | Type of Change | Impact |
| ----------- | -------------- | ------ |
| `CLAUDE.md` | Modified — new `## Teaching Principles` section; why-framing in Change Request classification template | High |
| `skills/sdd-ff/SKILL.md` | Modified — post-cycle narrative in Step 5; error reformulation in blocked/failed handling | Medium |
| `openspec/specs/orchestrator-behavior/spec.md` | Modified — new requirements for teaching behavior in classification responses | Medium |

## Risks

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| CLAUDE.md context length increase | Medium | Low | Teaching Principles section capped at ~15 lines total; principles are concise rules, not prose |
| Expert user friction from teaching content | Low | Low | Why-framing constrained to 1 sentence max; post-cycle narrative is 1 paragraph max; no verbose explanations |
| Companion change conflicts (4 other orchestrator changes in-flight) | Low | Medium | This change is purely additive (new section, no deletions); it defines the voice before other changes land |
| New-user detection heuristic false positives | Low | Low | Heuristic uses changelog-ai.md archived-change count; a project with 0 changes is genuinely new; teaching note is brief and non-blocking |

## Rollback Plan

1. Remove the `## Teaching Principles` section from `CLAUDE.md`
2. Revert the why-framing addition in the Change Request classification template in `CLAUDE.md`
3. Revert the post-cycle narrative paragraph addition in `skills/sdd-ff/SKILL.md` Step 5
4. Revert the error reformulation pattern in `skills/sdd-ff/SKILL.md` blocked/failed handling
5. Revert spec additions in `openspec/specs/orchestrator-behavior/spec.md`
6. Run `bash install.sh` to deploy reverted files
7. All changes are in 3 files; rollback is a simple git revert of the apply commit

## Dependencies

- None — this change is self-contained and purely additive
- Exploration confirmed no contradictions with existing orchestrator behavior
- The pre-seeded proposal at `openspec/changes/2026-03-21-orchestrator-teaching-personality/proposal.md` provides the original user intent and success criteria

## Success Criteria

- [ ] CLAUDE.md contains a `## Teaching Principles` section with exactly 5 concise teaching rules
- [ ] Change Request classification response includes a "why" sentence explaining the risk the SDD cycle prevents
- [ ] sdd-ff Step 5 post-cycle summary includes a narrative paragraph (not just a file list)
- [ ] sdd-ff blocked/failed sub-agent status triggers a reformulated learning message (cause + prevention)
- [ ] New-user detection heuristic is defined: 0 archived changes in changelog-ai.md triggers a brief SDD context note
- [ ] Teaching content does not exceed 1 sentence for why-framing and 1 paragraph for post-cycle reflection
- [ ] No changes to intent classification routing logic or sub-agent execution behavior

## Effort Estimate

Low (hours) — 3 files modified with additive text content; no architectural changes.

## Context

Recorded from conversation at 2026-03-21:

### Explicit Intents

- **Teaching personality**: User explicitly requested adding why-framing, educational gates, error reformulation, post-cycle reflection, and progressive disclosure to the orchestrator
- **Cycle ordering**: This is declared as "Cycle 1 of 5" — teaching tone must land first because it defines the voice used in all subsequent orchestrator changes

### Platform Constraints

- **Conciseness constraint**: Why-framing must be 1 sentence max; post-cycle narrative must be 1 paragraph max
- **No behavioral change**: Do NOT change intent classification logic or routing rules

### Provisional Notes

- **New-user detection source**: The proposal references `ai-context/changelog-ai.md` for archived-change count; exploration notes that `openspec/changes/archive/` directory listing may be a better source of truth. Design phase should evaluate both options.
- **Error reformulation scope**: Proposal targets sdd-ff only (the orchestrator that surfaces errors to users); expanding to other phase skills is out of scope for this change.
