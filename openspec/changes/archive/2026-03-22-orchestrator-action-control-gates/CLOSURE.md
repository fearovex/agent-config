# Closure: 2026-03-21-orchestrator-action-control-gates

Start date: 2026-03-21
Close date: 2026-03-22

## Summary

Added two advisory-only Pre-flight Check gates to the orchestrator's Change Request routing pipeline: Gate 1 (active change scan using stop-word-filtered slug token overlap) and Gate 2 (spec drift advisory via index.yaml keyword match). Also updated `sdd-spec` to create `index.yaml` when absent on first spec write.

## Modified Specs

| Domain | Action | Change |
| --- | --- | --- |
| orchestrator-behavior | Modified | Added requirements for Gate 1 (active change scan) and Gate 2 (spec drift advisory) |
| sdd-spec-index-creation | Created | New domain spec for sdd-spec creating index.yaml when absent |

## Modified Code Files

- `CLAUDE.md` — Pre-flight Check section added between Classification Decision Table and Scope Estimation Heuristic
- `skills/sdd-spec/SKILL.md` — Sub-step 3.0 added: create index.yaml if absent when writing first spec
- `openspec/specs/orchestrator-behavior/spec.md` — New REQ entries appended (lines 1490+)
- `openspec/specs/sdd-spec-index-creation/spec.md` — Created as new master spec

## Key Decisions Made

- Both gates are advisory-only (non-blocking) — user always receives routing recommendation regardless of advisory output
- Gate 1 stop-word filter: tokens of length ≤ 3 or common verbs (fix, add, etc.) are discarded to prevent false positives
- Gate 2 is keyword-match only — no spec files are read at pre-flight stage (performance constraint)
- index.yaml absence degrades gracefully (Gate 2 skips silently)
- Feedback session detection remains user-initiated (Rule 5); hard-blocking behavior delegated to separate change (mandatory-new-session, Cycle 5)

## Lessons Learned

- Gate 2 scope for Trivial tier is an open UX question: Trivial doc-fix messages may generate spec drift advisories for keyword-matching domains. Left as a future improvement if noise is observed in practice.

## User Docs Reviewed

NO — change affects orchestrator internal routing pipeline only; does not add, remove, or rename user-facing skills or commands.
