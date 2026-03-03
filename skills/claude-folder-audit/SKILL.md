---
name: claude-folder-audit
description: >
  Audits the ~/.claude/ runtime folder or a project's .claude/ configuration for installation
  drift, skill deployment gaps, orphaned artifacts, and scope tier compliance. Read-only.
  Produces claude-folder-audit-report.md at the appropriate location.
  Trigger: /claude-folder-audit, audit runtime, audit .claude folder, check installation drift,
  verify skill deployment, audit project claude config.
format: procedural
---

# claude-folder-audit

> Audits the `~/.claude/` runtime folder **or** a project's `.claude/` configuration depending on where it is invoked. Read-only. Produces `claude-folder-audit-report.md` at the appropriate location.

**Triggers**: `/claude-folder-audit`, audit runtime, audit .claude folder, check installation drift, verify skill deployment, audit project claude config, runtime out of sync

---

## Purpose

This skill diagnoses the health of Claude configuration by adapting its checks to where it is invoked:

- **From the `claude-config` source repo** (`global-config` mode): audits the `~/.claude/` runtime for installation drift, missing skill deployments, and orphaned artifacts
- **From a project with a `.claude/` folder** (`project` mode): audits the project's `.claude/CLAUDE.md`, registered skills vs. actual files on disk, and orphaned local skills
- **From any other location** (`global` mode): audits the `~/.claude/` runtime structure

It is **strictly read-only**. The only file it writes is the report.

---

## Process

### Step 1 — Resolve paths (path normalization)

Determine the absolute path to the `~/.claude/` runtime directory without relying on shell tilde expansion.

Use the following priority chain (same as `install.sh`):

1. If `$HOME` is set and non-empty → `CLAUDE_DIR = $HOME/.claude`
2. Else if `$USERPROFILE` is set and non-empty → `CLAUDE_DIR = $USERPROFILE/.claude`
3. Else if `$HOMEDRIVE` and `$HOMEPATH` are both set → `CLAUDE_DIR = $HOMEDRIVE$HOMEPATH/.claude`
4. Else → record a **HIGH** finding: "Cannot resolve home directory — path normalization failed" and write a minimal report containing only that finding. Stop all further checks.

Normalize all paths to forward slashes for display in the report.

Also record:
- `RUNTIME_ROOT` = resolved `CLAUDE_DIR` (e.g., `C:/Users/juanp/.claude`)
- `CWD_ROOT` = current working directory (absolute path, forward slashes)
- `RUN_DATE` = current date and time in ISO 8601 format

### Step 2 — Detect execution mode

Evaluate the following conditions in strict priority order:

1. **`global-config`** — if both `install.sh` AND `skills/` (as a directory) exist at `CWD_ROOT`:
   - `MODE = global-config`
   - `SOURCE_ROOT = CWD_ROOT`

2. **`project`** — else if a `.claude/` directory exists at `CWD_ROOT` (condition 1 is false):
   - `MODE = project`
   - `PROJECT_ROOT = CWD_ROOT`
   - `PROJECT_CLAUDE_DIR = CWD_ROOT/.claude`

3. **`global`** — all other locations:
   - `MODE = global`
   - `SOURCE_ROOT = "Not detected"`

If mode cannot be determined, default to `global`.

---

### Step 3 — Run audit checks (always run all checks — no early abort)

Accumulate findings in a list. Each finding has:

```
severity: HIGH | MEDIUM | LOW | INFO
check:    identifier (1..5 for global-config/global modes; P1..P5 for project mode)
title:    short description
detail:   what was observed
remediation: exact step to resolve (optional for INFO)
```

---

**If `MODE = project`** — run Checks P1–P5 below (skip Checks 1–5):

---

#### Check P1 — CLAUDE.md Presence and Skills Registry

**Phase A — File presence**:

Check whether `PROJECT_CLAUDE_DIR/CLAUDE.md` exists.

If **absent**:
```
severity: HIGH
check: P1
title: .claude/CLAUDE.md missing — project Claude config not found
detail: No CLAUDE.md file found at PROJECT_CLAUDE_DIR/CLAUDE.md.
remediation: Create .claude/CLAUDE.md with a Skills Registry section, or run /project-setup to initialize the project Claude config.
```

If **present**, proceed to Phase B.

**Phase B — Skills Registry section and path parsing**:

Scan the file for a line matching (case-insensitive): `## skills registry`.

