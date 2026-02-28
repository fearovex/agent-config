# Closure: global-config-skill-audit

Start date: 2026-02-27
Close date: 2026-02-27

## Summary

Extended `project-audit` D9 and D10 to recognize the global-config repo's root-level `skills/` directory as equivalent to `.claude/skills/` in standard projects, eliminating the false "skipped" outcome on both dimensions when auditing `claude-config` itself.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| audit-dimensions | Modified | D10 heuristic fallback now uses `$LOCAL_SKILLS_DIR` instead of `.claude/skills/` |
| audit-dimensions | Added | D9 uses `LOCAL_SKILLS_DIR` requirement + 4 scenarios |
| audit-dimensions | Added | D10-a/D10-d path references use `LOCAL_SKILLS_DIR` requirement + 2 scenarios |
| audit-execution | Modified | Phase A output schema extended with `LOCAL_SKILLS_DIR` key + 4 scenarios |

## Modified Code Files

- `skills/project-audit/SKILL.md` — 5 targeted edits:
  1. Phase A Bash script: `LOCAL_SKILLS_DIR` detection block (after SYNC_SH_EXISTS)
  2. Phase A output key schema: `LOCAL_SKILLS_DIR` entry added
  3. D9-1 skip condition: uses `$LOCAL_SKILLS_DIR` + global-config circular detection note
  4. D9 report format: `[value of $LOCAL_SKILLS_DIR]` header
  5. D10 Source 1 + D10-a: `$LOCAL_SKILLS_DIR` references

## Key Decisions Made

- Detection reuses existing Condition A (install.sh + sync.sh) and Condition B (openspec/config.yaml framework string) from D1 — no new detection mechanism
- `LOCAL_SKILLS_DIR` is a relative string (`"skills"` or `".claude/skills"`), always used as `$PROJECT/$LOCAL_SKILLS_DIR` in path checks
- D9 global-config circular detection: all skills under `skills/` match `~/.claude/skills/` by design — documented as `keep` disposition, not a warning

## Lessons Learned

- D10 colateral finding: Gentleman-Skills imports (smart-commit, github-pr, django-drf, electron, react-native and ~18 others) are missing `**Triggers**` and/or `## Rules` sections per SDD standard. This is a separate concern — deferred to follow-up change `normalize-tech-skill-structure`.

## User Docs Reviewed

N/A — this change affects audit tool behavior only, not user-facing onboarding workflows. No update needed to scenarios.md, quick-reference.md, or onboarding.md.
