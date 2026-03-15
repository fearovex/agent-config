# ADR-034: Spec Index — Flat YAML as Primary Storage with SQLite/FTS5 as Migration Path

## Status

Proposed

## Context

`openspec/specs/` holds 55 domain directories. Sub-agents that need background spec context during SDD phases have no structured mechanism to identify which spec files are relevant without reading all of them (expensive in tokens) or guessing by directory name stem matching (fragile due to vocabulary mismatch).

As the spec catalog grows, three failure modes emerge: exhaustive loading degrades output quality through signal dilution; blind name matching misses semantically related domains with different vocabulary; skipping spec context entirely causes sub-agents to produce lower-fidelity outputs that may contradict established behavioral contracts.

A lightweight index of domain entries (each with a summary, keywords, and optional cross-references) allows sub-agents to select the correct 2–5 spec files with a single read, at near-zero token cost. Two storage options were evaluated: a flat YAML file (readable without tooling, diffable in git) and a SQLite database with FTS5 (higher recall, query-based, requires MCP server or runtime tooling).

## Options Considered

**Option A — Flat YAML `index.yaml` with keyword matching (current choice)**

Store a hand-authored YAML file at `openspec/specs/index.yaml`. Each entry has `domain`, `summary`, `keywords` (3–8 terms), and optional `related`. Sub-agents read the file once and match entries against the change slug. `sdd-archive` appends a new entry whenever a new spec domain is created.

**Option B — SQLite database with FTS5 (migration path, not implemented)**

Replace `index.yaml` with a SQLite database using the FTS5 extension for full-text search. Provides higher recall and query-based lookup. Requires runtime tooling or an MCP server to expose the database to sub-agents. Migration trigger: 100+ spec domains.

**Option C — MCP server resource exposing the index**

Expose the spec index as an MCP server resource (either backed by YAML or SQLite). Sub-agents query the resource endpoint instead of reading a file. Highest flexibility but introduces a new infrastructure dependency and requires MCP server setup and maintenance.

## Decision

We will implement **Option A**: store the spec domain index as a flat YAML file at `openspec/specs/index.yaml`. Each entry contains: `domain` (directory name), `summary` (one-line description), `keywords` (3–8 change-slug vocabulary terms), and `related` (optional list of co-relevant domain names).

The flat-file approach is the current decision. When the spec catalog reaches **100+ domains** and flat-file linear scan becomes a measurable bottleneck, this decision should be revisited and Option B (SQLite/FTS5) evaluated. Option C remains available as a longer-term evolution path. Neither Option B nor Option C is implemented in this change.

## Consequences

**Option A (current) — Positive:**

- Index is human-readable and editable with no tooling — any contributor can correct keyword sets or add entries
- A single YAML read gives sub-agents all the domain selection signal they need in one operation
- The index is version-controlled alongside the specs it describes (git diff shows keyword changes)
- sdd-archive SKILL.md maintains the index as a mandatory step, keeping it consistent with `openspec/specs/` directory state
- No new runtime dependencies — no MCP server, no SQLite tooling, no code

**Option A (current) — Negative:**

- Linear scan performance degrades as entry count grows; at 100+ entries, keyword matching over YAML is slower than FTS5 queries
- Keyword quality depends on human authoring — mismatched or missing keywords cause false negatives; the stem-based algorithm remains as a fallback
- Index can drift from reality if sdd-archive step is bypassed or a new domain is added outside the SDD cycle

**Option B (future) — Consequences if adopted:**

- Higher recall via FTS5 full-text indexing — vocabulary-mismatched domains surface correctly
- Requires MCP server setup and ongoing maintenance; adds a runtime infrastructure dependency
- SQLite migration requires coordinated changes to phase skills, MCP server configuration, and replacement of `index.yaml`
- Migration trigger: 100+ spec domains

**Option C (future) — Consequences if adopted:**

- Maximum flexibility — index query logic is centralized in the MCP server, not duplicated across phase skills
- Highest infrastructure cost: MCP server must be deployed, versioned, and kept running
- Decouples index format from file system — enables richer query patterns (fuzzy match, ranking, filters)
- Not justified at current scale; revisit alongside Option B evaluation at 100+ domain threshold