If **no Skills Registry section found**:
```
severity: HIGH
check: P1
title: .claude/CLAUDE.md has no Skills Registry section
detail: The ## Skills Registry section header was not found in PROJECT_CLAUDE_DIR/CLAUDE.md.
remediation: Add a ## Skills Registry section to .claude/CLAUDE.md listing all skills used by this project.
```

If **Skills Registry section found**, classify each path-bearing line in the file:
- A line containing `~/.claude/skills/` → **global-tier registration**; extract skill name from the segment after `skills/` (e.g., `~/.claude/skills/sdd-ff/SKILL.md` → name = `sdd-ff`)
- A line containing `.claude/skills/` but NOT `~/.claude/skills/` → **local-tier registration**; extract skill name (e.g., `.claude/skills/my-skill/SKILL.md` → name = `my-skill`)

> **Important**: always match `~/.claude/skills/` before `.claude/skills/` to avoid the substring overlap. A line with `~/.claude/skills/` must never be classified as local-tier.

Collect:
- `GLOBAL_SKILLS` = list of globally-registered skill names
- `LOCAL_SKILLS` = list of locally-registered skill names

If no findings in P1 → no finding for this check.

---

#### Check P2 — Global-Path Registration Verification

**If P1 found no CLAUDE.md or no Skills Registry**:
```
severity: INFO
check: P2
title: P1 failed — global registration check skipped
```
Skip the rest of P2.

**Otherwise**, for each skill name `<n>` in `GLOBAL_SKILLS`:

- If `RUNTIME_ROOT/skills/<n>/` does **not** exist:
  ```
  severity: HIGH
  check: P2
  title: Global skill '<n>' registered in CLAUDE.md but not deployed to ~/.claude/skills/
  detail: Expected at RUNTIME_ROOT/skills/<n>/ — directory not found.
  remediation: Run install.sh from the claude-config repo, or install the skill manually.
  ```

- If `RUNTIME_ROOT/skills/<n>/` exists but `RUNTIME_ROOT/skills/<n>/SKILL.md` is **absent**:
  ```
  severity: MEDIUM
  check: P2
  title: Global skill '<n>' directory present in ~/.claude/skills/ but SKILL.md missing
  detail: Directory exists at RUNTIME_ROOT/skills/<n>/ but SKILL.md not found inside it.
  remediation: Re-run install.sh or restore the SKILL.md file manually.
  ```

If `GLOBAL_SKILLS` is empty → record one INFO: "No global-tier skill registrations found in CLAUDE.md — check skipped."

---

#### Check P3 — Local-Path Registration Verification

**If P1 found no CLAUDE.md or no Skills Registry**:
```
severity: INFO
check: P3
title: P1 failed — local registration check skipped
```
Skip the rest of P3.

**Otherwise**, for each skill name `<n>` in `LOCAL_SKILLS`:

- If `PROJECT_ROOT/.claude/skills/<n>/` does **not** exist:
  ```
  severity: HIGH
  check: P3
  title: Local skill '<n>' registered in CLAUDE.md but not found at .claude/skills/<n>/
  detail: Expected at PROJECT_ROOT/.claude/skills/<n>/ — directory not found.
  remediation: Add the skill file at .claude/skills/<n>/SKILL.md or remove the registry entry from CLAUDE.md.
  ```

- If `PROJECT_ROOT/.claude/skills/<n>/` exists but `SKILL.md` is **absent**:
  ```
  severity: MEDIUM
  check: P3
  title: Local skill '<n>' directory present but SKILL.md missing
  detail: Directory exists at PROJECT_ROOT/.claude/skills/<n>/ but SKILL.md not found inside it.
  remediation: Restore SKILL.md at .claude/skills/<n>/SKILL.md.
  ```

If `LOCAL_SKILLS` is empty → record one INFO: "No local-tier skill registrations found in CLAUDE.md — check skipped."

---

#### Check P4 — Orphaned Local Skills

Enumerate all directories under `PROJECT_ROOT/.claude/skills/` that contain a `SKILL.md` file.

**If `.claude/skills/` does not exist at `PROJECT_ROOT`**:
```
severity: INFO
check: P4
title: No .claude/skills/ directory found — orphan check skipped
```
Skip the rest of P4.

**If `.claude/skills/` exists but is empty**:
```
severity: INFO
check: P4
title: .claude/skills/ is empty — no local skills to check
```
Skip the rest of P4.

**Otherwise**, for each skill directory name `<n>` found on disk that is **NOT** in `LOCAL_SKILLS`:
```
severity: MEDIUM
check: P4
title: Local skill '<n>' found at .claude/skills/ but not registered in CLAUDE.md Skills Registry
detail: Directory PROJECT_ROOT/.claude/skills/<n>/ exists on disk but has no corresponding entry in the Skills Registry.
remediation: Register the skill in the CLAUDE.md Skills Registry, or remove the directory if no longer needed.
```

