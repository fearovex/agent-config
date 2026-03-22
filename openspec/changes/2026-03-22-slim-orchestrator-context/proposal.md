# Proposal: 2026-03-22-slim-orchestrator-context

Date: 2026-03-22
Status: Draft

## Intent

Reduce the always-loaded orchestrator context from ~88k characters to ~20k by eliminating project/global CLAUDE.md duplication, extracting separable presentation sections into on-demand skills, removing redundant SDD flow documentation, and establishing budget governance to prevent future growth.

## Motivation

The orchestrator's CLAUDE.md has grown through successive additive changes (classification logic, ambiguity heuristics, scope estimation, teaching principles, communication persona, and redundant SDD flow summaries) to the point where both the global and project copies total ~88k characters of always-loaded context. This consumes a significant portion of the context window before any user interaction begins, leaving less room for codebase analysis, skill content, and conversation history. The project CLAUDE.md is 95% identical to the global version, doubling context waste. Without governance, every future orchestrator improvement will continue expanding the file.

## Supersedes

### REPLACED

| Old | New | Reason |
|-----|-----|--------|
| Project CLAUDE.md (~46k chars, full duplicate of global orchestrator config) | Project CLAUDE.md (~5k chars, override-only: tech stack, project-specific rules, project memory pointers) | Eliminates ~42k chars of duplication; project file retains only project-specific content |
| Inline `## Communication Persona` section (~3.3k chars in CLAUDE.md) | `skills/orchestrator-persona/SKILL.md` (loaded on first orchestrator free-form response) | Separates presentation logic from routing logic; loaded on demand, not at session start |
| Inline `## Teaching Principles` + New-User Detection (~1.6k chars in CLAUDE.md) | Merged into `skills/orchestrator-persona/SKILL.md` | Same rationale: presentation layer, not classification-critical |
| Inline `## Fast-Forward`, `## Apply Strategy`, `## SDD Flow` (~1.8k chars) | Removed entirely (already documented in `sdd-ff/SKILL.md` and `sdd-new/SKILL.md`) | Pure duplication — skill files are authoritative |
| Inline `## How I Execute Commands` delegation pattern (~2.8k chars) | Removed entirely (already documented in `sdd-ff/SKILL.md` and `sdd-new/SKILL.md`) | Pure duplication — skill files are authoritative |
| Verbose `## Skills Registry` (~6k chars with descriptions) | Compact format: path-only entries, no descriptions (~3k chars) | Descriptions are available in skill frontmatter; registry needs only paths |
| Verbose `## Available Commands` (~2.4k chars) | Condensed single-line-per-command format (~1.4k chars) | Reduce without losing discoverability |

### CONTRADICTED

- **ADR #18 / conventions.md: "classification is inline in CLAUDE.md (no new skill)"**: Prior context states classification gate is inline procedural logic requiring no separate skill. This proposal does NOT move classification logic out. Instead, it refines the boundary: classification stays inline (as ADR #18 mandates), but presentation/teaching/flow documentation — which are distinct from classification — move to skills. ADR #18 is refined, not reversed.
  Resolution: ADR supersession — new ADR documenting the refined inline boundary (classification = inline, presentation = skill).

## Scope

### Included

1. **Deduplication**: Restructure project CLAUDE.md to override-only format (~5k chars), retaining only: Tech Stack, Unbreakable Rules (project additions if any), Project Memory pointers, and project-specific Skills Registry entries
2. **Presentation extraction**: Create `skills/orchestrator-persona/SKILL.md` containing Communication Persona, Teaching Principles, New-User Detection, and Session Banner content (~5k chars total)
3. **Redundancy removal**: Delete inline `## Fast-Forward`, `## Apply Strategy`, `## SDD Flow — Phase DAG`, and `## How I Execute Commands` sections from global CLAUDE.md (already in skill files)
4. **Registry condensation**: Reformat `## Skills Registry` to path-only entries (remove one-line descriptions) and condense `## Available Commands` to single-line format
5. **Budget governance**: Define and document three character budgets — global CLAUDE.md (20k chars), project CLAUDE.md (5k chars), new orchestrator skills (8k chars)
6. **Audit enforcement**: Add a budget compliance check to `/project-audit` that warns when CLAUDE.md files or new orchestrator skills exceed their budgets
7. **ADR**: Create ADR documenting the refined inline-vs-skill boundary and the budget governance decision

### Excluded (explicitly out of scope)

