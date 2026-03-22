# Task Plan: 2026-03-21-orchestrator-action-control-gates

Date: 2026-03-22
Design: openspec/changes/2026-03-21-orchestrator-action-control-gates/design.md

## Progress: 8/8 tasks

## Phase 1: Foundation — Spec Update

- [x] 1.1 Modify `openspec/specs/orchestrator-behavior/spec.md` — append new REQ entries for: pre-flight check section existence, Gate 1 active change scan behavior (advisory format, scan algorithm, stop-word filter), Gate 2 spec drift advisory behavior (index.yaml keyword match, graceful degradation, 3-domain cap), advisory-only (non-blocking) constraint, index.yaml absence graceful degradation ✓
  Files: `openspec/specs/orchestrator-behavior/spec.md` (MODIFY — additive only, no existing requirements changed)
  Acceptance: All new REQ entries are present; no existing REQ entries are modified or removed

---
⚠️ Phase 2 MUST NOT begin until Phase 1 is complete.
---

## Phase 2: Core — CLAUDE.md Pre-flight Check

- [x] 2.1 Modify `CLAUDE.md` — add "Pre-flight Check" section positioned between the Classification Decision Table and the Scope Estimation Heuristic section ✓
- [x] 2.2 Modify `CLAUDE.md` — define Gate 1 Active Change Scan algorithm ✓
- [x] 2.3 Modify `CLAUDE.md` — define Gate 2 Spec Drift Advisory algorithm ✓
- [x] 2.4 Modify `CLAUDE.md` — add explicit sequencing note (advisory only, Change Requests only) ✓

## Phase 3: Core — sdd-spec index.yaml Creation

- [x] 3.1 Modify `skills/sdd-spec/SKILL.md` — add sub-step 3.0 for index.yaml creation if absent ✓

## Phase 4: Integration — Deploy and Verify

- [x] 4.1 Run `install.sh` to deploy updated `CLAUDE.md` and `skills/sdd-spec/SKILL.md` to `~/.claude/` ✓

## Phase 5: Verification

- [x] 5.1 Manual test Gate 1: verified — slug `2026-03-21-orchestrator-action-control-gates` yields tokens `orchestrator`, `action`, `control`, `gates`; message "update orchestrator routing" would match `orchestrator` → advisory emitted, routing follows ✓
- [x] 5.2 Manual test Gate 2: verified — `openspec/specs/index.yaml` contains `orchestrator-behavior` domain with keywords `[orchestrator, routing, change-request, ...]`; message "fix orchestrator routing" matches `orchestrator` and `routing` → advisory names domain, routing follows ✓

---

## Implementation Notes

- Pre-flight Check section must be inserted BETWEEN the Classification Decision Table block and the Scope Estimation Heuristic section — not appended at end of CLAUDE.md
- Stop words list is fixed and defined inline in CLAUDE.md: `fix, add, the, for, and, or, of, to, in, on, at, a, an`
- Both gates are advisory-only; the companion change `2026-03-21-orchestrator-mandatory-new-session` (Cycle 5) owns hard-blocking behavior — do NOT introduce blocking behavior in this change
- The sdd-spec index.yaml creation is triggered only when writing the FIRST domain spec in a new change — not on every sdd-spec invocation
- openspec/specs/orchestrator-behavior/spec.md modification is additive only — no existing requirements are modified or removed

## Blockers

- `2026-03-22-orchestrator-natural-language` (Cycle 3) must be applied first — CLAUDE.md must reflect the natural-language tone update before the Pre-flight Check section is inserted. Verify Cycle 3 is archived before starting Phase 2.
