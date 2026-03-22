# Exploration: Slim Orchestrator Context — CLAUDE.md Refactoring

## Current State

### Context Measurements

**Project CLAUDE.md** (`C:/Users/juanp/claude-config/CLAUDE.md`):
- Total: **45,925 characters** / 825 lines
- Deployed to `~/.claude/CLAUDE.md` via `install.sh` — loaded at every session start

**Global (runtime) CLAUDE.md** (`~/.claude/CLAUDE.md`):
- Total: **42,381 characters** / 782 lines
- Missing: `## Communication Persona` section (3,353 chars) — added only in project version
- Otherwise nearly identical (64 lines of diff, mostly session banner wording)

**Combined always-loaded context**: ~88k characters (both are loaded — see system-reminder context injection)

### Section-by-Section Breakdown (Project CLAUDE.md)

| Section | Characters | Lines | Extraction Candidate? |
|---------|-----------|-------|----------------------|
| `## Identity and Purpose` | 318 | 8 | No — minimal, identity anchor |
| `## Always-On Orchestrator — Intent Classification` | **17,722** | **261** | **YES — largest section, primary target** |
| `## Always-On Orchestrator — Override` (x2) | 275 | 13 | No — small, needed inline |
| `## Tech Stack` | 433 | 12 | No — small reference table |
| `## Architecture` | 872 | 21 | No — small, architectural summary |
| `## Unbreakable Rules` | 3,784 | 58 | Partial — Rules 5-7 can move |
| `## Teaching Principles` | 1,619 | 27 | **YES — fully extractable** |
| `## Communication Persona` | 3,353 | 42 | **YES — fully extractable** |
| `## Plan Mode Rules` | 525 | 19 | No — small reference |
| `## Working Principles` | 372 | 10 | No — small reference |
| `## Available Commands` | 2,441 | 44 | Partial — could be a reference skill |
| `## Agent Discovery` | 779 | 10 | No — small pointer section |
| `## How I Execute Commands` | 2,861 | 69 | **YES — delegation pattern is in sdd-ff/sdd-new already** |
| `## SDD Flow — Phase DAG` | 464 | 32 | Can merge with How I Execute |
| `## Fast-Forward (/sdd-ff)` | 1,148 | 20 | **YES — duplicated in sdd-ff SKILL.md** |
| `## Apply Strategy` | 177 | 8 | Can merge with sdd-apply |
| `## SDD Artifact Storage` | 704 | 28 | No — small reference |
| `## Project Memory` | 2,007 | 30 | Partial — Skill Overlap table can move |
| `## Skills Registry` | 5,989 | 92 | **YES — can become an auto-generated index** |

### Intent Classification Sub-section Breakdown

The largest section (`## Always-On Orchestrator — Intent Classification`, 17,722 chars) breaks down into:

| Sub-section | Approx chars | Extractable? |
|-------------|-------------|-------------|
| Session Banner | ~600 | Yes — presentation layer |
| Response Signal | ~700 | Yes — presentation layer |
| Intent Classes and Routing table | ~800 | **MUST STAY — core router** |
| Ambiguity Detection Heuristics | ~1,800 | Yes — detail logic |
| Classification Decision Table | **~5,500** | Yes — decision logic |
| Scope Estimation Heuristic | ~2,500 | Yes — sub-step logic |
| Unbreakable Rules (orchestrator-specific) | ~500 | **MUST STAY — critical guard** |

### Duplication Analysis

1. **Global vs. Project CLAUDE.md**: 95% identical content. The project version adds `## Communication Persona` (3,353 chars) and uses a different session banner wording. Both are loaded into context simultaneously, meaning ~42k chars are loaded **twice**.

2. **CLAUDE.md vs. sdd-ff SKILL.md**: The `## Fast-Forward` section (1,148 chars) is a summary of what sdd-ff SKILL.md (16,543 chars) contains in full detail. The sdd-ff skill already contains the complete algorithm — the CLAUDE.md version is redundant.

3. **CLAUDE.md vs. sdd-new SKILL.md**: Same pattern as sdd-ff — the `## SDD Flow` diagram and delegation pattern are documented in both CLAUDE.md and sdd-new.

4. **CLAUDE.md vs. orchestrator-behavior spec**: The orchestrator-behavior spec (1,234 lines) is the authoritative behavioral contract for intent classification. The CLAUDE.md section is the implementation in natural language — both exist and serve different purposes, but the CLAUDE.md implementation is what the LLM actually follows.

### install.sh Analysis

`install.sh` is a straightforward copy operation:
- Copies `CLAUDE.md` from repo to `~/.claude/CLAUDE.md` (line 92)
- Copies entire `skills/` directory recursively (line 106)
- No transformation, no templating, no conditional includes
- **No changes needed** unless we introduce a build step (e.g., assembling CLAUDE.md from partials)