---

#### Check P5 — Scope Tier Overlap

**If P1 found no Skills Registry**:
```
severity: INFO
check: P5
title: P1 failed — scope tier overlap check skipped
```
Skip the rest of P5.

**Otherwise**, for each skill name `<n>` in `LOCAL_SKILLS`:

- If `RUNTIME_ROOT/skills/<n>/` also exists (global tier):
  ```
  severity: LOW
  check: P5
  title: Skill '<n>' exists in both .claude/skills/ (local) and ~/.claude/skills/ (global)
  detail: This is expected for intentional global overrides; verify the intended tier is active.
  remediation: Confirm which tier is authoritative for this project; consult ADR-008.
  ```

> Severity MUST NOT exceed LOW for P5 findings regardless of count.

If `LOCAL_SKILLS` is empty → record one INFO: "No local-tier skills registered — scope tier overlap check skipped."

---

**If `MODE = global-config` or `MODE = global`** — run Checks 1–5 below (skip Checks P1–P5):

---

#### Check 1 — Runtime Structure

Verify that the following top-level directories exist inside `RUNTIME_ROOT`:
- `skills/`
- `openspec/`
- `ai-context/`
- `memory/`
- `hooks/`

Also verify that `RUNTIME_ROOT/CLAUDE.md` exists as a file.

For each **missing directory**, record:
```
severity: HIGH
check: 1
title: Required directory missing: ~/.claude/<dir>/
detail: The directory does not exist in the runtime root.
remediation: Run install.sh from the claude-config repo
```

If `CLAUDE.md` is **absent** from `RUNTIME_ROOT`, record:
```
severity: HIGH
check: 1
title: CLAUDE.md missing from ~/.claude/
detail: The CLAUDE.md file is not present at the runtime root.
remediation: Run install.sh from the claude-config repo
```

If all required directories and CLAUDE.md are present → no finding for this check.

---

#### Check 2 — Skill Deployment Completeness

**If `MODE = global`** (no source `skills/` directory readable from cwd):

Record one INFO note:
```
severity: INFO
check: 2
title: Source repo not detected — skill deployment completeness check skipped
detail: No skills/ directory found at the current working directory.
```

Skip the rest of Check 2.

**If `MODE = global-config`** (source `skills/` exists at cwd):

1. List all subdirectories under `SOURCE_ROOT/skills/`. These are the expected source skills.
2. For each source skill `<name>`:
   - If `RUNTIME_ROOT/skills/<name>/` does **not** exist → record:
     ```
     severity: HIGH
     check: 2
     title: Skill '<name>' present in source but not deployed to ~/.claude/skills/
     detail: Source path: SOURCE_ROOT/skills/<name>/ — Runtime path: RUNTIME_ROOT/skills/<name>/ does not exist.
     remediation: Run install.sh from the claude-config repo
     ```
   - If `RUNTIME_ROOT/skills/<name>/` exists but `RUNTIME_ROOT/skills/<name>/SKILL.md` does **not** → record:
     ```
     severity: MEDIUM
     check: 2
     title: Deployed skill '<name>' has no SKILL.md — directory may be empty or corrupt
     detail: The directory exists at RUNTIME_ROOT/skills/<name>/ but SKILL.md is absent.
     remediation: Run install.sh to restore the skill file
     ```

---

#### Check 3 — Installation Drift Detection

**If `MODE = global`** (no source repo detected):

Record one INFO note:
```
severity: INFO
check: 3
title: No source repo detected — drift check skipped
```

Skip the rest of Check 3.

**If `MODE = global-config`**:

Attempt to read the modification time (mtime) of:
- `SOURCE_ROOT` (the source repo root directory)
- `RUNTIME_ROOT` (the `~/.claude/` runtime directory)

If **either mtime cannot be read** (filesystem access error):
```
severity: INFO
check: 3
title: Could not read directory mtime for drift comparison — check skipped
detail: mtime-based drift detection requires read access to both directories.
```

If **source repo mtime is more recent than runtime mtime**:
```
severity: MEDIUM
check: 3
title: Possible installation drift — source repo appears newer than ~/.claude/ (mtime proxy)
detail: Source mtime: <ISO 8601 timestamp> / Runtime mtime: <ISO 8601 timestamp>
        Note: mtime comparison is an approximate proxy. Re-running install.sh is always safe.
remediation: Run install.sh from the claude-config repo to re-sync runtime with source repo
```

