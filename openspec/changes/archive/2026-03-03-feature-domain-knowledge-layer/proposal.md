# Proposal: feature-domain-knowledge-layer

Date: 2026-03-03
Status: Draft

## Intent

Add a Feature Intelligence Layer (`ai-context/features/`) to the SDD system so that domain knowledge — business rules, invariants, integration points, and known gotchas — is captured once and automatically preloaded into relevant SDD phases instead of being rediscovered from code on every cycle.

## Motivation

Before SDD adoption, projects maintained "feature-expert" skills that encoded bounded-context knowledge: what the payments domain invariants are, how the auth module is integrated, what known failure modes exist in notifications. When the SDD workflow was adopted, this per-feature domain knowledge layer was not carried forward. The result is that every SDD cycle that touches a known domain (auth, payments, etc.) starts from zero context — the sub-agent must re-infer business rules from code, risking shallow specs and design decisions that violate established invariants.

The `ai-context/` layer already captures system-wide memory (stack, architecture, conventions). A `features/` subdirectory is the natural extension: feature-specific memory that complements the existing layer without conflating it with the observable-behavior contract encoded in `openspec/specs/<domain>/spec.md`.

The `openspec/config.yaml` already has a commented-out `feature_docs:` block for Dimension 10 auditing, confirming that a hook point for feature documentation was anticipated in the system design. V1 activates the memory side of this (authoring + loading); the audit integration can follow in a separate change.

## Scope

### Included

- A canonical template file: `ai-context/features/_template.md` — defines the required sections for any feature knowledge file
- A new skill `feature-domain-expert` (format: `reference`) — teaches how to author feature knowledge files, what goes in each section, and how they are consumed by SDD phases
- Integration into `sdd-propose`: add an optional domain context preload step that reads `ai-context/features/<domain>.md` when a file matching the change's domain exists
- Integration into `sdd-spec`: same optional preload (read `ai-context/features/<domain>.md` as enrichment context when present)
- Integration into `memory-init`: add a feature discovery step that generates `ai-context/features/` stubs for detected bounded contexts when the directory does not exist
- Integration into `memory-update`: add a feature file update path so session-acquired domain knowledge is persisted to the relevant `ai-context/features/<domain>.md`
- Updates to `CLAUDE.md` memory layer table to document `ai-context/features/` as a first-class memory artifact
- Update `ai-context/architecture.md` to document the new layer and its artifact communication contract
- Usage documentation included in the `feature-domain-expert` SKILL.md (the skill itself serves as the canonical how-to guide per the explicit user request)

### Excluded (explicitly out of scope)

- **Tier 2 feature-expert skills** (`.claude/skills/<feature>-expert/SKILL.md`): structured reference-format skills per bounded context — deferred to V2. V1 establishes the free-form `ai-context/features/` convention first; V2 can layer structured skills on top once the document format is validated in practice.
- **project-audit Dimension 10 integration** for `ai-context/features/`: audit enforcement of feature doc presence/quality is deferred. V1 files are authored voluntarily; a D10 extension can enforce coverage in a follow-up change.
- **Auto-generation of feature files by `project-analyze`**: `project-analyze` is an observer skill — it does not write to `ai-context/features/`. Only `memory-init` (scaffolding) and `memory-update` (session persistence) write to feature files.
- **`openspec/config.yaml` `feature_docs:` block activation**: the existing commented-out block points `feature_docs.paths` to `.claude/skills/`; extending it to reference `ai-context/features/` is an audit concern deferred to V2.
- **Automatic domain-to-feature mapping via change-name parsing**: V1 uses a simple filename-match heuristic (change name contains or starts with a domain slug found in `ai-context/features/`). A more robust domain-tagging mechanism (e.g., `domains:` frontmatter in `proposal.md`) is deferred to V2.

## Proposed Approach

Extend `ai-context/` with a `features/` subdirectory. Each file in this directory is a bounded-context knowledge document, named `<domain>.md` (e.g., `auth.md`, `payments.md`). A canonical template defines the required sections: Domain Overview, Business Rules and Invariants, Data Model Summary, Integration Points, Decision Log, and Known Gotchas.

A new `feature-domain-expert` skill (format: `reference`) serves as both the authoring guide and the usage reference. It explains what each section means, when to create a feature file, how to update it, and how it is consumed by SDD phases.

The SDD phase integration is minimal and non-blocking: `sdd-propose` and `sdd-spec` gain an optional domain context preload step. Before writing their primary artifact, each phase checks whether any file in `ai-context/features/` has a filename matching a stem from the change name. If a match is found, the file is read and its content is used to enrich the phase's context. If no match exists, the phase proceeds normally — the feature layer is never a hard dependency.

