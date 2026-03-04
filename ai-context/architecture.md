# Architecture — claude-config

> Last updated: 2026-03-03

## System role

`claude-config` is the global brain of Claude Code. It defines:
1. **How Claude orchestrates** — the SDD workflow, delegation patterns, phase DAG
2. **What Claude knows** — skill catalog covering SDD phases, meta-tools, tech stacks
3. **How projects are managed** — setup, audit, fix, update lifecycle

## Two-layer architecture

```
claude-config (repo)          ~/.claude/ (runtime)
      │                              │
      ├── CLAUDE.md    ──install──►  ├── CLAUDE.md       ← Claude reads at session start
      ├── skills/      ──install──►  ├── skills/          ← Claude reads on demand
      ├── settings.json ─install──►  ├── settings.json    ← Claude Code config
      ├── hooks/       ──install──►  ├── hooks/           ← Event hooks
      ├── openspec/    ──install──►  ├── openspec/        ← SDD artifacts
      ├── ai-context/  ──install──►  ├── ai-context/      ← Project memory
      └── memory/      ──install──►  └── memory/          ← User memory snapshot
                            ◄──sync────  (memory/ only — Claude writes here during sessions)
```

- `install.sh` : repo/ → ~/.claude/  (all directories — the deploy operation)
- `sync.sh`    : ~/.claude/memory/ → repo/memory/  (memory only — periodic capture)

## Skill architecture

Every skill is a directory with a `SKILL.md` entry point:

```
skills/
└── skill-name/
    └── SKILL.md       # Instructions Claude reads and executes
```

A SKILL.md must contain (authoritative contract: `docs/format-types.md`):
- **Trigger definition** — when to use this skill
- **Format-specific main section** — depends on the `format:` frontmatter field:
  - `procedural` (default): `## Process` — step-by-step instructions
  - `reference`: `## Patterns` or `## Examples` — technology patterns and code examples
  - `anti-pattern`: `## Anti-patterns` — catalog of bad practices with fixes
- **Rules** — constraints and invariants

### Skill format type system

Every `SKILL.md` declares its structural type via the `format:` YAML frontmatter field:

```yaml
---
name: react-19
description: >
  React 19 patterns with React Compiler...
format: reference   # valid values: procedural | reference | anti-pattern
---
```

| `format:` value | Required main section | Used for |
|-----------------|----------------------|---------|
| `procedural` (default when absent) | `## Process` | SDD phases, meta-tools, orchestrators |
| `reference` | `## Patterns` or `## Examples` | Technology and library skills |
| `anti-pattern` | `## Anti-patterns` | Anti-pattern catalog skills |

- Absent `format:` defaults to `procedural` (backwards-compatible).
- Unrecognized values default to `procedural` with an INFO audit finding.
- `project-audit` D4b and D9-3 validate structural compliance per declared format.
- `project-fix` Phase 5.3 generates format-correct stub sections.
- `skill-creator` Step 1b prompts for format and generates the matching skeleton.

## SDD meta-cycle (applied to this repo itself)

Any change to a skill or the global CLAUDE.md must go through:

```
/sdd-ff <change-name>   →   review   →   /sdd-apply   →   install.sh + git commit
```

Fast-forward is the minimum cycle. For breaking changes to core skills (orchestrator, SDD phases), full cycle is required.

## Communication between skills via artifacts

Skills that need to pass state to each other use **file artifacts**:

