# Technical Design: 2026-03-22-slim-orchestrator-context

Date: 2026-03-22
Proposal: openspec/changes/2026-03-22-slim-orchestrator-context/proposal.md

## General Approach

Reduce always-loaded orchestrator context from ~91k chars (47.5k project + 43.9k global) to ~25k by executing three sequential phases: (1) deduplicate project CLAUDE.md to override-only format, (2) extract presentation-layer content into a new on-demand skill and remove redundant SDD flow sections from global CLAUDE.md, (3) establish budget governance via project-audit enforcement and a new ADR. Classification logic stays inline throughout; only presentation, teaching, and already-duplicated SDD flow documentation is relocated or removed.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
| -------- | ------ | ---------------------- | ------------- |
| Project CLAUDE.md structure | Override-only: project identity header, Tech Stack, project-specific Unbreakable Rules additions, Project Memory pointers, project-local Skills Registry entries | Keep full duplicate; use a template-assembly build step | The project file and global file are loaded simultaneously by Claude Code. Deduplication eliminates ~42k chars with no build-step complexity. `install.sh` remains a plain copy — no transformation needed. |
| Presentation extraction target | Single `skills/orchestrator-persona/SKILL.md` containing Session Banner, Communication Persona, Teaching Principles, New-User Detection | Multiple skills (one per concern); keep everything inline | One skill keeps presentation logic cohesive and reduces file count. The total content (~5k chars) fits well within a single skill. Loading one file is cheaper than loading three. |
| Persona skill loading trigger | Orchestrator loads persona skill on first free-form response per session (not at session start) | Load at session start; load on every response; never load (keep inline) | Loading at session start would negate savings. Loading on every response is redundant — once loaded, the persona context persists. First-response loading balances savings with availability. |
| Redundant SDD flow sections | Remove entirely from global CLAUDE.md: `## Fast-Forward`, `## Apply Strategy`, `## SDD Flow — Phase DAG`, `## How I Execute Commands` (delegation pattern and sub-agent launch pattern) | Keep as summary; move to a separate skill | These sections are fully documented in `sdd-ff/SKILL.md` and `sdd-new/SKILL.md`. The skill files are authoritative — CLAUDE.md summaries are pure waste. |
| Skills Registry format | Path-only entries: remove inline descriptions, keep category groupings | Auto-generate from `skills/` directory; keep verbose format | Manual path-only format cuts ~3k chars while preserving discoverability. Auto-generation introduces a build step and scope expansion. Descriptions are available in each skill's frontmatter. |
| Available Commands format | Single-line-per-command: `/command` — brief action (no table headers per subsection) | Keep current table format; remove entirely | Tables add visual overhead (~1k chars of formatting). Single-line format is scannable and compact. |
| Budget governance mechanism | Character count thresholds checked by `project-audit` with INFO-severity findings | Hard enforcement in install.sh; pre-commit hook; manual-only | Audit-based enforcement is consistent with the existing quality gate pattern. INFO severity means it warns but does not block, appropriate for a governance guideline. Budget can be overridden with documented exceptions. |
| Classification logic location | Stays inline in global CLAUDE.md (unchanged — Classification Decision Table, Scope Estimation, Ambiguity Heuristics) | Extract to `skills/orchestrator-classify/SKILL.md` | Classification MUST run before any response. If in a skill, the orchestrator must read it at session start, making it effectively always-loaded. Keeping it inline eliminates the indirection risk and preserves the current timing guarantee. This decision refines ADR-029 (not reverses it). |

## Data Flow

### Session Start (current — before change)
```
Claude Code start
    ↓
Load ~/.claude/CLAUDE.md (43.9k chars)     ← global
    ↓
Load project CLAUDE.md (47.5k chars)        ← project (95% duplicate)
    ↓
Total loaded: ~91.4k chars
    ↓
User sends message → classify intent → generate response
```

### Session Start (after change)
```
Claude Code start
    ↓
Load ~/.claude/CLAUDE.md (~18-20k chars)    ← global (slimmed)
    ↓
Load project CLAUDE.md (~3-5k chars)        ← project (override-only)
    ↓
Total loaded: ~21-25k chars
    ↓
User sends message → classify intent (inline, unchanged)
    ↓
First free-form response:
    ↓
Read skills/orchestrator-persona/SKILL.md (~5k chars, on-demand)
    ↓
Generate response with persona + teaching context
```

