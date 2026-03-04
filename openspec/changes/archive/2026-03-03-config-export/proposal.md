# Proposal: config-export

Date: 2026-03-03
Status: Draft

## Intent

Create a new `config-export` skill that reads the global Claude configuration (CLAUDE.md, ai-context/ files) and uses LLM transformation to generate tool-specific instruction files for GitHub Copilot, Google Gemini, and Cursor — enabling cross-tool portability of the project's AI assistant configuration.

## Motivation

Users of this SDD system invest significant effort in curating CLAUDE.md instructions, ai-context/ memory files, and a skills registry that captures the full project context. Today, that investment is locked to Claude Code. When a team member works in a different AI coding assistant (Copilot, Gemini, Cursor), they start from zero — no project conventions, no skills catalog, no architectural context.

`config-export` allows the configured context to travel with the project: one canonical source of truth in Claude format, exported on demand to the format each tool expects. This is not a sync mechanism (the exported files are read-only snapshots), but a deliberate, user-triggered translation pass using Claude as the transformation engine.

## Scope

### Included

- New skill directory: `skills/config-export/SKILL.md`
- Invocation command: `/config-export` (invocable from any project that has a CLAUDE.md + ai-context/)
- Four export targets:
  - **GitHub Copilot** → `.github/copilot-instructions.md`
  - **Google Gemini** → `GEMINI.md`
  - **Cursor** → `.cursor/rules/` (one `.mdc` file per exported domain)
  - **Claude** → `CLAUDE.md` (full re-export/refresh of the project CLAUDE.md from global config + ai-context/)
- Source inputs per export:
  - Global/project `CLAUDE.md` (rules, commands, skills registry)
  - `ai-context/stack.md`
  - `ai-context/architecture.md`
  - `ai-context/conventions.md`
  - `ai-context/known-issues.md` (optional — included if it exists)
- LLM-driven adaptation: each target receives a purpose-specific system prompt that transforms Claude-centric instructions into the idiom and structure each tool expects
- Dry-run mode: user can preview generated content before any file is written
- Selective export: user can choose one or more targets rather than all four
- Registration in global CLAUDE.md skills registry under "Tools / Platforms"

### Excluded (explicitly out of scope)

- **Bidirectional sync**: exported files are one-way snapshots; changes made in `.github/copilot-instructions.md` or `GEMINI.md` are NOT imported back into CLAUDE.md
- **Continuous/automatic export**: no hooks, no watch mode — export is always explicitly triggered
- **Tool-specific feature mapping**: the skill will not attempt to map Claude Code sub-agent patterns to Copilot Chat participants or Cursor Composer agents — it adapts instructions and context only
- **Non-AI-tool formats**: no export to Windsurf, Codeium, Continue, or other tools in V1
- **Validation of exported files**: the skill does not verify the exported files render correctly in the target tool's UI
- **Claude target (CLAUDE.md)**: the Claude re-export target is deferred — `project-update` already handles CLAUDE.md synchronization and adding a full-export path risks conflicting with its merge logic. V1 exports only the three external tools (Copilot, Gemini, Cursor).

## Proposed Approach

The skill operates as a procedural meta-tool invocable from any project:

1. **Source collection**: read CLAUDE.md and all present ai-context/ files into a structured context bundle
2. **Target selection**: present a menu (or accept CLI argument) to choose export targets
3. **Dry-run preview** (default): for each selected target, render the transformed output and ask for confirmation before writing
4. **LLM transformation**: use a purpose-built prompt per target format that instructs Claude to:
   - Strip Claude Code-specific syntax (backtick commands, Task tool references, sub-agent patterns)
   - Retain: project conventions, tech stack, architecture decisions, coding rules, known issues
   - Adapt structure to the target tool's expected format and idiomatic section names
5. **File writing**: write each output file to its canonical location; create directories as needed
6. **Idempotency**: re-running overwrites previous output with a warning (no silent overwrite of non-generated files)
7. **Summary**: report which files were written and note that exported files are snapshots — they will drift and should be re-exported after significant config changes

Transformation prompts per target:
- **Copilot**: flat Markdown, focus on code conventions and tech stack; strip orchestration machinery
- **Gemini**: GEMINI.md follows a similar format to CLAUDE.md — preserve structure, adapt command names, remove Claude Code-specific tool references
- **Cursor**: `.cursor/rules/*.mdc` files use Cursor's MDC format with YAML frontmatter (`description`, `globs`, `alwaysApply`); split into logical domains (conventions, stack, architecture)

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/config-export/` | New skill directory | Low — additive only |
| `CLAUDE.md` (global) | Updated skills registry entry | Low — append only |
| Target project files (`.github/`, `GEMINI.md`, `.cursor/`) | New generated files | Medium — creates new files in the user's project |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| LLM transformation produces low-quality output for a given target tool's format | Medium | Medium | Dry-run mode is default — user reviews before writing; iteration is cheap |
| Exported files diverge from CLAUDE.md over time without user awareness | High | Low | Skill summary always reminds user that exports are snapshots and not auto-synced |
| Cursor MDC format evolves, breaking the export format | Low | Medium | Cursor rules format is documented as stable; pin format version in skill notes; revisit if Cursor changes spec |
| Skill conflicts with `project-update` on the Claude target | Medium | Medium | Claude (CLAUDE.md) export is explicitly excluded from V1 scope — deferred to avoid conflict |
| User runs `/config-export` in a project with no ai-context/ | Medium | Low | Skill detects missing ai-context/ and warns; exports what it can from CLAUDE.md alone |

## Rollback Plan

`config-export` only creates new files in the target project — it never modifies CLAUDE.md or ai-context/ files. Rollback is:

1. Delete the generated files:
   - `.github/copilot-instructions.md`
   - `GEMINI.md`
   - `.cursor/rules/` directory
2. If the change was committed: `git revert` the commit that added them, or delete and commit the removal
3. Remove the skill directory `skills/config-export/` from the repo
4. Remove the skills registry entry from `CLAUDE.md`
5. Run `install.sh` to redeploy

No data is lost — no existing files are modified by this skill.

## Dependencies

- `docs/templates/prd-template.md` — exists (used in Step 5 of this proposal)
- No new external dependencies: the skill uses Claude's in-context LLM transformation; no APIs or packages required
- Requires a project with at minimum a `CLAUDE.md` to export from; `ai-context/` is optional but strongly recommended for quality output

## Success Criteria

- [ ] `skills/config-export/SKILL.md` exists and passes `/project-audit` format compliance (format: procedural, all required sections present)
- [ ] Running `/config-export` in a project with CLAUDE.md + ai-context/ produces a `.github/copilot-instructions.md` that contains the project's tech stack, conventions, and coding rules — free of Claude Code-specific syntax
- [ ] Running `/config-export` produces a `GEMINI.md` with equivalent content structured in Gemini's expected format
- [ ] Running `/config-export` produces at least one `.cursor/rules/*.mdc` file with valid MDC YAML frontmatter (`description`, `globs`, `alwaysApply` fields)
- [ ] Dry-run mode is the default: no files are written until the user explicitly confirms
- [ ] Re-running the skill on a project that already has exported files overwrites them with a warning rather than silently or erroring
- [ ] The global `CLAUDE.md` skills registry includes an entry for `config-export` under "Tools / Platforms"
- [ ] `/project-audit` score on `claude-config` is >= score before this change

## Effort Estimate

Medium (1-2 days) — the skill logic itself is straightforward, but crafting quality transformation prompts for each of the three target tools requires iteration and testing against a real project.
