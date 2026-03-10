# Technical Design: 2026-03-10-codebase-teach-skill

Date: 2026-03-10
Proposal: openspec/changes/2026-03-10-codebase-teach-skill/proposal.md

---

## General Approach

`codebase-teach` is a new procedural skill that follows the existing meta-tool pattern:
one directory (`skills/codebase-teach/`), one `SKILL.md` entry point, registered in `CLAUDE.md`.
The skill executes a five-step analysis pipeline when invoked manually: scan bounded contexts,
read key files per context sequentially, write or update `ai-context/features/<context>.md` files
using the six-section `_template.md` format, evaluate coverage, and produce `teach-report.md`.
No existing skills are modified; the skill is fully isolated and shares state only via the
`ai-context/features/` files it writes.

---

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|----------------------|---------------|
| Skill format type | `procedural` (standard meta-tool pattern) | `reference` | The skill executes a multi-step process with ordered steps and guard clauses — not a reference catalog. Consistent with `memory-init`, `project-analyze`, and all other analysis meta-tools. |
| Context detection strategy | Directory name heuristics on `src/`, `app/`, `features/`, `domain/` at depth ≤ 2, cross-referenced with `openspec/specs/` subdirectory names | Full AST / import-graph analysis | AST analysis requires language-specific parsers not available in a pure Markdown skill. Directory heuristics are reliable for the feature-based and layer-based project patterns documented in `architecture.md`. Consistent with the approach in `project-analyze` Step 3 and `memory-init` Step 7.2. |
| File sample cap per context | Configurable integer, default 10; read from `openspec/config.yaml` key `teach_max_files_per_context` if present | Fixed limit of 5 or 20 | 10 is proven adequate by the `project-analyze` default of 20 for the entire project. Per-context cap prevents context window overflow on large codebases. Aligns with the risk mitigations in the proposal. |
| Sequential context processing | Process one bounded context at a time — read files, write feature file, then move to next context | Parallel processing | Sequential processing prevents context window saturation and maintains output coherence. Each context analysis is self-contained and does not benefit from parallelism in this skill's pattern. |
| Human-content preservation when updating existing feature files | Section-level `[auto-updated]` marker awareness — only overwrite sections bracketed by markers | Wholesale file replacement | Consistent with the established `[auto-updated]` marker convention already used by `project-analyze` in `ai-context/stack.md`, `ai-context/architecture.md`, and `ai-context/conventions.md`. Human-authored content outside markers MUST be preserved byte-for-byte. |
| `teach-report.md` output location | Project working directory root (same level as `analysis-report.md`) | `ai-context/` subdirectory | Meta-tool reports (audit-report.md, analysis-report.md) are written to project root by convention. Consistent placement; `teach-report.md` is a run-time artifact, not a durable memory file. |
| CLAUDE.md registration placement | `## Available Commands` > Meta-tools section; `## Skills Registry` > Meta-tool Skills subsection | New sub-section | Consistent with all existing meta-tools (memory-init, project-analyze, memory-update, etc.). No new pattern introduces unnecessary complexity. |
| Bounded context naming convention for feature file slug | kebab-case of the detected directory name (lowercased, spaces to hyphens) | Canonical slug inference | Mirrors the slug convention already in use: `ai-context/features/<domain>.md` where domain is derived from the directory name. Same as `memory-init` Step 7.4. |

---

## Data Flow

```
User invokes /codebase-teach
        |
        v
Step 0 — Load project context (non-blocking)
  read: ai-context/stack.md, ai-context/architecture.md, ai-context/conventions.md, CLAUDE.md Skills Registry
        |
        v
Step 1 — Scan bounded contexts
  read: project directory tree (depth ≤ 2 under src/, app/, features/, domain/ — or openspec/specs/ subdirs)
  cross-ref: existing ai-context/features/*.md (excluding _template.md and files starting with _)
  output: context_list = [{ slug, dir_path, existing_feature_file: bool }]
        |
        v
Step 2 — For each context (sequential)
  read: up to teach_max_files_per_context implementation files
         (services, models, handlers — prioritized by recency)
  extract:
    - Business rules (explicit conditional constraints)
    - Invariants (always-true assertions in domain logic)
    - Data model entities (struct/class names + key fields)
    - Integration points (imports of external services or APIs)
  output: context_knowledge = { slug, rules[], invariants[], entities[], integrations[], files_read[], skipped[] }
        |
        v
Step 3 — Write ai-context/features/<slug>.md
  IF file does not exist:
    create with all six sections, [auto-updated] markers on AI-generated sections
  IF file exists:
    read existing content → parse [auto-updated] blocks → overwrite only auto-updated sections
    preserve all human-authored content outside markers
        |
        v
Step 4 — Evaluate coverage
  coverage % = contexts with existing feature file (post-write) / total contexts detected
  gap_list  = contexts that still have no feature file after Step 3
        |
        v
Step 5 — Write teach-report.md
  sections: Summary, Coverage %, Gaps, Files read per context, Sections written/updated, Skipped files
```

