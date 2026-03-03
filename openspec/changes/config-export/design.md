# Technical Design: config-export

Date: 2026-03-03
Proposal: openspec/changes/config-export/proposal.md

---

## General Approach

`config-export` is implemented as a single procedural skill (`skills/config-export/SKILL.md`) that follows the same meta-tool pattern used by `project-analyze`, `memory-init`, and `project-fix`. When invoked, it reads the project's CLAUDE.md and any present `ai-context/` files into an in-context bundle, presents a target menu to the user, generates each selected output via LLM transformation in-context (no external API calls), performs a dry-run preview, and writes the accepted files to their canonical locations. No new dependencies are introduced. The skill is self-contained and additive — it never modifies existing project files.

---

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Implementation pattern | Procedural skill (SKILL.md only, no helper scripts) | Bash script wrapper, Node.js CLI, hook-based trigger | All existing meta-tools (project-analyze, memory-init, project-fix) are procedural SKILL.md files. Consistent pattern reduces cognitive overhead and requires no runtime dependency. |
| Transformation engine | Claude in-context LLM transformation via structured prompts embedded in SKILL.md | External LLM API call, template-based string substitution, manual sed/awk scripts | The skill is invoked inside a Claude session — Claude is already the transformation engine. No separate API call needed. Prompts embedded in SKILL.md can be reviewed and tuned by the user. |
| Target file locations (convention) | Canonical tool-expected paths: `.github/copilot-instructions.md`, `GEMINI.md`, `.cursor/rules/*.mdc` | Custom output paths configurable per project, single merged output file | Tool-native paths ensure that the target AI assistant picks up the generated file automatically without extra configuration. Convention over configuration. |
| Dry-run default | Preview before write (dry-run is the default flow) | Write immediately then offer rollback, require explicit `--dry-run` flag | The proposal explicitly requires dry-run as default. Prevents silent overwrites of non-generated files. Matches the risk profile: the transformation output quality is unknown until previewed. |
| Idempotency on existing files | Overwrite with a warning banner at top of the generated file | Error and refuse to overwrite, create versioned backups, silently overwrite | Overwriting is correct for snapshot exports — the generated file is always the authoritative latest snapshot. Warning banner makes the generated-file status visible to anyone who opens it. Refusing to overwrite would break re-export workflows. |
| Cursor MDC structure | One `.mdc` file per logical domain (conventions, stack, architecture) | Single merged `.cursor/rules/project.mdc`, one file per SKILL.md entry | Domain-split files let Cursor apply rules selectively via `globs` and `alwaysApply` frontmatter. Avoids a single monolithic rules file that Cursor loads for every file regardless of context. This introduces a cross-cutting convention for how rules are split across domains. |
| Source bundle composition | CLAUDE.md + ai-context/ files (stack, architecture, conventions, known-issues) | CLAUDE.md only, full repo scan, openspec/ artifacts | These five files are the authoritative project context as defined by the SDD memory layer. Including known-issues is optional (skill checks for file existence). Skills catalog and SDD orchestration machinery are filtered out during transformation — they are Claude Code-specific. |
| Global CLAUDE.md registration | Entry added to Skills Registry under "Tools / Platforms" | No registration (manual discovery only), separate skills-registry.md | All skills in this system are registered in CLAUDE.md. Consistency with the existing pattern is non-negotiable per the conventions. |

---

## Data Flow

```
User invokes /config-export
        │
        ▼
Step 1: Source collection
  Read CLAUDE.md (project)
  Read ai-context/stack.md
  Read ai-context/architecture.md
  Read ai-context/conventions.md
  Read ai-context/known-issues.md  (optional — skip if absent)
        │
        ▼
Step 2: Target selection
  Present menu:
    1. GitHub Copilot  → .github/copilot-instructions.md
    2. Google Gemini   → GEMINI.md
    3. Cursor          → .cursor/rules/*.mdc
    [all] / [specific targets]
        │
        ▼
Step 3: Dry-run generation (per selected target)
  Apply target-specific transformation prompt → rendered Markdown/MDC output
  Print preview to user
  Ask: "Write these files? [y/N/edit]"
        │
        ├── N → abort, no files written
        │
        ▼
Step 4: File writing
  For each confirmed target:
    Create directories if absent (.github/, .cursor/rules/)
    Check for existing file → if found, warn user
    Write file with generated-file banner at top
        │
        ▼
Step 5: Summary
  List files written
  Remind user: "These are snapshots — re-run after significant config changes."
```

### Transformation prompt per target

```
Source bundle (CLAUDE.md + ai-context/ files)
        │
        ├── Copilot prompt ──► Strip: Task tool refs, sub-agent patterns, /commands,
        │                             skills catalog, SDD phase machinery
        │                      Retain: tech stack, coding conventions, architecture
        │                              decisions, known issues, key rules
        │                      Format: flat Markdown, H2 sections, no YAML frontmatter
        │
        ├── Gemini prompt  ──► Same strip as Copilot
        │                      Adapt: rename Claude-specific section headers to Gemini
        │                             equivalents; preserve Markdown structure
        │                      Format: similar to CLAUDE.md but without orchestration
        │
        └── Cursor prompt  ──► Same strip as Copilot
                               Split into 3 domains:
                                 conventions.mdc  → coding rules + naming
                                 stack.mdc        → tech stack + dependencies
                                 architecture.mdc → architecture decisions + patterns
                               Format per file:
                                 ---
                                 description: [domain summary]
                                 globs: [relevant file patterns or ""]
                                 alwaysApply: [true for conventions, false for others]
                                 ---
                                 [Markdown content for domain]
```

