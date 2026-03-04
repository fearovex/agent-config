# Task Plan: solid-ddd-quality-enforcement

Date: 2026-03-04
Design: openspec/changes/solid-ddd-quality-enforcement/design.md

## Progress: 7/7 tasks

## Phase 1: New Skill — solid-ddd

- [x] 1.1 Create directory `skills/solid-ddd/` and file `skills/solid-ddd/SKILL.md` with `format: reference` frontmatter (`name: solid-ddd`), `**Triggers**` block, `## Patterns` section covering all five SOLID principles (SRP, OCP, LSP, ISP, DIP) each with at least one DO and one DON'T example, all required DDD tactical patterns (Entity, Value Object, Aggregate, Repository, Domain Service, Application Service) with distinguishing signals, `## Anti-Patterns` section covering God Class, Anemic Domain Model, and Service as God Object with detection signals and corrective direction, a `## Relationship with Other Skills` note documenting the co-existence with `hexagonal-architecture-java`, and `## Rules` section. Body MUST be >= 30 non-frontmatter lines.

## Phase 2: Modify sdd-apply — Stack-to-Skill Mapping Table

- [x] 2.1 Modify `skills/sdd-apply/SKILL.md`: add a new row at the end of the Stack-to-Skill Mapping Table under the existing keyword-based rows — `| (always for code changes) | ~/.claude/skills/solid-ddd/SKILL.md |` — and add a note below the table making explicit that this entry is unconditional (no keyword match required) and is subject to the same scope guard (skipped for documentation-only changes).

## Phase 3: Modify sdd-apply — Quality Gate

- [x] 3.1 Modify `skills/sdd-apply/SKILL.md`: replace the entire `## Code standards` section (lines from `## Code standards` through the end of that section, before `## Output to Orchestrator`) with a new `## Quality Gate` section. The new section MUST contain: (a) an introductory line stating the sub-agent evaluates each criterion before marking any code task `[x]`; (b) a numbered list of exactly 7 criteria — Single Responsibility (SRP), Abstraction appropriateness, Dependency direction (DIP), Domain model integrity, Interface segregation (ISP), No scope creep, No over-engineering — each with a concrete "what to look for" heuristic and a `QUALITY_VIOLATION` reporting instruction; (c) explicit N/A-with-reason documentation; (d) the QUALITY_VIOLATION format (`QUALITY_VIOLATION: <principle> — <description>`); (e) DEVIATION escalation rule for spec-contradicting violations; (f) overall `status: warning` rule when violations are non-contradicting; (g) a reference back to Step 0 for the skill loading mechanism (no inline re-listing of loading logic).

## Phase 4: Register solid-ddd in CLAUDE.md

- [x] 4.1 Modify `CLAUDE.md`: add a new `### Design Principles` section in the Skills Registry (after the existing technology/platform sections) containing the entry `- \`~/.claude/skills/solid-ddd/SKILL.md\` — language-agnostic SOLID and DDD tactical patterns; always loaded for non-documentation code changes via sdd-apply`.

## Phase 5: Verification and Deployment

- [x] 5.1 Verify `skills/solid-ddd/SKILL.md` structural compliance: confirm `format: reference` in frontmatter, `**Triggers**` present, `## Patterns` present, `## Rules` present, body line count >= 30; confirm all five SOLID principles and all six required DDD patterns are identifiable in the file.
- [x] 5.2 Verify `skills/sdd-apply/SKILL.md` modifications: confirm the Stack-to-Skill Mapping Table contains the `solid-ddd` unconditional row, the `## Code standards` section is fully replaced by `## Quality Gate`, the Quality Gate contains a numbered list with >= 5 items (target 7), each item has a concrete signal, N/A-with-reason is documented, and `QUALITY_VIOLATION` format is specified.
- [x] 5.3 Update `ai-context/changelog-ai.md` with a summary of the changes made in this apply cycle (solid-ddd skill created, sdd-apply Quality Gate added, CLAUDE.md registry updated).

---

## Implementation Notes

- **Skill creation order matters**: Task 1.1 (create `solid-ddd/SKILL.md`) MUST be completed before Task 2.1 (add it to sdd-apply's mapping table), so the referenced path is valid at apply time. Tasks 2.1 and 3.1 are independent of each other and may be done in either order after 1.1.
- **solid-ddd is language-agnostic**: No language-specific syntax in pattern descriptions. Code examples, if any, MUST be labeled with their language and framed as illustrative, not production code.
- **Scope guard edge case**: The File Change Matrix in design.md contains only `.md` files (SKILL.md, CLAUDE.md). The sdd-apply scope guard would classify this change as documentation-only and skip the solid-ddd preload — this is expected and correct. For all seven tasks, the Quality Gate criteria are N/A (no domain model, no dependency graph, no SRP concerns in SKILL.md content).
- **solid-ddd must NOT duplicate hexagonal-architecture-java**: The new skill covers language-agnostic DDD principles and SOLID. Java-specific Hexagonal Architecture implementation idioms remain exclusively in `hexagonal-architecture-java`. The relationship note (task 1.1) makes this explicit.
- **Quality Gate replaces, not supplements Code Standards**: The entire `## Code standards` section must be removed and replaced. Do not leave vague directives ("follow conventions", "no over-engineering" as standalone instructions) as the sole content of any quality criterion.
- **Numbered list format for Quality Gate**: The checklist MUST use a numbered list (not bullet points) so items can be referenced by number in QUALITY_VIOLATION notes.

## Blockers

None.
