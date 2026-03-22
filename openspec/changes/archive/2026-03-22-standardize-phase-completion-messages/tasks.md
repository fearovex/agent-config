# Task Plan: 2026-03-22-standardize-phase-completion-messages

Date: 2026-03-22
Design: openspec/changes/2026-03-22-standardize-phase-completion-messages/design.md

## Progress: 5/5 tasks

## Phase 1: Foundation — Audit and confirm no-change skills

- [x] 1.1 Read `skills/sdd-explore/SKILL.md` and confirm no command-as-gate completion prose exists (output JSON only)
- [x] 1.2 Read `skills/sdd-propose/SKILL.md`, `skills/sdd-spec/SKILL.md`, `skills/sdd-design/SKILL.md`, and `skills/sdd-tasks/SKILL.md` and confirm none contain command-as-gate prose completion messages

## Phase 2: Core — Replace command-as-gate messages with natural language gate pattern

- [x] 2.1 Modify `skills/sdd-new/SKILL.md` lines ~326-327 — replace:
  ```
  Ready to implement? Run:
    /sdd-apply [inferred-slug]
  ```
  With the canonical two-line template:
  ```
  Continue with implementation? Reply **yes** to proceed or **no** to pause.
  _(Manual: `/sdd-apply [inferred-slug]`)_
  ```
  Linked spec: Requirement: Natural language gate template (sdd-phase-completion-messages/spec.md)
  Acceptance: sdd-new completion block uses conversational gate; command appears as secondary reference

- [x] 2.2 Modify `skills/sdd-apply/SKILL.md` lines ~580-584 — replace:
  ```
  Implementation complete. Next step:
    /sdd-verify <change-name>  — verify against specs before committing
  ```
  With the canonical two-line template:
  ```
  Continue with verification? Reply **yes** to proceed or **no** to pause.
  _(Manual: `/sdd-verify <change-name>`)_
  ```
  Linked spec: Requirement: Natural language gate template (sdd-phase-completion-messages/spec.md)
  Acceptance: sdd-apply completion block uses conversational gate; command appears as secondary reference

- [x] 2.3 Modify `skills/sdd-verify/SKILL.md` — add natural language gate for sdd-archive transition in the Output to Orchestrator section or final prose area. The gate MUST read:
  ```
  Continue with archive? Reply **yes** to proceed or **no** to pause.
  _(Manual: `/sdd-archive <slug>`)_
  ```
  Linked spec: Scenario: sdd-verify completion message uses natural language gate
  Acceptance: sdd-verify output section includes conversational gate before or alongside next_recommended JSON; command is secondary

## Phase 3: Cleanup

- [x] 3.1 Update `ai-context/changelog-ai.md` — record that phase completion messages for sdd-new, sdd-apply, and sdd-verify have been standardized to natural language gates

---

## Implementation Notes

- The canonical template is: `Continue with <next phase>? Reply **yes** to proceed or **no** to pause.\n_(Manual: \`/sdd-<phase> <slug>\`)_`
- Phase names per skill: sdd-new → "implementation", sdd-apply → "verification", sdd-verify → "archive"
- sdd-ff Step 4 and sdd-new's existing confirmation gates MUST NOT be touched — they are already compliant
- The `next_recommended` JSON field in Output JSON blocks MUST NOT be changed — it is machine-readable for the orchestrator
- sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks all use JSON-only output — no prose gate exists in those files (confirmed by design.md File Change Matrix)
- Phase 1 tasks are read-only audits to confirm the design finding before applying changes

## Blockers

None.
