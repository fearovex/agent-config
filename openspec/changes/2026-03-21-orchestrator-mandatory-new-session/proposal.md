# Proposal: Mandatory New Session Per SDD Cycle

## Problem Statement

Rule 6 (Cross-session ff handoff) currently activates only when the user explicitly states "new session", "next chat", or "context compaction." This is opt-in — users who don't know the rule skip it entirely.

The user has determined that **every SDD cycle must begin in a new session**, not just when the user requests it. This is a workflow discipline decision: mixing exploration, discussion, and execution in a single session degrades context quality and blurs the audit trail.

## Proposed Solution

Convert Rule 6 from opt-in to **always-on mandatory behavior**:

### New Rule: One Cycle Per Session

Every time the orchestrator would recommend `/sdd-ff` or `/sdd-new` in response to a Change Request, it MUST:

1. **Check if any SDD phase work has already occurred in this session** (heuristic: has a `proposal.md` been created, or has a Task been launched for sdd-explore/sdd-propose/sdd-spec/sdd-design?)
2. **If this is the first cycle attempt in the session**: proceed normally — recommend `/sdd-ff`, create `proposal.md` pre-population per Rule 6, remind user to start a new session before running the command
3. **If a cycle has already been initiated in this session**: block and explain — "Each SDD cycle runs in its own session. This session already has `<change-name>` in flight. Open a new chat and run: `/sdd-ff <new-slug>`"

### Mandatory proposal.md Creation

Rule 6 currently requires `proposal.md` only when "context reset is imminent." The new rule requires it **always** before any `/sdd-ff` recommendation:

- Orchestrator creates `openspec/changes/<slug>/proposal.md` with: design context, goal, target files, constraints
- Orchestrator displays the path and the exact command to run in the new session
- Orchestrator offers `/memory-update` before closing

### Session Boundary Marker

Add a lightweight session marker: when the orchestrator creates a `proposal.md`, it records `session_created: <timestamp>` in the file's frontmatter. The next session that picks up the proposal can see when it was written.

## Success Criteria

- [ ] Rule 6 updated from opt-in to always-on in CLAUDE.md
- [ ] New Rule "One Cycle Per Session" documented with explicit block behavior
- [ ] Mandatory `proposal.md` creation before every `/sdd-ff` recommendation
- [ ] Command block message template defined for second-cycle-in-session attempts
- [ ] `/memory-update` offer added to the end of every session that creates a proposal

## Files and Artifacts to Target

- `CLAUDE.md` — Rule 6 rewrite + new "One Cycle Per Session" rule
- `openspec/specs/orchestrator-behavior/spec.md` — new REQ for mandatory session discipline
- `skills/sdd-ff/SKILL.md` — check for pre-existing proposal.md as session context

## Constraints

- Do NOT block the user from exploring or asking questions in the same session — only SDD execution is blocked
- The block must be clear and give the exact next step (which command, which session)
- The `proposal.md` creation must be fast and not require sub-agent delegation

## Execution Order

**Cycle 5 of 5** — run last, after all other orchestrator improvements are in place. This rule governs how the orchestrator manages itself — it depends on the teaching tone (Cycle 1) to communicate the block gracefully.
