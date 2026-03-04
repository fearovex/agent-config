---
name: project-claude-organizer
description: >
  Reads the project .claude/ folder, compares observed contents against the canonical SDD
  structure, presents a dry-run reorganization plan, and applies it additively after user
  confirmation. Never deletes or moves files. Produces claude-organizer-report.md.
  Trigger: /project-claude-organizer, organize .claude folder, fix project claude structure,
  align project .claude to canonical SDD layout.
format: procedural
---

# project-claude-organizer

> Reads the project `.claude/` folder, compares it against the canonical SDD structure,
> presents a reorganization plan, and applies it additively after explicit user confirmation.
> Never deletes or moves files.

**Triggers**: `/project-claude-organizer`, organize .claude folder, fix project claude structure, align .claude to canonical SDD layout, project claude organizer

> **Scope note**: This skill reads the **live `.claude/` folder state** directly — it does NOT
> read from `audit-report.md`. The skill that reads `audit-report.md` and applies its
> corrections is `project-fix`. This skill targets `PROJECT_ROOT/.claude/` only — it MUST
> NOT be run against `~/.claude/` (the user-level runtime).

---

## Process

### Step 1 — Resolve paths

Determine the project root and the target `.claude/` directory.

**1.1 — Resolve CWD as project root:**

`PROJECT_ROOT` = current working directory (absolute path).

Normalize all paths to forward slashes for display.

**1.2 — Resolve home directory (Windows-compatible):**

Use the following priority chain (same as `install.sh` and `claude-folder-audit`):

1. If `$HOME` is set and non-empty → `HOME_DIR = $HOME`
2. Else if `$USERPROFILE` is set and non-empty → `HOME_DIR = $USERPROFILE`
3. Else if `$HOMEDRIVE` and `$HOMEPATH` are both set → `HOME_DIR = $HOMEDRIVE$HOMEPATH`
4. Else → output error: "Cannot resolve home directory." and stop.

**1.3 — Set target directory:**

`PROJECT_CLAUDE_DIR = PROJECT_ROOT/.claude`

**1.4 — Guard: verify `.claude/` exists:**

Check whether `PROJECT_CLAUDE_DIR` exists as a directory.

If it does NOT exist:
```
No .claude/ folder found at <PROJECT_ROOT>.
This skill targets project .claude/ folders only — not the ~/.claude/ runtime.
It requires a project with an existing .claude/ directory.
Exiting without changes.
```
Stop. Do not write any files.

**1.5 — Guard: prevent targeting `~/.claude/`:**

If `PROJECT_CLAUDE_DIR` resolves to the same path as `HOME_DIR/.claude`, output:
```
This skill targets project .claude/ folders only — not the ~/.claude/ runtime.
Exiting without changes.
```
Stop.

---

### Step 2 — Enumerate observed items

List all items (files and directories) **one level deep** under `PROJECT_CLAUDE_DIR`.
Do not recurse into subdirectories.

Record each item as:
- `<name>` — for files
- `<name>/` — for directories

Collect the result as `OBSERVED_ITEMS`.

---

### Step 3 — Compare against canonical expected item set

The canonical expected item set for a project `.claude/` folder is defined below.
This set is cross-referenced to `claude-folder-audit` Check P8 and MUST remain consistent with it.

**Canonical expected item set (V1):**

```
# Cross-reference: claude-folder-audit Check P8
#
# Required (absence triggers a create action):
CLAUDE.md
skills/
#
# Optional (absence is informational only — not an error):
hooks/
audit-report.md
claude-folder-audit-report.md
claude-organizer-report.md
settings.json
settings.local.json
openspec/
ai-context/
```

**Classification rules:**

- `MISSING_REQUIRED` = items in the Required subset that are NOT in `OBSERVED_ITEMS`
  - Required items: `CLAUDE.md`, `skills/`
- `UNEXPECTED` = items in `OBSERVED_ITEMS` that are NOT in the full canonical expected set
- `PRESENT` = items in `OBSERVED_ITEMS` that ARE in the canonical expected set

**DOCUMENTATION_CANDIDATES classification (runs after the three-bucket classification above):**

```
KNOWN_AI_CONTEXT_TARGETS = [
  "stack",
  "architecture",
  "conventions",
  "known-issues",
  "changelog-ai",
  "onboarding",
  "quick-reference",
  "scenarios"
]

KNOWN_HEADING_PATTERNS = [
  "## Tech Stack",
  "## Architecture",
  "## Known Issues",
  "## Conventions",
  "## Changelog",
  "## Domain Overview"
]

DOCUMENTATION_CANDIDATES = []
```

For each `.md` file currently in `UNEXPECTED`:

