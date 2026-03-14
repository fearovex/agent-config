# ADR-031: Orchestrator Classification Edge Cases Pattern

## Status

Proposed

## Context

The `Classification Decision Table` in `CLAUDE.md` defines how the orchestrator routes every user message into one of four intent classes (Meta-Command, Change Request, Exploration, Question). The table includes happy-path examples that demonstrate the most common, unambiguous inputs for each class. However, it does not address edge cases: implicit change intent expressed without explicit action verbs ("the login is broken"), investigative phrasing that superficially resembles a change directive ("check the auth module"), questions about broken behavior ("why does login fail?"), or single-word ambiguous inputs ("login"). Across independent sessions, these inputs have been classified inconsistently, undermining the goal of deterministic orchestrator behavior. The existing pattern for addressing classification ambiguity is to add inline `✓` / `✗` example lines directly in the decision table fenced code block — consistent with how all current happy-path examples are expressed. The alternative of extracting edge cases to a separate file or skill would require an additional file read during classification and would fragment the classification reference.

## Decision

We will extend the `Classification Decision Table` fenced code block in `CLAUDE.md` with at least 10 new edge-case examples, distributed across the Change Request, Exploration, and Question/Default branches. Each example follows the existing `✓ "<message>" → <Class>` or `✗ "<message>" → <Class>` format. The four categories covered are: (1) implicit change intent without explicit action verb, (2) investigative phrases that resemble but are not change directives, (3) questions about broken behavior, and (4) single-word ambiguous inputs. No new file, no new skill, and no structural change to the table are introduced.

## Consequences

**Positive:**

- Classification behavior becomes deterministic for the identified ambiguous input patterns
- Edge cases are co-located with the happy-path examples — no additional file read required at classification time
- The extension follows the exact existing convention, requiring zero new tooling or format changes

**Negative:**

- The decision table grows longer with each new edge-case batch; at a sufficiently large scale, a structured lookup mechanism (e.g., a dedicated classification skill) would be preferable to an inline fenced block
- Coverage remains example-based (not exhaustive); novel ambiguous inputs not in the table still depend on keyword heuristics