| Artifact | Producer | Consumer | Location |
|----------|---------|---------|----------|
| `audit-report.md` | project-audit | project-fix | `.claude/audit-report.md` in project |
| `analysis-report.md` | project-analyze | project-audit (D7), user | project root |
| `openspec/config.yaml` | project-setup / project-fix | all SDD phases | `openspec/` in project — also contains the optional `feature_docs:` top-level key (config-driven detection source for D10); when absent, project-audit falls back to heuristic detection |
| `openspec/changes/*/proposal.md` | sdd-propose | sdd-spec, sdd-design | `openspec/changes/<name>/` |
| `openspec/changes/*/tasks.md` | sdd-tasks | sdd-apply | `openspec/changes/<name>/` |
| `ai-context/*.md` | memory-init / memory-update / project-fix | all skills | `ai-context/` in project |
| `ai-context/onboarding.md` | (human / project-fix) | humans / new project sessions | `ai-context/` in project — canonical external project onboarding sequence |
| `ai-context/scenarios.md` | (human / project-onboard) | humans / new project sessions | `ai-context/` in project — 6-case onboarding guide, case-based entry point for users at different project states |
| `ai-context/quick-reference.md` | (human) | humans | `ai-context/` in project — single-page SDD quick reference: situation table, command glossary, flow diagram |
| `skills/project-onboard/SKILL.md` | SDD cycle | Claude at session start / on demand | `~/.claude/skills/project-onboard/` — automated project state diagnostic, triggered by `/project-onboard` |
| `~/.claude/skills/memory-update/SKILL.md` | (read by sdd-archive Step 6) | sdd-archive sub-agent | `~/.claude/skills/memory-update/` — auto-invoked inline by sdd-archive after successful archive; non-blocking (archive success is independent of memory-update outcome) |
| `docs/templates/prd-template.md` | proposal-prd-and-adr-system SDD cycle | humans / Claude sessions starting product-level changes | `docs/templates/` — optional PRD template; feeds into `proposal.md`, not a replacement |
| `docs/templates/adr-template.md` | proposal-prd-and-adr-system SDD cycle | humans adding new ADRs | `docs/templates/` — Nygard format ADR template |
| `docs/adr/README.md` + `docs/adr/NNN-*.md` | proposal-prd-and-adr-system SDD cycle | humans / Claude sessions making architectural decisions | `docs/adr/` — ADR index + individual decision records; must be updated when new ADRs are added |
| `openspec/changes/*/prd.md` | sdd-propose (Step 5, optional) | humans / product-level change authors | `openspec/changes/<name>/` — auto-created shell when `docs/templates/prd-template.md` exists and no `prd.md` is present; idempotent (never overwrites existing file); non-blocking if template absent |
| `docs/adr/NNN-<slug>.md` | sdd-design (Step 5, optional) | humans / architecture reviewers | `docs/adr/` — auto-created when Technical Decisions table in `design.md` contains a keyword-significant architectural decision; numbering via filesystem count; non-blocking if template or README.md absent |
| `~/.claude/claude-folder-audit-report.md` | claude-folder-audit (runtime artifact, never committed) | humans / operators | `~/.claude/` — generated on each `/claude-folder-audit` invocation; overwritten on re-run; contains findings with HIGH/MEDIUM/LOW/INFO severity; includes Findings Summary table, per-check detail sections, and Recommended Next Steps |
| `claude-organizer-report.md` | project-claude-organizer (runtime artifact, never committed) | humans / operators | `.claude/claude-organizer-report.md` in the target project — generated on each `/project-claude-organizer` invocation; overwritten on re-run; contains plan executed (items created, documentation files copied to ai-context/, unexpected items flagged, items already correct) and recommended next steps |
| `docs/adr/` (D12 — ADR Coverage) | N/A (human-maintained) | project-audit (D12) | `docs/adr/` — informational audit dimension; no score impact. Checks `README.md` existence (HIGH finding if absent) and each `docs/adr/NNN-*.md` for a `## Status` section (MEDIUM finding per ADR missing Status). Activated only when CLAUDE.md references `docs/adr/`; skipped with "N/A" when no reference found. Findings placed in `required_actions` and are actionable by `/project-fix`. |
| `openspec/specs/` (D13 — Spec Coverage) | sdd-spec | project-audit (D13) | `openspec/specs/` — informational audit dimension; no score impact. Activated when `openspec/specs/` exists and is non-empty. Checks each domain directory for a `spec.md` (MEDIUM finding per missing file) and scans referenced paths in each spec for existence (INFO finding per stale path, added to `violations[]` only). Skipped with "N/A" when directory is absent or empty. Findings placed in `required_actions` and are actionable by `/project-fix`. |
| `ai-context/features/*.md` | `memory-init` (scaffold on first run) / `memory-update` (session updates) / human authors | `sdd-propose` (Step 0, optional), `sdd-spec` (Step 0, optional) | `ai-context/features/` in project | `project-analyze` does NOT write to `ai-context/features/`; `_template.md` is never loaded by SDD phases |

## Key architectural decisions

