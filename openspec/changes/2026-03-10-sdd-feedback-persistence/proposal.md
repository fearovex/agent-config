# Proposal: sdd-feedback-persistence

Date: 2026-03-10
Status: Draft

## Intent

Establish a protocol that converts any user feedback or improvement idea into a persisted `proposal.md` in `openspec/changes/` before any SDD cycle is initiated, ensuring that no actionable feedback is lost to chat session expiration.

## Motivation

When the user provides feedback (bug observations, improvement ideas, process complaints), the current workflow allows — and implicitly encourages — immediately starting `/sdd-ff` or `/sdd-new` from the same session. This means:

1. The feedback exists only in the chat context
2. If the session ends before implementation: the feedback is lost
3. If the conversation is compressed: the feedback context degrades
4. There is no backlog of pending improvements — work items exist only as implicit intentions

The correct model: feedback → `proposal.md` on disk → separate session for implementation. The proposal is the durable record; the session is ephemeral.

This also applies to feedback sessions themselves: a session that collects feedback should only produce `proposal.md` files, never implementations.

## Scope

### Included

- Define a **Feedback Session Protocol** rule in CLAUDE.md:
  - A session that starts with user feedback must produce `proposal.md` files only — no SDD cycles, no implementations
  - The orchestrator must not offer `/sdd-ff` or `/sdd-apply` within a feedback session
  - Each feedback item maps to exactly one `proposal.md` in `openspec/changes/<date-slug>/`
- Add a `feedback` intake mode to the orchestrator behavior: when the user provides a list of observations or complaints, the orchestrator creates proposals, not cycles
- Document the feedback → proposal → separate session workflow in `docs/workflows/feedback-to-proposal.md`
- Update CLAUDE.md with the rule: "Never start an SDD cycle in the same session as feedback collection"

### Excluded

- Automated feedback parsing (proposals are written by the AI reading the feedback, not by a parser)
- Integration with external issue trackers (Jira, GitHub Issues)
- Changes to any SDD phase skills

## Proposed Approach

### Feedback Session Protocol

When the user provides feedback items (observations, complaints, improvement ideas):

```
RULE: This is a feedback session.
  1. Convert each feedback item to a proposal.md
  2. Store in openspec/changes/YYYY-MM-DD-<slug>/proposal.md
  3. Do NOT suggest /sdd-ff, /sdd-apply, or any implementation command
  4. End the session by listing the proposals created with their paths
  5. The user initiates implementation in a new session by reading the proposal
```

### Proposal quality in feedback sessions

Each `proposal.md` created from feedback must include:
- `## Intent` — what the change achieves
- `## Motivation` — the specific feedback that triggered it (quoted or paraphrased)
- `## Scope` — what is included/excluded
- `## Success Criteria` — at least 3 verifiable criteria

### CLAUDE.md rule addition

Add to the Unbreakable Rules section:

> **Rule 5 — Feedback persistence**
> A session that begins with user feedback (bug reports, process observations, improvement ideas) MUST produce only `proposal.md` files. No SDD cycles, no implementations, no `/sdd-ff` suggestions within the same session.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `CLAUDE.md` | Modified | High — new unbreakable rule added |
| `docs/workflows/feedback-to-proposal.md` | New | Medium — protocol documented |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Orchestrator forgets the rule mid-session | Medium | Medium | Rule is in Unbreakable Rules section — highest priority in CLAUDE.md |
| User insists on implementing in the same session | Medium | Low | Orchestrator explains the rule and offers to implement only after creating the proposal |

## Success Criteria

- [ ] CLAUDE.md Unbreakable Rules section contains Rule 5 — Feedback persistence
- [ ] `docs/workflows/feedback-to-proposal.md` documents the feedback → proposal → separate session workflow
- [ ] When the orchestrator receives feedback items, it creates `proposal.md` files and does NOT suggest `/sdd-ff`
- [ ] Each `proposal.md` created from feedback includes Intent, Motivation (with feedback reference), Scope, and Success Criteria
- [ ] `verify-report.md` has at least one [x] criterion checked
