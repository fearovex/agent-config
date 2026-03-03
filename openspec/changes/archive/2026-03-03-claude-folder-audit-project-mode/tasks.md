# Task Plan: claude-folder-audit-project-mode

Date: 2026-03-03
Design: openspec/changes/claude-folder-audit-project-mode/design.md

## Progress: 7/7 tasks

---

## Phase 1: Frontmatter and Preamble Update

- [ ] 1.1 Modify `skills/claude-folder-audit/SKILL.md` — update the YAML frontmatter `description:` field to include "project mode" in the list of supported execution contexts (e.g., "Audits the ~/.claude/ runtime folder or a project's .claude/ configuration for installation drift, skill deployment gaps, orphaned artifacts, and scope tier compliance.")
- [ ] 1.2 Modify `skills/claude-folder-audit/SKILL.md` — update the `> ...` tagline (line directly below the `# claude-folder-audit` heading) to reflect that the skill also audits project-local `.claude/` directories and can write to `.claude/claude-folder-audit-report.md`

---

## Phase 2: Mode Detection (Step 2)

- [ ] 2.1 Modify `skills/claude-folder-audit/SKILL.md` — replace the two-branch Step 2 detection block with a three-branch priority chain:
  1. `global-config` — both `install.sh` AND `skills/` directory present at CWD root → `MODE = global-config`; `SOURCE_ROOT` confirmed
  2. `project` — `.claude/` directory present at CWD root (condition 1 false) → `MODE = project`; set `PROJECT_ROOT = <absolute CWD>`; set `PROJECT_CLAUDE_DIR = <absolute CWD>/.claude/`
  3. `global` — all other locations → `MODE = global`; `SOURCE_ROOT = "Not detected"`

  Preserve the fallback rule: if mode cannot be determined, default to `global`.

---

## Phase 3: Project-Mode Check Block (Step 3)

- [ ] 3.1 Modify `skills/claude-folder-audit/SKILL.md` — insert a new `MODE = project` branch at the top of Step 3, before the existing Check 1–5 logic. The branch header must read: "**If `MODE = project`** — run Checks P1–P5 below (skip Checks 1–5)." Include all five project checks P1–P5 with the exact finding schemas, severity levels, skip/INFO behaviors, and remediation text specified in:
  - `openspec/changes/claude-folder-audit-project-mode/specs/folder-audit-execution/spec.md` (P1–P5 behavior)
  - `openspec/changes/claude-folder-audit-project-mode/design.md` (Check Specifications section)

  **P1 — CLAUDE.md Presence and Skills Registry**: check that `PROJECT_CLAUDE_DIR/CLAUDE.md` exists and contains `## Skills Registry` section (or `~/.claude/skills/` / `.claude/skills/` path patterns); HIGH if absent or no registry.

  **P2 — Global-Path Skill Registration Verification**: parse global-tier registrations (`~/.claude/skills/<n>/SKILL.md` patterns) from CLAUDE.md; HIGH if SKILL.md not found on disk; INFO skip if P1 found no CLAUDE.md or no global registrations.

  **P3 — Local-Path Skill Registration Verification**: parse local-tier registrations (`.claude/skills/<n>/SKILL.md` patterns, but NOT lines that also match `~/.claude/skills/`) from CLAUDE.md; HIGH if SKILL.md not found at `PROJECT_ROOT/.claude/skills/<n>/SKILL.md`; INFO skip if P1 found no CLAUDE.md or no local registrations.

  **P4 — Orphaned Local Skills**: enumerate all `PROJECT_ROOT/.claude/skills/*/SKILL.md` files on disk; MEDIUM for each whose directory name is absent from the P1 local-tier set; INFO if `.claude/skills/` does not exist or is empty.

  **P5 — Scope Tier Overlap**: for each local-tier skill name from P1, check if `CLAUDE_DIR/skills/<name>/` also exists; LOW if found in both tiers; INFO if no `.claude/skills/` or if `~/.claude/skills/` is not accessible. Severity MUST NOT exceed LOW.

- [ ] 3.2 Modify `skills/claude-folder-audit/SKILL.md` — wrap the existing Check 1–5 block with an explicit guard: "**If `MODE = global-config` or `MODE = global`** — run Checks 1–5 below." This makes the mutual exclusion with the project-mode branch unambiguous.

---

## Phase 4: Report Generation and Output (Steps 4 and 5)

- [ ] 4.1 Modify `skills/claude-folder-audit/SKILL.md` — update Step 4 to parameterize the report write path by mode:
  - `MODE = project` → write to `PROJECT_ROOT/.claude/claude-folder-audit-report.md`
  - `MODE = global-config` or `MODE = global` → write to `RUNTIME_ROOT/claude-folder-audit-report.md` (unchanged)

  Also update the project-mode report format to use the project-specific header fields and check section labels (P1–P5) as specified in `openspec/changes/claude-folder-audit-project-mode/specs/folder-audit-reporting/spec.md`:
  - Header fields: `Run date:`, `Mode: project`, `Project root:`, `Project .claude/ dir:`, `Global runtime:`, `Summary:`
  - Per-check sections: `## Check P1 — CLAUDE.md Presence and Skills Registry` through `## Check P5 — Scope Tier Overlap`
  - Footer note: "This file is a runtime artifact. Add `.claude/claude-folder-audit-report.md` to `.gitignore` to prevent accidental commits."
  - Recommended Next Steps section using project-context-aware guidance (fix `.claude/CLAUDE.md` for P1, run `install.sh` for P2, fix `.claude/skills/` for P3/P4)

- [ ] 4.2 Modify `skills/claude-folder-audit/SKILL.md` — update Step 5 (output summary to user) so that when `MODE = project`, the displayed `Report written to:` line shows the expanded absolute path `<PROJECT_ROOT>/.claude/claude-folder-audit-report.md` (not the global runtime path).

---

## Phase 5: Rules Update

- [ ] 5.1 Modify `skills/claude-folder-audit/SKILL.md` — append two new rules to the `## Rules` section:
  - "In `project` mode, the skill MUST NOT audit `~/.claude/` as the primary target; references to `~/.claude/` are only for P2 and P5 reachability checks"
  - "In `project` mode, the report MUST be written to `<PROJECT_ROOT>/.claude/claude-folder-audit-report.md` — NEVER to `~/.claude/`"

---

## Implementation Notes

- The change is confined entirely to `skills/claude-folder-audit/SKILL.md`. No other files are created or modified during apply.
- After applying all tasks, run `bash install.sh` from the repo root to deploy the updated skill to `~/.claude/skills/claude-folder-audit/SKILL.md`.
- The P1 parsing contract (global-tier match before local-tier match to handle the substring overlap between `~/.claude/skills/` and `.claude/skills/`) MUST be respected in task 3.1.
- All 5 project checks (P1–P5) MUST run even when P1 produces HIGH findings. P2 and P3 record INFO skip notes if CLAUDE.md is absent; P4 and P5 still execute against the filesystem.
- Check P5 severity is capped at LOW — do not raise to MEDIUM or HIGH regardless of findings count.
- The existing Checks 1–5 and their behavior MUST remain identical after the change. Zero modifications to the check 1–5 logic are permitted.

## Blockers

None.
