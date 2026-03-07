# Project Skills Rewrite Roadmap

Date: 2026-03-06
Repository: `claude-config`
Scope: `project-audit`, `project-fix`, `project-claude-organizer`
Purpose: Turn the portfolio review into an actionable rewrite plan for the three highest-cost `project-*` skills.

## Executive Summary

The next step should be a controlled rewrite of three skills, not more incremental patching.

- `project-audit` needs a narrower contract and clearer modular boundaries.
- `project-fix` needs a simpler action model and a tighter relationship to the audit contract.
- `project-claude-organizer` needs aggressive scope reduction so it remains safe and understandable.

The goal is not to change the command surface first. The goal is to reduce internal complexity while preserving the user-facing commands.

## Key Diagnosis

### 1. `project-audit` is strategically central but specification-fragmented

`project-audit` currently distributes its contract across multiple spec domains:

- `openspec/specs/audit-execution/spec.md`
- `openspec/specs/audit-dimensions/spec.md`
- `openspec/specs/audit-scoring/spec.md`

That separation made incremental growth possible, but it also made the skill harder to reason about as one product. The skill has become the place where many policy exceptions accumulate.

### 2. `project-fix` is operationally valuable but action-heavy

`project-fix` remains the right idea: audit produces a spec, fix applies it. The problem is not the command. The problem is the size of the action vocabulary and the number of special-case handlers.

The current skill already has dedicated specs for behavior exceptions, including:

- `openspec/specs/project-fix-behavior/spec.md`
- `openspec/specs/fix-setup-behavior/spec.md`

That is a signal that the behavior surface is growing faster than the core model.

### 3. `project-claude-organizer` has the steepest maintenance curve

This skill has expanded from folder normalization into a broad migration engine with:

- documentation classification
- legacy-directory intelligence
- multiple migration strategies
- commands scaffolding
- local skills audit logic
- optional cleanup deletion flows

It solves a real problem, but too many edge cases are now first-class behavior.

## Rewrite Principles

These three rewrites should follow the same principles:

1. Preserve command names unless there is a compelling usability reason to change them.
2. Prefer fewer behavior classes over more heuristics.
3. Separate stable core behavior from transitional compatibility behavior.
4. Move passive analysis and recommendation logic out of mutation-heavy paths where possible.
5. Reduce the amount of policy encoded directly in one giant `SKILL.md`.

## Target State by Skill

## `project-audit`

### Keep

- Read-only behavior
- `audit-report.md` as canonical output artifact
- Role as spec producer for `project-fix`
- Relationship with `project-analyze`

### Rewrite goals

1. Define a compact audit kernel:
   - discovery
   - evaluation
   - report generation

2. Split dimension types explicitly:
   - scored dimensions
   - informational dimensions
   - compatibility checks

3. Reduce policy sprawl in the main skill body:
   - keep invariant rules in one place
   - move dimension-specific details to a smaller, more regular structure

4. Consolidate its spec story:
   - keep cross-cutting specs if needed
   - add a direct `project-audit` master spec or equivalent design artifact that describes the whole command as one product

### Desired outcome

`project-audit` should become easier to extend without every change increasing cognitive load across the whole file.

## `project-fix`

### Keep

- `audit-report.md` as input contract
- phase-oriented repair flow
- clear boundary that it does not invent fixes beyond the audit artifact

### Rewrite goals

1. Shrink the action taxonomy:
   - fewer action types
   - more predictable handler semantics

2. Separate actions into three groups:
   - safe automatic edits
   - guided edits that always require confirmation
   - informational recommendations with no side effects

3. Tighten compatibility handling:
   - keep support for stale manifests only where necessary
   - avoid carrying deprecated action types indefinitely

4. Reduce knowledge duplication with `project-audit`:
   - the audit defines what is wrong
   - the fix defines only how each action class is applied

### Desired outcome

`project-fix` should feel like a compact executor of a stable manifest schema, not a growing library of bespoke repair routines.

## `project-claude-organizer`

### Keep

- project `.claude/` scope only
- dry-run planning before mutation
- additive-first migration posture

### Rewrite goals

1. Narrow the core job to four stages:
   - detect
   - classify
   - propose
   - apply additive migrations

2. Remove edge-case policy from the core path:
   - treat unusual structures as manual-review outcomes
   - stop encoding every migration scenario as custom behavior

3. Separate safe moves from advisory output:
   - safe copy/append operations remain in scope
   - scaffolding, deletion, and ambiguous transforms should be explicit opt-in or advisory-only

4. Revisit whether local skills audit belongs here at all:
   - likely better as a separate audit concern than a folder-reorganization concern

### Desired outcome

`project-claude-organizer` should become a conservative migration assistant, not a generalized `.claude/` transformation engine.

## Recommended Sequence

The rewrite order should be:

1. `project-audit`
2. `project-fix`
3. `project-claude-organizer`

Reasoning:

- `project-audit` defines the diagnostic contract.
- `project-fix` should be rewritten against the stabilized audit contract.
- `project-claude-organizer` is more independent and can be narrowed after the audit/fix pair is stable.

## Suggested SDD Changes

If you want to execute this as proper SDD work, these are the natural change names:

1. `rewrite-project-audit-core`
2. `simplify-project-fix-action-model`
3. `narrow-project-claude-organizer-scope`

Each change should start with a small proposal and a design file before any edits to the skill bodies.

## Immediate Recommendation

Do not patch these three skills further in an ad hoc way unless it is a critical bug.

The highest-leverage next move is to start the first rewrite formally around `project-audit`, because it is the contract producer for the rest of the project-health workflow.