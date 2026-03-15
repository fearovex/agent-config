# Exploration: specs-search-optimization

## Current State

`openspec/specs/` holds **55 domain directories**, each with a `spec.md` file that acts as a master behavioral contract. There is no index or summary file — the directory listing is a flat alphabetical list of domain names.

### Spec context preload — current mechanism

Five SDD phase skills (`sdd-explore`, `sdd-propose`, `sdd-spec`, `sdd-design`, `sdd-tasks`) include a "Spec context preload" sub-step in Step 0. All five skills use the same stem-based matching algorithm:

```
stems = change_name.split("-").filter(s => s.length > 1)
matches = []
for domain in candidates:
  if domain in change_name OR any stem in domain:
    matches.append(domain)
matches = matches[:3]   ← hard cap at 3
```

This algorithm is implemented inline in each SKILL.md and documented in `docs/SPEC-CONTEXT.md`. The doc explicitly references `specs-search-optimization` as the companion proposal for improving selection quality.

### sdd-archive — current behavior

`sdd-archive` merges delta specs into `openspec/specs/` during archiving but does **not** maintain any index file. No step currently ensures `openspec/specs/index.yaml` exists or is updated.

### Observed issues with stem matching

| Problem | Example | Result |
|---|---|---|
| Vocabulary mismatch | change `add-resilience-layer` vs domain `retry-policy` | No match — semantically related but lexically different |
| Compound domain names | domain `sdd-phase-context-loading` vs stem `phase` | May match unintentionally if a generic stem appears in many domain names |
| False positives with generic stems | stem `add`, `fix`, `new` | Matches any domain containing those characters |
| Cap at 3 limits multi-domain changes | change spans `sdd-apply`, `sdd-verify`, `sdd-tasks` | Only 3 loaded even if 5+ are relevant |

### Existing `docs/SPEC-CONTEXT.md` anticipates the index

`docs/SPEC-CONTEXT.md` (section "Relationship to Companion Proposal") already describes the expected behavior after this change:
- Skills read `index.yaml` first
- Select matching domains from index
- Then read selected spec files
- The doc is explicitly deferred pending this change

---

## Affected Areas

| File/Module | Impact | Notes |
| ----------- | ------ | ----- |
| `openspec/specs/index.yaml` | New file (55-entry YAML) | Core deliverable — does not exist today |
| `skills/sdd-archive/SKILL.md` | Modified (new step) | Add index maintenance after spec merge |
| `docs/adr/034-spec-index-sqlite-migration.md` | New ADR | Documents SQLite/FTS5 as future option at 100+ domains; status: Proposed |
| `docs/SPEC-CONTEXT.md` | Modified (new section) | Add "Using the spec index" two-step lookup description |
| 5 phase skills (sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks) | No change in this cycle | Stem-matching algorithm stays; skills will be updated to use the index in a follow-on change (see Open Questions) |

---

## Analyzed Approaches

### Approach A: Static index YAML only (proposed approach)

**Description**: Author `openspec/specs/index.yaml` by hand, covering all 55 domains with `domain`, `summary`, `keywords` (3-8), and optional `related` fields. Update `sdd-archive` to append new entries when new domain specs are created. Document the SQLite migration path in an ADR.

**Pros**:
- Zero runtime tooling — a YAML file is read by any LLM context loader with no code
- Reversible: removing `index.yaml` restores current behavior immediately
- Enables semantic matching immediately (keywords can express synonyms, abbreviations)
- Low maintenance cost: one small YAML append per new domain (enforced by sdd-archive step)
- Matches the project's Markdown + YAML + Bash tech stack

**Cons**:
- Initial authoring of 55 entries is manual effort (~2-3 hours)
- Index can become stale if sdd-archive step is skipped or bypassed
- Keyword quality depends on the initial author's coverage of likely change-slug vocabulary

**Estimated effort**: Medium (hours)
**Risk**: Low

---

### Approach B: Full-text search via SQLite FTS5

**Description**: Generate a SQLite database from spec content with FTS5 full-text search. MCP server or shell script exposes query results to the sub-agent.

**Pros**:
- True semantic search over full spec content
- Handles vocabulary mismatch well

**Cons**:
- Requires Node.js or Python runtime + SQLite
- MCP server introduces a new dependency and failure mode
- Significantly more engineering than authoring a YAML file
- Out of scope for a 55-domain catalog where a flat index is sufficient

**Estimated effort**: High
**Risk**: Medium

---

### Approach C: Automated index generation script

**Description**: Write a `scripts/gen-spec-index.sh` that reads all `openspec/specs/*/spec.md` files and extracts the H1 heading and first paragraph as a summary.

**Pros**:
- Reduces manual authoring burden for future domains

**Cons**:
- Auto-generated summaries may be generic/low-quality
- Keywords cannot be auto-extracted reliably without LLM involvement
- A script adds tooling the project currently does not have (no scripts/ directory)
- Human-curated keywords are more reliable for change-slug matching

**Estimated effort**: Medium
**Risk**: Low-Medium

---

## Recommendation

**Approach A — Static index YAML only** is the correct choice. It:

1. Solves the stated problem (better domain selection) immediately
2. Is consistent with the project's Markdown + YAML + Bash tech stack
3. Has a clear maintenance path (sdd-archive step)
4. Documents the SQLite path for future scale (ADR) without building it now
5. Is trivially reversible

The 55-entry initial authoring is the dominant cost, but it is one-time and produces a durable, human-readable artifact.

The 5 phase skills that currently use stem matching do NOT need to change in this cycle. The index enables better selection, but whether phase skills read the index first (vs. listing the directory) is a separate follow-on change. The proposal is clear on this: the index is a new file + archive maintenance + docs update only.

---

## Identified Risks

- **Index staleness**: if `sdd-archive` is skipped, new domains go unindexed — mitigated by making the index maintenance step non-optional in the archive process
- **Keyword gaps**: initial keyword sets may miss some future change-slug vocabulary — mitigated by treating the index as a living document (keyword additions are trivial YAML edits)
- **ADR expectation mismatch**: reviewers may assume the SQLite ADR implies imminent migration — mitigated by explicitly setting `Status: Proposed` with a clear 100+ domain trigger condition
- **Domains with multi-word names**: a domain like `sdd-phase-context-loading` needs carefully chosen keywords to avoid spurious matches — authoring responsibility

---

## Open Questions

1. **Should phase skills be updated to prefer `index.yaml` over raw directory listing in this cycle?** The proposal explicitly excludes this (scope: index creation + archive step + ADR + doc update only). The SKILL.md update is a natural follow-on. Leave for a follow-on change.
2. **What is the exact `keywords` vocabulary strategy?** Recommendation: use verbs and nouns that would appear in realistic change slug words (e.g. for `sdd-apply`: `[apply, implement, execute, tasks, tdd, code-generation, coding]`). Avoid generic words (`fix`, `update`, `add`) that would over-match.
3. **Should `related` be required or optional?** Proposal says optional. Keep optional — not all domains have clear neighbors, and forcing the field increases authoring friction.

---

## Ready for Proposal

Yes — `proposal.md` already exists at `openspec/changes/2026-03-14-specs-search-optimization/proposal.md` with full intent, scope, approach, success criteria, and rollback plan. The exploration confirms the proposal is well-founded and no new scope items were discovered.
