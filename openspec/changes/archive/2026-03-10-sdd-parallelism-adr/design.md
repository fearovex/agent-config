# Technical Design: 2026-03-10-sdd-parallelism-adr

Date: 2026-03-10
Proposal: openspec/changes/2026-03-10-sdd-parallelism-adr/proposal.md

## General Approach

This change is documentation-only: create `docs/adr/026-sdd-parallelism-model.md` that documents the SDD parallelism model and register it in `docs/adr/README.md`. No SKILL.md files are modified. The ADR answers four research questions from the proposal: parallel Task limit, file conflict boundary, bounded-context parallel apply feasibility, and CLAUDE.md update need. The design section below resolves each question so the apply phase can write a complete, authoritative ADR.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Maximum parallel Task count | 2 (the current spec+design pair) | 3–4 parallel Tasks | Observed behavior: 2 parallel Tasks (spec + design) reliably produce consistent output. 3–4 Tasks on the same change have not been validated and introduce context-window pressure within Claude Code's orchestration model. The current architecture (one orchestrator + N sub-agents) does not have hard CPU/memory limits, but quality degradation risk increases with Task count. Documenting 2 as the confirmed safe limit is accurate and conservative. |
| File conflict boundary rule | Tasks that write to non-overlapping files MAY run in parallel; Tasks that write to the same files MUST NOT | No restriction / ad-hoc coordination | File write conflicts produce silent data loss or partial overwrites when two sub-agents write to the same path. The rule must be explicit to prevent mistakes when adding new parallel phases in the future. |
| Bounded-context parallel apply | Feasible under strict conditions: each batch touches only domain-local files with no cross-domain writes | Reject entirely / allow freely | Independent domains (e.g., auth vs notifications) do not share `tasks.md` or domain spec files. Cross-domain shared files (CLAUDE.md, ai-context/*.md, openspec/config.yaml) impose a sequential constraint on any batch that touches them. The ADR records this as "conditionally feasible" with a checklist. Implementation is a separate change. |
| CLAUDE.md update | Not required for this ADR | Update Apply Strategy section | The ADR confirms the current model (spec+design parallel, everything else sequential) is correct. No new parallel boundary is introduced. CLAUDE.md is already accurate. |
| ADR number | 026 | N/A | Count of `docs/adr/[0-9]{3}-*.md` = 25 as of 2026-03-10; next sequential number is 026. |

## Data Flow

```
sdd-apply reads:
  proposal.md
  specs/sdd-parallelism/spec.md
  design.md (this file)
       │
       ▼
  Creates: docs/adr/026-sdd-parallelism-model.md
  Modifies: docs/adr/README.md (adds row for ADR 026)
  Verifies: CLAUDE.md needs no change
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `docs/adr/026-sdd-parallelism-model.md` | Create | New ADR: SDD Parallelism Model with Status, Context, Decision, Consequences, Alternatives Considered, and Parallelism Limits Table |
| `docs/adr/README.md` | Modify | Add row for ADR 026 to the ADR Index table |

## Interfaces and Contracts

The ADR must have the following structure:

```markdown
# ADR-026: SDD Parallelism Model

## Status

Accepted

## Context

[Forces and constraints that motivated defining the model]

## Decision

We will limit simultaneous Task sub-agents to a maximum of 2 in the SDD cycle.
Tasks that write to non-overlapping files MAY run in parallel.
Tasks that write to the same file MUST NOT run in parallel.
[Full decision prose...]

## Consequences

**Positive:**
- Clear limit prevents quality degradation from over-parallelism
- File conflict boundary rule makes it safe to add new parallel phases in the future

**Negative:**
- Conservative limit (2) may under-utilise available parallelism

## Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| 3–4 parallel Tasks | Unvalidated; risk of context-window pressure and output degradation |
| No restriction | Silent file write conflicts produce data loss |
| Parallel apply without conditions | Cross-domain shared files impose a sequential constraint that cannot be ignored |

## Parallelism Limits Table

| Phase pair | Safe to parallelize? | Reason |
|------------|---------------------|--------|
| sdd-spec + sdd-design | Yes | Write to different files (specs/ vs design.md) |
| sdd-tasks + any other phase | No | tasks.md is written by sdd-tasks and read by sdd-apply |
| sdd-apply batches (same domain) | No | Tasks in the same domain write to the same domain files |
| sdd-apply batches (different domains, no shared files) | Conditionally yes | Only if no batch touches shared cross-domain files |
| sdd-apply + sdd-verify | No | sdd-verify reads output of all apply tasks; must be sequential |
```

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual | ADR file exists at `docs/adr/026-sdd-parallelism-model.md` with all required sections | Human review / verify-report.md checklist |
| Manual | README.md row is correctly formatted and links to the new ADR file | Human review |
| Manual | No SKILL.md files were modified | `git diff --name-only` check in verify phase |

## Migration Plan

No data migration required. This is a new documentation file and a one-row table addition.

## Open Questions

None. The proposal's four research questions are resolved in the Technical Decisions table above:
1. Parallel limit: 2 Tasks (spec + design)
2. File conflict rule: same-file writes must be sequential
3. Bounded-context parallel apply: conditionally feasible; implementation deferred
4. CLAUDE.md update: not needed