1. **Skills are directories, not files** — allows co-locating templates, examples, or sub-skills
2. **SKILL.md is the convention** — every skill directory has exactly one entry point named `SKILL.md`
3. **Artifacts over in-memory state** — skills communicate via files, never via conversation context alone
4. **Orchestrator delegates everything** — the global CLAUDE.md never executes work itself, always spawns subagents via Task tool
5. **install.sh is repo-authoritative** — all directories flow repo → ~/.claude/. The only reverse direction is `sync.sh`, which captures `memory/` only. Every other directory (skills/, CLAUDE.md, hooks/, openspec/, ai-context/) must always be edited in the repo — never in ~/.claude/ directly.
8. **sdd-apply enforces a structured Quality Gate before task completion** (added 2026-03-04, change: solid-ddd-quality-enforcement) — The vague "Code Standards" section in `sdd-apply` is replaced by a 7-item numbered Quality Gate (SRP, abstraction appropriateness, DIP, domain model integrity, ISP, no scope creep, no over-engineering). Sub-agents MUST evaluate each criterion before marking a task `[x]` complete. QUALITY_VIOLATION is non-blocking by default; escalates to DEVIATION only when it contradicts a spec scenario. `solid-ddd` skill is loaded unconditionally for all non-documentation code changes via the Stack-to-Skill Mapping Table (no keyword match required).

9. **solid-ddd is a universal design principles skill, not a tech-stack skill** (added 2026-03-04, change: solid-ddd-quality-enforcement) — `skills/solid-ddd/SKILL.md` is `format: reference` and covers language-agnostic SOLID + DDD tactical patterns. Unlike technology skills (react-19, typescript, etc.) which are keyword-triggered, `solid-ddd` is unconditional — loaded for every non-documentation code change. It co-exists with `hexagonal-architecture-java` (which covers Java-specific Hexagonal implementation idioms); both skills are complementary.

7. **Runtime-auditing skill is standalone, not a project-audit dimension** (added 2026-03-03, change: claude-folder-audit) — `claude-folder-audit` audits `~/.claude/` installation state (drift, missing skills, orphans, scope tier compliance) as a standalone procedural skill, not as a D11 extension of `project-audit`. Rationale: single-responsibility and independently invocable from any context. Report written to `~/.claude/claude-folder-audit-report.md` (runtime artifact, never committed). V1 is read-only; auto-fix companion (`claude-folder-fix`) is future work.

6. **Two-tier skill placement model** (added 2026-03-02, change: skill-scope-global-vs-project) — Skills have two placement tiers: global (`~/.claude/skills/`) and project-local (`.claude/skills/`). When `/skill-add` or `/skill-creator` is used inside a project (not `claude-config`), the default placement is project-local — the skill file is copied into the repo and versioned alongside project source code. Global placement remains available as an explicit override. `project-fix` treats `move-to-global` as informational only (no automated file moves). Project-local skills MUST be committed to the repo; no `.gitignore` rule should exclude `.claude/skills/`. The CLAUDE.md Skills Registry uses `.claude/skills/<name>/SKILL.md` for local copies and `~/.claude/skills/<name>/SKILL.md` for global references — both formats can coexist.

## claude-folder-audit: Check Inventory (project mode)

Project mode runs **8 checks** (P1–P8). Each check is listed below with its sub-phases and severity caps.

| Check | Name | Sub-phases | Max severity |
|-------|------|-----------|-------------|
| P1 | CLAUDE.md presence and content quality | A: file presence; B: openspec/config.yaml; C: section headings, line count, SDD commands, Skills Registry paths | MEDIUM (Phase C caps at MEDIUM) |
| P2 | Global skills reachability and content quality | A: existence at ~/.claude/skills/; B: reachability; C: SKILL.md frontmatter, format: field, section contract, body length, TODO marker | MEDIUM |
| P3 | Local skills reachability and content quality | A: existence in .claude/skills/; B: reachability; C: SKILL.md frontmatter, format: field, section contract, body length, TODO marker | MEDIUM |
| P4 | Orphaned global skills | Detects skills present in ~/.claude/skills/ but not referenced in CLAUDE.md | MEDIUM |
| P5 | Scope tier overlap | Detects skills registered in both global and local tiers simultaneously | HIGH |
| P6 | Memory layer (ai-context/) | Presence of ai-context/ directory; presence of each of the five required files (stack.md, architecture.md, conventions.md, known-issues.md, changelog-ai.md); line count per file | MEDIUM |
| P7 | Feature domain knowledge layer (ai-context/features/) | Presence of ai-context/features/; non-template file count; section headings per domain file (Domain Overview, Business Rules and Invariants, Data Model Summary, Integration Points, Decision Log, Known Gotchas); line count per file | LOW (severity cap — never above LOW) |
| P8 | .claude/ folder inventory | Unexpected items directly under .claude/ vs. expected set; empty hook files in hooks/ | MEDIUM |

