# Task Plan: 2026-03-22-slim-orchestrator-context

Date: 2026-03-22
Design: openspec/changes/2026-03-22-slim-orchestrator-context/design.md

## Progress: 15/22 tasks

## Phase 1: Removals and Replacements — Global CLAUDE.md Section Extraction and Deletion

Remove sections from global CLAUDE.md that are either redundant (already in skill files) or being extracted to the new persona skill. This phase operates exclusively on `CLAUDE.md` at repo root.

- [x] 1.1 Remove `## Teaching Principles` section (including `### New-User Detection` subsection) from `CLAUDE.md` ✓
  Linked spec: Requirement: CLAUDE.md MUST contain a Teaching Principles section with exactly 5 rules (modified — relocated to skill)
  Files: `CLAUDE.md` (MODIFY — delete section)
  Acceptance: Section heading and all content between it and the next H2 are absent from CLAUDE.md

- [x] 1.2 Remove `## Communication Persona` section (including all subsections: Tone Profile, Response Voice, Forbidden Mechanical Phrases, Adaptive Formality) from `CLAUDE.md` ✓
  Linked spec: Requirement: CLAUDE.md MUST contain a Communication Persona section (modified — relocated to skill)
  Files: `CLAUDE.md` (MODIFY — delete section)
  Acceptance: Section heading and all content between it and the next H2 are absent from CLAUDE.md

- [x] 1.3 Remove `### Orchestrator Session Banner` subsection from `## Always-On Orchestrator — Intent Classification` in `CLAUDE.md` ✓
  Linked spec: Requirement: Session-start orchestrator banner (modified — relocated to skill)
  Files: `CLAUDE.md` (MODIFY — delete subsection)
  Acceptance: Banner template absent from CLAUDE.md; Classification Decision Table and subsequent subsections remain intact

- [x] 1.4 Remove `## Fast-Forward (/sdd-ff)` section from `CLAUDE.md` ✓
  Linked spec: Requirement: Redundant SDD flow documentation MUST be removed — Fast-Forward scenario
  Files: `CLAUDE.md` (MODIFY — delete section)
  Acceptance: Section heading and all fast-forward algorithm content absent from CLAUDE.md

- [x] 1.5 Remove `## Apply Strategy` section from `CLAUDE.md` ✓
  Linked spec: Requirement: Redundant SDD flow documentation MUST be removed — Apply Strategy scenario
  Files: `CLAUDE.md` (MODIFY — delete section)
  Acceptance: Section heading and all apply strategy content absent from CLAUDE.md

- [x] 1.6 Remove `## SDD Flow — Phase DAG` section from `CLAUDE.md` ✓
  Linked spec: Requirement: Redundant SDD flow documentation MUST be removed — SDD Flow Phase DAG scenario
  Files: `CLAUDE.md` (MODIFY — delete section)
  Acceptance: Section heading and full phase DAG diagram absent from CLAUDE.md

- [x] 1.7 Remove `## How I Execute Commands` section (delegation pattern, sub-agent launch pattern, meta-tools table) from `CLAUDE.md` ✓
  Linked spec: Requirement: Redundant SDD flow documentation MUST be removed — How I Execute Commands scenario
  Files: `CLAUDE.md` (MODIFY — delete section)
  Acceptance: Section heading and all delegation/sub-agent content absent from CLAUDE.md

---
Phase 2 MUST NOT begin until all Phase 1 tasks are complete.
---

## Phase 2: Foundation — Create Persona Skill and Add Loading Instruction

Create the new orchestrator-persona skill with extracted content and wire it into CLAUDE.md.

- [x] 2.1 Create `skills/orchestrator-persona/SKILL.md` with YAML frontmatter (`name: orchestrator-persona`, `format: procedural`, `model: sonnet`), `**Triggers**`, `## Process` (Step 1: Session Banner, Step 2: Teaching Principles + New-User Detection, Step 3: Communication Persona with all 4 subsections), and `## Rules` ✓
  Linked spec: Requirement: Orchestrator persona skill MUST contain all presentation-layer content
  Files: `skills/orchestrator-persona/SKILL.md` (CREATE)
  Acceptance: File exists, contains all moved content (banner, 5 teaching principles, new-user detection, tone profile, response voice, forbidden phrases, adaptive formality), and is under 8,000 characters

