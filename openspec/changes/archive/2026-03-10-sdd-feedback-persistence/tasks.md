# Task Plan: sdd-feedback-persistence

Date: 2026-03-10
Design: openspec/changes/2026-03-10-sdd-feedback-persistence/design.md

## Progress: 4/4 tasks

## Phase 1: Configuration — Add Rule 5 to CLAUDE.md

- [x] 1.1 Modify `CLAUDE.md` — Add "Rule 5 — Feedback persistence" to the Unbreakable Rules section after Rule 4 (Sync discipline), stating that feedback sessions MUST produce only `proposal.md` files and MUST NOT start `/sdd-ff`, `/sdd-new`, `/sdd-apply`, or other implementation commands in the same session ✓

## Phase 2: Documentation — Create feedback-to-proposal workflow

- [x] 2.1 Create `docs/workflows/feedback-to-proposal.md` documenting the end-to-end protocol: (1) what constitutes a feedback session, (2) the proposal structure and quality requirements, (3) how to initiate implementation in a separate session, and (4) the folder layout for persisted proposals in `openspec/changes/` ✓
- [x] 2.2 Ensure `docs/workflows/feedback-to-proposal.md` includes at least one worked example showing user feedback → orchestrator action → created `proposal.md` with Intent, Motivation, Scope, and Success Criteria sections ✓

## Phase 3: Verification and Memory Update

- [x] 3.1 Run `/project-audit` to verify the audit score remains >= previous (expected to pass — this is documentation only) ✓ score: 98/100 (was 93)
- [x] 3.2 Update `ai-context/changelog-ai.md` with a session note recording the addition of the feedback persistence rule and workflow documentation ✓

---

## Implementation Notes

- Rule 5 must be positioned in the Unbreakable Rules section (highest priority for the orchestrator to read)
- The rule text should reference the spec scenarios and explicitly forbid `/sdd-ff`, `/sdd-apply`, and other implementation commands within a feedback session
- The workflow document should be human-readable and clarify the distinction between "feedback session" (produces only proposals) and "implementation session" (consumes a proposal and runs `/sdd-ff` or `/sdd-new`)
- The worked example in the workflow doc should use concrete feedback phrasing and show the resulting `proposal.md` structure with all required sections
- No skills are modified; this is purely orchestrator behavior change via documentation and configuration

## Blockers

None. All artifacts (CLAUDE.md and docs/workflows/) exist and are writable.
