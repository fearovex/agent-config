# Task Plan: add-orchestrator-skills

Date: 2026-02-26
Design: openspec/changes/add-orchestrator-skills/design.md

## Progress: 0/14 tasks

---

## Phase 1: New Skill Files — Orchestrators

- [ ] 1.1 Create `skills/sdd-ff/SKILL.md` — full sdd-ff orchestrator skill with triggers, 5-step process (argument validation → propose → parallel spec+design → tasks → summary+confirmation), sub-agent delegation template, and rules including: stop on blocked/failed, highlight warnings, do NOT invoke sdd-apply automatically
- [ ] 1.2 Create `skills/sdd-new/SKILL.md` — full sdd-new orchestrator skill with triggers, process (argument validation → ask explore → optional sdd-explore → user confirmation after propose → parallel spec+design → user confirmation before tasks → tasks → full DAG summary with remaining phases reminder), sub-agent delegation template, and rules

## Phase 2: New Skill Files — Utilities

- [ ] 2.1 Create `skills/sdd-status/SKILL.md` — status read skill with triggers, process (read openspec/changes/ excluding archive/ → check presence of each artifact per change → render table with present/absent indicators → current phase inference → archived count footer), output format as defined in design, and rules including: filesystem-only, no git inspection, handle missing openspec/changes/ gracefully
- [ ] 2.2 Create `skills/skill-add/SKILL.md` — skill installer with triggers, process (argument validation → check ~/.claude/skills/<name>/SKILL.md existence → list partial matches if needed → offer Option A/B → preview changes → confirm before writing → update project CLAUDE.md registry), and rules including: duplicate detection, create Skills Registry section if absent, distinguish /skill-add from /skill-create

## Phase 3: CLAUDE.md Routing and Registry Updates

- [ ] 3.1 Modify `CLAUDE.md` — routing table (How I Execute Commands section): add row `/sdd-ff` → `~/.claude/skills/sdd-ff/SKILL.md`; add row `/sdd-new` → `~/.claude/skills/sdd-new/SKILL.md`; add row `/sdd-status` → `~/.claude/skills/sdd-status/SKILL.md`; update existing `/skill-add` row to point to `~/.claude/skills/skill-add/SKILL.md` instead of `skill-creator/SKILL.md`
- [ ] 3.2 Modify `CLAUDE.md` — Skills Registry section: add new subsection `### SDD Orchestrator Skills` (or equivalent) listing all four new skills with their paths and one-line descriptions

## Phase 4: Memory Update

- [ ] 4.1 Modify `ai-context/conventions.md` — add "Orchestrator skills" subsection under the SKILL.md structure conventions: note that `sdd-ff` and `sdd-new` use the Task tool directly and are first-class orchestrators; document when Task tool delegation inside a SKILL.md is appropriate vs. when it is not

## Phase 5: Verification and Cleanup

- [ ] 5.1 Verify all four SKILL.md files exist at their expected paths: `skills/sdd-ff/SKILL.md`, `skills/sdd-new/SKILL.md`, `skills/sdd-status/SKILL.md`, `skills/skill-add/SKILL.md`
- [ ] 5.2 Verify `CLAUDE.md` routing table contains all four new rows and that the `/skill-add` row is updated
- [ ] 5.3 Verify `ai-context/conventions.md` contains the new orchestrator skills subsection
- [ ] 5.4 Run `sync.sh` to propagate new skill directories to `~/.claude/skills/`
- [ ] 5.5 Smoke-test: confirm `ls ~/.claude/skills/sdd-ff/SKILL.md ~/.claude/skills/sdd-new/SKILL.md ~/.claude/skills/sdd-status/SKILL.md ~/.claude/skills/skill-add/SKILL.md` exits 0
- [ ] 5.6 Run `/project-audit` and confirm score is not lower than the pre-change baseline

---

## Implementation Notes

- Each SKILL.md must follow the established structure: trigger definition, process steps, rules section — all present
- `sdd-ff` and `sdd-new` embed the sub-agent delegation pattern from design.md "Interfaces and Contracts" section verbatim — do not paraphrase
- `sdd-ff` does NOT gate phases with user confirmation (fast-forward runs automatically); `sdd-new` DOES gate after propose and after spec+design (per spec)
- `sdd-status` is filesystem-only: never read git history or git status
- `skill-add` uses Option A (reference) as default; Option B (local copy) must be explicitly requested or chosen by the user
- `skill-add` must show a preview and ask for confirmation BEFORE any write operation
- CLAUDE.md modifications are purely additive (new rows + new registry entries); no existing content is removed or restructured
- After `sync.sh` the four new directories must be present under `~/.claude/skills/` for the smoke test to pass

## Blockers

None.
