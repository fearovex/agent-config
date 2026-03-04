# Technical Design: solid-ddd-quality-enforcement

Date: 2026-03-04
Proposal: openspec/changes/solid-ddd-quality-enforcement/proposal.md

## General Approach

Create a new `reference` format skill `solid-ddd` that serves as a language-agnostic catalog of SOLID principles and DDD tactical patterns with concrete do/don't examples. Modify `sdd-apply` in two places: add an unconditional `solid-ddd` entry to the Stack-to-Skill Mapping Table (for all non-docs changes), and replace the vague "Code Standards" section with a structured Quality Gate containing a numbered checklist of 5–7 independently verifiable criteria that sub-agents must evaluate before marking any code task `[x]`. Register the new skill in the global `CLAUDE.md` Skills Registry under a new "Design Principles" section.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| `solid-ddd` skill format | `format: reference` — pattern catalog with `## Patterns` and `## Rules` | `format: procedural`, `format: anti-pattern` | The skill is a reference catalog (do/don't examples), not a procedure to follow step by step. `format: reference` is the established convention for technology and design pattern skills (react-19, typescript). Using `anti-pattern` would omit positive patterns. |
| Skill placement (global vs. local) | Global — `~/.claude/skills/solid-ddd/SKILL.md` | Project-local (`.claude/skills/`) | `solid-ddd` contains language-agnostic design principles that apply universally across all projects. Global placement follows the same convention as all other catalog skills. |
| `solid-ddd` loading trigger in sdd-apply | Unconditional for all non-documentation code changes (no keyword match required) | Keyword-based (`solid`, `ddd` in stack.md) | SOLID and DDD are universal design principles, not stack-specific. Keyword gating would make enforcement optional and miss most projects. The scope guard (docs-only exclusion) already handles the skip case correctly. |
| Quality Gate location in sdd-apply | New `## Quality Gate` subsection replacing the existing `## Code standards` section | Add checklist to an existing section, add a new Step 7, enforce in sdd-verify only | Replacing `## Code standards` is the minimal, surgical change — it retains the section heading hierarchy, and replacing "vague directives" with a concrete checklist is the exact intent of the proposal. Adding a new Step 7 would create process overhead for a quality check that should be atomic with task completion. |
| Quality Gate items count and scope | 7 criteria covering SRP, abstraction, dependency direction, domain model integrity, interface segregation, scope creep, and over-engineering | 3 items (too coarse), 10+ items (too heavyweight) | 7 items cover the cross-cutting quality concerns without becoming a lengthy audit. Each item is independently verifiable and maps to a specific SOLID or DDD principle. Items use N/A semantics to avoid rigidity on trivial tasks. |
| QUALITY_VIOLATION severity model | QUALITY_VIOLATION is non-blocking by default; escalates to DEVIATION when it contradicts the spec | Always blocking, always non-blocking | Matches the proposal's intent: prevent over-blocking while still surfacing quality issues. The distinction between "style violation" and "spec contradiction" follows the existing DEVIATION reporting pattern in sdd-apply. |
| Relationship with `hexagonal-architecture-java` skill | Explicit co-existence: `solid-ddd` covers language-agnostic DDD principles; `hexagonal-architecture-java` covers Java-specific Hexagonal Architecture implementation idioms. Both skills complement each other. | Merge into one skill, suppress one skill | Merging conflates universal principles with Java idioms. The two-skill model is the established convention (one principles skill + one technology-specific skill). The relationship is documented in `solid-ddd` to prevent confusion. |

## Data Flow

```
sdd-apply sub-agent invoked
        │
        ▼
Step 0: Scope guard check
  All files in design.md File Change Matrix have .md/.yaml extension?
  ├── YES → "Tech skill preload: skipped (documentation-only change)"
  │         (Note: SKILL.md authoring changes ARE .md but not doc-only)
  └── NO  → Stack detection (ai-context/stack.md or openspec/config.yaml)
               │
               ▼
           Stack-to-Skill Mapping Table
           ┌──────────────────────────────────────┐
           │ Framework skills matched by keyword  │
           │ solid-ddd: ALWAYS loaded for code    │
           │           changes (no keyword req.)  │
           └──────────────────────────────────────┘
               │
               ▼
           Skill files read into context
               │
               ▼
Step 4: Implement task
               │
               ▼
        Quality Gate (## Quality Gate in sdd-apply)
        ┌─────────────────────────────────────────────┐
        │ 1. Single Responsibility — check             │
        │ 2. Abstraction appropriateness — check       │
        │ 3. Dependency direction — check              │
        │ 4. Domain model integrity — check            │
        │ 5. Interface segregation — check             │
        │ 6. No scope creep — check                    │
        │ 7. No over-engineering — check               │
        │                                              │
        │ Each: PASS | FAIL → QUALITY_VIOLATION        │
        │              or N/A (with reason)            │
        └─────────────────────────────────────────────┘
               │
               ▼
        Task marked [x] in tasks.md
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/solid-ddd/SKILL.md` | Create (new directory + file) | New reference skill: SOLID principles + DDD tactical patterns, do/don't examples, anti-patterns section, relationship note with `hexagonal-architecture-java` |
| `skills/sdd-apply/SKILL.md` | Modify | (1) Add `solid-ddd` row to Stack-to-Skill Mapping Table; (2) Replace `## Code standards` section with `## Quality Gate` containing 7-item numbered checklist + QUALITY_VIOLATION reporting instruction |
| `CLAUDE.md` | Modify | Add `~/.claude/skills/solid-ddd/SKILL.md` entry under a new "Design Principles" section in the Skills Registry |

