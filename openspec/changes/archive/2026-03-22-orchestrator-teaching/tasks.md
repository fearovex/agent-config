# Task Plan: 2026-03-21-orchestrator-teaching

Date: 2026-03-21
Design: openspec/changes/2026-03-21-orchestrator-teaching/design.md

## Progress: 10/10 tasks

## Phase 1: Teaching Principles Foundation

- [x] 1.1 Modify `CLAUDE.md` — insert new `## Teaching Principles` section (5 numbered rules, max 15 lines) between `## Unbreakable Rules` and `## Plan Mode Rules` ✓
  Files: `CLAUDE.md` (MODIFY)
  Acceptance: Section exists with heading `## Teaching Principles`, contains exactly 5 numbered rules (why-framing, educational gates, error reformulation, post-cycle reflection, progressive disclosure), does not exceed 15 lines excluding heading

## Phase 2: Why-Framing in Change Request Classification

- [x] 2.1 Modify `CLAUDE.md` — add why-sentence template to Change Request classification response in the Classification Decision Table ✓
  Files: `CLAUDE.md` (MODIFY)
  Acceptance: Change Request routing action includes a why-sentence pattern: `I recommend /sdd-ff <slug> — [1 sentence explaining what risk the SDD cycle prevents]`; why-sentence does not appear in Question or Exploration routing

## Phase 3: Educational Gates

- [x] 3.1 Modify `CLAUDE.md` — add consequence sentence to Rule 7 removal confirmation template ✓
  Files: `CLAUDE.md` (MODIFY)
  Acceptance: Rule 7 confirmation pattern includes one appended sentence explaining the consequence being avoided; gate options and structure remain unchanged

- [x] 3.2 Modify `skills/sdd-ff/SKILL.md` — add consequence sentence to contradiction gate prompt (Step 2a) ✓
  Files: `skills/sdd-ff/SKILL.md` (MODIFY)
  Acceptance: Contradiction gate prompt includes one appended sentence explaining why contradictions are surfaced before proceeding; gate options (Yes/No/Review) remain unchanged

## Phase 4: Error Reformulation in sdd-ff

- [x] 4.1 Modify `skills/sdd-ff/SKILL.md` — add error reformulation pattern for blocked/failed sub-agent statuses after Steps 0, 1, 2, 3 ✓
  Files: `skills/sdd-ff/SKILL.md` (MODIFY)
  Acceptance: When a sub-agent returns `status: blocked` or `status: failed`, sdd-ff presents a reformulated message with structure: `⚠️ [Phase] returned [status]: [summary]. This happened because [cause]. To resolve it, [action].`; statuses `ok` and `warning` are not affected

## Phase 5: Post-Cycle Narrative in sdd-ff

- [x] 5.1 Modify `skills/sdd-ff/SKILL.md` — add narrative reflection paragraph to Step 4 summary template, after artifact list and before "Ready to implement?" prompt ✓
  Files: `skills/sdd-ff/SKILL.md` (MODIFY)
  Acceptance: Step 4 summary includes a 1-paragraph narrative after artifact list summarizing what was decided, specified, and what risks were mitigated; narrative references the specific change domain; narrative does not appear when cycle is incomplete (halted at gate or failure)

## Phase 6: Progressive Disclosure (New-User Detection)

- [x] 6.1 Modify `CLAUDE.md` — add new-user detection logic ✓ using `openspec/changes/archive/` directory listing (0 subdirectories = new user), with brief SDD context note prepended to first SDD-routed response per session
  Files: `CLAUDE.md` (MODIFY)
  Acceptance: Logic checks `openspec/changes/archive/` subdirectory count; if 0 or directory absent, a 2-3 sentence context note is prepended to the first Change Request or Exploration response; note appears once per session only; note does not appear on Questions; established projects (1+ archived changes) skip the note

## Phase 7: Spec Updates

- [x] 7.1 Modify `openspec/specs/orchestrator-behavior/spec.md` — merge delta spec requirements ✓ (why-framing, educational gates, new-user detection, conciseness constraints) into master spec
  Files: `openspec/specs/orchestrator-behavior/spec.md` (MODIFY)
  Acceptance: Master spec contains new requirements matching all scenarios from `openspec/changes/2026-03-21-orchestrator-teaching/specs/orchestrator-behavior/spec.md`; no existing requirements are altered or removed

## Phase 8: Cleanup and Documentation

- [x] 8.1 Modify `ai-context/architecture.md` — add architecture decision entry ✓ for teaching principles layer (decision number, summary, date, change reference)
  Files: `ai-context/architecture.md` (MODIFY)
  Acceptance: New numbered entry exists in `## Key architectural decisions` section documenting the teaching personality addition, its placement in CLAUDE.md, and scope (additive, no routing changes)

- [x] 8.2 Modify `ai-context/changelog-ai.md` — add changelog entry ✓ for teaching principles implementation
  Files: `ai-context/changelog-ai.md` (MODIFY)
  Acceptance: New entry with date and summary of changes made (CLAUDE.md Teaching Principles section, sdd-ff error reformulation, sdd-ff post-cycle narrative, new-user detection)

---

## Implementation Notes

- All changes are additive text template modifications — no routing logic, classification rules, or sub-agent execution patterns are changed
- The Teaching Principles section placement between Unbreakable Rules and Plan Mode Rules keeps behavioral directives grouped
- New-user detection uses `openspec/changes/archive/` directory listing (design decision), NOT `ai-context/changelog-ai.md` (proposal mentioned this but design resolved to archive directory)
- Error reformulation applies to sdd-ff only — phase skills return structured status codes and do not communicate directly with users
- Why-framing must be context-specific to the change domain, not a generic "SDD is good" statement
- Post-cycle narrative must not appear when the cycle is incomplete

## Blockers

None.
