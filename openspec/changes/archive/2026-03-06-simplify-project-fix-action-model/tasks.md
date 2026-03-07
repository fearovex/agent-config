# Task Plan: simplify-project-fix-action-model

Date: 2026-03-06
Design: openspec/changes/simplify-project-fix-action-model/design.md

## Progress: 6/6 tasks

## Phase 1: Contract Artifacts

- [x] 1.1 Create `openspec/changes/simplify-project-fix-action-model/proposal.md` with explicit scope, rollback plan, and measurable success criteria
- [x] 1.2 Create `openspec/changes/simplify-project-fix-action-model/specs/project-fix-action-model/spec.md` as the umbrella product contract for `project-fix`
- [x] 1.3 Create `openspec/changes/simplify-project-fix-action-model/design.md` with the rewrite strategy and concrete file matrix

## Phase 2: Core Rewrite

- [x] 2.1 Modify `skills/project-fix/SKILL.md` — add an explicit `## Execution Model` section describing manifest intake, phase execution, and final reporting
- [x] 2.2 Modify `skills/project-fix/SKILL.md` — add an explicit `## Action Classes` section separating automatic, guided, and informational actions
- [x] 2.3 Modify `skills/project-fix/SKILL.md` — add an explicit `## Compatibility Policy` section and clarify that unknown or deprecated action types never gain automatic side effects

## Phase 3: Verification and Closure

- [x] 3.1 Create `openspec/changes/simplify-project-fix-action-model/verify-report.md` verifying that the new contract sections exist and handler behavior remains present

---

## Implementation Notes

- Keep the rewrite additive and local near the top of `skills/project-fix/SKILL.md`
- Do not rewrite the internal logic of Phase 1-5 handlers in this change
- Preserve the audit-report prerequisite and the no-commands/no-global-write safeguards

## Blockers

None.