### Persona Skill Loading Flow
```
User message (free-form, not slash command)
    ↓
Intent classification (inline in CLAUDE.md — unchanged)
    ↓
IF first_free_form_response_in_session:
    Read ~/.claude/skills/orchestrator-persona/SKILL.md
    ↓
    Cache persona context for remainder of session
    ↓
Generate response with tone, teaching, and persona rules applied
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `CLAUDE.md` (repo root = global source) | **Major modify** | Remove: `## Teaching Principles`, `## Communication Persona`, `## How I Execute Commands` (delegation pattern + sub-agent launch pattern), `## SDD Flow — Phase DAG`, `## Fast-Forward (/sdd-ff)`, `## Apply Strategy`. Condense: `## Available Commands` to single-line format, `## Skills Registry` to path-only format. Add: persona skill loading instruction (1 line in `## Always-On Orchestrator`), budget governance comment block (~5 lines). Keep unchanged: Identity, Intent Classification (full Decision Table + Scope Estimation + Ambiguity Heuristics), Unbreakable Rules 1-7, Override, Tech Stack, Architecture, Agent Discovery, SDD Artifact Storage, Project Memory, Plan Mode, Working Principles |
| `CLAUDE.md` (project — same file, dual role) | **Major modify** | After global slimming, create a separate project-override section at the bottom (or restructure the single file to clearly separate global-authoritative content from project-override content). Since this repo's `CLAUDE.md` is both the project file AND the source deployed to `~/.claude/`, the override-only pattern applies to OTHER projects. For this repo (agent-config), the file IS the global config. See Open Questions. |
| `skills/orchestrator-persona/SKILL.md` | **Create** | New skill containing: Session Banner (moved from CLAUDE.md), Tone Profile, Response Voice by Intent Class, Forbidden Mechanical Phrases, Adaptive Formality (all from `## Communication Persona`), Teaching Principles 1-5, New-User Detection logic. Format: `procedural`. Estimated size: ~5k chars. |
| `skills/project-audit/SKILL.md` | **Modify** | Add a new informational dimension (D14 or similar) or a budget compliance sub-check within an existing dimension. Checks: (1) global CLAUDE.md char count vs 20k budget, (2) project CLAUDE.md char count vs 5k budget (skip if project IS agent-config), (3) `skills/orchestrator-persona/SKILL.md` char count vs 8k budget. Findings are INFO severity — warn, never block. |
| `ai-context/conventions.md` | **Modify** | Update the `CLAUDE.md — Intent Classification and Clarification Gate` subsection to reflect the refined inline-vs-skill boundary: classification logic = inline, presentation/teaching = `orchestrator-persona` skill. |
| `ai-context/architecture.md` | **Modify** | Add architectural decision #29 documenting the slim orchestrator context refactoring: what was removed, what was extracted, the inline-vs-skill boundary refinement, and budget governance. |
| `docs/adr/041-slim-orchestrator-context.md` | **Create** | ADR documenting: (1) refined inline-vs-skill boundary (classification = inline for timing safety, presentation = on-demand skill), (2) budget governance (global 20k, project 5k, new orchestrator skills 8k), (3) supersedes the spirit of ADR-029's "no new skill" clause by refining the boundary. |
| `docs/adr/README.md` | **Modify** | Append new ADR index row for ADR-041. |
| `openspec/specs/orchestrator-behavior/spec.md` | **Modify** | Add requirements for: persona skill loading trigger, budget governance enforcement in project-audit, inline-vs-skill boundary rule. |

## Interfaces and Contracts

### orchestrator-persona SKILL.md — Structure

```markdown
---
name: orchestrator-persona
description: >
  Presentation layer for orchestrator responses: session banner, communication
  persona, teaching principles, and new-user detection.
format: procedural
model: sonnet
---

# orchestrator-persona

> Presentation layer for orchestrator responses.

**Triggers**: Loaded by the orchestrator on first free-form response per session.
Not invoked directly by the user.

---

## Process

### Step 1 — Session Banner
[Moved content from CLAUDE.md ### Orchestrator Session Banner]

### Step 2 — Teaching Principles
[Moved content from CLAUDE.md ## Teaching Principles + ### New-User Detection]

### Step 3 — Communication Persona
[Moved content from CLAUDE.md ## Communication Persona — all subsections]

---

## Rules
- This skill is loaded once per session on first free-form response
- Content is presentation-layer only — no classification or routing logic
- Session Banner is displayed at session start (before first response)
- Teaching principles apply cross-cutting to all orchestrator responses
- Persona rules apply to response tone and phrasing
```

### CLAUDE.md Persona Loading Instruction

Single line added to the `## Always-On Orchestrator — Intent Classification` section, after the Response Signal subsection:

```markdown
**Persona loading**: On the first free-form response in a session, read `~/.claude/skills/orchestrator-persona/SKILL.md` for session banner, communication tone, and teaching principles. This content is presentation-layer only and does not affect classification.
```

