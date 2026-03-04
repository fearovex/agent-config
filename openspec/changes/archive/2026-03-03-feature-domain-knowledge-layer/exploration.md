# Exploration: feature-domain-knowledge-layer

Date: 2026-03-03
Change: feature-domain-knowledge-layer

---

## Current State

### What exists

The `claude-config` project has the following relevant structures:

**Skill catalog (skills/):**
- 44 skill directories, each with one `SKILL.md` entry point
- Three declared format types: `procedural` (SDD phases, meta-tools), `reference` (tech/library skills), `anti-pattern` (elixir-antipatterns)
- Reference-format skills (react-19, nextjs-15, django-drf, etc.) encode technology knowledge — code patterns, examples, rules — NOT project/feature domain knowledge
- No skill currently encodes business domain or bounded-context knowledge (e.g., "what is the auth feature in project X", "what are the invariants of the payments domain")

**ai-context/ (project memory layer):**
- 8 files: `stack.md`, `architecture.md`, `conventions.md`, `known-issues.md`, `changelog-ai.md`, `onboarding.md`, `quick-reference.md`, `scenarios.md`
- All files are project-wide (session-agnostic system state)
- No `features/` subdirectory exists — feature-level memory is absent
- The `architecture.md` contains per-skill notes and system-level decisions, not feature domain knowledge
- `memory-init` and `memory-update` do not generate or update feature-level context

**openspec/specs/ (permanent domain specs):**
- 22 domain directories exist (adr-system, audit-dimensions, smart-commit, skill-creation, etc.)
- All 22 represent SDD system configuration domains (how the meta-system works), not application feature domains
- `smart-commit/spec.md` is a good example of a "master spec" that accumulates delta merges over time — this is the closest existing pattern to permanent domain knowledge, but it encodes system behavior, not business feature knowledge
- Only ONE spec has been observed to accumulate deltas: `smart-commit/spec.md` (last updated 2026-03-03 by two consecutive changes)
- The spec format (GIVEN/WHEN/THEN) is designed for observable behavior, not for business rules or domain model documentation

**SDD phases — current context loading:**
- `sdd-propose` (Step 1): reads `exploration.md` + `openspec/config.yaml` + `ai-context/architecture.md`
- `sdd-spec` (Step 1): reads `proposal.md` + `openspec/specs/<domain>/spec.md` + `ai-context/architecture.md`
- `sdd-design` (Step 1): reads `proposal.md` + all `specs/` + `ai-context/architecture.md` + `ai-context/conventions.md`
- `sdd-apply` (Step 1): reads `tasks.md` + `specs/` + `design.md` + `openspec/config.yaml` + `ai-context/conventions.md` + existing code files
- **None of these steps preloads feature-domain context.** Domain knowledge about a bounded context (e.g., the rules of the payments module, invariants of the auth domain) must be re-discovered from code during each cycle.

**openspec/config.yaml:**
- Contains a commented-out `feature_docs:` block that configures `project-audit` Dimension 10 (feature documentation audit)
- The `feature_docs:` convention supports three patterns: `skill` (SKILL.md files in `.claude/skills/`), `markdown` (`.md` files in a `docs/` subdirectory), `mixed`
- This is the closest existing "hook point" for feature domain knowledge — it detects feature docs for audit purposes but does not wire them into SDD phases

**project-audit Dimension 10:**
- Audits feature documentation coverage — checks whether features (detected by directory scan or explicit list) have associated documentation
- Uses heuristic detection when `feature_docs:` is absent from `openspec/config.yaml`
- Produces MEDIUM findings for features without docs, but does not define a doc structure or wire them into SDD

**No "feature-expert" skill pattern exists anywhere in the current catalog.** The `reference` format is the closest structural match but is only used for technology knowledge.

---

## Affected Areas

| File/Module | Impact | Notes |
|-------------|--------|-------|
| `skills/sdd-propose/SKILL.md` | Modified — add Step 0: domain context preload | Must read `ai-context/features/<domain>.md` and `openspec/specs/<domain>/spec.md` before writing proposal |
| `skills/sdd-spec/SKILL.md` | Modified — Step 1 already reads `openspec/specs/<domain>/spec.md` | Potentially add `ai-context/features/<domain>.md` read |
| `skills/memory-init/SKILL.md` | Modified — add feature discovery and `ai-context/features/` generation | Optional: scan for bounded contexts and generate feature stubs |
| `skills/memory-update/SKILL.md` | Modified — add feature context update | Persist feature decisions made during session |
| `openspec/config.yaml` (template) | Potentially modified — `feature_docs:` already supports `skill` convention | Could extend to reference `ai-context/features/` |
| `ai-context/architecture.md` | No change needed — already documents system-level decisions | Feature knowledge goes to `ai-context/features/`, not here |
| `CLAUDE.md` | Modified — document new `ai-context/features/` in memory layer table | Skills Registry may also need entries if new skills are created |
| `docs/format-types.md` | Possibly modified — if a 4th format type (`domain-knowledge`) is introduced | Could also reuse `reference` format with different conventions |
| `skills/project-audit/SKILL.md` | Minimal change — D10 already handles feature doc audit | May add check for `ai-context/features/` existence |

