# ADR-013: Smart Commit Unstaged Detection Pattern

## Status

Proposed

## Context

The smart-commit skill applies a priority-ordered grouping heuristic (test → config/infra → docs → directory prefix → misc) to staged files before generating per-group conventional commit messages. The skill already collects `git status --porcelain` in Step 1 and already applies the grouping rules in Step 1b. When a developer forgets to stage files that are functionally related to what is already staged, the commit is executed with an incomplete picture and the unstaged files linger. The grouping heuristic is sufficiently well-defined that it can be applied symmetrically to unstaged files to produce actionable suggestions without requiring new conventions or new logic. The design reuses the existing build-artifact WARNING patterns from Step 3 as a pre-filter to suppress noise before surfacing suggestions.

## Decision

We will add a new Step 1d to the smart-commit skill that (1) reads unstaged candidates from the existing `git status --porcelain` output, (2) applies the Step 1b grouping heuristic verbatim to those candidates, (3) intersects the result with already-staged groups, and (4) surfaces a suggestion block only for groups that have both staged and unstaged members. Build-artifact filtering reuses the Step 3 WARNING patterns as a pre-filter. The suggestion step is entirely opt-in: declining all suggestions leaves the staged area and all downstream steps fully unchanged. No existing step is replaced or restructured.

## Consequences

**Positive:**

- Developers are prompted about related unstaged files at the most natural moment — before the commit plan is finalized — without any extra commands
- The suggestion is scoped to the developer's expressed intent (only groups already staged), preventing accidental widening of scope
- All logic reuses existing skill conventions (grouping heuristic, build-artifact patterns), keeping the skill internally consistent
- The feature is fully backward-compatible: if no unstaged candidates match, the new step exits silently

**Negative:**

- Step 1d adds length and conditional branching to the SKILL.md, increasing reading complexity
- The re-grouping check after `git add` introduces a rare but real edge case (new group appears) that requires an additional notification path
- The cap of 10 displayed files per group is a heuristic; edge cases with exactly 10 or 11 files may feel arbitrary to users