**(a) Signal 1 — Filename stem match (case-insensitive):**
Extract the file's stem (filename without `.md` extension). If the stem matches any entry in `KNOWN_AI_CONTEXT_TARGETS` (case-insensitive):
- Add to `DOCUMENTATION_CANDIDATES` with `source = PROJECT_CLAUDE_DIR/<filename>.md`, `destination = PROJECT_ROOT/ai-context/<filename>.md`, `reason = "filename-match"`.
- Remove from `UNEXPECTED`.
- Do NOT apply Signal 2 for this file.

**(b) Signal 2 — Content heading match (for remaining `.md` files in UNEXPECTED only):**
Read the file's content. If any line starts with one of the `KNOWN_HEADING_PATTERNS` entries (case-sensitive, line-starts-with match):
- Add to `DOCUMENTATION_CANDIDATES` with `source = PROJECT_CLAUDE_DIR/<filename>.md`, `destination = PROJECT_ROOT/ai-context/<filename>.md`, `reason = "heading-match"`.
- Remove from `UNEXPECTED`.

Files matching neither signal remain in `UNEXPECTED` — no false promotion.

> **Scope note**: Only root-level `.md` files from `OBSERVED_ITEMS` are eligible. Subdirectory entries (e.g. `extra/`) are not scanned recursively — only the top-level directory entry is considered.

---

### Step 4 — Build and present dry-run plan

Build the reorganization plan from the three categories above.

**If `MISSING_REQUIRED` is empty AND `UNEXPECTED` is empty AND `DOCUMENTATION_CANDIDATES` is empty:**

Output:
```
No reorganization needed — .claude/ already matches the canonical SDD structure.
```

Proceed directly to Step 6 to write the report (no confirmation prompt needed).

**Otherwise**, display the plan in this format:

```
Reorganization Plan for: <PROJECT_CLAUDE_DIR>
─────────────────────────────────────────────

To be created (missing required items):
  + CLAUDE.md    — stub file (5 section headings)
  + skills/      — empty directory

Documentation to migrate → ai-context/:
  → stack.md      → ai-context/stack.md       (copy only — source preserved)
  → notes.md      → ai-context/notes.md       (copy only — source preserved)

  Note: individual files can be excluded before confirmation — list them as
  exclusions when responding to the prompt below.

Unexpected items (will be flagged, NOT deleted or moved):
  ! commands/    — not part of canonical SDD .claude/ structure (review manually)

Already correct:
  ✓ hooks/
  ✓ ai-context/
  ✓ openspec/

These items will NOT be deleted or moved — unexpected items receive a warning
comment in the report only.
```

Omit any category that has zero items (applies to all four categories).

After displaying the plan, prompt:
```
Apply this plan? (yes/no)
```

Wait for user input before proceeding.

- If the user responds with `yes`, `y`, `proceed`, or `apply` (case-insensitive) → proceed to Step 5.
- If the user responds with `no`, `n`, `cancel`, or `abort`, or provides no answer → output:
  ```
  Reorganization cancelled. No changes were made.
  ```
  Stop. Do not write any files (including the report).

---

### Step 5 — Apply plan (strictly additive)

Apply ONLY the operations listed in the plan. No additional operations.

**5.1 — Create missing `skills/` directory:**

If `skills/` is in `MISSING_REQUIRED`:
- Create an empty directory at `PROJECT_CLAUDE_DIR/skills/`.
- Do NOT place any files inside it.
- Record: `skills/ — directory created`.

**5.2 — Create missing `hooks/` directory:**

If `hooks/` is in `MISSING_REQUIRED` (hooks/ is optional, but if explicitly listed in plan):
- Create an empty directory at `PROJECT_CLAUDE_DIR/hooks/`.
- Record: `hooks/ — directory created`.

**5.3 — Create missing `CLAUDE.md` stub:**

If `CLAUDE.md` is in `MISSING_REQUIRED`:
- Verify `PROJECT_CLAUDE_DIR/CLAUDE.md` does NOT already exist (idempotency guard).
  If it already exists → skip this operation, record as `CLAUDE.md — already exists (skipped)`.
- Write the following minimal stub to `PROJECT_CLAUDE_DIR/CLAUDE.md`:

```markdown
# [Project Name] — Claude Configuration

## Tech Stack

<!-- Add your project tech stack here. -->

## Architecture

<!-- Describe the project architecture here. -->

## Unbreakable Rules

<!-- Add project-specific rules here. -->

## Plan Mode Rules

<!-- Add plan mode rules here. -->

## Skills Registry

<!-- List skills used by this project here.
     Global skills: ~/.claude/skills/<name>/SKILL.md
     Local skills:  .claude/skills/<name>/SKILL.md
     Run /project-setup for full initialization. -->
```

- Record: `CLAUDE.md — stub file created`.

**5.4 — Copy documentation candidates to ai-context/:**

Process each file in `DOCUMENTATION_CANDIDATES`:

**(a) Ensure `PROJECT_ROOT/ai-context/` exists:**
If the directory does not exist, create it before attempting any copy.

