# Exploration: Skill Scope — Global vs Project

## Problem Statement

When `/project-setup`, `/project-analyze`, and `/project-audit` propose or create skills,
those skills end up in `~/.claude/skills/` (personal machine) rather than in `.claude/skills/`
(project repository). This means collaborators who clone the project will be missing those
skills, since they live only on the original author's machine.

---

## Current State

### How skills are stored today

The system has two placement mechanisms:

| Location | Path | Visibility |
|----------|------|------------|
| Global catalog | `~/.claude/skills/<name>/SKILL.md` | Only the owner's machine |
| Project-local | `.claude/skills/<name>/SKILL.md` | Versioned in the repo — team-visible |

### How `skill-creator` decides placement

`skill-creator` asks the user to choose:
1. **Generic** → `~/.claude/skills/` (global, available in all projects)
2. **Project-specific** → `.claude/skills/` (local, only this project)

There is no automatic choice — it always prompts. However, the framing and defaults lean
toward global ("generic catalog"), and when invoked from within audit or setup workflows
the call often lacks enough context for the user to make an informed decision.

### How `skill-add` registers skills in a project

`skill-add` uses **Option A (conceptual symbolic reference)** as the default strategy:
it adds `~/.claude/skills/<name>/SKILL.md` paths into the project `CLAUDE.md`.
This is a _reference_ to a global skill — not a local copy. A collaborator who clones
the repo will see the registry entry but have no skill file to back it.

### How `project-fix` handles local vs global

`project-fix` Phase 5 has a `move-to-global` handler that actively _promotes_ local
project skills to `~/.claude/skills/`, reinforcing the global-first direction.

### What `install.sh` does

`install.sh` deploys `claude-config` (the meta-repo) to `~/.claude/`. Skills from this
meta-repo become globally available on **the current machine only**. There is no mechanism
to bundle project-specific skills or deploy them for a new team member.

---

## Affected Areas

| File/Module | Impact | Notes |
|-------------|--------|-------|
| `skills/skill-creator/SKILL.md` | High | Mode selection is present but framing defaults to global |
| `skills/project-fix/SKILL.md` | High | `move-to-global` disposition actively moves local → global |
| `skills/skill-add/SKILL.md` (inside skill-creator) | High | Option A adds global path references, not local copies |
| `skills/project-setup/SKILL.md` | Low | Mentions `/skill-create` without steering toward project scope |
| `skills/project-audit/SKILL.md` | Low | Recommends skills via `missing_global_skills[]` — global by name |

---

## Analyzed Approaches

### Approach A: Local copy on /skill-add (copy-on-add)

**Description**: When `/skill-add` is called inside a project, copy the global skill file
to `.claude/skills/<name>/SKILL.md` instead of adding a path reference.

**Pros**:
- Project becomes self-contained — the skill file travels with the repo
- No dependency on the developer's `~/.claude/` at runtime
- Collaborators get the skill automatically after cloning

**Cons**:
- Duplication: the same skill exists in `~/.claude/` and in the project
- Updates to the global skill do not propagate automatically to the project copy
- Version drift between teams becomes possible over time
- Increases repo size (skills are small Markdown files, so this is a minor concern)

**Estimated effort**: Low
**Risk**: Low — it is a behavioral change in `skill-add` only

---

### Approach B: Skills manifest in the project (dependency model)

**Description**: Add a `skills` manifest to `openspec/config.yaml` (or a dedicated
`skills.yaml`). Each project declares which global skills it needs. A new command
(e.g., `/skills-install`) reads the manifest and copies the required skills from
`~/.claude/skills/` (or fetches from `claude-config`) into `.claude/skills/`.

**Pros**:
- Explicit, auditable skill dependencies
- Skills are installed on-demand, keeping the repo lightweight
- Familiar pattern (like `npm install` or `pip install`)

**Cons**:
- Adds a new command and a new concept to the system
- Requires team members to run an installation step after cloning
- If `~/.claude/` doesn't have the skill, the install fails (requires the meta-repo)

**Estimated effort**: High
**Risk**: Medium — introduces a new abstraction

---

### Approach C: Change skill-creator default for project context (context-aware default)

**Description**: When `skill-creator` or `skill-add` is invoked inside a project
(i.e., not inside `claude-config`), default the placement to `.claude/skills/` instead
of `~/.claude/skills/`. The user can still override to global if needed.

**Pros**:
- Minimal change — only the default changes, not the capability
- Project skills land in the project without adding new commands
- Works naturally with git: `.claude/skills/` is versioned

**Cons**:
- Skills created this way are NOT available in other projects (project-local by design)
- If the user wants a skill in all projects, they need to know to pick "global"
- Does not fix the `skill-add` Option A symbolic-reference issue

**Estimated effort**: Low
**Risk**: Low

---

### Approach D: Hybrid — local copy by default + option to reference (recommended)

**Description**: Combine Approaches A and C:
1. `skill-creator` in a project context defaults to **project-local** (`.claude/skills/`)
2. `skill-add` defaults to **local copy** (Option B), with Option A (symbolic reference) as an explicit override
3. Remove or demote the `move-to-global` disposition from `project-fix` — it should be manual only
4. CLAUDE.md skill registry references become local paths (`.claude/skills/<name>/SKILL.md`)
   instead of global paths when the skill was added as a local copy

**Pros**:
- Projects become self-contained and sharable via git
- No new commands or abstractions introduced
- Minimal surface change — two behavioral defaults altered
- `move-to-global` is preserved for intentional promotion, but not auto-applied

**Cons**:
- Slight duplication when the same skill is used in multiple projects
- CLAUDE.md registry paths differ between global and local skills (minor inconsistency)

**Estimated effort**: Low–Medium (changes in 3 skills)
**Risk**: Low

---

## Recommendation

**Approach D — Hybrid (local copy by default + option to reference)** is the best fit.

It solves the core problem (skills must be in the project to be sharable via git) while
keeping the existing architecture intact. The change is contained, reversible, and does
not introduce new commands or concepts.

Priority of changes:
1. `skill-add` — change Option A from "symbolic reference" to "local copy" as the default;
   keep symbolic reference as an explicit secondary choice
2. `skill-creator` — when running inside a project (not `claude-config`), default to
   project-local placement
3. `project-fix` — change `move-to-global` from an automated disposition to a purely
   informational recommendation (already partially informational — just remove any
   automation and make it fully manual-only)

---

## Identified Risks

- **Version drift**: Local copies of global skills can diverge from the global catalog
  over time. Mitigation: document in the skill registry entry that the skill was copied
  from the global catalog at a specific date, and suggest periodic review.
- **Confusion between local and global paths**: The CLAUDE.md registry mixes
  `~/.claude/skills/...` (global) and `.claude/skills/...` (local) paths. The distinction
  is visible but requires the user to understand the two-tier model.
  Mitigation: add a comment in the registry section explaining the difference.

---

## Open Questions

1. Should the `.claude/skills/` directory be committed to git by default, or should
   a `.gitignore` pattern exclude it? Currently there is no `.gitignore` guidance for it.
2. Should `skill-add` silently copy, or notify the user that a local copy was created
   and suggest running `install.sh` if they want it globally too?
3. When a collaborator clones the repo and runs `/project-setup` or `/project-audit`,
   should the skill discovery also look in `.claude/skills/` (project-local) before
   falling back to `~/.claude/skills/` (global)?

---

## Ready for Proposal

**Yes** — the problem is well-defined, the affected files are identified, and Approach D
provides a clear, low-risk path. The change can proceed to `/sdd-ff skill-scope-global-vs-project`.
