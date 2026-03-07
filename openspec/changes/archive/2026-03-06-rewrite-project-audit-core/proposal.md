# Proposal: rewrite-project-audit-core

Date: 2026-03-06
Status: Draft

## Intent

Refactor the `project-audit` skill so its core contract is explicit, stable, and easier to evolve without changing its command surface or current scoring behavior.

## Motivation

`project-audit` has become the central diagnostic command for project health, but its product contract is fragmented across multiple spec domains and a very large `SKILL.md` body. The current implementation still works, but the skill is carrying too much implicit structure:

- the audit kernel is not described as one stable model
- scored and informational dimensions are mixed together in one long flow
- compatibility behavior exists, but is not formalized as a distinct policy layer

That makes future changes harder to reason about and increases the risk of more append-only growth.

## Scope

### Included

- Define an explicit `project-audit` core contract as a standalone spec domain
- Rework `skills/project-audit/SKILL.md` so the audit kernel, dimension classes, and compatibility policy are explicit top-level sections
- Remove unstable count-based framing from the audit process header and replace it with a more durable structure
- Preserve the current command name, read-only behavior, output artifact, and scoring model

### Excluded (explicitly out of scope)

- Rewriting the detailed logic of every existing audit dimension
- Changing the numeric scoring model or FIX_MANIFEST schema
- Rewriting `project-fix` or `project-analyze`
- Merging or removing any `project-*` skill

## Proposed Approach

Create a new master spec domain for `project-audit` as one product, then update the live skill so the command is described in three stable layers:

1. audit kernel
2. dimension classes
3. compatibility policy

The change is structural and contractual, not behavioral. Existing detailed dimension rules remain in place, but the skill becomes easier to read and extend because its core model is explicit.

## Affected Areas

| Area/Module | Type of Change | Impact |
| ----------- | -------------- | ------ |
| `skills/project-audit/SKILL.md` | Modified | High |
| `openspec/changes/rewrite-project-audit-core/specs/project-audit-core/spec.md` | New | Medium |
| `openspec/specs/project-audit-core/spec.md` | Created on archive | Medium |

## Risks

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| Structural rewrite introduces contradictory wording with existing dimension sections | Medium | Medium | Keep detailed dimension bodies intact and only add top-level contract sections plus localized wording changes |
| The new core spec overlaps ambiguously with `audit-execution`, `audit-dimensions`, and `audit-scoring` | Medium | Medium | Define the new domain as the umbrella product contract and leave the older domains as cross-cutting detail specs |
| Future work assumes this change already simplified all dimension logic | Medium | Low | State explicitly in proposal, design, and closure that this is a core-contract rewrite, not a full logic rewrite |

## Rollback Plan

1. Restore `skills/project-audit/SKILL.md` to its pre-change version from git history.
2. Remove the new `project-audit-core` master spec if the contract proves confusing or redundant.
3. Re-run the repository review artifacts to confirm the prior structure is back in place.

## Dependencies

- Existing `project-audit` behavior specs remain the detailed source of truth for execution, dimensions, and scoring
- No dependency on `project-fix` changes for this phase
- No dependency on `project-analyze` changes for this phase

## Success Criteria

- [ ] `skills/project-audit/SKILL.md` contains explicit sections for audit kernel, dimension classes, and compatibility policy
- [ ] `skills/project-audit/SKILL.md` no longer uses a fragile numeric count in the main audit-process heading
- [ ] A new `project-audit-core` spec domain exists and describes the command as one product
- [ ] Existing detailed dimension behavior remains intact after the rewrite

## Effort Estimate

Medium (1 day)