If **runtime mtime is equal to or more recent than source mtime** → no finding for this check.

> **Known limitation**: mtime is an imprecise proxy for deployment state. A `.installed-at` metadata file (future improvement) would provide exact tracking.

---

#### Check 4 — Orphaned Artifact Detection

List all items (files and directories) directly under `RUNTIME_ROOT` (one level only — not recursive).

Build the **expected item set** from:
- All top-level items in `SOURCE_ROOT/` (if global-config mode) — these were deployed by `install.sh`
- Known runtime-only items: `CLAUDE.md`, `settings.json`, `settings.local.json`, `claude-folder-audit-report.md`, `.installed-at`, `audit-report.md`

For each item found in `RUNTIME_ROOT` that is **not** in the expected item set:

- If the item is inside `openspec/changes/` (subdirectory of `openspec/changes/`) → record:
  ```
  severity: INFO
  check: 4
  title: Work-in-progress SDD change directories found in runtime openspec/changes/
  detail: These are expected SDD artifacts, not orphans.
  ```

- Otherwise → record (severity capped at MEDIUM regardless of count):
  ```
  severity: MEDIUM
  check: 4
  title: Unexpected item in ~/.claude/: <name> — possible manual edit or stale artifact
  detail: This item does not correspond to any source repo item or known runtime-only artifact.
  remediation: Review manually; run install.sh if this file should not exist; do NOT delete without inspection
  ```

If all items are in the expected set → no finding for this check.

**Note**: In `global` mode without a source repo, the expected set is the list of known runtime-only items only. Any item not in that list is flagged as MEDIUM.

---

#### Check 5 — Scope Tier Compliance

Check for skills present in the project-local `.claude/skills/` directory (relative to cwd) that overlap with or are missing from the global catalog.

**If `.claude/skills/` does not exist** at the cwd:

Record one INFO note:
```
severity: INFO
check: 5
title: No project-local .claude/skills/ found — scope tier compliance check skipped for project-local tier
```

Then list global tier contents as INFO only:
```
severity: INFO
check: 5
title: Global tier contains <N> skill(s): [comma-separated list]
```

Skip the rest of Check 5.

**If `.claude/skills/` exists** at the cwd:

List all subdirectories under `.claude/skills/`. For each `<name>`:

1. If `RUNTIME_ROOT/skills/<name>/` also exists (global tier):
   ```
   severity: LOW
   check: 5
   title: Skill '<name>' exists in both global (~/.claude/skills/) and project-local (.claude/skills/) tiers
   detail: This is expected for intentional global overrides; verify the intended tier is active.
   remediation: Confirm which tier is authoritative for this project; consult ADR 008
   ```

2. If `SOURCE_ROOT/skills/<name>/` does **not** exist (global catalog gap) — global-config mode only:
   ```
   severity: MEDIUM
   check: 5
   title: Project-local skill '<name>' has no counterpart in the global catalog (skills/)
   detail: The skill exists only in the project-local tier and has not been promoted to the global catalog.
   remediation: If intentional, register the skill in CLAUDE.md; if not, consider adding it to skills/
   ```

---

### Step 4 — Generate report

Determine the report write path by mode:
- `MODE = project` → write to `PROJECT_ROOT/.claude/claude-folder-audit-report.md`
- `MODE = global-config` or `MODE = global` → write to `RUNTIME_ROOT/claude-folder-audit-report.md`

**Overwrite** any previous report (do not append).

**Project-mode report format** (`MODE = project`):

```markdown
# .claude/ Project Audit Report

Run date: <RUN_DATE>
Mode: project
Project root: <PROJECT_ROOT>
CLAUDE.md: <PROJECT_CLAUDE_DIR>/CLAUDE.md
Summary: <N> HIGH, <N> MEDIUM, <N> LOW, <N> INFO

---

## Findings Summary

| Severity | Check | Description | Remediation |
|----------|-------|-------------|-------------|
...
| — | — | No HIGH / MEDIUM / LOW findings | — |

---

## Check P1 — CLAUDE.md Presence and Skills Registry

[findings or "No findings."]

---

## Check P2 — Global-Path Registration Verification

[findings or "No findings."]

---

## Check P3 — Local-Path Registration Verification

[findings or "No findings."]

---

## Check P4 — Orphaned Local Skills

[findings or "No findings."]

---

## Check P5 — Scope Tier Overlap

[findings or "No findings."]

---

## Recommended Next Steps

<!-- If HIGH findings exist: -->
1. Fix .claude/CLAUDE.md (P1 findings) or run /project-setup to initialize project config
2. Run install.sh from claude-config repo to deploy missing global skills (P2 findings)
3. Add missing SKILL.md files or remove stale registry entries (P3/P4 findings)
4. Review LOW findings at your discretion

<!-- If no HIGH or MEDIUM findings: -->
Project .claude/ configuration appears healthy — no required actions detected.
[Optional: list LOW/INFO items as review notes]

---

> This file is a runtime artifact. Add `.claude/claude-folder-audit-report.md` to `.gitignore` to prevent accidental commits.
```

