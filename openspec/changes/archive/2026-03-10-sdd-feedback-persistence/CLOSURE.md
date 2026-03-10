# Closure: sdd-feedback-persistence

Start date: 2026-03-10
Close date: 2026-03-10

## Summary

Added Rule 5 — Feedback persistence to CLAUDE.md Unbreakable Rules and created `docs/workflows/feedback-to-proposal.md` to enforce a two-session model: feedback is persisted as proposals before any SDD implementation cycle begins.

## Modified Specs

| Domain | Action | Change |
|--------|--------|--------|
| feedback-session | Created | New master spec with 5 requirements and 11 scenarios covering feedback persistence, proposal structure, session-closing summary, workflow documentation, and Rule 5 in CLAUDE.md |

## Modified Code Files

| File | Change |
|------|--------|
| `CLAUDE.md` | Added Rule 5 — Feedback persistence to Unbreakable Rules (after Rule 4) |
| `docs/workflows/feedback-to-proposal.md` | Created — end-to-end protocol document with worked example |
| `ai-context/changelog-ai.md` | Session entry added for 2026-03-10 |

## Key Decisions Made

- Rule placed in **Unbreakable Rules** (not a new skill or config file) — highest priority section Claude reads, ensuring compliance without additional file reads at session start
- Feedback session detection is **implicit** (orchestrator judgment by content pattern) — no explicit `/feedback` command needed, avoids surface area growth
- Workflow documented in `docs/workflows/` (not `ai-context/`) — separates operational guides from AI memory context, keeps CLAUDE.md focused on rules

## Lessons Learned

- The two-session model is a behavioral constraint on the orchestrator, not a technical feature — documentation + rule placement is the correct implementation mechanism
- task 3.1 (project-audit) was run in the same session as sdd-apply, which is correct, but the checkbox was not auto-ticked by the apply agent — the verify step caught and resolved this

## User Docs Reviewed

NO — this change modifies orchestrator behavior rules, not user-facing skill workflows. `scenarios.md`, `quick-reference.md`, and `onboarding.md` do not require updates.