### Skill Size Analysis

Top skills by size (for budget context):
- `project-claude-organizer`: 77,565 chars (already violates any 8k budget)
- `project-audit`: 67,719 chars
- `claude-folder-audit`: 40,910 chars
- `sdd-apply`: 30,144 chars
- Total skill corpus: 733,005 chars across all skills

## Branch Diff

Files modified in current branch relevant to this change:
- CLAUDE.md (modified) — the primary refactoring target
- ai-context/architecture.md (modified) — architecture decisions
- ai-context/changelog-ai.md (modified) — session log
- openspec/specs/orchestrator-behavior/spec.md (modified) — orchestrator spec
- openspec/specs/sdd-orchestration/spec.md (modified) — SDD orchestration spec
- skills/sdd-ff/SKILL.md (modified) — fast-forward skill
- skills/sdd-explore/SKILL.md (modified) — explore skill
- skills/sdd-propose/SKILL.md (modified) — propose skill
- openspec/changes/2026-03-21-orchestrator-action-control-gates/ (untracked) — pending proposal
- openspec/changes/2026-03-21-orchestrator-mandatory-new-session/ (untracked) — pending proposal

## Prior Attempts

Prior archived changes related to this topic:
- 2026-02-26-add-orchestrator-skills: COMPLETED — introduced sdd-ff and sdd-new as skill files
- 2026-03-12-orchestrator-always-on: COMPLETED — added intent classification to CLAUDE.md
- 2026-03-14-orchestrator-visibility: COMPLETED — added session banner and intent signals
- 2026-03-14-orchestrator-classification-edge-cases: COMPLETED — refined classification rules
- 2026-03-22-orchestrator-natural-language: COMPLETED — added Communication Persona section
- 2026-03-22-orchestrator-scope-estimation: COMPLETED — added scope estimation heuristic
- 2026-03-22-orchestrator-teaching: COMPLETED — added teaching principles

No prior attempts at slimming or refactoring CLAUDE.md size. The trend has been consistently additive — each change has grown the file.

## Contradiction Analysis

Contradictions detected between user intent and existing context:

- Item: Intent classification as inline CLAUDE.md logic
  Status: UNCERTAIN — The user wants to extract classification logic into on-demand skills. However, `ai-context/conventions.md` (line 98) explicitly states: "This gate is inline procedural logic in CLAUDE.md — no separate skill is required." And architectural decision #18 states the classification is "inline in CLAUDE.md (no new skill)."
  Severity: WARNING
  Resolution: This is a deliberate architectural reversal. The original decision to keep classification inline was made when the section was smaller (~3k chars). It has since grown to ~17.7k chars. The proposal should explicitly acknowledge this as an ADR supersession. The key constraint is: the LLM must still be able to classify intent at session start — if classification logic is in a skill, there must be a routing stub in CLAUDE.md that triggers the skill read.

- Item: Existing skill sizes exceed proposed 8k budget
  Status: CERTAIN — 15 skills already exceed 8,000 characters. The proposed 8k budget for individual skills is immediately violated by most complex skills (project-audit: 67k, project-claude-organizer: 77k, claude-folder-audit: 40k, sdd-apply: 30k, etc.).
  Severity: INFO
  Resolution: The 8k budget should apply to newly extracted orchestrator skills only, or the budget should be framed as a guideline with documented exceptions. Enforcing it retroactively would require splitting dozens of existing skills.

- Item: Project CLAUDE.md vs Global CLAUDE.md redundancy
  Status: CERTAIN — Both files are loaded simultaneously (global via `~/.claude/CLAUDE.md`, project via `CLAUDE.md` in repo). They are 95% identical. Claude Code loads both — the project CLAUDE.md overrides/extends the global one, but both consume context window.
  Severity: WARNING
  Resolution: The project CLAUDE.md should be reduced to project-specific overrides only (max 5k chars as proposed). The global CLAUDE.md should contain the universal orchestrator config. This is the highest-impact single change — eliminating ~42k chars of duplication.

## Affected Areas

| File/Module | Impact | Notes |
|-------------|--------|-------|
| `CLAUDE.md` (project) | HIGH | Primary refactoring target — reduce from 45k to ~5k chars |
| `~/.claude/CLAUDE.md` (global, same source) | HIGH | Primary refactoring target — reduce from 42k to ~15k chars |
| `install.sh` | LOW | May need changes only if a build/assembly step is introduced |
| `skills/sdd-ff/SKILL.md` | LOW | Already self-contained — remove duplication from CLAUDE.md |
| `skills/sdd-new/SKILL.md` | LOW | Already self-contained — remove duplication from CLAUDE.md |
| `openspec/specs/orchestrator-behavior/spec.md` | MEDIUM | Spec must be updated to reflect new architecture |
| `ai-context/conventions.md` | LOW | Update to reflect new inline-vs-skill boundaries |
| `ai-context/architecture.md` | LOW | Record the refactoring decision |
| `skills/project-audit/SKILL.md` | MEDIUM | Must add budget enforcement dimensions |
| `openspec/config.yaml` | LOW | May need new config keys for budget thresholds |