## Interfaces and Contracts

### solid-ddd SKILL.md structure (reference format)

```yaml
---
name: solid-ddd
description: >
  Language-agnostic SOLID principles and DDD tactical patterns.
  Trigger: Always loaded for non-documentation code changes via sdd-apply.
format: reference
---
```

Required sections (reference format contract):
- `**Triggers**` — when to use this skill
- `## Patterns` — SOLID + DDD patterns with do/don't examples
- `## Rules` — constraints and invariants

Optional companion sections:
- `## Anti-Patterns` — anti-pattern catalog (god class, anemic domain model, etc.)
- `## Relationship with Other Skills` — documents the co-existence with `hexagonal-architecture-java`

### sdd-apply Stack-to-Skill Mapping Table — new row

```
| (always for code changes) | `~/.claude/skills/solid-ddd/SKILL.md` |
```

Placement: at the end of the table, after all keyword-based rows. The parenthetical note "(always for code changes)" makes the unconditional trigger explicit without introducing new syntax.

### sdd-apply Quality Gate section — structure

```markdown
## Quality Gate

Before marking any code task `[x]`, I evaluate each criterion:

1. **Single Responsibility (SRP)**: Does each new/modified class, function, or module have exactly one reason to change? If a unit does more than one thing, I flag a QUALITY_VIOLATION.
2. **Abstraction appropriateness**: Are abstractions justified by actual reuse or testability need? Premature abstractions with no current consumer are QUALITY_VIOLATION.
3. **Dependency direction (DIP)**: Do high-level modules depend on abstractions, not concretions? Dependencies that point inward toward stable abstractions → PASS. Outward dependencies on volatile implementations → QUALITY_VIOLATION.
4. **Domain model integrity**: Is domain logic inside domain objects (entities, aggregates, value objects), not leaked into services or controllers? An anemic domain model is a QUALITY_VIOLATION.
5. **Interface segregation (ISP)**: Are interfaces and abstractions narrow — clients depend only on what they use? Fat interfaces that force no-op implementations are QUALITY_VIOLATION.
6. **No scope creep**: Does the implementation stay within the task's defined scope (tasks.md + design.md)? Features or files outside the scope → QUALITY_VIOLATION escalated to DEVIATION.
7. **No over-engineering**: Is the implementation the minimum necessary to satisfy the spec scenarios? Speculative abstractions, unused generics, or future-proofing not in the spec → QUALITY_VIOLATION.

**Reporting:**
- If a criterion does NOT apply to the task (e.g., no domain model touched → criterion 4 is N/A), mark it `N/A: [one-line reason]`.
- If a criterion FAILS: report `QUALITY_VIOLATION: [criterion number] — [description]`. Non-blocking by default.
- If the violation also contradicts the spec: escalate to `DEVIATION: [criterion number] — [description]`. Report `status: warning`.
```

### CLAUDE.md Skills Registry addition

```markdown
### Design Principles
- `~/.claude/skills/solid-ddd/SKILL.md` — language-agnostic SOLID and DDD tactical patterns; always loaded for non-documentation code changes via sdd-apply
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Structural | `solid-ddd/SKILL.md` has `format: reference`, `**Triggers**`, `## Patterns`, `## Rules`, body >= 30 lines | Manual inspection / `/project-audit` (P2-C check) |
| Structural | `sdd-apply/SKILL.md` Quality Gate section contains numbered list with >= 5 items | Manual inspection |
| Structural | `sdd-apply/SKILL.md` Stack-to-Skill Mapping Table includes `solid-ddd` row | Manual inspection |
| Structural | `CLAUDE.md` Skills Registry contains `solid-ddd` entry | Manual inspection |
| Integration | `install.sh` deploys both files to `~/.claude/skills/` without error | `bash install.sh` exit code 0 |
| Integration | `/project-audit` score on claude-config >= pre-change score | Run `/project-audit` and compare |

## Migration Plan

No data migration required. This change adds new files and modifies existing skill content. All changes are additive or surgical replacements within existing SKILL.md files. No database, schema, or existing runtime state is affected.

The git rollback plan (documented in the proposal) is sufficient for reverting: `git revert` or `git checkout <sha> -- skills/sdd-apply/SKILL.md skills/solid-ddd skills/CLAUDE.md`.

## Open Questions

- **Scope guard edge case**: The design.md File Change Matrix lists only `.md` files (SKILL.md, CLAUDE.md). The scope guard in `sdd-apply` Step 0 checks file extension — `.md` — and would trigger "documentation-only change", skipping the `solid-ddd` preload for this very change cycle. This is acceptable: the change is about skill content (`.md` files), and the solid-ddd quality gate applies to changes that produce *code*, not SKILL.md content. The sub-agent applying this change should understand that the quality gate is N/A for all criteria (no domain model, no dependency graph, no SRP concerns) — or the scope guard correctly identifies this as a docs-only change. No impact on quality; document as N/A with reason in apply phase.
