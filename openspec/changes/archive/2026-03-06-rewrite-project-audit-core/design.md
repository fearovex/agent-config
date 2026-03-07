# Technical Design: rewrite-project-audit-core

Date: 2026-03-06
Proposal: openspec/changes/rewrite-project-audit-core/proposal.md

## General Approach

The change introduces a stable top-level contract for `project-audit` without rewriting the detailed logic of each dimension. The implementation will add three explicit sections near the top of `skills/project-audit/SKILL.md`: audit kernel, dimension classes, and compatibility policy. The current dimension bodies and report format stay largely intact, but the main process heading becomes count-free so future dimension additions do not immediately invalidate the skill's framing.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
| -------- | ------ | ---------------------- | ------------- |
| Product contract location | Add a new `project-audit-core` spec domain | Keep relying only on `audit-execution`, `audit-dimensions`, `audit-scoring` | `project-audit` needs one umbrella contract that describes the command as a whole product |
| Skill rewrite strategy | Add top-level structural sections and local wording fixes, preserve detailed dimension bodies | Full rewrite of all dimensions in one pass | This change must remain implementable and low-risk within one SDD cycle |
| Main process heading | Remove hardcoded dimension count | Update the count to a new number | Count-based framing is inherently brittle because D5 was removed and D10-D13 were added incrementally |
| Compatibility treatment | Describe compatibility as a policy layer | Continue letting compatibility rules remain implicit and scattered | The current maintenance problem is partly caused by compatibility behavior lacking a named contract |

## Data Flow

```text
Reader
  -> project-audit SKILL.md
      -> Audit Kernel
      -> Dimension Classes
      -> Compatibility Policy
      -> Detailed Dimension Rules
      -> Report Format
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/project-audit/SKILL.md` | Modify | Add explicit audit-kernel, dimension-classes, and compatibility-policy sections; replace fragile count-based heading; clarify transitional compatibility wording |
| `openspec/changes/rewrite-project-audit-core/specs/project-audit-core/spec.md` | Create | New umbrella spec for `project-audit` as one product-level command |

## Interfaces and Contracts

```text
project-audit core contract
  - Audit Kernel: discovery -> evaluation -> report generation
  - Dimension Classes: scored vs informational
  - Compatibility Policy: transitional behavior documented explicitly
```

## Testing Strategy

| Layer | What to test | Tool |
| ----- | ------------ | ---- |
| Structural review | Presence of new top-level sections in `skills/project-audit/SKILL.md` | File inspection |
| Contract review | Presence of new umbrella spec domain | File inspection |
| Regression review | Existing detailed dimension sections still present | File inspection |

## Migration Plan

No data migration required.

## Open Questions

None.