---

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/config-export/SKILL.md` | Create | Full procedural skill: 5-step process, transformation prompts per target, dry-run flow, idempotency rules |
| `CLAUDE.md` (project root) | Modify | Add `config-export` entry to Skills Registry under "Tools / Platforms" |

**Files created at runtime in the user's project (not in this repo):**

| File | Created by | Notes |
|------|-----------|-------|
| `.github/copilot-instructions.md` | `/config-export` at runtime | Created in user's project, not in claude-config |
| `GEMINI.md` | `/config-export` at runtime | Created in user's project, not in claude-config |
| `.cursor/rules/conventions.mdc` | `/config-export` at runtime | Created in user's project, not in claude-config |
| `.cursor/rules/stack.mdc` | `/config-export` at runtime | Created in user's project, not in claude-config |
| `.cursor/rules/architecture.mdc` | `/config-export` at runtime | Created in user's project, not in claude-config |

---

## Interfaces and Contracts

### Generated file header (all targets)

Every generated file begins with a standard banner:

```markdown
<!-- GENERATED BY config-export — DO NOT EDIT MANUALLY -->
<!-- Source: CLAUDE.md + ai-context/ | Generated: YYYY-MM-DD -->
<!-- Re-generate: run /config-export in your Claude Code session -->
```

### Cursor MDC frontmatter contract

```yaml
---
description: "[one-line description of this rules domain]"
globs: "[glob pattern matching files this rule applies to, or empty string]"
alwaysApply: [true|false]
---
```

Domain defaults:

| Domain file | `globs` | `alwaysApply` |
|-------------|---------|---------------|
| `conventions.mdc` | `""` | `true` |
| `stack.mdc` | `""` | `false` |
| `architecture.mdc` | `""` | `false` |

### Skill YAML frontmatter

```yaml
---
name: config-export
description: >
  Exports the project's Claude configuration (CLAUDE.md + ai-context/) to
  tool-specific instruction files for GitHub Copilot, Google Gemini, and Cursor.
  Trigger: /config-export, export config, copilot instructions, gemini config, cursor rules.
format: procedural
---
```

### Source availability matrix (governs Step 1 behavior)

| Source file | Required? | Behavior when absent |
|-------------|----------|---------------------|
| `CLAUDE.md` | Yes — minimum source | If absent, skill exits: "No CLAUDE.md found — nothing to export." |
| `ai-context/stack.md` | No | Skipped; transformation prompt notes "stack.md not available" |
| `ai-context/architecture.md` | No | Skipped; transformation prompt notes "architecture.md not available" |
| `ai-context/conventions.md` | No | Skipped; transformation prompt notes "conventions.md not available" |
| `ai-context/known-issues.md` | No | Skipped silently if absent |

---

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Structural | `skills/config-export/SKILL.md` exists and passes `/project-audit` format compliance (format: procedural, Triggers + Process + Rules present) | `/project-audit` |
| Integration | Running `/config-export` in a project with CLAUDE.md + ai-context/ produces the three expected output files at canonical paths | Manual invocation in a test project |
| Output quality | Each generated file is free of Claude Code-specific syntax (`Task tool`, `sub-agent`, `/sdd-*` commands, backtick command references) | Manual review of dry-run preview |
| Cursor MDC | Each `.mdc` file has valid YAML frontmatter with `description`, `globs`, and `alwaysApply` fields | Manual inspection |
| Idempotency | Re-running `/config-export` on a project that already has exported files overwrites them with a warning banner present | Manual second-run test |
| Graceful degradation | Running `/config-export` in a project with CLAUDE.md but no `ai-context/` produces a warning and exports from CLAUDE.md alone | Manual invocation in minimal test project |
| Registry | `CLAUDE.md` Skills Registry contains the `config-export` entry under "Tools / Platforms" | Manual inspection |

---

## Migration Plan

No data migration required. `config-export` is a purely additive change:
- One new skill directory (`skills/config-export/`) is created
- The global `CLAUDE.md` gains one new Skills Registry row
- No existing files are modified beyond the registry append
- All runtime output files are created in the user's project, not in this repo

---

## Open Questions

- **Cursor MDC `globs` precision**: Cursor's documentation suggests `globs` should match the files the rule applies to. For general project conventions, `""` (empty, matches all) is the pragmatic choice for V1. If a later version of the skill adds language-specific rules, per-extension globs (`**/*.ts`, `**/*.py`) should be considered. Impact if not resolved before V1: rules always apply to all files — acceptable for V1 scope.

- **Overwrite detection for non-generated files**: The idempotency rule warns on overwrite. A future refinement could detect whether the existing file was previously generated by `config-export` (by checking for the banner header) vs. manually authored — and apply different warnings for each case. Impact if not resolved: user sees the same warning on every re-run, even when the file is a previous export. Low friction for V1.
