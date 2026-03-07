# Technical Design: simplify-project-fix-action-model

Date: 2026-03-06
Proposal: openspec/changes/simplify-project-fix-action-model/proposal.md

## General Approach

The change introduces a stable top-level contract for `project-fix` without rewriting every existing phase handler. The implementation will add explicit sections near the top of `skills/project-fix/SKILL.md`: execution model, action classes, and compatibility policy. Existing phase and handler bodies stay largely intact, but the command becomes easier to understand because the action taxonomy is declared explicitly.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
| -------- | ------ | ---------------------- | ------------- |
| Product contract location | Add a new `project-fix-action-model` spec domain | Keep relying only on `project-fix-behavior` and `fix-setup-behavior` | `project-fix` needs one umbrella contract that describes the command as a whole product |
| Rewrite strategy | Add top-level contract sections and localized wording changes, preserve existing handlers | Full rewrite of Phase 1-5 handlers in one pass | This change must remain implementable and low-risk within one SDD cycle |
| Action taxonomy | Group actions into automatic, guided, and informational classes | Keep action classes implicit inside each handler | The current maintenance problem is partly caused by implicit action categories |
| Unknown action handling | Downgrade unknown or deprecated actions to non-automatic behavior | Attempt best-effort execution of unknown action types | Safety matters more than speculative recovery in a meta-tool that edits project configuration |

## Data Flow

```text
project-fix
  -> read audit-report.md
  -> classify actions
      -> automatic
      -> guided
      -> informational
  -> execute applicable phases
  -> write final summary and changelog
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/project-fix/SKILL.md` | Modify | Add `## Execution Model`, `## Action Classes`, and `## Compatibility Policy`; clarify non-automatic handling of unknown or deprecated action types |
| `openspec/changes/simplify-project-fix-action-model/specs/project-fix-action-model/spec.md` | Create | New umbrella spec for `project-fix` as one product-level command |

## Interfaces and Contracts

```text
project-fix action model
  - Execution Model: manifest intake -> phase execution -> final reporting
  - Action Classes: automatic | guided | informational
  - Compatibility Policy: stale, deprecated, and unknown actions never gain automatic side effects
```

## Testing Strategy

| Layer | What to test | Tool |
| ----- | ------------ | ---- |
| Structural review | Presence of new top-level sections in `skills/project-fix/SKILL.md` | File inspection |
| Contract review | Presence of new umbrella spec domain | File inspection |
| Regression review | Existing Phase 1-5 handlers still present | File inspection |

## Migration Plan

No data migration required.

## Open Questions

None.