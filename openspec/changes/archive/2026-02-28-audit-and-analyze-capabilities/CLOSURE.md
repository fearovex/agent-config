# Closure: audit-and-analyze-capabilities

Start date: 2026-02-28
Close date: 2026-02-28

## Summary

Fixed spec-SKILL.md contradictions, added missing user guidance for audit/analyze/memory skill interactions, and documented the marker-awareness gap as a known issue.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| project-analysis | Modified | Fixed ai-context/ creation scenario (GAP-2), corrected marker format (GAP-7) |
| memory-management | Created | Added conventions.md support requirement |
| skill-guidance | Created | Added CLAUDE.md skill overlap guidance requirement |
| known-issues | Created | Added marker-awareness documentation requirement |

## Modified Code Files

- `openspec/specs/project-analysis/spec.md` — Fixed contradictory scenario and marker format
- `skills/memory-manager/SKILL.md` — Added conventions.md to /memory-update decision table and Step 4b
- `CLAUDE.md` — Added "Skill Overlap — When to Use Which" guidance section
- `ai-context/known-issues.md` — Added marker-awareness gap entry

## Key Decisions Made

- Approach A (Document and Clarify) chosen over Approach B (Ownership Model) or C (Merge Skills)
- Spec updated to match SKILL.md (not the other way around) — SKILL.md is the runtime source of truth
- Marker-awareness gap documented as known issue with Approach B deferred for future

## Lessons Learned

- Three skills writing to the same ai-context/ files without coordination is a design smell worth documenting even if no issues have been observed yet

## User Docs Reviewed

N/A — change does not affect user-facing workflows