`memory-init` gains a feature discovery step: when `ai-context/features/` does not exist and the project has identifiable bounded contexts (from `openspec/specs/` or `src/` directory structure), it generates minimal stubs to be filled in later. `memory-update` gains a feature update path: if the session involved a domain with an existing feature file, the agent updates the relevant file with any new rules, decisions, or gotchas surfaced during the session.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `ai-context/features/` | New — directory + template | Low (additive only) |
| `skills/feature-domain-expert/` | New skill | Low (standalone) |
| `skills/sdd-propose/SKILL.md` | Modified — add optional domain context preload step | Low (non-blocking addition) |
| `skills/sdd-spec/SKILL.md` | Modified — add optional domain context preload step | Low (non-blocking addition) |
| `skills/memory-init/SKILL.md` | Modified — add feature discovery step | Low (additive, only fires when `features/` absent) |
| `skills/memory-update/SKILL.md` | Modified — add feature file update path | Low (additive, non-blocking) |
| `CLAUDE.md` | Modified — document `ai-context/features/` in memory layer table | Low |
| `ai-context/architecture.md` | Modified — add artifact entry for `ai-context/features/*.md` | Low |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Domain name disambiguation fails — change name doesn't map to any feature file | Medium | Low | Preload is optional; phase proceeds normally on miss. Naming convention documented in template. |
| Feature files and `openspec/specs/<domain>/spec.md` are confused — authors put behavioral specs in feature docs | Low-Medium | Medium | Template headers and `feature-domain-expert` skill explain the distinction clearly: spec = observable behavior (GIVEN/WHEN/THEN), feature doc = business context and rules. |
| `memory-update` and `project-analyze` both attempt to write to `ai-context/features/` causing conflicts | Low | Medium | Explicit ownership rule in architecture.md: `memory-update` writes feature files; `project-analyze` does not touch `features/`. |
| Feature files become stale or out of sync with actual code | Medium | Low | Known-acceptable risk for V1; files are living documents maintained by the team. Staleness is visible (date headers). V2 can add audit enforcement. |
| Scope creep into Tier 2 feature-expert skills during implementation | Low | Medium | Scope gate enforced by this proposal: Tier 2 is explicitly excluded. Any Tier 2 work requires a new SDD change. |

## Rollback Plan

This change is purely additive — no existing files are deleted and no existing skill behavior is removed. To roll back:

1. Delete `ai-context/features/` and all files within it.
2. Delete `skills/feature-domain-expert/` directory.
3. Revert `skills/sdd-propose/SKILL.md` to the previous version (remove the domain context preload step).
4. Revert `skills/sdd-spec/SKILL.md` to the previous version (remove the domain context preload step).
5. Revert `skills/memory-init/SKILL.md` to the previous version (remove feature discovery step).
6. Revert `skills/memory-update/SKILL.md` to the previous version (remove feature update path).
7. Revert `CLAUDE.md` and `ai-context/architecture.md` to their pre-change versions.
8. Run `install.sh` to deploy the reverted state to `~/.claude/`.

All changes are in version control. The `git revert` of the apply commit is sufficient to restore state. No data loss risk: existing `openspec/` artifacts and project memory files are not touched.

## Dependencies

- No blocking dependencies: this change is self-contained within `claude-config`.
- `openspec/config.yaml` `feature_docs:` block remains commented out — this change does not require activating it.
- The `feature-domain-expert` skill must be created before modifying `sdd-propose` and `sdd-spec`, so that the SKILL.md referenced in those phases' preload notes actually exists.
- `install.sh` must be run after apply to deploy changes to `~/.claude/`.

## Success Criteria

- [ ] `ai-context/features/_template.md` exists with all six required sections: Domain Overview, Business Rules and Invariants, Data Model Summary, Integration Points, Decision Log, Known Gotchas
- [ ] `skills/feature-domain-expert/SKILL.md` exists with `format: reference`, required frontmatter, `**Triggers**`, `## Patterns` or `## Examples`, and `## Rules` sections; it documents how to author a feature file and how SDD phases consume it
- [ ] `skills/sdd-propose/SKILL.md` includes an optional domain context preload step that reads `ai-context/features/<domain>.md` when a filename match exists, and proceeds normally when no match is found
- [ ] `skills/sdd-spec/SKILL.md` includes the same optional domain context preload step
- [ ] `skills/memory-init/SKILL.md` includes a feature discovery step that generates `ai-context/features/` stubs for detected bounded contexts when the directory does not exist
- [ ] `skills/memory-update/SKILL.md` includes a feature file update path so session-acquired domain knowledge is persisted to `ai-context/features/<domain>.md`
- [ ] `CLAUDE.md` memory layer table includes an `ai-context/features/*.md` row documenting the new layer
- [ ] `ai-context/architecture.md` includes an artifact entry for `ai-context/features/*.md` in the communication table
- [ ] A worked example feature file (one real or illustrative bounded context) exists in `ai-context/features/` to demonstrate the template in use
- [ ] Running `/project-audit` on `claude-config` after apply yields a score >= the score before apply (no regressions)
- [ ] `install.sh` runs without error after the change is applied

## Effort Estimate

Medium (1-2 days) — four skill modifications, one new skill, one template, documentation updates, and install/verify.