**(b) For each file NOT excluded by the user:**
- Check whether the destination (`PROJECT_ROOT/ai-context/<filename>.md`) already exists.
  - If destination **exists**: do not write anything. Record: `<filename>.md — skipped (destination exists — review manually)`. Leave both source and destination untouched.
  - If destination **does not exist**: copy source to destination. After the copy, verify that the source file still exists at `PROJECT_CLAUDE_DIR/<filename>.md`.
    - If source still exists → record: `<filename>.md — copied to ai-context/<filename>.md`.
    - If source no longer exists after copy → record: `<filename>.md — failed — source missing after copy` and do NOT mark as success.
  - On any other copy failure: record `<filename>.md — failed — <error reason>` and continue processing remaining candidates.

**(c) For each file excluded by the user:**
- Do NOT copy or modify the file.
- Record: `<filename>.md — excluded by user`.

**Source preservation invariant**: NEVER delete or modify the source file under any circumstance. The source file at `PROJECT_CLAUDE_DIR/<filename>.md` must exist and be unmodified after this step completes.

**5.5 — Flag unexpected items:**

For each item in `UNEXPECTED`:
- Do NOT touch the file or directory in any way.
- Record it as `<name> — unexpected item flagged in report (not modified)`.

**5.6 — Acknowledge already-correct items:**

For each item in `PRESENT`:
- No operation performed.
- Record it as `<name> — already correct (no change)`.

---

### Step 6 — Write report

Write `claude-organizer-report.md` to `PROJECT_CLAUDE_DIR`. Overwrite any previous file.

Use this format:

```markdown
# Claude Organizer Report

Run date: <YYYY-MM-DD>
Project root: <PROJECT_ROOT>
Target: <PROJECT_CLAUDE_DIR>
Summary: <N> item(s) created, <N> documentation file(s) copied to ai-context/, <N> unexpected item(s) flagged, <N> item(s) already correct

---

## Plan Executed

### Created

<!-- List items created, or state "Nothing to create — no required items were missing." -->
- `skills/` — empty directory created
- `CLAUDE.md` — stub file created with 5 section headings (Tech Stack, Architecture, Unbreakable Rules, Plan Mode Rules, Skills Registry)

> CLAUDE.md stub note: the file contains the 5 required section headings only.
> Populate this file with project-specific SDD configuration.
> Run /project-setup for full initialization.

### Documentation copied to ai-context/

<!-- Omit this subsection entirely when DOCUMENTATION_CANDIDATES was empty for the run. -->
<!-- List each candidate with its outcome: -->
- `stack.md` — copied to ai-context/stack.md
- `architecture.md` — skipped (destination exists — review manually)
- `notes.md` — excluded by user

### Unexpected items (not modified)

<!-- List unexpected items, or state "None." -->
- `commands/` — This item is not part of the canonical SDD .claude/ structure.
  Review manually — it was NOT deleted or moved.

### Already correct

<!-- List items that were already present and expected, or state "None." -->
- `hooks/`
- `ai-context/`
- `openspec/`

---

## Recommended Next Steps

<!-- Conditional content — include only the applicable items: -->

1. Review the unexpected item(s) listed above — if intentional, document them in
   .claude/CLAUDE.md; if not, remove them manually.
2. Populate the created stub files with project-specific content.
3. Review skipped documentation files — a file was skipped because its destination in
   ai-context/ already exists. Compare source and destination manually and merge if needed.
4. Project .claude/ structure is now aligned with the canonical SDD layout.

<!-- For a no-op run where nothing was missing: -->
<!-- No action required — .claude/ is already canonical. -->

---

> This file is a runtime artifact. Add `.claude/claude-organizer-report.md` to `.gitignore`
> to prevent accidental commits.
```

After writing the report, emit:
```
Report written to: <PROJECT_CLAUDE_DIR>/claude-organizer-report.md
```

Use the expanded absolute path (no tilde or relative segments).

---

## Rules

1. **Target is `PROJECT_ROOT/.claude/` only — NEVER `~/.claude/`.**
   This skill MUST NOT be invoked against the user-level runtime directory. If the resolved
   `PROJECT_CLAUDE_DIR` matches `~/.claude/`, the skill MUST exit immediately without changes.

2. **Apply step is strictly additive.**
   Only `mkdir` for missing directories and write stubs for missing files. No delete, move,
   rename, or overwrite operations are permitted under any circumstances. Existing files and
   directories are never touched, regardless of content.

3. **User confirmation gate MUST NOT be skipped.**
   The plan MUST be presented in full before any file write occurs. The skill MUST pause and
   wait for explicit user confirmation. If the user does not confirm affirmatively, the skill
   exits without writing any files (including the report).

4. **Canonical expected item set MUST remain consistent with `claude-folder-audit` Check P8.**
   The inline expected set defined in Step 3 is the single source of truth for this skill.
   Whenever `claude-folder-audit` Check P8 expected items are updated, this skill's inline
   set MUST be updated in sync to prevent false-positive MEDIUM findings.