- **Extracting classification logic to a skill**: The Classification Decision Table, Scope Estimation Heuristic, and Ambiguity Detection Heuristics MUST remain inline in CLAUDE.md for timing safety. This is a non-negotiable constraint.
- **Retroactive skill budget enforcement**: The 15 existing skills exceeding 8k chars are grandfathered. The budget applies only to newly created orchestrator skills.
- **install.sh build step**: No template assembly or partial-concatenation mechanism. The repo source files remain the deployed form.
- **Pending orchestrator proposals**: `2026-03-21-orchestrator-action-control-gates` and `2026-03-21-orchestrator-mandatory-new-session` are not implemented in this change. They should target the new structure after this refactoring completes.
- **Auto-generated Skills Registry**: The registry remains manually maintained; auto-generation from `skills/` directory is deferred.

## Proposed Approach

The change is executed in three sequential phases:

**Phase 1 — Deduplication (~42k chars saved)**: Reduce the project `CLAUDE.md` to an override-only file containing: a brief project identity header, Tech Stack table, any project-specific Unbreakable Rules additions, Project Memory section pointers, and project-local Skills Registry entries. The global `~/.claude/CLAUDE.md` (source: `CLAUDE.md` in repo root) becomes the single source of truth for all orchestrator logic.

**Phase 2 — Selective extraction (~13.5k chars saved from global CLAUDE.md)**: (a) Create `skills/orchestrator-persona/SKILL.md` and move Communication Persona, Teaching Principles, New-User Detection, and Session Banner into it. The orchestrator loads this skill on its first free-form response in a session. (b) Delete the `## Fast-Forward`, `## Apply Strategy`, `## SDD Flow — Phase DAG`, and `## How I Execute Commands` sections — they are already fully documented in `sdd-ff/SKILL.md` and `sdd-new/SKILL.md`. (c) Condense `## Skills Registry` to path-only format and `## Available Commands` to single-line format.

**Phase 3 — Budget governance**: Add budget constants and a compliance check to `project-audit`. Document the budgets in a new ADR. Update `ai-context/conventions.md` with the new inline-vs-skill boundary rule.

The final global CLAUDE.md should land at approximately 14.5-20k characters: Identity (~300), Intent Classes table (~800), Classification Decision Table (~5.5k), Scope Estimation (~2.5k), Ambiguity Heuristics (~1.8k), Unbreakable Rules 1-7 (~3.8k), Override mechanism (~275), Tech Stack (~433), Architecture (~872), Condensed Commands (~1.4k), Condensed Registry (~3k), Plan Mode (~525), Working Principles (~372), Agent Discovery (~779), SDD Artifact Storage (~704), Project Memory (~2k).

## Affected Areas

| Area/Module | Type of Change | Impact |
| ----------- | -------------- | ------ |
| `CLAUDE.md` (project, repo root) | Modified — reduced to override-only | High |
| `CLAUDE.md` (global, same source file deployed to `~/.claude/`) | Modified — sections removed/condensed | High |
| `skills/orchestrator-persona/SKILL.md` | New — presentation layer skill | Medium |
| `skills/project-audit/SKILL.md` | Modified — add budget compliance check | Medium |
| `ai-context/conventions.md` | Modified — update inline-vs-skill boundary | Low |
| `ai-context/architecture.md` | Modified — record refactoring decision | Low |
| `openspec/specs/orchestrator-behavior/spec.md` | Modified — spec must reflect new architecture | Medium |
| `docs/adr/` | New ADR — refined inline boundary + budget governance | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| Classification timing failure: if any classification logic is accidentally moved to a skill, the orchestrator will not classify intent on the first message | Low | High | Mark all classification sub-sections with "MUST STAY INLINE" comments during refactoring; verify post-apply that Classification Decision Table, Scope Estimation, and Ambiguity Heuristics remain in CLAUDE.md |
| Persona skill not loaded when needed: if the orchestrator generates a free-form response without first loading orchestrator-persona, tone will revert to mechanical defaults | Medium | Low | The orchestrator response quality degrades gracefully (it still classifies correctly); add a CLAUDE.md stub note "Load orchestrator-persona before generating free-form responses" |
| Project CLAUDE.md too minimal for first-time setup: projects without a global CLAUDE.md would lack orchestrator logic | Low | Medium | This only affects the agent-config repo itself when cloned fresh; `install.sh` deploys the global CLAUDE.md, so all other projects are covered |
| Pending proposals add content to old structure: if action-control-gates or mandatory-new-session implement before this change, they will target the pre-refactored CLAUDE.md | Medium | Medium | Complete this refactoring first; communicate sequencing dependency to user |
| Budget numbers too tight: the 20k global budget may not accommodate future features without extraction | Low | Low | Budget is a governance guideline with explicit exception process, not a hard blocker; review annually |