---

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/codebase-teach/SKILL.md` | Create | New procedural skill — all five steps, Rules, Output sections |
| `CLAUDE.md` | Modify | Add `/codebase-teach` row in Available Commands (Meta-tools table); add skill entry in Skills Registry (Meta-tool Skills subsection) |

Files written at runtime (per project, not in the claude-config repo itself):

| Runtime File | Action | Trigger |
|---|---|---|
| `ai-context/features/<context>.md` | Create or update | Per detected bounded context during `/codebase-teach` run |
| `teach-report.md` | Create (overwrite on re-run) | At end of each `/codebase-teach` run |

---

## Interfaces and Contracts

### SKILL.md YAML frontmatter

```yaml
---
name: codebase-teach
description: >
  Analyzes project bounded contexts, extracts business rules and domain knowledge,
  writes ai-context/features/<context>.md files, and produces a teach-report.md
  with documentation coverage metrics.
  Trigger: /codebase-teach, teach codebase, extract domain knowledge, update feature docs.
format: procedural
---
```

### `openspec/config.yaml` optional key

```yaml
teach_max_files_per_context: 10   # default; overridable per project
```

### `teach-report.md` mandatory sections

```markdown
# Teach Report — [Project Name]

Last run: [YYYY-MM-DD]
Skill: codebase-teach

## Summary

Contexts detected: N
Contexts documented: M
Coverage: X%

## Coverage

[coverage % — documented / total]

## Gaps

Contexts detected in code but not documented in ai-context/features/:
- [context-slug] — [dir_path]

[If no gaps: "None — all detected contexts are documented."]

## Files Read

### [context-slug]
- [file path] (sampled)
- [file path] (sampled)
- [file path] — SKIPPED: [reason]

## Sections Written / Updated

- ai-context/features/[context].md — [created|updated] — sections: [list]
```

### `ai-context/features/<context>.md` [auto-updated] marker usage

```markdown
<!-- [auto-updated]: codebase-teach — last run: YYYY-MM-DD -->
## Business Rules and Invariants

[AI-extracted content]

<!-- [/auto-updated] -->
```

Sections following the append-only model (Decision Log, Known Gotchas) will use a scoped
auto-updated block that appends new entries below an existing `<!-- [auto-updated]: codebase-teach -->` marker rather than replacing the whole section. Human entries above the marker are preserved.

---

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual functional | Run `/codebase-teach` on `claude-config` repo — verify at least one `ai-context/features/<context>.md` is produced | Manual inspection |
| Manual structural | Verify `teach-report.md` exists with required sections: Summary, Coverage %, Gaps, Files Read, Sections Written | Manual inspection |
| Manual idempotency | Run `/codebase-teach` twice — verify second run produces the same content (no duplication of auto-updated sections) | Manual diff |
| Audit regression | Run `/project-audit` after install — verify score does not decrease; no MEDIUM/HIGH finding for codebase-teach | `/project-audit` |
| Boundary check | Verify `ai-context/stack.md`, `architecture.md`, `conventions.md`, `known-issues.md`, `changelog-ai.md` are untouched | `git diff` |

No automated test framework is applicable — this is a Markdown/YAML/Bash meta-system with no test runner. Validation is via manual inspection and `/project-audit` integration test per project conventions.

---

## Migration Plan

No data migration required. The skill is additive only:
- No existing files are modified by the `sdd-apply` implementation (only `skills/codebase-teach/SKILL.md` is created and `CLAUDE.md` is updated).
- `ai-context/features/` files are written only when the skill is explicitly invoked at runtime.

---

## Open Questions

None.

---