## Analyzed Approaches

### Approach A: Skill Extraction (Extract classification logic into on-demand skills)

**Description**: Move the heavy orchestrator logic (Classification Decision Table, Scope Estimation, Ambiguity Detection, Teaching Principles, Communication Persona) into dedicated skills that are loaded on demand. CLAUDE.md retains a compact router stub (~15k chars) with:
- Identity and Purpose
- Intent Classes and Routing table (the compact summary table, not the decision table)
- Unbreakable Rules (1-4 only; 5-7 move to skills)
- Command routing table (command → skill path)
- Skills Registry (compact index format)

New skills created:
- `skills/orchestrator-classify/SKILL.md` — Classification Decision Table, Ambiguity Heuristics, Scope Estimation
- `skills/orchestrator-persona/SKILL.md` — Communication Persona, Teaching Principles, Session Banner
- (Rules 5-7 stay in CLAUDE.md — they are guard rails, not logic)

**Pros**:
- Largest reduction: ~25k chars removed from always-loaded context
- Skills are loaded only when needed (classification skill at session start, persona skill when generating responses)
- Clean separation of concerns: routing vs. classification vs. presentation

**Cons**:
- **Critical risk**: Intent classification must happen before ANY response. If the classification logic is in a skill, it must be read at session start — which means it is effectively always-loaded anyway (Claude reads CLAUDE.md, sees the routing stub, immediately reads the classification skill). The savings are real in file organization but may not reduce actual context usage.
- Requires a routing stub mechanism that does not currently exist
- Adds complexity: instead of one file, now three files must be consistent

**Estimated effort**: High
**Risk**: Medium — the critical question is whether Claude Code actually loads skills on demand or if CLAUDE.md references cause eager loading

### Approach B: Deduplication Only (Eliminate project/global redundancy)

**Description**: Restructure the project CLAUDE.md to contain only project-specific overrides (tech stack, unbreakable rules additions, project memory, project-specific skills registry entries). The global CLAUDE.md remains the single source of truth for orchestrator logic. No skills are extracted.

Project CLAUDE.md becomes:
```
# Project: agent-config — Configuration Overrides
## Tech Stack
## Unbreakable Rules (project additions)
## Project Memory
## Skills Registry (project-local entries only)
```

**Pros**:
- Immediate ~42k char savings (eliminate duplication)
- No new skills to create or maintain
- No risk to classification timing — logic stays in CLAUDE.md
- Simplest possible change

**Cons**:
- Global CLAUDE.md stays at ~42k chars (still large)
- Does not address the fundamental growth problem — next additions will keep growing the file
- Does not establish governance budgets

**Estimated effort**: Low
**Risk**: Low

### Approach C: Hybrid — Deduplication + Selective Extraction + Budget Governance

**Description**: Combine Approach B (deduplication) with targeted extraction of clearly separable sections, plus establish governance rules to prevent future growth.

Phase 1 — Deduplication:
- Project CLAUDE.md becomes override-only (~5k chars)

Phase 2 — Selective extraction from global CLAUDE.md:
- Extract `## Communication Persona` → `skills/orchestrator-persona/SKILL.md` (~3.3k chars saved)
- Extract `## Teaching Principles` + New-User Detection → `skills/orchestrator-persona/SKILL.md` (~1.6k chars saved)
- Extract `## Fast-Forward`, `## Apply Strategy`, `## SDD Flow` → remove entirely (already in sdd-ff/sdd-new SKILL.md, 1.8k chars saved)
- Extract `## How I Execute Commands` delegation pattern → remove (already in sdd-ff/sdd-new, 2.8k chars saved)
- Condense `## Skills Registry` to compact format (remove descriptions, keep paths only) → (~3k chars saved)
- Condense `## Available Commands` into a single-line-per-command format → (~1k chars saved)

Phase 3 — Budget governance:
- CLAUDE.md global budget: 15k chars
- CLAUDE.md project budget: 5k chars
- New orchestrator skills budget: 8k chars
- Enforcement: add budget check to `/project-audit`