---

## Analyzed Approaches

### Approach A: ai-context/features/ directory (new memory sub-layer)

**Description**: Create a new subdirectory `ai-context/features/` where each file is a domain knowledge document for one bounded context or feature area. Each file captures: business rules, key invariants, data model summary, integration points, decision history, and known gotchas for that domain. `sdd-propose` and `sdd-spec` preload the relevant feature file(s) when the change name or proposal content matches a domain. `memory-update` can update feature files at session end.

**Pros**:
- Minimal structural change — extends the existing `ai-context/` pattern
- Natural integration with `memory-init` and `memory-update`
- Easy for humans to read and maintain directly
- Does not require new skill format types
- Can coexist with existing `openspec/specs/<domain>/spec.md` (complementary: specs = observable behavior, features = domain knowledge/context)
- No new skill required — just new files and small step additions to existing skills

**Cons**:
- Feature files are free-form Markdown — no structural contract or audit validation
- No trigger mechanism: skills must be told which features apply to a given change (risk of context not loading)
- Discovery of relevant features for a given change requires heuristic matching (change name → domain name)

**Estimated effort**: Low-Medium
**Risk**: Low

---

### Approach B: feature-expert skills (reference format, .claude/skills/)

**Description**: Create per-feature skills using `format: reference` following the two-tier skill placement model. Each bounded context gets a skill file at `.claude/skills/<feature>-expert/SKILL.md`. The skill encodes domain rules, patterns, and invariants as a reference catalog. `sdd-propose` and `sdd-spec` are modified to check for a matching feature-expert skill and load it before writing artifacts.

**Pros**:
- Leverages the existing reference format — structural contract (`## Patterns`, `## Rules`, `**Triggers**`) is enforced by `project-audit`
- Triggers can be defined in SKILL.md frontmatter — Claude can auto-load when relevant
- Skills are versioned alongside project source code (project-local placement per ADR 008)
- `project-audit` Dimension 10 already partially audits for feature documentation

**Cons**:
- Adds more SKILL.md files — may increase cognitive overhead in projects already skill-heavy
- Reference format was designed for technology patterns, not business domain knowledge — the `## Patterns` section is an awkward fit for domain invariants and business rules
- SDD phases do not auto-load skills by trigger — they load by explicit path; `sdd-propose` would need logic to discover and load a matching feature-expert skill
- Does not integrate naturally with `memory-update` (session memory is not written back to SKILL.md files)

**Estimated effort**: Medium
**Risk**: Medium (requires changes to SDD phase loading logic)

---

### Approach C: Enrich openspec/specs/<domain>/spec.md with permanent domain knowledge sections

**Description**: Extend the existing `openspec/specs/<domain>/spec.md` pattern to include a non-delta "domain knowledge" header section. Each domain spec gets a new `## Domain Context` section (above Requirements) that accumulates business rules, invariants, and domain model notes. `sdd-spec` is modified to populate/update this section in addition to writing delta requirements.

**Pros**:
- No new files or directories — extends an existing artifact
- Natural accumulation point — each change's delta spec adds to the domain's permanent knowledge
- `sdd-spec` already reads the base spec before writing deltas; preloading domain context is a small step addition

**Cons**:
- Conflates two concerns in one file: observable behavior (GIVEN/WHEN/THEN) vs. domain knowledge narrative
- `openspec/specs/` currently only exists in projects with active SDD cycles — early-stage projects with no specs would have no domain knowledge
- `sdd-propose` does not currently read `openspec/specs/` — it only reads `openspec/changes/<name>/proposal.md`; proposal-phase context gap remains
- Harder to update domain knowledge outside a SDD cycle (no skill for direct domain knowledge maintenance)

**Estimated effort**: Low
**Risk**: Low-Medium (risk of spec file complexity growth)

---

### Approach D: Hybrid (Approach A + Approach B, tiered)

**Description**: Implement both `ai-context/features/` (Tier 1 — session memory, free-form) and feature-expert skills (Tier 2 — curated, structured). `ai-context/features/` files are generated and updated by `memory-init` and `memory-update`. Feature-expert skills are created manually (via `/skill-create`) when a domain reaches sufficient maturity to warrant a structured reference. `sdd-propose` and `sdd-spec` preload from both tiers in priority order (feature-expert skill if exists, then `ai-context/features/<domain>.md` as fallback).

