# Closure: skill-scope-global-vs-project

Start date: 2026-03-02
Close date: 2026-03-02

## Summary

Changed the default skill placement from global (`~/.claude/skills/`) to project-local
(`.claude/skills/`) so that skills added to a project are versioned in the repository
and available to all collaborators. Three skills were updated: `skill-add` (copy-first
default), `skill-creator` (context-aware placement default), and `project-fix`
(`move-to-global` demoted from automated action to informational recommendation).

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| skill-placement | Created | New master spec defining the two-tier placement model, `/skill-add` default behavior, registry path conventions, and collaborator access guarantees |
| skill-creation | Added | New requirement block: skill-creator defaults to project-local placement inside a project context, with 4 new scenarios and an additional rule |
| project-fix-behavior | Created | New master spec defining the demoted `move-to-global` behavior: informational-only output, no file-system action, two-tier model explanation |

## Modified Code Files

| File | Change |
|------|--------|
| `skills/skill-add/SKILL.md` | Default strategy switched from Option A (global path reference) to local copy; Option A retained as explicit override; registry path format updated to `.claude/skills/<name>/SKILL.md`; origin annotation added to local copies; duplicate check extended to both tiers |
| `skills/skill-creator/SKILL.md` | Context detection added in Step 1; project-local set as default placement inside any project that is not `claude-config`; global remains default inside `claude-config`; `/skill-add` delegation section updated to remove duplicated strategy logic |
| `skills/project-fix/SKILL.md` | `move-to-global` Phase 5 handler converted from automated file-move to informational output only; two-tier model explanation added; `move-to-global` items excluded from automated correction count |
| `CLAUDE.md` | Two-tier comment block added to Skills Registry section explaining `.claude/skills/` vs `~/.claude/skills/` path formats |

## Key Decisions Made

- **Local copy as default**: A local copy makes projects self-contained and git-sharable without new abstractions. A reference cannot be retroactively resolved on a collaborator's machine; a copy can always be promoted to global manually.
- **Context detection in skill-creator**: Implicit detection via `openspec/` or `.claude/` presence, with `claude-config` identity excluded by a two-factor check (`install.sh` + config name). No user configuration required for the common case.
- **move-to-global demoted, not removed**: Removing the handler would silently break existing FIX_MANIFEST entries. Keeping it as informational preserves the audit signal while eliminating the automation that reinforced the anti-pattern.
- **Origin annotation in local copy**: HTML comment header in the copied SKILL.md records the source path and copy date — co-located, tooling-free, survives file moves.
- **Two-tier comment in CLAUDE.md**: Co-located with the path entries it explains; survives copy-paste of the registry section.

## Lessons Learned

- The `/skill-add in claude-config` scenario is not enforced by `skill-add` itself — the claude-config exclusion is only enforced by `skill-creator`. A future change could add a context-detection guard in `skill-add` as well (noted as a suggestion in the verify-report).
- The 14-task cycle was completed and verified in a single day with no scope creep, confirming that targeted behavioral changes to Markdown skill files are low-risk and fast to deliver.

## User Docs Reviewed

N/A — this change updates internal skill behavior (`skill-add`, `skill-creator`, `project-fix`). It does not add, remove, or rename user-facing commands, and does not alter onboarding workflows. No update to `scenarios.md`, `quick-reference.md`, or `onboarding.md` is required.