### Budget Governance Constants

Added as a comment block at the top of CLAUDE.md (after `## Identity and Purpose`):

```markdown
<!-- Context budget governance (ADR-041):
     Global CLAUDE.md: 20,000 chars max
     Project CLAUDE.md: 5,000 chars max (override-only projects)
     New orchestrator skills: 8,000 chars max
     Enforcement: project-audit INFO-severity finding when exceeded
     Exception: existing skills are grandfathered; document exceptions in ADR -->
```

### Project-Audit Budget Check Contract

```
Dimension: Budget Compliance (informational, no score)
Activation: Always (every project-audit run)

Checks:
  1. Read CLAUDE.md, count characters
     - IF project is agent-config (openspec/config.yaml project.name == "agent-config"):
         Check against 20,000 char global budget
     - ELSE:
         Check against 5,000 char project budget
     Finding severity: INFO
     Message: "CLAUDE.md is [N] chars ([N-budget] over [budget] budget). Consider extracting content to skills."

  2. IF skills/orchestrator-persona/SKILL.md exists:
     Count characters
     Check against 8,000 char budget
     Finding severity: INFO
     Message: "orchestrator-persona skill is [N] chars ([N-budget] over [budget] budget)."

Output location: audit-report.md, appended as informational findings (no score impact)
```

### Condensed Skills Registry Format

```markdown
## Skills Registry

### SDD Orchestrator
- `~/.claude/skills/sdd-ff/SKILL.md`
- `~/.claude/skills/sdd-new/SKILL.md`
- `~/.claude/skills/sdd-status/SKILL.md`
- `~/.claude/skills/orchestrator-status/SKILL.md`
- `~/.claude/skills/orchestrator-persona/SKILL.md`

### SDD Phases
- `~/.claude/skills/sdd-explore/SKILL.md`
- `~/.claude/skills/sdd-propose/SKILL.md`
- `~/.claude/skills/sdd-spec/SKILL.md`
- `~/.claude/skills/sdd-design/SKILL.md`
- `~/.claude/skills/sdd-tasks/SKILL.md`
- `~/.claude/skills/sdd-apply/SKILL.md`
- `~/.claude/skills/sdd-verify/SKILL.md`
- `~/.claude/skills/sdd-archive/SKILL.md`

### SDD Maintenance
- `~/.claude/skills/sdd-spec-gc/SKILL.md`

### Meta-tools
- `~/.claude/skills/project-setup/SKILL.md`
- `~/.claude/skills/project-onboard/SKILL.md`
- `~/.claude/skills/project-audit/SKILL.md`
- `~/.claude/skills/project-analyze/SKILL.md`
- `~/.claude/skills/project-fix/SKILL.md`
- `~/.claude/skills/project-update/SKILL.md`
- `~/.claude/skills/skill-creator/SKILL.md`
- `~/.claude/skills/skill-add/SKILL.md`
- `~/.claude/skills/memory-init/SKILL.md`
- `~/.claude/skills/memory-update/SKILL.md`
- `~/.claude/skills/codebase-teach/SKILL.md`

### Technology (global catalog)
- `~/.claude/skills/react-19/SKILL.md`
- `~/.claude/skills/nextjs-15/SKILL.md`
- `~/.claude/skills/typescript/SKILL.md`
- `~/.claude/skills/zustand-5/SKILL.md`
- `~/.claude/skills/zod-4/SKILL.md`
- `~/.claude/skills/tailwind-4/SKILL.md`
- `~/.claude/skills/ai-sdk-5/SKILL.md`
- `~/.claude/skills/react-native/SKILL.md`
- `~/.claude/skills/electron/SKILL.md`
- `~/.claude/skills/django-drf/SKILL.md`
- `~/.claude/skills/spring-boot-3/SKILL.md`
- `~/.claude/skills/hexagonal-architecture-java/SKILL.md`
- `~/.claude/skills/java-21/SKILL.md`
- `~/.claude/skills/playwright/SKILL.md`
- `~/.claude/skills/pytest/SKILL.md`
- `~/.claude/skills/github-pr/SKILL.md`
- `~/.claude/skills/jira-task/SKILL.md`
- `~/.claude/skills/jira-epic/SKILL.md`
- `~/.claude/skills/smart-commit/SKILL.md`
- `~/.claude/skills/elixir-antipatterns/SKILL.md`

### Domain & Design
- `~/.claude/skills/feature-domain-expert/SKILL.md`
- `~/.claude/skills/solid-ddd/SKILL.md`

### Tools & Platforms
- `~/.claude/skills/claude-code-expert/SKILL.md`
- `~/.claude/skills/excel-expert/SKILL.md`
- `~/.claude/skills/image-ocr/SKILL.md`
- `~/.claude/skills/config-export/SKILL.md`

### System Audits
- `~/.claude/skills/claude-folder-audit/SKILL.md`
- `~/.claude/skills/project-claude-organizer/SKILL.md`
```

