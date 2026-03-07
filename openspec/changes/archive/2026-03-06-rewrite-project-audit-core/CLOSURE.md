# Closure: rewrite-project-audit-core

Start date: 2026-03-06
Close date: 2026-03-06

## Summary

Formalized `project-audit` as a product-level command by adding an explicit audit kernel, dimension classes, and compatibility policy to the live skill. Promoted a new `project-audit-core` master spec to complement the existing cross-cutting audit specs.

## Modified Specs

| Domain | Action | Change |
| ------ | ------ | ------ |
| `project-audit-core` | Created | New umbrella contract for the `project-audit` command |

## Modified Code Files

- `skills/project-audit/SKILL.md`
- `openspec/specs/project-audit-core/spec.md`

## Key Decisions Made

- `project-audit` now has an explicit three-stage kernel: discovery, evaluation, report generation.
- Scored and informational dimensions remain in the same skill, but their classes are now explicit.
- Compatibility behavior is documented as a separate policy layer instead of remaining implicit in scattered dimension wording.
- This change deliberately avoids rewriting the detailed logic of D1-D13 in the same cycle.

## Lessons Learned

- The highest-value first step in rewriting a large skill is often contractual clarity, not logic replacement.
- The repo needed a direct `project-audit` spec domain because the existing audit specs had become too fragmented to describe the command as one product.
- The validator warning about `format: procedural` remains a tooling mismatch and should not be confused with a regression in the repo contract.

## User Docs Reviewed

NO — the change does not affect user-facing command names or onboarding workflows.