- [x] 2.2 Add persona loading instruction to `## Always-On Orchestrator — Intent Classification` section in `CLAUDE.md` (single line after Orchestrator Response Signal subsection): `**Persona loading**: On the first free-form response in a session, read ~/.claude/skills/orchestrator-persona/SKILL.md for session banner, communication tone, and teaching principles.` ✓
  Linked spec: Requirement: Orchestrator content MUST be split into classification-critical and presentation layers — persona loading scenario
  Files: `CLAUDE.md` (MODIFY — add 1 line)
  Acceptance: Loading instruction present in CLAUDE.md within the Always-On Orchestrator section

- [x] 2.3 Add budget governance comment block to `CLAUDE.md` after `## Identity and Purpose` section (HTML comment with 3 budget constants: global 20k, project 5k, orchestrator skills 8k) ✓
  Linked spec: Requirement: Character budgets MUST be documented and enforceable
  Files: `CLAUDE.md` (MODIFY — add ~5 lines)
  Acceptance: Comment block present and matches design spec format

## Phase 3: Condensation — Compact Skills Registry and Available Commands

Reduce the character footprint of registry and commands sections without losing entries.

- [x] 3.1 Replace `## Skills Registry` section in `CLAUDE.md` with compact path-only format (category groupings retained, inline descriptions removed) per design template in `### Condensed Skills Registry Format` ✓
  Linked spec: Requirement: Skills Registry section MUST use compact path-only format
  Files: `CLAUDE.md` (MODIFY — rewrite section)
  Acceptance: All skill paths present, no inline descriptions, section under 3,000 characters

- [x] 3.2 Replace `## Available Commands` section in `CLAUDE.md` with condensed single-line format per design template in `### Condensed Available Commands Format` ✓
  Linked spec: Requirement: Available Commands section MUST use condensed single-line format
  Files: `CLAUDE.md` (MODIFY — rewrite section)
  Acceptance: All commands present, section under 1,500 characters

## Phase 4: Project CLAUDE.md — Create Override-Only Version

Since `CLAUDE.md` in this repo serves dual duty (global source AND project file), create a clear structural separation. The global CLAUDE.md is slimmed in Phases 1-3. For other projects consuming this system, the project CLAUDE.md pattern is override-only. For agent-config itself, the single file IS the global config.

- [ ] 4.1 Verify the global `CLAUDE.md` character count is at or under 20,000 characters after Phases 1-3
  Linked spec: Requirement: Global CLAUDE.md MUST stay under 20,000 characters
  Files: `CLAUDE.md` (READ — `wc -c`)
  Acceptance: Character count is <= 20,000; if over budget, identify additional content to condense before proceeding

- [ ] 4.2 Verify Classification Decision Table, Scope Estimation Heuristic, and Ambiguity Detection Heuristics remain intact in `CLAUDE.md` (structural integrity check via section header grep)
  Linked spec: Requirement: Classification and routing logic remains unaffected
  Files: `CLAUDE.md` (READ — grep for section headers)
  Acceptance: All three section headers present and their content intact

## Phase 5: Governance — Budget Audit Check and ADR

Add budget enforcement to project-audit and ensure the ADR is complete.

- [x] 5.1 Modify `skills/project-audit/SKILL.md` — add a budget compliance check (informational dimension, no score impact) that measures CLAUDE.md character count against 20k global budget or 5k project budget, and reports combined context count against 25k budget ✓
  Linked spec: Requirement: project-audit MUST include a budget compliance check for CLAUDE.md character counts
  Files: `skills/project-audit/SKILL.md` (MODIFY — add budget check step)
  Acceptance: Budget check logic present in skill file; checks global (20k), project (5k), and combined (25k) thresholds; findings are INFO severity

- [x] 5.2 Verify `docs/adr/041-slim-orchestrator-context.md` exists and contains Context, Decision, and Consequences sections documenting: (1) refined inline-vs-skill boundary, (2) three character budgets, (3) existing skills grandfathered ✓
  Linked spec: Requirement: ADR MUST document the refined inline-vs-skill boundary
  Files: `docs/adr/041-slim-orchestrator-context.md` (READ or MODIFY if incomplete)
  Acceptance: ADR has Status, Context, Decision, Consequences sections; all 3 budgets documented; exception process documented

