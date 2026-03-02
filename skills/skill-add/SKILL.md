---
name: skill-add
description: >
  Adds a global skill from ~/.claude/skills/ to the current project's CLAUDE.md Skills Registry.
  Trigger: /skill-add <name>, add skill to project, register global skill locally.
format: procedural
---

# skill-add

> Adds a global skill from ~/.claude/skills/ to the current project's CLAUDE.md Skills Registry.

**Triggers**: `/skill-add <name>`, add skill to project, register global skill locally

---

## Distinction from skill-create

- `/skill-add <name>` — adds an EXISTING global skill to the current project registry (this skill)
- `/skill-create <name>` — creates a NEW skill from scratch (use `~/.claude/skills/skill-creator/SKILL.md`)

---

## Process

### Step 1 — Validate argument

`$ARGUMENTS` must be a non-empty skill name (e.g. `typescript`, `react-19`).

If empty or missing:
```
Usage: /skill-add <name>

Example:
  /skill-add typescript
  /skill-add react-19

To create a new skill from scratch, use: /skill-create <name>
```
Stop here if argument is missing.

---

### Step 2 — Check global skill existence

Check if `~/.claude/skills/<name>/SKILL.md` exists.

If it does NOT exist, search for partial matches under `~/.claude/skills/` (any directory whose name contains `<name>` as a substring).

**If exact match found**: proceed to Step 3.

**If no exact match but partial matches found**:
```
Skill "[name]" not found at ~/.claude/skills/[name]/SKILL.md

Did you mean one of these?
  - [partial-match-1]
  - [partial-match-2]

To install an exact match, retry with the full name.
To create a new skill from scratch: /skill-create [name]
```
Stop here.

**If no match at all**:
```
Skill "[name]" not found in ~/.claude/skills/

Available skills can be listed at: ~/.claude/skills/
To create a new skill from scratch: /skill-create [name]
```
Stop here.

---

### Step 3 — Read skill description

Read the first line of `~/.claude/skills/<name>/SKILL.md` after the `# skill-name` heading. This is the one-line description (the `> Description` line).

If not found, use the heading text as the description.

---

### Step 4 — Check project CLAUDE.md

Check if a `CLAUDE.md` exists in the current project (not `~/.claude/CLAUDE.md` — the project-level one, typically at `.claude/CLAUDE.md` or the project root).

**If CLAUDE.md does not exist**:
```
No project CLAUDE.md found.

Cannot add skill to registry without a project CLAUDE.md.
Run /project-setup first to initialize the project.
```
Stop here.

**If CLAUDE.md exists**: check if it has a `## Skills Registry` section.

---

### Step 5 — Check for duplicate

Scan the `## Skills Registry` section (if present) for any existing entry referencing either:
- `~/.claude/skills/<name>/` (global reference), or
- `.claude/skills/<name>/` (local copy)

If either entry already exists:
```
Skill "[name]" is already registered in this project's CLAUDE.md.
No changes made.
```
Stop here.

---

### Step 6 — Preview and confirm

Present to the user:

```
Add skill to project registry:

  Skill   : [name]
  Source  : ~/.claude/skills/[name]/SKILL.md
  Desc    : [one-line description]

  Action  : copy to .claude/skills/[name]/SKILL.md  [DEFAULT]
  Option A: reference ~/.claude/skills/[name]/SKILL.md only (not committed to repo)

[If Skills Registry section is absent]
  Note: A "## Skills Registry" section will be created at the end of CLAUDE.md.

Confirm? (Y / A for Option A / N)
```

Wait for user confirmation before writing anything.

---

### Step 7a — Default: copy skill file to project (Y)

1. Create the directory `.claude/skills/<name>/` if it does not exist.
2. Copy `~/.claude/skills/<name>/SKILL.md` to `.claude/skills/<name>/SKILL.md`.
3. Prepend the following origin comment to the copied file, BEFORE the YAML frontmatter block (or before the first `#` heading if no frontmatter exists):
   ```
   <!-- skill-add: copied from ~/.claude/skills/[name]/SKILL.md on YYYY-MM-DD -->
   ```
   (Replace `YYYY-MM-DD` with today's date.)
4. Add a registry entry to the `## Skills Registry` section of CLAUDE.md using the local path:
   - **If `## Skills Registry` section exists**: append under an appropriate subsection (or at the end of the registry).
   - **If `## Skills Registry` section does NOT exist**: append this block at the end of CLAUDE.md:
     ```markdown
     ## Skills Registry

     ### Project Skills
     - `.claude/skills/[name]/SKILL.md` — [description]
     ```

---

### Step 7b — Option A: registry reference only (A)

Add a registry entry to the `## Skills Registry` section of CLAUDE.md using the global path:

- **If `## Skills Registry` section exists**: append under an appropriate subsection (or at the end of the registry).
- **If `## Skills Registry` section does NOT exist**: append this block at the end of CLAUDE.md:
  ```markdown
  ## Skills Registry

  ### Project Skills
  - `~/.claude/skills/[name]/SKILL.md` — [description]
  ```

Display a notice to the user:
```
ℹ️  Option A selected: registry reference only.
   The skill file is NOT copied into this repository.
   Collaborators who clone this project will not have access to this skill
   unless they have installed the global catalog (~/.claude/skills/) on their machine.
```

---

### Step 8 — Confirm to user

**After Step 7a (default — local copy):**
```
✅ Skill "[name]" added to project registry.

  Copied to : .claude/skills/[name]/SKILL.md
  Registry  : .claude/skills/[name]/SKILL.md — [description]

  The skill file is versioned in this repository and will be available to all collaborators.
  Commit .claude/skills/[name]/SKILL.md to include it in the project history.

To use: /[name] (or as documented in the skill's trigger definition)
```

**After Step 7b (Option A — registry reference):**
```
✅ Skill "[name]" added to project registry (global reference).

  Registry  : ~/.claude/skills/[name]/SKILL.md — [description]

To use: /[name] (or as documented in the skill's trigger definition)
```

---

## Rules

- Only adds skills that already exist at `~/.claude/skills/<name>/SKILL.md` — never creates new skills
- Always shows a preview and waits for confirmation before any write operation
- Detects and refuses to add duplicates — scans for both `~/.claude/skills/<name>/` and `.claude/skills/<name>/` entries in the registry
- Creates `## Skills Registry` section if absent — never fails due to missing section
- The default strategy is a **local copy** (Step 7a): the skill file is copied to `.claude/skills/<name>/SKILL.md` and the registry entry uses the local path; this makes the skill versioned and available to all collaborators without any additional setup
- Option A (global registry reference, `~/.claude/skills/<name>/SKILL.md`) is an explicit secondary choice; select it by entering `A` at the confirm prompt; the `--copy` flag is no longer needed — copy is the default
- A local copy receives an origin comment (`<!-- skill-add: copied from ... -->`) prepended to the file recording the source path and copy date
- Never touches `~/.claude/CLAUDE.md` — only the project-level CLAUDE.md
- Does not invoke `install.sh` or `sync.sh` — those are user-managed workflows
