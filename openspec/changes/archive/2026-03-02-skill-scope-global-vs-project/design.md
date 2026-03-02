# Technical Design: skill-scope-global-vs-project

Date: 2026-03-02
Proposal: openspec/changes/skill-scope-global-vs-project/proposal.md

## General Approach

Three targeted behavioral edits to existing skill Markdown files — no new scripts, no new commands, no schema changes. `skill-add` becomes copy-first by default; `skill-creator` detects project context and sets the default placement accordingly; `project-fix` demotes its `move-to-global` handler from an automated action to a purely informational recommendation. All three skills remain backward-compatible: the previous behavior is preserved as an explicit user choice, not removed.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Default strategy in `skill-add` | Switch from Option A (global path reference) to Option B (local copy) as the default; keep Option A as an explicit override | Keep Option A as default but add a `--copy` flag; introduce a `skills.yaml` manifest (Approach B) | Local copy makes projects self-contained and git-sharable without introducing new abstractions. A copy can always be made a reference manually; a reference cannot be made a copy retroactively on a collaborator's machine. Approach B (manifest) is excluded by the proposal scope as over-engineering for the current problem. |
| Context detection in `skill-creator` | Detect project context by checking for the presence of `openspec/` or `.claude/` in the current working directory AND the absence of a `claude-config` identity marker | Always prompt without a default; auto-select based on a config flag | Implicit detection requires no user configuration while still covering the overwhelmingly common case. The `claude-config` exclusion guard prevents the meta-repo from silently adopting project-local defaults, which would be incorrect. |
| `move-to-global` handler in `project-fix` | Convert from automated action to informational-only output (print instructions, take no file-system action) | Remove the handler entirely; keep as-is | Removing the handler would silently break any existing FIX_MANIFEST entries that reference the `move-to-global` disposition; keeping them as informational preserves the audit signal while eliminating the automation that reinforces the anti-pattern. |
| CLAUDE.md registry path format for local copies | Use `.claude/skills/<name>/SKILL.md` (relative-looking, project-local) for local copies; keep `~/.claude/skills/<name>/SKILL.md` for global references | Use an absolute path from project root; use a `skill://` URI scheme | The `.claude/skills/` prefix is already the established project-local convention (used by `skill-creator` in project-specific mode). Consistency with the existing convention avoids introducing a new path scheme. |
| `skill-add` duplicate check scope | Extend duplicate detection to also scan for existing `.claude/skills/<name>/SKILL.md` entries, not only `~/.claude/` entries | Scan for both simultaneously and warn; treat the two as independent | A skill should not be added twice regardless of which tier it was previously registered under. Checking both paths prevents duplicate registry entries after the default changes. |
| Origin annotation in local copy | Add a comment header to the copied SKILL.md recording the source global skill path and copy date | Store metadata in a sidecar file; store it in CLAUDE.md only | A header comment in the file itself is immediately visible when the file is opened, requires no tooling to read, and survives copy/move operations. The comment is a Markdown HTML comment (`<!-- -->`) so it does not alter rendered output. |
| `claude-config` identity check | Treat a directory as the `claude-config` meta-repo if `install.sh` exists at its root AND `openspec/config.yaml` declares `project.name: claude-config` (or the directory is literally named `claude-config` as a fallback) | Check for a dedicated sentinel file; check for specific CLAUDE.md content | Two-factor check (install.sh + config name) avoids false positives on projects that happen to have an `install.sh` or happen to be in a directory named `claude-config`. Fallback by directory name handles the common single-machine case where the meta-repo is cloned as `~/claude-config`. |
| Two-tier model explanation in CLAUDE.md | Add a two-line comment block in the Skills Registry section explaining global vs local paths | Add a separate documentation page; rely on implicit understanding | The comment is co-located with the path entries it explains, survives copy-paste of the registry section, and requires no navigation. A separate documentation page would be invisible at the point of confusion. |

## Data Flow

### `/skill-add <name>` — new default flow

