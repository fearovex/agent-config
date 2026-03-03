---
name: claude-folder-audit
description: >
  Audits the ~/.claude/ runtime folder for installation drift, skill deployment gaps,
  orphaned artifacts, and scope tier compliance. Read-only. Produces claude-folder-audit-report.md.
  Trigger: /claude-folder-audit, audit runtime, check installation drift, verify skill deployment.
format: procedural
---

# claude-folder-audit

> Audits the `~/.claude/` runtime folder for installation drift, missing skills, orphaned artifacts, and scope tier compliance. Read-only. Produces `~/.claude/claude-folder-audit-report.md`.

**Triggers**: `/claude-folder-audit`, audit runtime, audit .claude folder, check installation drift, verify skill deployment, runtime out of sync

---

## Purpose

This skill diagnoses the health of the `~/.claude/` runtime folder — the directory where `install.sh` deploys configuration, skills, and tooling from the source repo. It finds:

- **Installation drift**: source repo updated but `install.sh` not re-run
- **Missing skills**: skills in the source repo not deployed to `~/.claude/skills/`
- **Orphaned artifacts**: files in `~/.claude/` that don't belong to the expected layout
- **Scope tier conflicts**: skills duplicated across the global and project-local tiers

It is **strictly read-only**. The only file it writes is the report at `~/.claude/claude-folder-audit-report.md`.

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
- `SOURCE_ROOT` = current working directory (e.g., `C:/Users/juanp/claude-config`) — will be confirmed or cleared in Step 2
- `RUN_DATE` = current date and time in ISO 8601 format

### Step 2 — Detect execution mode

Check whether `install.sh` AND `skills/` (as a directory) both exist at the current working directory root.

- **If both exist** → `MODE = global-config`; the cwd IS the source repo; `SOURCE_ROOT` is confirmed
- **If either is absent** → `MODE = global`; `SOURCE_ROOT = "Not detected"`

The mode MUST be determined before running any check. If mode cannot be determined, default to `global`.

---

### Step 3 — Run all 5 audit checks (always run all — no early abort)

Accumulate findings in a list. Each finding has:

```
severity: HIGH | MEDIUM | LOW | INFO
check:    1..5
title:    short description
detail:   what was observed
remediation: exact step to resolve (optional for INFO)
```

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

> **Known limitation**: mtime is an imprecise proxy for deployment state. A `.installed-at` metadata file (future improvement) would provide exact tracking. This limitation is documented here and does not block the audit.

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

Write the report to `RUNTIME_ROOT/claude-folder-audit-report.md`. **Overwrite** any previous report (do not append).

Report format:

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
| HIGH | 1 | CLAUDE.md missing from ~/.claude/ | Run install.sh |
| ... | | | |

<!-- If no HIGH/MEDIUM/LOW findings: -->
| — | — | No HIGH / MEDIUM / LOW findings | — |

---

## Check 1 — Runtime Structure

[**HIGH** | **MEDIUM** | **LOW** | **INFO**] **[Title]**
Observed: [detail]
Remediation: `[command or instruction]`

No findings.  ← when no findings for this check

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
1. Run `install.sh` from the claude-config repo to re-sync the runtime with the source
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

- Run all 5 checks even if earlier checks produce HIGH findings — never abort early
- Severity caps: Check 3 (drift) MUST NOT exceed MEDIUM; Check 4 (orphaned artifacts) MUST NOT exceed MEDIUM
- Path normalization MUST use the explicit env var priority chain — NEVER rely on shell tilde expansion
- The report file MUST be overwritten on every run (never appended)
- The ONLY file write permitted during execution is `RUNTIME_ROOT/claude-folder-audit-report.md`
- All displayed paths in report and output MUST use forward slashes
- INFO observations MAY omit the `Remediation:` line; HIGH, MEDIUM, and LOW findings MUST include one
- The report MUST be valid Markdown — all section headers use `##`, all finding labels use bold (`**HIGH**`, etc.)
- The skill MUST NOT emit any finding that recommends deleting a file without human review as a prerequisite
- On Windows, all path operations MUST use `$USERPROFILE` (not `~`) for the home directory
