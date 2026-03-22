# Task Plan: 2026-03-21-orchestrator-mandatory-new-session

Date: 2026-03-22
Design: openspec/changes/2026-03-21-orchestrator-mandatory-new-session/design.md

## Progress: 8/8 tasks

## Phase 1: Removals and Replacements

- [x] 1.1 Remove old: Rule 6 opt-in trigger text from `CLAUDE.md`
  Linked spec: Requirement: Rule 6 — Cross-session ff handoff (context-aware heuristic)
  Files: `CLAUDE.md` (MODIFY — remove "new session", "next chat", "context reset", "compaction imminent" opt-in trigger text from Rule 6 body)
  Acceptance: Rule 6 body no longer references explicit user language triggers; no dangling references elsewhere in CLAUDE.md

- [x] 1.2 Remove old: command-as-gate prompt text from `skills/sdd-ff/SKILL.md` Step 4
  Linked spec: Requirement: sdd-ff Step 4 — ask-before-apply gate uses natural language
  Files: `skills/sdd-ff/SKILL.md` (MODIFY — remove or replace "Ready to implement? Run: `/sdd-apply <slug>`" primary prompt at Step 4)
  Acceptance: Old command-as-gate pattern is fully removed; no remaining "Run: /sdd-apply" as sole primary prompt at Step 4

---
⚠️ Phase 2 MUST NOT begin until all Phase 1 tasks are complete.
---

## Phase 2: Implementations

- [x] 2.1 Implement new: context-aware two-branch heuristic in `CLAUDE.md` Rule 6
  Linked spec: Requirement: Rule 6 — Cross-session ff handoff (context-aware heuristic)
  Depends on: 1.1
  Files: `CLAUDE.md` (MODIFY — rewrite Rule 6 body with Branch A / Branch B heuristic, proposal creation step, /memory-update offer)
  Acceptance: Rule 6 contains Branch A (≥5 messages → create proposal.md + recommend new session + offer /memory-update) and Branch B (clean session → proceed inline); wording matches design.md interface contract

- [x] 2.2 Implement new: natural language confirmation gate in `skills/sdd-ff/SKILL.md` Step 4
  Linked spec: Requirement: sdd-ff Step 4 — ask-before-apply gate uses natural language
  Depends on: 1.2
  Files: `skills/sdd-ff/SKILL.md` (MODIFY — replace Step 4 prompt with "Continue with implementation? Reply **yes** to proceed." and add secondary "(Manual: /sdd-apply [slug])" reference)
  Acceptance: Step 4 prompt reads as natural language question; slash command appears only as optional manual reference; "yes" / affirmatives listed as valid replies

- [x] 2.3 Append new requirements to `openspec/specs/orchestrator-behavior/spec.md`
  Linked spec: Delta spec at openspec/changes/2026-03-21-orchestrator-mandatory-new-session/specs/orchestrator-behavior/spec.md
  Files: `openspec/specs/orchestrator-behavior/spec.md` (MODIFY — append REQ for context-aware session handoff heuristic with scenarios from delta spec)
  Acceptance: Base spec contains the two new requirements (context-aware handoff + natural language gate); scenarios match those in the delta spec file

- [x] 2.4 Append modified/new requirements to `openspec/specs/sdd-orchestration/spec.md`
  Linked spec: Delta spec at openspec/changes/2026-03-21-orchestrator-mandatory-new-session/specs/sdd-orchestration/spec.md
  Files: `openspec/specs/sdd-orchestration/spec.md` (MODIFY — append or update REQ for sdd-ff Step 4 natural language gate with scenarios from delta spec)
  Acceptance: Base spec reflects the updated sdd-ff Step 4 gate behavior; old "Run: /sdd-apply" requirement is superseded or annotated

## Phase 3: Verification

- [x] 3.1 Verify scenario coverage against both delta specs
  Files: `openspec/changes/2026-03-21-orchestrator-mandatory-new-session/specs/orchestrator-behavior/spec.md`, `openspec/changes/2026-03-21-orchestrator-mandatory-new-session/specs/sdd-orchestration/spec.md` (READ — cross-check that all GIVEN/WHEN/THEN scenarios are addressed by tasks 2.1–2.4)
  Acceptance: Each scenario in both delta specs maps to at least one completed task; no scenario left uncovered

- [x] 3.2 Run `/project-audit` to confirm CLAUDE.md, spec files, and SKILL.md are internally consistent
  Files: `CLAUDE.md`, `openspec/specs/orchestrator-behavior/spec.md`, `openspec/specs/sdd-orchestration/spec.md`, `skills/sdd-ff/SKILL.md` (AUDIT)
  Acceptance: No structural violations reported by project-audit

## Phase 4: Cleanup

- [x] 4.1 Update `ai-context/changelog-ai.md` to record this change
  Files: `ai-context/changelog-ai.md` (MODIFY — add session entry for 2026-03-22 describing Rule 6 heuristic replacement and sdd-ff Step 4 natural language gate)
  Acceptance: Changelog entry present with date, affected files, and short description of what changed

---

## Implementation Notes

- All changes are text-only edits in existing files — no new files, no new skills, no data migration
- CLAUDE.md Rule 6 replacement text is specified verbatim in `design.md` — implementer should use that exact wording
- The `sdd-ff/SKILL.md` change affects Step 4 only; all other steps are unchanged
- The delta spec files (under `openspec/changes/.../specs/`) are the authoritative source for what text to append to the base specs; copy/adapt from there
- The heuristic threshold (~5 messages) is advisory — it must be stated as such in the rewritten Rule 6

## Blockers

None.
