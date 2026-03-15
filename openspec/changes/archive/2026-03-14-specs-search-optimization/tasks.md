# Task Plan: 2026-03-14-specs-search-optimization

Date: 2026-03-14
Design: openspec/changes/2026-03-14-specs-search-optimization/design.md

## Progress: 7/7 tasks

## Phase 1: Index Creation

- [x] 1.1 Create `openspec/specs/index.yaml` ✓ with the file header comment, `domains:` root key, and all 55 domain entries — each entry containing `domain` (matching the directory name exactly), `summary` (one-line description), `keywords` (3–8 realistic change-slug terms), and `related` (optional list of co-relevant domain names)

  Domains to cover (in order, taken from `openspec/specs/` directory listing):
  `adr-system`, `audit-dimensions`, `audit-execution`, `audit-scoring`, `codebase-teach`,
  `config-export-skill`, `config-export-targets`, `config-schema`, `feature-domain-knowledge`,
  `feedback-session`, `fix-setup-behavior`, `folder-audit-execution`, `folder-audit-reporting`,
  `folder-organizer-execution`, `folder-organizer-reporting`, `format-contract`,
  `global-permissions`, `memory-management`, `openspec-config-documentation`,
  `orchestrator-behavior`, `prd-system`, `project-analysis`, `project-audit-core`,
  `project-claude-organizer`, `project-fix-action-model`, `project-fix-behavior`,
  `project-identity`, `sdd-apply`, `sdd-apply-execution`, `sdd-archive-execution`,
  `sdd-context-loading`, `sdd-design-adr-integration`, `sdd-orchestration`, `sdd-parallelism`,
  `sdd-phase-context-loading`, `sdd-propose-prd-integration`, `sdd-verify-execution`,
  `sdd-warning-classification`, `skill-authoring-conventions`, `skill-compliance`,
  `skill-creation`, `skill-format-types`, `skill-orchestration`, `skill-placement`,
  `skills-catalog-consistency`, `skills-catalog-format`, `skill-structure`,
  `skill-template-noise`, `smart-commit`, `solid-ddd-skill`, `spec-index`,
  `step-0a-governance-discovery`, `sub-agent-execution-contract-update`,
  `sub-agent-governance-injection`, `system-documentation`, `user-documentation`

  Entry schema:
  ```yaml
  - domain: <string>
    summary: <string>
    keywords: [<string>, ...]
    related: [<string>, ...]   # omit if empty
  ```

  Self-consistency rule: every value in a `related` list MUST appear as a `domain` entry within the same file.

## Phase 2: Skill Update

- [x] 2.1 Modify `skills/sdd-archive/SKILL.md` ✓ — after the existing Step 3 (sync delta specs to master specs), add a new step titled "Step 3a — Update spec index" with the following contract:
  - Condition: a new domain directory was created under `openspec/specs/` during this archive operation
  - Action: append one entry to `openspec/specs/index.yaml` under the `domains:` key
  - Fields to populate: `domain` (new directory name), `summary` (derived from spec title or first requirement), `keywords` (derived from domain name tokens and key nouns in the spec), `related` (empty or inferred from proposal cross-references)
  - Constraint: entry MUST follow the existing YAML format (no schema changes)
  - If `index.yaml` does not exist yet: create it with the standard header and `domains:` root key before appending

## Phase 3: Documentation Updates

- [x] 3.1 Create `docs/adr/034-specs-search-optimization-architecture.md` ✓ with the Nygard ADR format:
  - Title: "034 — Spec Index: Flat YAML vs SQLite/FTS5"
  - Status: Proposed
  - Context: flat YAML index is sufficient at ≤100 spec domains; sequential parsing becomes expensive beyond that threshold
  - Decision options: (A) keep flat YAML `index.yaml` with keyword matching (current choice), (B) migrate to SQLite with FTS5 when 100-domain threshold is reached, (C) expose index as MCP server resource
  - Consequences section covering each option
  - Migration trigger stated explicitly: 100+ domains

- [x] 3.2 Modify `docs/adr/README.md` ✓ — append ADR 034 row to the ADR index table:
  - Number: 034
  - Title: Spec Index: Flat YAML vs SQLite/FTS5
  - Status: Proposed
  - Date: 2026-03-14

- [x] 3.3 Modify `docs/SPEC-CONTEXT.md` ✓ — add a new section "Using the spec index" immediately before or after the existing stem-based matching section, describing the two-step index-driven lookup:
  ```
  Step 1: Read openspec/specs/index.yaml (single read, if present)
  Step 2: For each entry — if entry.domain in change_name OR any keyword in entry.keywords matches change_name → match
  Step 3: matches = matches[:3]  (hard cap)
  Step 4: If index absent → fall back to stem-based name scan (existing algorithm)
  ```
  Also update the stem-based section to note that the index lookup is the preferred mechanism and stem-based is the fallback.

## Phase 4: Validation

- [x] 4.1 Verify `openspec/specs/index.yaml` self-consistency ✓: confirm all 55 `domain` values match an existing directory under `openspec/specs/` (manual directory listing comparison); confirm all `related` values point to entries present in the index; confirm each entry has 3–8 keywords

- [x] 4.2 Verify `docs/adr/README.md` contains ADR 034 row ✓ and the row is correctly formatted (number, title, status, date columns all populated)

---

## Implementation Notes

- `openspec/specs/index.yaml` is purely additive — no existing file is overwritten
- The sdd-archive step is non-destructive: it only appends; it does not re-index or modify existing entries
- `related` fields are optional; omit the key entirely rather than writing `related: []` for cleaner YAML
- YAML quoting: values containing `:` or `#` must be quoted; keyword arrays may use inline `[...]` format for compactness
- The ADR status MUST be "Proposed" (not "Accepted") — no implementation of SQLite is included in this change
- `docs/SPEC-CONTEXT.md` may not yet exist (it is created by companion proposal `2026-03-14-specs-as-subagent-background`); if absent, create the full file with both the index lookup section and the stem-based section so it is self-contained

## Blockers

- **`docs/SPEC-CONTEXT.md` dependency**: this file is expected to exist (created by companion proposal `2026-03-14-specs-as-subagent-background`). If that proposal has not been applied yet, task 3.3 must create the file from scratch rather than modify it. This does not block implementation — the implementer should check whether the file exists before choosing create vs. modify.
