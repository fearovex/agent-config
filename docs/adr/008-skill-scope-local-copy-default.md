# ADR-008: Local copy as the default placement for project-added skills

## Status

Proposed

## Context

When a developer runs `/skill-add <name>` inside a project, the existing default behavior (Option A) adds a path reference to `~/.claude/skills/<name>/SKILL.md` in the project's CLAUDE.md. This reference points to the global catalog on the current developer's machine. A collaborator who clones the repository sees the registry entry but has no local file at that path — the reference is broken on any machine other than the one where `/skill-add` was originally run.

Skills are configuration artifacts. The fundamental contract of a git-versioned config is that the repository should be sufficient to reproduce the development environment. The global-reference default violates this contract: projects are not self-contained, and the skill catalog is tied to the original author's machine setup.

Additionally, `project-fix` had a `move-to-global` handler that actively promoted local project skills to `~/.claude/skills/`, reinforcing the global-first direction instead of correcting it.

## Decision

We will change the default placement strategy for `/skill-add` from a global path reference (`~/.claude/skills/<name>/`) to a local copy (`.claude/skills/<name>/SKILL.md` inside the project). The global reference remains available as an explicit user choice (Option A), but is no longer the default. Copied skill files will include an HTML comment header recording the source path and copy date. The CLAUDE.md Skills Registry will include a two-line comment block explaining the two-tier model (local copy vs global reference). The `move-to-global` handler in `project-fix` will be converted from an automated file-system action to an informational-only output.

## Consequences

**Positive:**

- Projects become self-contained: `.claude/skills/` is versioned in the repository and available to all collaborators after cloning
- No new commands, abstractions, or manifest files are introduced — the change is a behavioral default swap in three existing skill files
- The origin comment in each copied SKILL.md provides traceability back to the global catalog
- `project-fix` no longer silently moves files to `~/.claude/`, eliminating an automated action that bypassed the `install.sh` deploy discipline

**Negative:**

- Duplication: the same skill may exist in `~/.claude/skills/` (global) and in `.claude/skills/` (project copy); updates to the global version do not propagate automatically
- CLAUDE.md registry entries now mix `.claude/skills/` and `~/.claude/skills/` paths, requiring developers to understand the two-tier model
- Any project skill copied before this change was applied remains at the old path; no migration is performed for existing entries