## Rollback Plan

1. Revert `CLAUDE.md` (project) to its pre-refactoring content using `git checkout HEAD~1 -- CLAUDE.md`
2. Delete `skills/orchestrator-persona/SKILL.md` (new file, simply remove)
3. Revert changes to `skills/project-audit/SKILL.md` via git
4. Revert `ai-context/conventions.md` and `ai-context/architecture.md` via git
5. Run `bash install.sh` to re-deploy the reverted configuration
6. Delete any new ADR created for this change
7. All changes are in the agent-config repo; no external project files are affected

## Dependencies

- The exploration artifact (`openspec/changes/2026-03-22-slim-orchestrator-context/exploration.md`) is complete and recommends Approach C (Hybrid)
- `sdd-ff/SKILL.md` and `sdd-new/SKILL.md` must already contain the full SDD flow, delegation pattern, and fast-forward algorithm (confirmed: they do)
- The two pending orchestrator proposals (`2026-03-21-orchestrator-action-control-gates`, `2026-03-21-orchestrator-mandatory-new-session`) should NOT be implemented until this refactoring is complete

## Success Criteria

- [ ] Global CLAUDE.md (repo `CLAUDE.md`) is under 20,000 characters
- [ ] Project CLAUDE.md is under 5,000 characters and contains only project-specific overrides
- [ ] Combined always-loaded context (global + project CLAUDE.md) is under 25,000 characters (down from ~88k)
- [ ] Classification Decision Table, Scope Estimation Heuristic, and Ambiguity Detection Heuristics remain inline in global CLAUDE.md
- [ ] `skills/orchestrator-persona/SKILL.md` exists with Communication Persona, Teaching Principles, New-User Detection, and Session Banner content
- [ ] `skills/orchestrator-persona/SKILL.md` is under 8,000 characters
- [ ] `## Fast-Forward`, `## Apply Strategy`, `## SDD Flow — Phase DAG`, and `## How I Execute Commands` sections are absent from global CLAUDE.md
- [ ] `/project-audit` includes a budget compliance check for CLAUDE.md character counts
- [ ] A new ADR documents the refined inline-vs-skill boundary and budget governance
- [ ] `ai-context/conventions.md` is updated to reflect the new inline-vs-skill boundary
- [ ] Intent classification still works correctly on first message in a new session (manual verification)
- [ ] `install.sh` deploys the refactored files without errors

## Effort Estimate

Medium (1-2 days) — The change involves careful content reorganization across multiple files, creation of one new skill, audit modifications, and governance documentation. The highest-risk portion (ensuring classification logic stays inline) requires careful verification.

## Contradiction Resolution

### Intent classification inline mandate (ADR #18 / conventions.md)

**Prior context**: Architecture decision #18 (2026-03-12) states "Every user message is classified [...] via keyword-based heuristics inline in CLAUDE.md (no new skill)." Conventions.md (line 98) states: "This gate is inline procedural logic in CLAUDE.md — no separate skill is required."

**This proposal**: Keeps all classification logic (Decision Table, Scope Estimation, Ambiguity Heuristics) inline in CLAUDE.md. Extracts only presentation-layer content (persona, teaching, session banner) that is not part of the classification pipeline.

**Resolution approach**: ADR supersession — the original ADR's spirit (classification must be inline for timing safety) is preserved and made explicit. A new ADR refines the boundary: "classification = inline, presentation = on-demand skill." The conventions.md note is updated to reflect this refined boundary.

## Context

Recorded from conversation at 2026-03-22T00:00Z:

### Explicit Intents

- **Budget governance**: User explicitly requested budget rules to prevent future CLAUDE.md bloat
- **Core Index + Skill Detail pattern**: User wants to establish a documented contribution pattern where CLAUDE.md serves as a compact index and skills contain the detail
- **15-20k target**: User specified a target range of 15-20k characters for always-loaded context

### Provisional Notes

- **8k skill budget scope**: Exploration found that 15 existing skills exceed 8k chars. The budget applies only to newly created orchestrator skills, with existing skills grandfathered. This scoping decision should be documented in the ADR.
- **Persona skill loading timing**: The orchestrator must load the persona skill for every free-form response. If this proves too frequent, the content could be inlined back — but at ~5k chars it should be manageable.
