# Proposal: add-orchestrator-skills

Date: 2026-02-26
Status: Draft

## Intent

Create four missing SKILL.md files (`sdd-ff`, `sdd-new`, `sdd-status`, `skill-add`) so that Claude Code CLI can register and invoke these orchestrator commands without returning "Unknown skill" errors.

## Motivation

The CLAUDE.md documents `/sdd-ff`, `/sdd-new`, `/sdd-status`, and `/skill-add` as first-class commands. When a user types any of them in the Claude Code CLI, the runtime looks for a corresponding directory under `~/.claude/skills/<command>/SKILL.md`. Because none of those directories exist, every invocation silently fails with "Unknown skill: <command>".

The orchestrator logic for `sdd-ff` and `sdd-new` is already fully documented in CLAUDE.md (the Fast-Forward section and the SDD Flow DAG). The `skill-add` process is already documented inside `skills/skill-creator/SKILL.md` under its own section. All four SKILL.md files need to be created to expose this existing logic as registered CLI commands.

This is a blocking gap: the SDD meta-system's primary entry points (`/sdd-ff` and `/sdd-new`) are unreachable from the CLI, which means users cannot start any SDD cycle through the intended fast path.

## Scope

### Included

- `skills/sdd-ff/SKILL.md` — orchestrator fast-forward: propose → (spec + design in parallel) → tasks; presents complete summary; asks for confirmation before `/sdd-apply`
- `skills/sdd-new/SKILL.md` — orchestrator full cycle: optional explore → propose → (spec + design in parallel) → tasks; presents summary and guides user through remaining phases
- `skills/sdd-status/SKILL.md` — reads `openspec/changes/` and reports active (non-archived) changes with their current phase artifacts present
- `skills/skill-add/SKILL.md` — adds an existing skill from the global catalog to the current project's `.claude/skills/` directory (extracted from `skill-creator/SKILL.md`)

### Excluded (explicitly out of scope)

- Modifying existing `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`, `sdd-apply`, `sdd-verify`, or `sdd-archive` skills — they are correct and will be invoked by the new orchestrators
- Modifying CLAUDE.md — the orchestrator documentation there remains the source of truth; SKILL.md files adapt it for CLI registration
- Creating project-level skill routing (`/skill-add` for project-specific skills already handled by `skill-creator`; this scope covers only global-catalog additions)
- Adding new SDD phases beyond the four missing skills

## Proposed Approach

Each new SKILL.md follows the established pattern in the skills catalog:

1. **sdd-ff**: Reads its own SKILL.md on invocation, then uses the Task tool to launch `sdd-propose` as a sub-agent, waits for completion, then launches `sdd-spec` and `sdd-design` in parallel sub-agents, waits for both, then launches `sdd-tasks`, presents the full summary to the user, and asks "Ready to implement with `/sdd-apply`?"

2. **sdd-new**: Same as `sdd-ff` but prepends an optional `sdd-explore` step. After tasks complete it also presents the full DAG status and reminds the user of the remaining phases (apply → verify → archive).

3. **sdd-status**: Reads `openspec/changes/` (excluding `archive/`), checks which SDD artifact files are present per change directory, and prints a table showing each active change and its current phase.

4. **skill-add**: Extracts the `/skill-add` section from `skill-creator/SKILL.md` into its own file. The process: list available global-catalog skills, copy the selected skill directory into the project's `.claude/skills/`, and update the project CLAUDE.md skills registry section.

The four files are standalone — no changes to existing skills or CLAUDE.md are required.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/sdd-ff/` | New directory + SKILL.md | High — primary fast-path entry point |
| `skills/sdd-new/` | New directory + SKILL.md | High — primary full-cycle entry point |
| `skills/sdd-status/` | New directory + SKILL.md | Medium — diagnostic/visibility command |
| `skills/skill-add/` | New directory + SKILL.md | Medium — convenience command for skill adoption |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| sdd-ff/sdd-new duplicate logic from CLAUDE.md and diverge over time | Medium | Medium | Keep SKILL.md content as thin wrappers that reference the sub-agent delegation pattern; avoid copy-pasting prose |
| skill-add overlaps with skill-creator and causes confusion about which to use | Low | Low | Document clear trigger distinction: `skill-add` = add from global catalog; `skill-create` = create new skill from scratch |
| sdd-status reports stale data if openspec/changes/ is not up to date | Low | Low | Document in SKILL.md that status reflects the filesystem state only — not git history |

## Rollback Plan

All four additions are net-new directories. To revert:

```bash
rm -rf ~/.claude/skills/sdd-ff
rm -rf ~/.claude/skills/sdd-new
rm -rf ~/.claude/skills/sdd-status
rm -rf ~/.claude/skills/skill-add
```

And in the repo:

```bash
rm -rf skills/sdd-ff skills/sdd-new skills/sdd-status skills/skill-add
git checkout -- .
```

No existing files are modified, so rollback has zero risk of data loss.

## Dependencies

- `skills/sdd-propose/SKILL.md` must exist (it does)
- `skills/sdd-spec/SKILL.md` must exist (it does)
- `skills/sdd-design/SKILL.md` must exist (it does)
- `skills/sdd-tasks/SKILL.md` must exist (it does)
- `skills/sdd-explore/SKILL.md` must exist (it does — required by `sdd-new` for the optional explore step)
- `skills/skill-creator/SKILL.md` must exist (it does — `skill-add` extracts its sub-process)
- `sync.sh` must be run after creation so files propagate to `~/.claude/skills/`

## Success Criteria

- [ ] Typing `/sdd-ff <change>` in Claude Code CLI triggers the fast-forward orchestration without "Unknown skill" error
- [ ] Typing `/sdd-new <change>` in Claude Code CLI starts the full SDD cycle
- [ ] Typing `/sdd-status` in Claude Code CLI prints a readable table of active changes and their current phase
- [ ] Typing `/skill-add <name>` in Claude Code CLI copies the named skill into the project without invoking `skill-creator`
- [ ] All four SKILL.md files pass `/project-audit` without reducing the current score
- [ ] `sync.sh` completes without errors after the new files are added

## Effort Estimate

Low (hours) — four new SKILL.md files, no code, no schema changes, no existing file modifications.