**Pros**:
- Full coverage: quick low-effort memory (Tier 1) and curated reference (Tier 2)
- Gradual adoption — projects start with Tier 1 and promote to Tier 2 when ready
- Aligns exactly with the background context provided (Tier 2 = feature-expert skills, ai-context/features/ = Feature Intelligence)

**Cons**:
- Higher complexity: two separate systems to understand and maintain
- Risk of divergence: Tier 1 and Tier 2 can contradict each other if not kept in sync
- More changes required to existing skills (propose, spec, memory-init, memory-update, skill-creator)

**Estimated effort**: High
**Risk**: Medium

---

## Recommendation

**Approach A (ai-context/features/) with a well-defined template**, with an explicit integration point in `sdd-propose` and `sdd-spec`, is the recommended starting point.

Rationale:
1. The current system already has `ai-context/` as the memory layer — extending it with a `features/` subdirectory is the lowest-friction path
2. The background context specifically calls out `ai-context/features/` as the "Feature Intelligence" home — this validates Approach A
3. Approach A is incrementally promotable to the full hybrid (Approach D) — once Approach A is stable and the domain knowledge format is proven, feature-expert skills (Approach B) can be layered on top without disruption
4. `openspec/specs/<domain>/spec.md` already serves as the observable-behavior layer — `ai-context/features/<domain>.md` can serve as the complementary business context layer without conflating the two concerns (Approach C risk avoided)

The key integration points that must be addressed are:
- `sdd-propose` Step 1: after reading `exploration.md` and `architecture.md`, also check for `ai-context/features/<domain>.md` where domain is inferred from the change name
- `sdd-spec` Step 1: add `ai-context/features/<domain>.md` to the required reads alongside the existing spec
- `memory-init`: add a feature discovery step that generates `ai-context/features/` stubs from project structure
- A canonical template for `ai-context/features/<domain>.md` files

---

## Identified Risks

- **Domain name disambiguation**: Change names use kebab-case descriptive slugs (e.g., `add-payment-gateway`); deriving the domain name (`payments`) requires either a naming convention or explicit configuration — risk of mismatched domain preloading. Mitigation: make domain preloading opt-in in `proposal.md` frontmatter, or match against known `ai-context/features/` filenames.

- **Spec vs. feature doc confusion**: Both `openspec/specs/<domain>/spec.md` and `ai-context/features/<domain>.md` will exist for mature domains. Developers may not understand the distinction. Mitigation: clear documentation in CLAUDE.md and in each file's header (spec = observable behavior, feature doc = business rules/context).

- **Memory-update awareness gap**: The existing `known-issues.md` entry documents that `memory-update` is not aware of `[auto-updated]` markers. Adding feature files to `ai-context/` introduces another overlap risk if both `project-analyze` and `memory-update` attempt to write to `ai-context/features/`. Mitigation: assign clear ownership — `memory-update` writes to feature files; `project-analyze` does not touch `features/`.

- **No project-audit validation for ai-context/features/**: Feature files are free-form; project-audit has no dimension checking their structure. Mitigation: acceptable for V1; a D10 extension can enforce feature doc presence/quality in a follow-up change.

- **Scope creep into feature-expert skills (Approach B)**: The background context mentions both layers. Including Approach B in scope significantly increases effort and complexity. Mitigation: scope V1 to Approach A only; gate Approach B behind a separate SDD change once Approach A is validated.

---

## Open Questions

1. **How should sdd-propose determine which feature domain is relevant?** By parsing the change name, by reading the proposal body, or via an explicit `domains:` field in `proposal.md`?
2. **Should feature docs be generated by memory-init automatically, or always created manually?** Auto-generation risks generating low-quality stubs that give false confidence. Manual creation ensures quality but slows adoption.
3. **What is the canonical template for `ai-context/features/<domain>.md`?** Sections needed: Domain Overview, Business Rules / Invariants, Data Model Summary, Integration Points, Decisions Log, Known Gotchas.
4. **Should openspec/config.yaml's `feature_docs:` key be extended to also reference `ai-context/features/`?** Or should feature docs remain outside the feature_docs audit scope?
5. **Is feature-expert skill (Approach B / Tier 2) in scope for this change or deferred?** The background context mentions it as part of the vision, but it substantially increases effort.

---

## Ready for Proposal

Yes — with the caveat that Open Question 5 (scope of Tier 2 / feature-expert skills) should be decided before writing the proposal. The recommendation is to defer Tier 2 to a separate SDD cycle and scope this change to:
- `ai-context/features/<domain>.md` template and conventions
- `sdd-propose` integration (domain context preload)
- `sdd-spec` integration (domain context preload)
- `memory-init` and `memory-update` feature discovery step (optional stubs)
- CLAUDE.md and ai-context/architecture.md updates to document the new layer
