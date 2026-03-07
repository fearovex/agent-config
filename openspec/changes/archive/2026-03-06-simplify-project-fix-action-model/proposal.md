# Proposal: simplify-project-fix-action-model

Date: 2026-03-06
Status: Draft

## Intent

Refactor the `project-fix` skill so its action model is explicit, grouped into stable classes, and easier to evolve without changing the command surface or existing safety guarantees.

## Motivation

`project-fix` remains operationally important, but its behavior is increasingly expressed through a growing set of specific handlers and special cases. The command still works, but the model is implicit:

- the difference between automatic, guided, and informational actions is not declared as one stable contract
- compatibility behavior is mixed into handler details
- the command feels like a list of routines rather than a compact executor of a manifest schema

The goal of this change is to simplify the contract, not to rewrite all fix handlers at once.

## Scope

### Included

- Define an explicit `project-fix` action model as a standalone spec domain
- Rework `skills/project-fix/SKILL.md` so the command declares its execution model, action classes, and compatibility policy explicitly
- Clarify that unknown or deprecated action types never trigger side effects automatically
- Preserve the current command name, audit-report prerequisite, phase-oriented flow, and existing core handlers

### Excluded (explicitly out of scope)

- Full redesign of all Phase 1-5 handlers
- Changing `project-audit` output schema in this change
- Rewriting `project-setup` or `project-analyze`
- Removing existing safeguards such as confirmation prompts and no-commands rules

## Proposed Approach

Create a new `project-fix-action-model` spec domain and update the live skill so its top-level contract is organized around:

1. execution model
2. action classes
3. compatibility policy

The detailed handler text remains largely intact, but the command becomes easier to reason about because the action taxonomy is explicit.

## Affected Areas

| Area/Module | Type of Change | Impact |
| ----------- | -------------- | ------ |
| `skills/project-fix/SKILL.md` | Modified | High |
| `openspec/changes/simplify-project-fix-action-model/specs/project-fix-action-model/spec.md` | New | Medium |
| `openspec/specs/project-fix-action-model/spec.md` | Created on archive | Medium |

## Risks

| Risk | Probability | Impact | Mitigation |
| ---- | ----------- | ------ | ---------- |
| New action-model wording contradicts existing handler details | Medium | Medium | Keep existing handlers intact and position the new sections as umbrella contract text |
| The new contract is too abstract to be useful for future edits | Medium | Low | Add concrete action classes and explicit behavior for unknown or deprecated actions |
| Reviewers assume this change already simplified every handler | Medium | Low | State explicitly in proposal, design, and closure that this is a contract rewrite, not a full handler rewrite |

## Rollback Plan

1. Restore `skills/project-fix/SKILL.md` to its pre-change version from git history.
2. Remove the new `project-fix-action-model` master spec if it proves redundant or confusing.
3. Re-run the portfolio review artifacts to confirm the previous contract structure is restored.

## Dependencies

- Existing `project-fix-behavior` and `fix-setup-behavior` specs remain valid detailed behavior specs
- No dependency on further `project-audit` changes for this phase
- No dependency on changes to `.claude/commands/` deprecation rules

## Success Criteria

- [ ] `skills/project-fix/SKILL.md` contains explicit sections for execution model, action classes, and compatibility policy
- [ ] `skills/project-fix/SKILL.md` explicitly groups actions into automatic, guided, and informational classes
- [ ] `skills/project-fix/SKILL.md` states that unknown or deprecated action types produce no automatic side effects
- [ ] A new `project-fix-action-model` spec domain exists and describes the command as one product

## Effort Estimate

Medium (1 day)