**Global-config / global report format** (`MODE = global-config` or `MODE = global`):

```markdown
# ~/.claude/ Audit Report

Run date: <RUN_DATE>
Mode: <MODE>
Runtime root: <RUNTIME_ROOT>
Source root: <SOURCE_ROOT>
Summary: <N> HIGH, <N> MEDIUM, <N> LOW, <N> INFO

---

## Findings Summary

| Severity | Check | Description | Remediation |
|----------|-------|-------------|-------------|
...
| — | — | No HIGH / MEDIUM / LOW findings | — |

---

## Check 1 — Runtime Structure

[findings or "No findings."]

---

## Check 2 — Skill Deployment Completeness

[findings or "No findings."]

---

## Check 3 — Installation Drift

[findings or "No findings."]

---

## Check 4 — Orphaned Artifacts

[findings or "No findings."]

---

## Check 5 — Scope Tier Compliance

[findings or "No findings."]

---

## Recommended Next Steps

<!-- If HIGH findings exist: -->
1. Run install.sh from the claude-config repo to re-sync the runtime with the source
2. [additional steps for MEDIUM findings]
3. Review LOW findings at your discretion

<!-- If no HIGH or MEDIUM findings: -->
Runtime appears healthy — no required actions detected.
[Optional: list LOW/INFO items as review notes]
```

Severity labels in the report body MUST use bold Markdown: `**HIGH**`, `**MEDIUM**`, `**LOW**`, `**INFO**`.

The report MUST NOT suggest deleting any file without "Review manually" as a prerequisite step.

---

### Step 5 — Output summary to user

After writing the report, display to the user:

**If `MODE = project`**:
```
## .claude/ Project Audit Complete

Mode: project
Project root: <PROJECT_ROOT>

Findings:
  HIGH:   N
  MEDIUM: N
  LOW:    N
  INFO:   N

Report written to: <PROJECT_ROOT>/.claude/claude-folder-audit-report.md

[If HIGH > 0]:   ⚠️  Action required — see HIGH findings in the report.
[If HIGH = 0 and MEDIUM = 0]:  ✓  Project .claude/ configuration appears healthy.
```

**If `MODE = global-config` or `MODE = global`**:
```
## ~/.claude/ Audit Complete

Mode: <MODE>
Runtime root: <RUNTIME_ROOT>

Findings:
  HIGH:   N
  MEDIUM: N
  LOW:    N
  INFO:   N

Report written to: <RUNTIME_ROOT>/claude-folder-audit-report.md

[If HIGH > 0]:   ⚠️  Action required — see HIGH findings in the report.
[If HIGH = 0 and MEDIUM = 0]:  ✓  Runtime appears healthy.
```

---

## Rules

- Run all checks even if earlier checks produce HIGH findings — never abort early
- Severity caps: Check 3 (drift) MUST NOT exceed MEDIUM; Check 4 (orphaned artifacts) MUST NOT exceed MEDIUM; Check P5 (scope tier overlap) MUST NOT exceed LOW
- Path normalization MUST use the explicit env var priority chain — NEVER rely on shell tilde expansion
- The report file MUST be overwritten on every run (never appended)
- All displayed paths in report and output MUST use forward slashes
- INFO observations MAY omit the `Remediation:` line; HIGH, MEDIUM, and LOW findings MUST include one
- The report MUST be valid Markdown — all section headers use `##`, all finding labels use bold (`**HIGH**`, etc.)
- The skill MUST NOT emit any finding that recommends deleting a file without human review as a prerequisite
- On Windows, all path operations MUST use `$USERPROFILE` (not `~`) for the home directory
- In `project` mode, the skill MUST NOT audit `~/.claude/` as the primary target; references to `~/.claude/` are only for P2 and P5 reachability checks
- In `project` mode, the report MUST be written to `<PROJECT_ROOT>/.claude/claude-folder-audit-report.md` — NEVER to `~/.claude/`
