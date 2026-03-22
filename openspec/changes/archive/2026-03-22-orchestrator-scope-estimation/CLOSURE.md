# Closure: orchestrator-scope-estimation

Start date: 2026-03-22
Close date: 2026-03-22

## Summary

Introduced a Scope Estimation Heuristic that classifies Change Requests into Trivial, Moderate, or Complex tiers before routing, so the SDD response is proportional to the actual change risk. Trivial changes can be applied inline (with user confirmation), Moderate routes to /sdd-ff, and Complex routes to /sdd-new.

## Modified Specs

| Domain               | Action   | Change                                                                 |
| -------------------- | -------- | ---------------------------------------------------------------------- |
| orchestrator-behavior | Added    | Scope estimation requirement with three tiers and detection signals     |
| orchestrator-behavior | Added    | Scope estimation documented in dedicated CLAUDE.md section requirement  |
| orchestrator-behavior | Modified | "Never writes inline code" requirement gains Trivial tier exception     |
| orchestrator-behavior | Added    | Unbreakable Rule 1 formal Trivial tier exception requirement            |
| orchestrator-behavior | Added    | Scope tier visibility in response signal (optional)                     |

## Modified Code Files

- `CLAUDE.md` — new Scope Estimation Heuristic section, Classification Decision Table cross-reference, Unbreakable Rule 1 exception clause, response signal tier suffix documentation
- `openspec/specs/orchestrator-behavior/spec.md` — 5 new/modified requirements with scenarios and validation criteria

## Key Decisions Made

- Scope estimation is inline CLAUDE.md logic (not a separate skill) — consistent with ambiguity heuristics pattern
- Trivial tier requires ALL conditions (restrictive); Complex requires ANY signal (permissive); Moderate is the residual default
- Trivial inline apply is a formal exception to Unbreakable Rule 1, requiring explicit user confirmation
- Default scope is always Moderate — never Trivial under ambiguity

## Lessons Learned

- The contradiction with Unbreakable Rule 1 was identified during exploration and resolved as a formal exception rather than a silent override, preserving Rule 1's authority for non-Trivial changes.

## User Docs Reviewed

N/A — change does not affect user-facing workflows (orchestrator internal behavior only)
