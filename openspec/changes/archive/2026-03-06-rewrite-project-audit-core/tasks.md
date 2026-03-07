# Task Plan: rewrite-project-audit-core

Date: 2026-03-06
Design: openspec/changes/rewrite-project-audit-core/design.md

## Progress: 6/6 tasks

## Phase 1: Contract Artifacts

- [x] 1.1 Create `openspec/changes/rewrite-project-audit-core/proposal.md` with explicit scope, rollback plan, and measurable success criteria
- [x] 1.2 Create `openspec/changes/rewrite-project-audit-core/specs/project-audit-core/spec.md` as the umbrella product contract for `project-audit`
- [x] 1.3 Create `openspec/changes/rewrite-project-audit-core/design.md` with the rewrite strategy and concrete file matrix

## Phase 2: Core Rewrite

- [x] 2.1 Modify `skills/project-audit/SKILL.md` — add an explicit `## Audit Kernel` section describing discovery, evaluation, and report generation
- [x] 2.2 Modify `skills/project-audit/SKILL.md` — add an explicit `## Dimension Classes` section separating scored dimensions from informational dimensions
- [x] 2.3 Modify `skills/project-audit/SKILL.md` — add an explicit `## Compatibility Policy` section and replace the hardcoded count-based audit-process heading with a durable heading

## Phase 3: Verification and Closure

- [x] 3.1 Create `openspec/changes/rewrite-project-audit-core/verify-report.md` verifying that the new contract sections exist and detailed dimension behavior remains present

---

## Implementation Notes

- Keep the rewrite additive and local near the top of `skills/project-audit/SKILL.md`
- Do not rewrite the internal logic of D1-D13 in this change
- Preserve the report format and FIX_MANIFEST schema

## Blockers

None.