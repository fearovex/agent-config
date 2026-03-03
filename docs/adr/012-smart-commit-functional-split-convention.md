# ADR-012: Smart Commit Functional Split Convention

## Status

Proposed

## Context

The `smart-commit` skill previously committed all staged files in one shot. When staged files span multiple functional directories or concern multiple commit types (e.g., feature code alongside docs, tests, and config), lumping them into a single commit violates the git best practice of one logical change per commit and produces semantic noise in the project history.

The change `smart-commit-functional-split` introduces a grouping heuristic that clusters staged files by functional area before generating commit messages. The grouping priority order — test files first, then docs, then config/infra, then directory prefix — was chosen to align with conventional commit type semantics (`test`, `docs`, `chore`, `feat`/`fix`/`refactor`). This ordering is a convention: it determines how the skill decides which files belong together and what commit type to assign, but it does not affect any cross-cutting infrastructure (no new files, no dependency changes, no hook modifications).

## Decision

We will use a priority-ordered, type-aligned grouping heuristic in `smart-commit` with the following fixed precedence: (1) test files by suffix pattern, (2) docs files by path/extension, (3) config/infra files by root-level extension, (4) remaining files by top-level directory prefix. This ordering is the canonical grouping convention for the smart-commit skill. Any future change to the grouping priority must update this ADR.

## Consequences

**Positive:**

- Grouping logic is deterministic and reviewable — the same staged set always produces the same groups.
- The convention mirrors conventional commit type semantics, making proposed messages easier to verify.
- The single-group fast-path preserves exact backward compatibility for focused, single-directory staged sets.

**Negative:**

- The heuristic is opinionated: a root-level file that logically belongs to a feature will be placed in the `chore` group unless the user edits the proposed message.
- The priority order cannot adapt to project-specific grouping preferences without a future configuration mechanism.
