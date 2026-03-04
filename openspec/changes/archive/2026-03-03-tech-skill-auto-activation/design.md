# Technical Design: tech-skill-auto-activation

Date: 2026-03-03
Proposal: openspec/changes/tech-skill-auto-activation/proposal.md

## General Approach

Insert a new **Step 0 — Technology Skill Preload** at the top of the `## Process` section in `skills/sdd-apply/SKILL.md`. The step reads `ai-context/stack.md`, extracts technology keywords, matches them against an inline Stack-to-Skill Mapping Table, and reads matching skill files to inject them as implementation context. The step is non-blocking and self-contained within a single SKILL.md file. No external configuration file is added or required.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Mapping table location | Inline in `sdd-apply/SKILL.md` | Separate config in `openspec/config.yaml`; separate mapping file | Self-contained is the system convention — skills communicate via artifacts, not shared mutable config. Embedding the table means no external dependency; the skill is deployable in isolation. `openspec/config.yaml` is project-specific and would require every project to maintain its own copy. |
| Detection primary source | `ai-context/stack.md` | `openspec/config.yaml` alone; CLAUDE.md parsing | `stack.md` is the canonical tech stack record for a project (per memory layer convention). It is human-readable, free-form, and already expected to contain technology names. `openspec/config.yaml` `project.stack` is secondary to cover projects that have config but no memory layer yet. |
| Keyword matching strategy | Case-insensitive substring match | Exact match; regex | Substring matching is robust to variation (`"React 19"` still matches `"react"`). Regex adds complexity with no benefit for this use case. Exact match would miss version-annotated entries. |
| Scope guard trigger | File-extension analysis of design.md file change matrix | Always run; flag in config | The design.md file matrix is already available in memory at apply time. Checking for `.md`/`.yaml`-only extensions is reliable and requires no extra configuration. |
| Blocking behavior | Non-blocking (all failure modes degrade to INFO or skip) | Blocking on missing stack.md | Consistency with TDD detection (Step 2), which is also non-blocking. Missing files are normal in projects that have not run memory-init. |
| Placement in Process | Before Step 1 (read context) | After Step 1; within Step 4 (implement) | Technology context must be available before the implementer reads specs and design. If loaded after Step 1, the skill content may not influence convention interpretation. Loading inside Step 4 would be too late and inconsistent across tasks. |

## Data Flow

```
sdd-apply sub-agent starts
         │
         ▼
Step 0 — Technology Skill Preload
         │
         ├─ Read design.md file change matrix
         │   └─ ALL files .md/.yaml only? → skip preload (scope guard)
         │
         ├─ Read ai-context/stack.md
         │   └─ Not found? → try openspec/config.yaml project.stack
         │       └─ Also not found? → skip preload (INFO note)
         │
         ├─ Extract technology keywords (lowercase, free text)
         │
         ├─ Match against inline Stack-to-Skill Mapping Table
         │   └─ For each match:
         │       ├─ File exists at ~/.claude/skills/<skill>/SKILL.md?
         │       │   ├─ YES → read file, add to context
         │       │   │        report: "Tech skill loaded: <skill>"
         │       │   └─ NO  → skip silently (or note in report)
         │
         └─ Produce detection report
                  │
                  ▼
Step 1 — Read full context (with tech skill context now available)
         │
         ▼
Step 2 — Detect Implementation Mode (TDD)
         │
         ▼
... (existing steps unchanged)
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/sdd-apply/SKILL.md` | Modify | Add Step 0 block before Step 1; add Stack-to-Skill Mapping Table; update `## Code standards` forward reference |

## Interfaces and Contracts

### Stack-to-Skill Mapping Table (embedded in sdd-apply/SKILL.md)

The table maps lowercase keyword substrings to skill directory names:

```
| Keyword(s)                        | Skill directory           |
|-----------------------------------|---------------------------|
| react                             | react-19                  |
| next, nextjs, next.js             | nextjs-15                 |
| typescript, ts                    | typescript                |
| zustand                           | zustand-5                 |
| zod                               | zod-4                     |
| tailwind                          | tailwind-4                |
| ai sdk, vercel ai, ai-sdk         | ai-sdk-5                  |
| react native, expo                | react-native              |
| electron                          | electron                  |
| django, drf                       | django-drf                |
| spring boot, spring-boot          | spring-boot-3             |
| hexagonal, ports and adapters     | hexagonal-architecture-java |
| java                              | java-21                   |
| playwright                        | playwright                |
| pytest, python test               | pytest                    |
| github pr, pull request           | github-pr                 |
| jira task                         | jira-task                 |
| jira epic                         | jira-epic                 |
| elixir                            | elixir-antipatterns       |
| excel, xlsx, spreadsheet          | excel-expert              |
| ocr, image text, image ocr        | image-ocr                 |
```

Skill path template: `~/.claude/skills/<skill-directory>/SKILL.md`

### Detection Report Format

```
Tech skill preload:
  - <skill-name> loaded (source: ai-context/stack.md)
  - <skill-name> loaded (source: openspec/config.yaml)
  - <skill-name>: skipped (file not found at ~/.claude/skills/<skill-name>/SKILL.md)

[or, if entire step skipped:]
Tech skill preload: skipped (ai-context/stack.md not found)
Tech skill preload: skipped (documentation-only change)
```

### Scope Guard Logic

```
scope_guard_triggered = true
for each file in design.md file change matrix:
    if file extension not in [".md", ".yaml", ".yml"]:
        scope_guard_triggered = false
        break
if scope_guard_triggered:
    skip Step 0 entirely
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual / integration | Apply a change to a TypeScript project — verify detection report lists `typescript` | /project-audit on real test project |
| Manual / integration | Apply a documentation-only change — verify scope guard fires | Ad hoc SDD cycle on claude-config itself |
| Manual / integration | Apply with no `ai-context/stack.md` — verify non-blocking skip | Ad hoc test |

No automated unit tests apply to SKILL.md (Markdown instructions, not executable code).

## Migration Plan

No data migration required. The change is a Markdown file edit. Deployment is `bash install.sh` after editing `skills/sdd-apply/SKILL.md` in the repo.

## Open Questions

None. The design is complete based on the proposal scope and existing architectural patterns.

---

## ADR Note

The decision to embed the Stack-to-Skill Mapping Table inline in `sdd-apply/SKILL.md` rather than in a shared config file introduces a **cross-cutting convention**: any new technology skill added to the catalog MUST also add a row to the mapping table in `sdd-apply/SKILL.md`. This is a system-wide convention that warrants an ADR (see `docs/adr/017-tech-skill-mapping-table-inline-convention.md`).
