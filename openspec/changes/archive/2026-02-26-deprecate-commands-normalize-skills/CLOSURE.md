# Closure: deprecate-commands-normalize-skills

Start date: 2026-02-26
Close date: 2026-02-26

## Summary

Removed Dimension 5 (Commands Quality) entirely from `project-audit`, redistributed its 10 points to D4 (Skills Quality, now 20 pts), and added a passive INFO notice for legacy `commands/` directories. `project-fix` and `project-setup` now explicitly prohibit any interaction with `.claude/commands/`.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| audit-dimensions | Created | New master spec — observable behavior of project-audit dimensions after commands deprecation |
| audit-scoring | Created | New master spec — scoring model with D4 at 20 pts, no D5, total = 100 |
| fix-setup-behavior | Created | New master spec — project-fix and project-setup no-commands constraints |

## Modified Code Files

- `skills/project-audit/SKILL.md` — removed D5, updated D1, updated D4 to 20 pts, added legacy commands/ INFO check
- `skills/project-fix/SKILL.md` — removed step 2.4 (Fix Commands registry), added explicit no-commands rule
- `skills/project-setup/SKILL.md` — added explicit no-commands rule to Rules section
- `CLAUDE.md` (repo root + `~/.claude/CLAUDE.md`) — removed commands registry references

## Key Decisions Made

- D5 (Commands Quality) is permanently removed; `skills/` is the sole extensibility mechanism going forward
- The 10 freed points go to D4 as a scored global skills coverage sub-check (D4c), making the redistribution earn-able rather than automatic
- Legacy `commands/` directories receive a zero-penalty LOW INFO finding — no migration is forced, but users are guided
- `project-fix` skips any stale `fix_commands_registry` FIX_MANIFEST actions silently; no hard error

## Lessons Learned

- Removing a dimension mid-audit cycle causes D8 (active changes penalty) to briefly show a 3-pt deduction. This resolves on archive and should not be treated as a regression signal.
- The verify-report confirmed a +3 score improvement (94 → 97) immediately after apply, demonstrating that the false penalty was real and affected the self-audit baseline.

## User Docs Reviewed

N/A — this change pre-dates the User Documentation checkbox requirement in the verify-report template. No user-facing workflow documents (scenarios.md, quick-reference.md, onboarding.md) required updates for this internal audit tooling change.
