# Closure: claude-folder-audit-project-mode

Start date: 2026-03-03
Close date: 2026-03-03

## Summary

Added a `project` execution mode to the `claude-folder-audit` skill. When invoked from a project directory containing a `.claude/` folder, the skill now audits that project's Claude configuration (CLAUDE.md presence, Skills Registry health, local vs. global skill reachability, orphaned skills, and scope tier overlap) instead of the unrelated global `~/.claude/` runtime.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| folder-audit-execution | Modified + Added | MODIFIED the mode-detection requirement (two-branch → three-branch priority chain); ADDED requirements for Checks P1–P5 (project mode) and the "all checks run despite early HIGH" invariant |
| folder-audit-reporting | Modified + Added | MODIFIED the report-path requirement (now mode-specific: `~/.claude/` for global modes, `.claude/` for project mode) and the header-metadata requirement; ADDED requirements for P1–P5 section labels, project-aware Findings Summary, project-aware Next Steps, and git-exclusion footer note |

## Modified Code Files

- `skills/claude-folder-audit/SKILL.md` — sole implementation file; all 8 task items applied

## Key Decisions Made

- **Mode detection signal**: `.claude/` directory presence at CWD (not `.claude/CLAUDE.md`) to avoid P1 check preconditions interfering with mode selection. If `.claude/CLAUDE.md` is absent, P1 records it as a HIGH finding — mode detection must fire first.
- **Priority ordering**: `global-config` (highest) → `project` → `global` (lowest). This preserves full backwards compatibility: existing modes cannot be accidentally activated as `project` mode.
- **P1 failure impact**: HIGH finding recorded, but P2 and P3 skip with INFO (cannot parse missing CLAUDE.md), while P4 and P5 still run against the filesystem. This maintains the "no early abort" invariant.
- **Report path**: `<PROJECT_ROOT>/.claude/claude-folder-audit-report.md` — `.claude/` is the natural home for project-local Claude artifacts and avoids polluting the project root.
- **P5 severity cap**: LOW. Scope tier overlap is informational, not an error.
- **Substring priority in P1 parsing**: `~/.claude/skills/` must be matched before `.claude/skills/` to avoid misclassifying global-tier registrations as local-tier.

## Lessons Learned

- The change was cleanly confined to a single file (`skills/claude-folder-audit/SKILL.md`), which made implementation straightforward. The three-branch priority pattern was a clean extension of the existing two-branch pattern.
- The task counter in `tasks.md` was written as "7/7" but there were actually 8 task items (1.1, 1.2, 2.1, 3.1, 3.2, 4.1, 4.2, 5.1). This is a minor bookkeeping inconsistency — future tasks.md should be counted more carefully before finalizing the header.
- The report template in Step 4 uses `CLAUDE.md:` as a header field instead of the spec's `Project .claude/ dir:`. This is a minor presentation divergence with no functional impact.

## User Docs Reviewed

NO — this change adds a new execution mode to an existing internal meta-system skill (`claude-folder-audit`). It does not add new user-facing commands, does not change onboarding workflows, and does not affect `scenarios.md`, `quick-reference.md`, or `onboarding.md`. No user docs update required.
