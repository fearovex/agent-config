# Proposal: skill-scope-global-vs-project

Date: 2026-03-02
Status: Draft

## Intent

Change the default skill placement from global (`~/.claude/skills/`) to project-local (`.claude/skills/`) so that project skills are versioned in the repository and available to all collaborators, not just the original author's machine.

## Motivation

Currently, when a developer uses `/skill-add`, `/skill-create`, or any meta-tool that triggers skill creation, the resulting skill file lands in `~/.claude/skills/` on the current machine only. The project's `CLAUDE.md` then records a symbolic reference to that global path. A collaborator who clones the repository will see the registry entry in `CLAUDE.md` but will have no skill file backing it — the reference points to a path that does not exist on their machine.

This breaks the fundamental contract of a git-versioned config: what is in the repository should be sufficient to reproduce the development environment. Skills are configuration artifacts, and configuration should travel with the code.

The `project-fix` skill compounds this by having a `move-to-global` disposition that actively promotes local project skills to `~/.claude/skills/`, reinforcing the anti-pattern instead of correcting it.

## Scope

### Included

- `skill-add` — change the default strategy from Option A (symbolic reference to `~/.claude/skills/`) to Option B (local copy into `.clone/skills/`); keep Option A as an explicit secondary choice
- `skill-creator` — when invoked inside a project context (not `claude-config`), default placement to `.clone/skills/`; keep global placement as an explicit override
- `project-fix` — remove or demote the `move-to-global` automated disposition to a purely informational recommendation; the promotion must be manual only
- `CLAUDE.md` registry path convention — skill registry entries for locally-copied skills use `.claude/skills/<name>/SKILL.md` paths, not `~/.claude/skills/` paths

### Excluded (explicitly out of scope)

- A new dependency manifest (`skills.yaml`) or `/skills-install` command — Approach B from the exploration; too much new abstraction for the current problem
- Automated sync of local copies back to the global catalog — no automatic propagation in either direction
- Changes to `project-setup`, `project-audit`, or `project-analyze` skill behavior — they use the existing `skill-add`/`skill-creator` pipeline, so the fix propagates naturally
- Changes to how the global `claude-config` meta-repo itself places its own skills — inside `claude-config`, global placement remains the correct default

## Proposed Approach

Three targeted edits to existing skill files:

1. **`skill-add`**: Swap the default from Option A (path reference) to a copy operation that writes the skill file into `.claude/skills/<name>/SKILL.md` inside the current project. Option A (symbolic reference) remains available as an explicit user choice when the developer intentionally wants a global-only skill referenced without a local copy. Update the CLAUDE.md registry line the skill writes to use the local relative path.

2. **`skill-creator`**: Add context detection — if the current working directory contains an `openspec/` or `.claude/` directory and is not the `claude-config` meta-repo itself, default the placement prompt to project-local. The global option remains fully available. No behavioral change when running inside `claude-config`.

3. **`project-fix`**: Convert the `move-to-global` Phase 5 disposition from an automated action to a recommendation comment in the fix output. The skill no longer moves any file; it tells the user "this skill could be promoted to global if desired" and stops there.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/skill-add/SKILL.md` | Modified — default strategy change | High |
| `skills/skill-creator/SKILL.md` | Modified — context-aware default | High |
| `skills/project-fix/SKILL.md` | Modified — move-to-global becomes informational | Medium |
| `CLAUDE.md` / project registry convention | Informational — path format changes for new entries | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Version drift between local copies and global catalog | Medium | Low | Document in the registry entry (via a comment) when and from which global skill the copy was made; recommend periodic review |
| Developer confusion between `~/.claude/skills/` and `.claude/skills/` paths in CLAUDE.md | Low | Low | Add a two-line comment block in the Skills Registry section of CLAUDE.md explaining the two-tier model |
| Existing projects that rely on Option A symbolic references break after update | Low | Medium | The change only affects new invocations of `skill-add`; existing entries in `CLAUDE.md` are untouched; no migration step required |
| `claude-config` meta-repo accidentally gets project-local defaults | Low | Medium | `skill-creator` context detection explicitly excludes `claude-config` from the project-local default |

## Rollback Plan

All changes are confined to three Markdown files inside `skills/`. To revert:

1. `git revert <commit>` on the commit that applies this change — restores all three SKILL.md files to their pre-change state.
2. Re-run `install.sh` to deploy the reverted skill files to `~/.claude/`.
3. No data migration is needed: skill files already copied to `.claude/skills/` in projects are left in place (they are harmless even if the default reverts to global).

## Dependencies

- No external dependencies.
- The three skills (`skill-add`, `skill-creator`, `project-fix`) must be edited in `claude-config` (repo) and deployed via `install.sh` before the changes take effect in `~/.claude/`.
- No other skills depend on the specific behavior being changed (they call `skill-add` or `skill-creator` as black boxes).

## Success Criteria

- [ ] Running `/skill-add <name>` inside any project (not `claude-config`) produces a copy of the skill at `.claude/skills/<name>/SKILL.md` and registers it with a local path in `CLAUDE.md`
- [ ] Running `/skill-add <name>` with explicit Option A still produces the old symbolic-reference behavior when the user explicitly selects it
- [ ] Running `/skill-create <name>` inside any project (not `claude-config`) defaults the placement prompt to project-local (`.claude/skills/`)
- [ ] Running `/skill-create <name>` inside `claude-config` still defaults to global (`~/.claude/skills/`)
- [ ] Running `/project-fix` no longer moves any skill file to `~/.claude/skills/`; the `move-to-global` output is a recommendation comment only
- [ ] A collaborator cloning a project that used `/skill-add` after this change finds the skill file present at `.claude/skills/<name>/SKILL.md` — no missing files, no broken registry entries
- [ ] `/project-audit` score on `claude-config` does not decrease after `install.sh` is run with the updated skills

## Effort Estimate

Low–Medium (3 skill files, behavioral default changes only — no new commands, no new abstractions, no script changes)
