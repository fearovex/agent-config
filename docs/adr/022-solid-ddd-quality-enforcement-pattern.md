# ADR-022: Solid Ddd Quality Enforcement Pattern

## Status

Proposed

## Context

Technology skills in the SDD system (react-19, typescript, etc.) teach framework patterns but contain no SOLID or DDD principles. The `sdd-apply` skill's "Code Standards" section only gives sub-agents vague directives ("follow conventions", "no over-engineering") with no actionable checklist. A sub-agent can produce structurally unsound code — god classes, anemic domain models, violated SRP — and still mark a task complete, because there is no explicit quality gate anchored in the skill system. Code quality in SDD-driven projects therefore depends entirely on the sub-agent's default behavior, with no repeatable standard.

## Decision

We will introduce a `solid-ddd` reference skill as a language-agnostic catalog of SOLID principles and DDD tactical patterns, loaded unconditionally for all non-documentation code changes in `sdd-apply`. We will replace `sdd-apply`'s vague "Code Standards" section with a structured Quality Gate containing a 7-item numbered checklist that sub-agents must evaluate before marking any code task complete. Violations are reported as `QUALITY_VIOLATION` (non-blocking by default) or escalated to `DEVIATION` when they contradict the spec.

## Consequences

**Positive:**

- Every sdd-apply invocation on a code-touching change now has an explicit, repeatable quality standard anchored in the skill system
- The `solid-ddd` skill is language-agnostic and applicable across all project stacks without modification
- Quality violations are visible in sub-agent output, enabling trend detection over time
- The unconditional loading model eliminates the risk of the quality gate being silently skipped due to a missing stack keyword

**Negative:**

- Sub-agents processing trivial changes (config edits, single-line fixes) must evaluate and mark 7 checklist items as N/A — this adds token overhead
- The quality gate enforcement is knowledge-based, not automated; a sub-agent could still overlook a violation without tooling enforcement
- The `solid-ddd` skill body is loaded once per task batch, adding marginal token cost to every non-docs sdd-apply run
