# Closure: simplify-project-fix-action-model

Start date: 2026-03-06
Close date: 2026-03-06

## Summary

Formalized `project-fix` as a product-level command by adding an explicit execution model, action classes, and compatibility policy to the live skill. Promoted a new `project-fix-action-model` master spec to complement the existing behavior-specific specs.

## Modified Specs

| Domain | Action | Change |
| ------ | ------ | ------ |
| `project-fix-action-model` | Created | New umbrella contract for the `project-fix` command |

## Modified Code Files

- `skills/project-fix/SKILL.md`
- `openspec/specs/project-fix-action-model/spec.md`

## Key Decisions Made

- `project-fix` now has an explicit three-stage execution model: manifest intake, phase execution, and final reporting.
- Actions are now classified explicitly as automatic, guided, or informational.
- Compatibility behavior is documented as a separate policy layer instead of remaining implicit in scattered handler text.
- Unknown or deprecated action types are explicitly downgraded to non-automatic behavior.
- This change deliberately avoids rewriting the internal logic of Phase 1-5 handlers in the same cycle.

## Lessons Learned

- The fix side of the audit/fix pair benefits from the same umbrella-contract treatment as the audit side.
- Making action classes explicit reduces ambiguity without requiring a large-scale handler rewrite.
- The existing behavior specs for `project-fix` remain useful, but they were not sufficient to explain the command as one product.

## User Docs Reviewed

NO — the change does not affect user-facing command names or onboarding workflows.