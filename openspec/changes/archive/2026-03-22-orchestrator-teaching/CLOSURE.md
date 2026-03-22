# Closure: 2026-03-21-orchestrator-teaching

Start date: 2026-03-21
Close date: 2026-03-22

## Summary

Added a teaching personality layer to the orchestrator with 5 principles: why-framing on Change Requests, educational gates on confirmation prompts, error reformulation for blocked/failed sub-agents in sdd-ff, post-cycle narrative reflection in sdd-ff Step 4 summaries, and progressive disclosure via new-user detection.

## Modified Specs

| Domain               | Action | Change                                                                                     |
| -------------------- | ------ | ------------------------------------------------------------------------------------------ |
| orchestrator-behavior | Added  | 7 new requirements: teaching principles section, why-framing, educational gates, error reformulation, post-cycle narrative, new-user detection, conciseness constraints |

## Modified Code Files

- `CLAUDE.md` — new `## Teaching Principles` section (5 rules); why-framing template in Change Request routing; new-user detection logic; educational sentence in Rule 7 confirmation
- `skills/sdd-ff/SKILL.md` — educational sentence in contradiction gate; error reformulation pattern for blocked/failed statuses; post-cycle narrative paragraph in Step 4 summary
- `openspec/specs/orchestrator-behavior/spec.md` — 7 new requirements with scenarios merged from delta spec
- `ai-context/architecture.md` — decision #26 for teaching principles layer
- `ai-context/changelog-ai.md` — session entry for teaching implementation

## Key Decisions Made

- Teaching principles placed in CLAUDE.md (always loaded, cross-cutting) rather than a separate skill
- New-user detection uses `openspec/changes/archive/` directory listing, not `ai-context/changelog-ai.md`
- Error reformulation scoped to sdd-ff only (the user-facing orchestrator)
- Post-cycle narrative added within existing Step 4, not as a new Step 5

## Lessons Learned

- The Teaching Principles section exceeded the 15-line limit when new-user detection subsection was included under it. The verify report flagged this as a WARNING — the 5 core rules themselves are within limit, but the full section is 24 lines. Future changes should consider whether subsections count toward parent section line limits.
- Delta spec referenced `changelog-ai.md` for new-user detection, but design correctly resolved to `archive/` directory. The delta spec artifact retained stale wording — cosmetic since master spec was merged with the correct approach.

## User Docs Reviewed

N/A — change does not affect user-facing workflow documentation (scenarios.md, quick-reference.md, onboarding.md do not exist in this project)