**Keep inline in CLAUDE.md** (non-negotiable):
- Identity and Purpose (~300 chars)
- Intent Classes and Routing table (~800 chars)
- Classification Decision Table (~5.5k chars) — MUST stay inline, this is the core router
- Scope Estimation Heuristic (~2.5k chars) — MUST stay inline, runs with every Change Request
- Ambiguity Detection Heuristics (~1.8k chars) — MUST stay inline, part of classification flow
- Unbreakable Rules 1-4 (~1.5k chars) — MUST stay inline, guard rails
- Orchestrator-specific Unbreakable Rules (~500 chars)
- Override mechanism (~275 chars)
- Tech Stack (~433 chars)
- Architecture (~872 chars)

Estimated residual: ~14.5k chars — within the 15k budget.

**Pros**:
- Largest overall savings: ~42k (dedup) + ~13.5k (extraction) = ~55.5k chars eliminated
- Establishes governance to prevent future growth
- Classification logic stays inline — no timing risk
- Only truly separable sections are extracted
- Persona/teaching extracted into a skill loaded only when generating orchestrator responses (not on every session start)

**Cons**:
- More work than Approach B
- Must update project-audit to enforce budgets
- Persona skill must be loaded when the orchestrator generates any free-form response (not truly on-demand)

**Estimated effort**: Medium
**Risk**: Low-Medium

## Recommendation

**Recommended approach: Approach C (Hybrid)**

Rationale:
1. **Deduplication is mandatory** — loading 42k chars twice is the biggest single waste. Approach B alone solves this but does not address future growth.
2. **Classification logic MUST stay inline** — Approach A's main extraction target (the classification logic) cannot safely move to a skill without risking classification timing. The LLM needs to see the decision table before it can classify any message.
3. **Persona and teaching ARE safely extractable** — These sections are only needed when generating the final response text, not during classification. Moving them to a skill that loads on first orchestrator response is safe and saves ~5k chars.
4. **Duplicate SDD flow sections MUST go** — The Fast-Forward, Apply Strategy, and Phase DAG sections are already fully documented in the skill files. Keeping summaries in CLAUDE.md is pure waste.
5. **Budget governance prevents future regression** — Without enforcement, the next round of orchestrator improvements will grow CLAUDE.md back to 40k+.

### Key Architectural Decision

The original decision (ADR implied in architecture.md #18) to keep classification inline was correct at the time but must now be **refined** (not reversed): classification stays inline, but presentation/teaching/flow documentation moves to skills. The classification decision table is ~5.5k chars — manageable. The rest (~37k chars) is either duplication, redundancy with skills, or presentation logic that can load on demand.

## Identified Risks

- **Classification timing**: If any classification logic is accidentally moved to a skill, the orchestrator will fail to classify intent on first message. Mitigation: explicit "MUST STAY INLINE" markers on all classification sub-sections during the refactoring.
- **Project CLAUDE.md too minimal**: If the project CLAUDE.md becomes override-only, projects that do not have a global CLAUDE.md (e.g., first-time setup) will lack orchestrator logic. Mitigation: this only affects the agent-config repo itself; all deployed projects get the global CLAUDE.md via install.sh.
- **Skill budget violations**: 15 existing skills already exceed 8k chars. Retroactive enforcement would be a massive scope expansion. Mitigation: apply budget only to newly created orchestrator skills; existing skills are grandfathered with a documented exception list.
- **Persona skill loading**: The orchestrator must load the persona skill for every free-form response, not just slash commands. If the skill is large, this partially negates the savings. Mitigation: keep the persona skill under 5k chars (Teaching Principles 1.6k + Communication Persona 3.3k = ~5k).
- **Two pending orchestrator proposals**: `2026-03-21-orchestrator-action-control-gates` and `2026-03-21-orchestrator-mandatory-new-session` are pending implementation. They will add content to CLAUDE.md. This refactoring should happen first, or those proposals should target the new skill structure. Mitigation: complete this refactoring before implementing pending proposals.

## Open Questions

- Should the Skills Registry be auto-generated from the skills/ directory at install time (build step in install.sh), or remain manually maintained but in a compact format?
- Should `install.sh` gain a build/assembly step (e.g., concatenating CLAUDE.md from partials), or should the repo source files be the final deployed form?
- What is the actual context window impact of Claude Code loading both global and project CLAUDE.md? Is there de-duplication at the platform level, or is every character counted twice?
- Should the 8k skill budget apply to all skills (with exceptions) or only to newly created skills?
- How should the pending orchestrator proposals (action-control-gates, mandatory-new-session) be handled — should they wait for this refactoring?

## Ready for Proposal

Yes — The exploration reveals a clear path forward with Approach C (Hybrid). The main risk (classification timing) is well-understood and mitigated by keeping classification logic inline. The primary savings come from deduplication (~42k chars), which is low-risk and high-impact. The change is well-scoped: CLAUDE.md restructuring + 1-2 new skills + project-audit budget enforcement.