```
User: /skill-add typescript
         │
         ▼
Step 1  Validate argument → "typescript"
         │
         ▼
Step 2  Check ~/.claude/skills/typescript/SKILL.md exists → found
         │
         ▼
Step 3  Read description from global SKILL.md
         │
         ▼
Step 4  Locate project CLAUDE.md
         │
         ▼
Step 5  Duplicate check:
          - scan for ~/.claude/skills/typescript/ in registry → not found
          - scan for .claude/skills/typescript/ in registry → not found
         │
         ▼
Step 6  Preview to user (default = local copy):
          Skill   : typescript
          Action  : copy to .claude/skills/typescript/SKILL.md  [DEFAULT]
          Alt     : reference ~/.claude/skills/typescript/SKILL.md  [option A]
          Confirm? (Y / A for option A / N)
         │
         ├─── Y ──► Step 7a: Copy skill file
         │            Write .claude/skills/typescript/SKILL.md
         │            Prepend origin comment (<!-- copied from ~/.claude/skills/typescript/SKILL.md on YYYY-MM-DD -->)
         │            Add to CLAUDE.md registry: .claude/skills/typescript/SKILL.md
         │
         └─── A ──► Step 7b: Reference only (old Option A)
                      Add to CLAUDE.md registry: ~/.claude/skills/typescript/SKILL.md
```

### `/skill-create <name>` — context-aware default

```
User: /skill-create my-api-patterns  (inside a project, not claude-config)
         │
         ▼
Step 1  Gather information
  Context detection:
    openspec/ present?  → yes
    .claude/ present?   → yes
    claude-config identity? → no
    ──► default = project-local (.claude/skills/)
         │
         ▼
Step 1b Format selection (unchanged)
         │
         ▼
Step 1 prompt:
  Is this skill for this project or all projects?
    1. This project only → .claude/skills/  [DEFAULT]
    2. Global catalog    → ~/.claude/skills/
         │
         ├─── 1 (or Enter) ──► placement = .claude/skills/my-api-patterns/SKILL.md
         └─── 2             ──► placement = ~/.claude/skills/my-api-patterns/SKILL.md
```

### `project-fix` — `move-to-global` handler (demoted)

```
FIX_MANIFEST contains: { action_type: "move-to-global", local_path: ".claude/skills/foo/SKILL.md" }
         │
         ▼
Phase 5 handler reads action_type → "move-to-global"
         │
         ▼
Print informational block:
  ℹ️ Manual action required — .claude/skills/foo/SKILL.md
  This skill may be a candidate for promotion to the global catalog.
  To promote manually:
    1. Copy: cp .claude/skills/foo/SKILL.md ~/.claude/skills/foo/SKILL.md
    2. Register in claude-config repo: skills/foo/SKILL.md
    3. Run install.sh to deploy
    4. Run /skill-add foo in the original project (optional — updates registry entry)
    5. Delete the local copy after verifying the global version works
         │
         ▼
No file-system action taken.  (CHANGED: was previously copying the file)
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `skills/skill-add/SKILL.md` | Modify | Step 5: extend duplicate check to include `.claude/skills/<name>/` entries. Step 6: redesign preview block — default becomes local copy, Option A becomes explicit user choice. Step 7: split into 7a (copy, default) and 7b (reference, explicit). Step 8: update confirmation message to reflect copy-by-default. Rules: update to state that local copy is the default. |
| `skills/skill-creator/SKILL.md` | Modify | Step 1: add context-detection block before the placement prompt; reframe the placement question so that project-local is shown as the default when in a project context. Process: /skill-add section — remove the step that duplicates the addition strategy (it is now owned entirely by `skill-add/SKILL.md`). |
| `skills/project-fix/SKILL.md` | Modify | `move-to-global` handler (5.4): remove the word "automated" and any implication of file-system action. Confirm the current text already matches the informational-only intent (the existing handler text already says "No automated action taken" — verify and reinforce if needed). Phase 5 checkpoint counter: ensure `move-to-global` count line reads "manual — see instructions above". |

## Interfaces and Contracts

### Origin comment format (prepended to copied SKILL.md)

```markdown
<!-- skill-add: copied from ~/.claude/skills/<name>/SKILL.md on YYYY-MM-DD -->
```

This comment is prepended before the YAML frontmatter block (or before the first `#` heading if no frontmatter exists). It uses an HTML comment so it is invisible in rendered Markdown.