### Condensed Available Commands Format

```markdown
## Commands

`/project-setup` — deploy SDD + memory structure | `/project-onboard` — diagnose state, recommend first command | `/project-audit` — audit config, generate audit-report.md | `/project-analyze` — deep codebase analysis, update ai-context/ | `/project-fix` — apply corrections from audit-report.md | `/project-update` — sync CLAUDE.md with global catalog | `/skill-create <name>` — create new skill | `/skill-add <name>` — add global skill to project | `/memory-init` — generate ai-context/ from scratch | `/memory-update` — record session changes to ai-context/ | `/codebase-teach` — extract domain knowledge to ai-context/features/ | `/project-claude-organizer` — reorganize .claude/ folder | `/orchestrator-status` — show orchestrator state

`/sdd-new <change>` — full SDD cycle | `/sdd-ff <change>` — fast-forward cycle | `/sdd-explore <topic>` — investigate without changing | `/sdd-propose` — create proposal | `/sdd-spec` — write specs | `/sdd-design` — create design | `/sdd-tasks` — break down tasks | `/sdd-apply` — implement | `/sdd-verify` — verify against specs | `/sdd-archive` — archive completed change | `/sdd-status` — view active cycle

`/sdd-spec-gc <domain>` — audit spec for stale requirements | `/sdd-spec-gc --all` — audit all specs
```

## Testing Strategy

| Layer | What to test | Tool |
| ----- | ------------ | ---- |
| Integration | Run `/project-audit` on agent-config after all changes — score must be >= previous | `/project-audit` (audit-as-integration-test) |
| Manual verification | Verify intent classification works on first message in a new Claude Code session | Manual — start fresh session, send free-form message, confirm classification signal appears |
| Manual verification | Verify persona skill loads correctly on first free-form response | Manual — observe session banner and tone in response |
| Character count | Verify global CLAUDE.md is under 20,000 chars after all removals | `wc -c CLAUDE.md` |
| Character count | Verify `skills/orchestrator-persona/SKILL.md` is under 8,000 chars | `wc -c skills/orchestrator-persona/SKILL.md` |
| Structural | Verify Classification Decision Table, Scope Estimation, and Ambiguity Heuristics remain in global CLAUDE.md | `grep` for section headers |
| Structural | Verify removed sections (`## Fast-Forward`, `## Apply Strategy`, `## SDD Flow — Phase DAG`, `## How I Execute Commands`) are absent from global CLAUDE.md | `grep` for section headers |
| Deploy | Run `bash install.sh` and verify it completes without errors | `bash install.sh` |

## Migration Plan

No data migration required. All changes are to configuration files (Markdown, YAML). The migration is a content reorganization:

- Step 1: Create `skills/orchestrator-persona/SKILL.md` with extracted content
- Step 2: Modify global CLAUDE.md (remove sections, condense registry/commands, add persona loading instruction and budget comment)
- Step 3: Add budget check to `skills/project-audit/SKILL.md`
- Step 4: Create ADR-041 and update ADR index
- Step 5: Update `ai-context/conventions.md` and `ai-context/architecture.md`
- Step 6: Run `bash install.sh` to deploy
- Step 7: Verify character counts and structural integrity

## Open Questions

- **agent-config dual-role file**: In this repo, `CLAUDE.md` serves as BOTH the global config source (deployed to `~/.claude/` by `install.sh`) AND the project CLAUDE.md. The "override-only project CLAUDE.md" pattern applies to OTHER projects that use this system, not to agent-config itself. For agent-config, the single `CLAUDE.md` IS the global config and contains all orchestrator logic. The 20k budget applies to this file. Impact if not resolved: none for this change — the budget target is clear (20k for the single file). The 5k project budget applies only to non-agent-config projects.

- **Persona skill caching**: Claude Code does not have explicit skill caching across messages within a session. The persona skill content will persist in conversation context once loaded, but whether Claude re-reads the file on subsequent messages is implementation-dependent. Impact if not resolved: low — worst case is the skill is re-read (adding ~5k chars per response), which is still far less than the current ~91k always-loaded overhead.

- **Response Signal section**: The `### Orchestrator Response Signal` subsection (~700 chars) could arguably move to the persona skill since it is a presentation concern. However, it directly relates to the intent classification output format, making it a boundary case. Decision: keep it inline in CLAUDE.md alongside the classification logic it describes, to avoid splitting the signal definition from the classification that produces it.
