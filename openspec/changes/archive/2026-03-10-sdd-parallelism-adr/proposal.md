# Proposal: sdd-parallelism-adr

Date: 2026-03-10
Status: Draft

## Intent

Document the current parallelism model of the SDD cycle (what runs in parallel, what is sequential, and why), define its limits, and evaluate whether `sdd-tasks` can decompose work across multiple bounded contexts in parallel when a change spans multiple domains.

## Motivation

The current SDD cycle runs `sdd-spec` and `sdd-design` in parallel (2 Tasks). Beyond that, parallelism is not defined. Questions that need answers:

1. What is the practical limit of parallel Tasks before quality degrades?
2. Can `sdd-tasks` subdivide the task plan by bounded context and execute each context's apply batch in parallel?
3. Should `sdd-apply` batches within a phase run in parallel or sequentially?
4. What is the coordination overhead when parallel agents write to the same files?

Without answers, the current model is conservative (mostly sequential) but potentially slow, and the user has no basis for making parallelism decisions.

## Scope

### Included

- Research the practical parallelism limits of Claude Task tool (based on observed behavior and documented constraints)
- Write `docs/adr/004-sdd-parallelism-model.md` documenting:
  - Current model: spec+design parallel, tasks sequential, apply sequential batches
  - Evaluated alternatives: full parallel spec/design/tasks, parallel apply by bounded context
  - Decision: recommended maximum parallel Tasks, rationale, file conflict risks
- Evaluate whether `sdd-ff` and `sdd-new` should offer parallel context apply as an option
- Update `CLAUDE.md` SDD Flow section with parallelism notes if the ADR changes the current model

### Excluded

- Implementation of parallel apply batches (ADR first; implementation is a separate change if the ADR recommends it)
- Changes to any SKILL.md files (this is research and documentation only)

## Proposed Approach

### Research questions to answer

1. **Parallel Task limit**: empirically, 2-3 parallel Tasks maintain quality; 4+ shows degradation. Document the evidence basis.
2. **File conflict model**: two Tasks writing to the same `tasks.md` simultaneously produce conflicts. What is the safe parallelism boundary? (Rule: Tasks that write to the same files must be sequential.)
3. **Bounded context parallelism**: if a change touches 3 independent domains, can 3 `sdd-apply` sub-agents run in parallel, each touching only their domain files? Evaluate feasibility.
4. **Current model assessment**: is the current spec+design parallelism providing meaningful throughput benefit? Should it be expanded or kept as-is?

### ADR structure

```
# ADR 004 — SDD Parallelism Model

Status: Accepted
Date: 2026-03-10

## Context
## Decision
## Consequences
## Alternatives Considered
## Parallelism Limits Table
```

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `docs/adr/004-sdd-parallelism-model.md` | New | Medium |
| `docs/adr/README.md` | Modified | Low — new ADR registered |
| `CLAUDE.md` | Modified (conditional) | Low — if ADR changes current model |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| ADR conclusions are speculative without empirical data | Medium | Medium | Document assumptions explicitly; mark conclusions as "based on observed behavior" |
| ADR recommends parallel apply but implementation is deferred | Low | Low | ADR is research; implementation is a separate proposal |

## Success Criteria

- [ ] `docs/adr/004-sdd-parallelism-model.md` exists with Status, Context, Decision, Consequences sections
- [ ] `docs/adr/README.md` lists the new ADR
- [ ] The ADR defines a maximum recommended parallel Task count with rationale
- [ ] The ADR defines the file conflict boundary rule (which Tasks can/cannot run in parallel)
- [ ] `verify-report.md` has at least one [x] criterion checked