### Registry entry formats

```markdown
# Local copy (new default for /skill-add):
- `.claude/skills/<name>/SKILL.md` — <description>

# Global reference (explicit Option A for /skill-add):
- `~/.claude/skills/<name>/SKILL.md` — <description>
```

### Two-tier comment block (added to CLAUDE.md Skills Registry section)

```markdown
<!-- Skills Registry: paths starting with .claude/skills/ are local copies (versioned in this repo).
     Paths starting with ~/.claude/skills/ are global references (machine-local, not in this repo). -->
```

### Context detection logic (pseudo-code for skill-creator Step 1)

```
is_claude_config = (
  file_exists("install.sh")
  AND (
    openspec_config_project_name == "claude-config"
    OR basename(cwd) == "claude-config"
  )
)

has_project_context = (
  dir_exists("openspec") OR dir_exists(".claude")
)

if has_project_context AND NOT is_claude_config:
  default_placement = "project-local"
else:
  default_placement = "global"
```

### Duplicate check scope in skill-add Step 5

```
existing_global_ref  = registry contains "~/.claude/skills/<name>/"
existing_local_copy  = registry contains ".claude/skills/<name>/"

if existing_global_ref OR existing_local_copy:
  → "Skill already registered. No changes made."
  → Stop
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual — functional | Run `/skill-add typescript` inside a test project (with `openspec/` present); verify `.claude/skills/typescript/SKILL.md` is created with origin comment; verify CLAUDE.md registry entry uses local path | Manual invocation in a scratch project |
| Manual — override | Run `/skill-add typescript` and select Option A; verify CLAUDE.md registry entry uses `~/.claude/` path; verify no file is copied | Manual invocation |
| Manual — duplicate guard | Run `/skill-add typescript` twice; verify second invocation stops with "already registered" after seeing either a local or global entry | Manual invocation |
| Manual — skill-creator in project | Run `/skill-create test-skill` inside a project; verify the placement prompt defaults to option 1 (project-local) | Manual invocation |
| Manual — skill-creator in claude-config | Run `/skill-create test-skill` inside `claude-config`; verify the placement prompt does NOT default to project-local | Manual invocation inside claude-config repo |
| Manual — project-fix move-to-global | Generate a FIX_MANIFEST with a `move-to-global` entry; run `/project-fix`; verify no file is moved, only the informational text is printed | Manual invocation |
| Integration | Run `/project-audit` on `claude-config` after `install.sh`; verify score does not decrease | `/project-audit` |

## Migration Plan

No data migration required.

Existing `CLAUDE.md` registry entries in all projects that reference `~/.claude/skills/<name>/SKILL.md` are left untouched. The change only affects new invocations of `/skill-add` and `/skill-create` after `install.sh` is run with the updated skill files. Existing entries remain valid — they continue to work as global references.

## Open Questions

1. **`.gitignore` guidance for `.claude/skills/`**: Should the project `.gitignore` explicitly include `.claude/skills/` (to ensure local copies are committed) or leave it absent? Current behavior: `.claude/` is not in `.gitignore` for most projects, so `.claude/skills/` would be committed by default. No action needed for this change, but should be documented in the skills registry comment block. Resolution: document in the two-tier comment that `.claude/skills/` should NOT be `.gitignore`-d.

2. **Skill lookup order for Claude at runtime**: When a skill is invoked, does Claude look in `.claude/skills/` before `~/.claude/skills/`? This is a Claude Code behavior question, not a change owned by this SDD cycle. Out of scope — noted for a future exploration.
