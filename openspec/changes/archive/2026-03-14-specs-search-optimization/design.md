# Technical Design: 2026-03-14-specs-search-optimization

Date: 2026-03-14
Proposal: openspec/changes/2026-03-14-specs-search-optimization/proposal.md

## General Approach

Introduce a hand-authored YAML index at `openspec/specs/index.yaml` covering all 55 current spec domains. Each entry contains a domain name, a one-line summary, 3–8 keywords drawn from realistic change-slug vocabulary, and an optional `related` list. Update `sdd-archive` to append a new index entry whenever a new spec domain is created. Document the SQLite/FTS5 migration path in ADR 034 as a Proposed option for projects reaching 100+ domains. Update `docs/SPEC-CONTEXT.md` to describe the two-step index-driven lookup as the preferred selection mechanism.

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
| -------- | ------ | ---------------------- | ------------- |
| Index storage format | Flat YAML (`openspec/specs/index.yaml`) | SQLite/FTS5, JSON, in-memory scan | YAML is readable, diffable, and writable without any runtime tooling. Sub-agents can read it with a single file read. At 55 domains the file is compact (<200 lines). This is the architecture decision also documented in ADR 034. |
| Index maintenance responsibility | `sdd-archive` SKILL.md step | Automated generation script, CI hook, manual only | sdd-archive is the only phase that introduces new spec domains. Placing the maintenance step there creates a natural gate — the index update happens at the same moment the new domain appears. |
| SQLite/FTS5 migration trigger | 100+ domains (ADR 034 — Proposed, not implemented) | 50 domains, never, on demand | Flat YAML parsing becomes linear-scan expensive past ~100 entries. The 100-domain threshold is documented as an architecture decision option so future maintainers have explicit guidance, but no implementation is included in this change. |
| Selection algorithm update | Extend SPEC-CONTEXT.md to describe index-driven two-step lookup; stem-based fallback remains in place | Replace stem-based with index-only | Index-driven lookup is higher recall; stem-based is the safe fallback when the index is absent. Both are documented as the authoritative algorithm in `docs/SPEC-CONTEXT.md`. |
| ADR scope | Single ADR 034 covers both flat YAML decision and SQLite migration path as alternatives | Two separate ADRs | The flat-file vs SQLite choice is one architectural decision with two competing options. A single ADR with both alternatives and a Proposed status is cleaner than two ADRs describing opposite sides of the same choice. |

## Data Flow

```
Sub-agent receives change slug (e.g. "add-resilience-layer")
          │
          ▼
Step 0 — Spec context preload
          │
          ├── Read openspec/specs/index.yaml (single read)
          │         │
          │         ▼
          │   For each domain entry:
          │     if domain in slug OR any keyword in slug → match
          │   matches = matches[:3]   ← hard cap
          │
          ├── No matches → skip silently (fallback: stem-based name match)
          │
          └── Matches found → read openspec/specs/<domain>/spec.md for each
                    │
                    ▼
              Treat as authoritative behavioral contracts
              (precedence over ai-context/ for behavioral questions)

Archive path (new domain spec created):
  sdd-archive Step 3 → new domain copied to openspec/specs/<domain>/
          │
          ▼
  sdd-archive NEW STEP — append entry to openspec/specs/index.yaml
          │
          ▼
  Index remains consistent with openspec/specs/ directory state
```

## File Change Matrix

| File | Action | What is added/modified |
|------|--------|------------------------|
| `openspec/specs/index.yaml` | Create | 55-entry YAML index with domain, summary, keywords, related fields |
| `skills/sdd-archive/SKILL.md` | Modify | New step after Step 3: append index entry when a new spec domain is created |
| `docs/adr/034-specs-search-optimization-architecture.md` | Create | ADR documenting flat YAML index choice and SQLite/FTS5 migration option (status: Proposed) |
| `docs/adr/README.md` | Modify | Append ADR 034 row to index table |
| `docs/SPEC-CONTEXT.md` | Modify | Add "Using the spec index" section describing two-step lookup; update stem-based section to note index as preferred mechanism |

## Interfaces and Contracts

```yaml
# openspec/specs/index.yaml — entry schema
domains:
  - domain: <string>       # matches openspec/specs/<domain>/ directory name exactly
    summary: <string>      # one-line description of what the spec covers
    keywords:              # 3–8 terms from realistic change-slug vocabulary
      - <string>
    related:               # optional — other domain names frequently co-relevant
      - <string>
```

**Selection algorithm (index-aware, replaces pure stem-based):**

```
Step 1: Read openspec/specs/index.yaml (if present)
Step 2: For each entry:
          if entry.domain in change_name → match
          OR for any keyword in entry.keywords: if keyword in change_name → match
Step 3: matches = matches[:3]
Step 4: If index absent → fall back to stem-based name scan (existing algorithm)
```

**sdd-archive index maintenance contract:**

After Step 3 (sync delta specs to master specs), if a new domain directory was created:
- Append one entry to `openspec/specs/index.yaml` under the `domains:` key
- Fields: `domain` (new directory name), `summary` (derived from spec title or first requirement), `keywords` (derived from domain name tokens + key nouns in spec), `related` (empty or inferred from proposal cross-references)
- Entry MUST follow the existing YAML format (no schema change)

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Manual validation | All 55 index entries reference existing `openspec/specs/<domain>/` directories | Manual directory listing comparison |
| Manual validation | Each entry has 3–8 keywords; `related` values point to existing entries | YAML review |
| Smoke test | Run `/sdd-ff` with a change slug that has clear domain overlap — verify spec context loads from index | Observe sub-agent Step 0 log output |
| Archive test | Create a test change with a new spec domain → archive it → verify index.yaml gains the new entry | Manual SDD cycle |

No automated test runner exists for this project (stack: Markdown + YAML + Bash). Validation is manual or via SDD cycle observation.

## Migration Plan

No data migration required. `index.yaml` is a new additive file. Existing spec files are unchanged. If the index is removed, sub-agents fall back to stem-based name matching (the current behavior) with no regression.

**SQLite migration (future — ADR 034, Proposed):**

Not implemented in this change. When the 100-domain threshold is reached, ADR 034 documents the migration path: create an MCP server exposing an FTS5-indexed SQLite database, update the spec context preload sub-step in phase skills to query the MCP endpoint instead of parsing `index.yaml`. This migration is isolated to the preload sub-step and does not affect spec file content or the archive process.

## Open Questions

- **Keyword authoring quality**: The initial 55 entries are hand-authored. Keyword choices may not reflect the full range of change-slug vocabulary used in practice. Monitoring is recommended over the first 5–10 SDD cycles. If a domain is consistently missed, its keyword set should be expanded. Impact if unresolved: low — stem-based fallback covers most cases.