**Phase C content quality sub-checks (P1-C, P2-C, P3-C):**
- P1-Phase C: Reads CLAUDE.md and validates mandatory section headings (`## Tech Stack`, `## Architecture`, `## Unbreakable Rules`, `## Plan Mode Rules`, `## Skills Registry`); line count thresholds (MEDIUM if <30 lines, LOW if 30–50 lines); SDD command presence (`/sdd-ff` or `/sdd-new`); Skills Registry path entries.
- P2-Phase C and P3-Phase C: Validates SKILL.md frontmatter presence (leading `---` block); extracts `format:` value (LOW if absent or unrecognized, defaults to procedural); runs section contract per format type (procedural: `**Triggers**`/`## Triggers` + `## Process`/`### Step N` + `## Rules`; reference: `**Triggers**`/`## Triggers` + `## Patterns`/`## Examples` + `## Rules`; anti-pattern: `**Triggers**`/`## Triggers` + `## Anti-patterns` + `## Rules`); body line count (LOW if <30); TODO marker detection (INFO).
- P4 orphaned skills are explicitly excluded from Phase C content sub-checks.

**Section detection rule (uniform across P1-C, P2-C, P3-C, P7):** A section is present when at least one line STARTS with `## <section-name>`. Lines inside fenced code blocks are not exempt from this rule. Bold-trigger pattern (`**Triggers**`) is also a valid match for the Triggers section specifically.

**ADR reference:** P7 is the V2 audit integration deferred in ADR-015 (feature-domain-knowledge-layer-architecture). ADR-016 (enhance-claude-folder-audit-content-quality-convention) documents the Phase C sub-check convention.

<!-- [auto-updated]: structure-mapping — last run: 2026-03-03 -->
## Observed Structure (auto-detected)

Organization pattern: **feature-based** (confidence: high)
Each `skills/` subdirectory is a distinct capability with one `SKILL.md` entry point.

```
claude-config/ (observed 2026-03-03)
├── CLAUDE.md, README.md, settings.json, install.sh, sync.sh, .gitattributes
├── skills/          47 skill directories
│   ├── sdd-*/       11 SDD phase/orchestrator skills (explore, propose, spec,
│   │                  design, tasks, apply, verify, archive, ff, new, status)
│   ├── project-*/   6 meta-tool skills (setup, onboard, audit, analyze, fix, update)
│   ├── memory-*/    2 memory management skills (memory-init, memory-update)
│   ├── skill-*/     2 skill management skills (skill-creator, skill-add)
│   ├── claude-*/    2 system skills (claude-code-expert, claude-folder-audit)
│   ├── config-export/  1 config export skill
│   ├── feature-domain-expert/  1 domain knowledge skill
│   ├── smart-commit/   1 commit automation skill
│   └── [tech-skills]   18 technology catalog skills
├── hooks/           smart-commit-context.js (Node.js)
├── openspec/        config.yaml + changes/ (3 active) + specs/ (22 domains) + archive/
├── ai-context/      8 files: stack, architecture, conventions, known-issues,
│                    changelog-ai, onboarding, quick-reference, scenarios
│                    + features/ sub-directory (domain knowledge scaffold)
├── docs/            adr/ (16 ADRs + README.md) + templates/ (prd, adr)
└── memory/          MEMORY.md + topic files
```

Active SDD changes: none — `config-export`, `enhance-claude-folder-audit`, and `feature-domain-knowledge-layer` all archived as of 2026-03-03.

<!-- [/auto-updated] -->

<!-- [auto-updated]: drift-summary — last run: 2026-03-03 -->
## Architecture Drift (auto-detected)

Drift level: **minor** (2 informational entries)

Summary of drift vs. `architecture.md` baseline (2026-03-03):
- Skill count: stack.md manual section documents ~44 skills; 47 observed (natural catalog growth — config-export, feature-domain-expert, and one additional skill added since last count)
- ai-context/ file count: stack.md lists 5 core files; 8 files observed (onboarding.md, quick-reference.md, scenarios.md are documented in the architecture.md artifact table but stack.md count is outdated)

All drift is informational. No structural mismatches detected. All documented architectural layers (skills/, hooks/, openspec/, ai-context/, docs/adr/, docs/templates/, memory/) are present and correctly positioned.

<!-- [/auto-updated] -->
