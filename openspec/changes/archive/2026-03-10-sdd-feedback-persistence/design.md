# Technical Design: sdd-feedback-persistence

Date: 2026-03-10
Proposal: openspec/changes/2026-03-10-sdd-feedback-persistence/proposal.md

## General Approach

Add a new Unbreakable Rule (Rule 5) to CLAUDE.md that enforces feedback persistence: sessions receiving user feedback produce only `proposal.md` files, never SDD cycles. Create a workflow document at `docs/workflows/feedback-to-proposal.md` describing the end-to-end protocol. No skills are modified; this is a documentation and orchestrator-behavior change only.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Where to codify the rule | Unbreakable Rules section in CLAUDE.md (Rule 5) | New skill, separate config file | Unbreakable Rules is the highest-priority section Claude reads; placing it here ensures compliance without needing a new skill or additional file reads |
| Workflow documentation location | `docs/workflows/feedback-to-proposal.md` | ai-context/ file, inline in CLAUDE.md | Workflows are procedural guides for humans and AI; a dedicated `docs/workflows/` directory separates operational documentation from AI context and keeps CLAUDE.md focused on rules, not procedures |
| Feedback session detection | Implicit — orchestrator judgment based on user intent | Explicit `/feedback` command, YAML flag | Adding a new command increases surface area unnecessarily; the rule in CLAUDE.md is sufficient for the orchestrator to recognize feedback sessions by their content pattern |

## Data Flow

```
User provides feedback (observations, complaints, ideas)
        ↓
Orchestrator detects feedback session (Rule 5 applies)
        ↓
For each feedback item:
    ↓
    Create openspec/changes/YYYY-MM-DD-<slug>/proposal.md
        ├── ## Intent
        ├── ## Motivation (references original feedback)
        ├── ## Scope
        └── ## Success Criteria (≥3 verifiable)
        ↓
Session ends — list all proposals created with paths
        ↓
User starts NEW session → reads proposal → /sdd-ff or /sdd-new
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `CLAUDE.md` | Modify | Add Rule 5 — Feedback persistence to Unbreakable Rules section (after Rule 4) |
| `docs/workflows/feedback-to-proposal.md` | Create | New workflow document: protocol, proposal quality requirements, examples |

## Interfaces and Contracts

No new interfaces or types. The only contract is the `proposal.md` structure required for feedback-originated proposals:

```markdown
# Proposal: <slug>

Date: YYYY-MM-DD
Status: Draft

## Intent
[what the change achieves]

## Motivation
[the specific feedback that triggered it — quoted or paraphrased]

## Scope
### Included
### Excluded

## Success Criteria
- [ ] criterion 1
- [ ] criterion 2
- [ ] criterion 3
```

This is the existing proposal template — no new structure needed.

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Integration | `/project-audit` score >= previous | /project-audit |
| Manual | Verify Rule 5 text is present in CLAUDE.md Unbreakable Rules | Read file |
| Manual | Verify `docs/workflows/feedback-to-proposal.md` exists and is well-structured | Read file |

## Migration Plan

No data migration required.

## Open Questions

None.