- [x] 5.3 Verify `docs/adr/README.md` contains index row for ADR-041 with number, title, status, and date ✓
  Linked spec: Requirement: ADR is referenced in the ADR index
  Files: `docs/adr/README.md` (READ or MODIFY if row missing)
  Acceptance: ADR-041 row present in index table

## Phase 6: Memory and Spec Updates

Update ai-context and master specs to reflect the new architecture.

- [ ] 6.1 Modify `ai-context/conventions.md` — update the `### CLAUDE.md — Intent Classification and Clarification Gate` subsection to reflect the refined inline-vs-skill boundary: classification logic = inline, presentation/teaching = `orchestrator-persona` skill loaded on demand
  Linked spec: Requirement: Conventions reflect the inline-vs-skill boundary
  Files: `ai-context/conventions.md` (MODIFY — update subsection)
  Acceptance: Subsection mentions both inline classification and skill-based presentation; references `skills/orchestrator-persona/SKILL.md`

- [ ] 6.2 Modify `ai-context/architecture.md` — add architectural decision entry documenting the slim orchestrator context refactoring: what was removed, what was extracted, the inline-vs-skill boundary, and budget governance
  Linked spec: Requirement: Orchestrator content MUST be split into classification-critical and presentation layers
  Files: `ai-context/architecture.md` (MODIFY — add decision entry)
  Acceptance: New decision entry present with date 2026-03-22 referencing ADR-041

- [ ] 6.3 Modify `openspec/specs/orchestrator-behavior/spec.md` — merge delta spec requirements: persona skill loading trigger, budget governance enforcement, inline-vs-skill boundary rule, relocated persona/teaching/banner requirements
  Linked spec: All delta spec requirements in `openspec/changes/2026-03-22-slim-orchestrator-context/specs/orchestrator-behavior/spec.md`
  Files: `openspec/specs/orchestrator-behavior/spec.md` (MODIFY — merge ADDED/MODIFIED/REMOVED requirements)
  Acceptance: Master spec updated with all new requirements; modified requirements reflect new location; removed requirements are deleted or marked superseded

## Phase 7: Deployment Verification and Cleanup

- [ ] 7.1 Run `bash install.sh` to deploy refactored files to `~/.claude/`
  Files: `install.sh` (EXECUTE)
  Acceptance: install.sh completes without errors; `~/.claude/CLAUDE.md` matches repo CLAUDE.md; `~/.claude/skills/orchestrator-persona/SKILL.md` exists

- [ ] 7.2 Verify `skills/orchestrator-persona/SKILL.md` is under 8,000 characters via `wc -c`
  Files: `skills/orchestrator-persona/SKILL.md` (READ — character count)
  Acceptance: Character count <= 8,000

---

## Implementation Notes

- **Dual-role CLAUDE.md**: In this repo (agent-config), `CLAUDE.md` is both the global config source AND the project file. The 20k budget applies (not the 5k project budget). The override-only pattern applies to OTHER projects, not to agent-config itself.
- **Content extraction must be exact**: When moving content from CLAUDE.md to the persona skill, the behavioral requirements (tone rules, forbidden phrases, teaching principles) must be preserved word-for-word. Only structural wrapping (SKILL.md frontmatter, section headers) is new.
- **Classification timing safety**: At NO point during this change may the Classification Decision Table, Scope Estimation Heuristic, or Ambiguity Detection Heuristics be removed from or relocated out of CLAUDE.md. These must remain inline for first-message availability.
- **Phase 1 ordering is critical**: Remove content from CLAUDE.md BEFORE creating the persona skill (Phase 2) to avoid a state where content exists in two places simultaneously. If applying in a single session, this ordering prevents duplication drift.

## Blockers

- Task 4.1 (budget verification) may block further progress if Phases 1-3 do not achieve the 20,000 character target. If this happens, additional condensation of remaining sections (e.g., Agent Discovery, SDD Artifact Storage, Project Memory) will be needed before proceeding.
