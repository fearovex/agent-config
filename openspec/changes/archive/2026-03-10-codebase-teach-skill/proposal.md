# Proposal: codebase-teach-skill

Date: 2026-03-10
Status: Draft

## Intent

Create a new skill `codebase-teach` that analyzes the project's implementation logic and documentation coverage, then writes structured domain knowledge into `ai-context/features/` so that future SDD cycles operate with progressively deeper understanding of the codebase.

## Motivation

Currently, the AI has no mechanism to learn from the codebase over time. Each SDD cycle starts with minimal project context, and the `ai-context/` layer is populated only when explicitly triggered (`/memory-init`, `/memory-update`, `/project-analyze`). No skill specifically focuses on:

1. Whether the existing code logic is documented well enough for the AI to understand it
2. Whether `ai-context/features/` reflects the actual bounded contexts in the code
3. Teaching the AI what the project does so it improves over successive cycles

The consequence: the AI makes implementation decisions without understanding the business logic it is modifying, leading to regressions and misaligned outputs.

## Scope

### Included

- New skill `codebase-teach` that:
  1. Scans source files for bounded context patterns (feature directories, domain modules, service layers)
  2. For each detected bounded context: reads key files, extracts business rules, invariants, and data models
  3. Writes or updates `ai-context/features/<context>.md` with extracted knowledge
  4. Evaluates documentation coverage: what is documented vs. what exists in code
  5. Produces a `teach-report.md` with coverage metrics and gaps
- `codebase-teach` is intended to be run: after `/memory-init`, after significant feature additions, or when SDD quality is degrading
- Register `codebase-teach` in CLAUDE.md Skills Registry and meta-tools table
- Add `/codebase-teach` to CLAUDE.md Available Commands section

### Excluded

- Automatic triggering of `codebase-teach` from other skills (it is a manual command)
- Code generation or documentation writing beyond `ai-context/features/`
- Changes to `project-analyze`, `memory-init`, or `memory-update`

## Proposed Approach

### Process

```
STEP 1 — Scan bounded contexts:
  Read project directory structure. Identify feature/domain directories.
  Cross-reference with existing ai-context/features/ files.

STEP 2 — Per bounded context analysis:
  For each detected context:
    - Read 5-10 key implementation files (services, models, handlers)
    - Extract: business rules (explicit conditions), invariants (always-true assertions),
      data model summary (key entities and relationships), integration points (external calls)

STEP 3 — Write ai-context/features/<context>.md:
  Use feature-domain-expert skill format.
  Sections: Business Rules, Invariants, Data Model Summary,
  Integration Points, Decision Log, Known Gotchas.
  Use [auto-updated] marker on AI-generated sections.

STEP 4 — Coverage evaluation:
  Compare features found in code vs. features documented in ai-context/features/.
  Calculate: documented / total = coverage %.

STEP 5 — Produce teach-report.md:
  Coverage metrics, gap list, files read, sections written.
```

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/codebase-teach/SKILL.md` | New | High — new skill |
| `CLAUDE.md` | Modified | Low — registration and command entry |
| `ai-context/features/` | Written by skill | High — per project |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Extracted rules are incorrect or misleading | Medium | High | Use [auto-updated] marker; human review required before treating as authoritative |
| Large codebases exceed context limits | High | Medium | Configurable file sample per context (default 10); process contexts sequentially |
| Overlaps with `project-analyze` | Medium | Low | Clear boundary: `project-analyze` observes structure; `codebase-teach` extracts business logic |

## Success Criteria

- [ ] `skills/codebase-teach/SKILL.md` exists with valid format, Triggers, Process, Rules, Output sections
- [ ] Running `/codebase-teach` on a project with feature directories produces at least one `ai-context/features/<context>.md`
- [ ] `teach-report.md` is produced with coverage % and gap list
- [ ] Sections written by the skill use `[auto-updated]` marker
- [ ] `CLAUDE.md` registers the skill correctly
- [ ] `verify-report.md` has at least one [x] criterion checked
