# Proposal: project-claude-organizer-smart-migration

Date: 2026-03-04
Status: Draft

## Intent

Extend `project-claude-organizer` with a "Legacy Directory Intelligence" layer that recognizes 8 known legacy directory and file patterns, replacing the generic "review manually" flag with concrete, actionable migration plans and SDD-aligned destinations.

## Motivation

The current `project-claude-organizer` skill correctly identifies items outside the canonical `.claude/` expected set, but it only flags them as "unexpected — review manually". In practice, real projects accumulate a predictable set of legacy directories that predate formal SDD adoption: `commands/`, `docs/`, `system/`, `plans/`, `requirements/`, `sops/`, `templates/`, and root-level overview files (`project.md`, `readme.md`). Each of these has a well-defined SDD-compliant destination and a clear migration strategy.

The current behavior forces the operator to figure out the migration manually every time, defeating the purpose of a structural reorganization assistant. For projects migrating from earlier Claude Code conventions to the full SDD layout, this limitation is the primary friction point.

Additionally, the `commands/` legacy pattern requires a fundamentally new capability: content analysis followed by delegation to `skill-creator`. This "skill orchestration" pattern — where one skill recognizes content that qualifies as a new skill and delegates its scaffolding to another skill — is not currently supported by any skill in the catalog. This change introduces that pattern in a well-scoped context.

## Scope

### Included

- New Step 3b in `project-claude-organizer` SKILL.md: Legacy Directory Intelligence layer that classifies 8 known legacy patterns before falling through to the generic UNEXPECTED bucket
- `commands/` pattern: read each `.md` file, analyze content for reusable workflow markers, delegate qualifying files to `/skill-create` for SKILL.md scaffolding; mark non-qualifying files for archival
- `docs/` pattern: map each `<name>.md` file to `ai-context/features/<name>.md` — copy with user confirmation
- `system/` pattern: route `architecture.md` → `ai-context/architecture.md`, route `database.md` + `api-overview.md` → `ai-context/stack.md`; merge strategy is append (never overwrite)
- `plans/` pattern: route active plans → `openspec/changes/<name>/`, route archived plans → `openspec/changes/archive/<name>/`
- `requirements/` pattern: route each file → `openspec/changes/<date>-<slug>/proposal.md` (scaffold only — never overwrite)
- `sops/` pattern: present dual-destination choice (`ai-context/conventions.md` section vs. `docs/sops/`); user selects per file or globally for the directory
- `templates/` pattern: copy files to `docs/templates/`
- `project.md` / `readme.md` root-level files: analyze section headings → distribute relevant sections into `ai-context/stack.md`, `ai-context/architecture.md`, `ai-context/known-issues.md` as appropriate; each section copy requires user confirmation
- Per-category user confirmation gate before applying any migration
- All migrations are strictly additive (copy or scaffold only — no deletes, no moves of the original)
- Update to the dry-run plan format in Step 4 to include legacy migration categories alongside existing categories
- Update to the report format in Step 6 to capture legacy migration outcomes

### Excluded (explicitly out of scope)

- Automatic merging or deduplication of content when a destination file already exists (append strategy is the maximum permitted operation)
- Auto-detection of patterns beyond the 8 defined above — any new pattern requires a future change
- Migration of items inside subdirectories (only top-level `.claude/` items are in scope per existing skill design)
- Recursive scanning of `commands/` subdirectories — only `.md` files at the immediate `commands/` level are processed
- Modification of the `claude-folder-audit` Check P8 expected set (that is a separate change if needed)
- Removal or deprecation of the existing DOCUMENTATION_CANDIDATES classification (it coexists with the new layer)
- Auto-creation of ADRs for migrated content
- Any interaction with `~/.claude/` — the skill's existing guard against targeting the user-level runtime remains unchanged

## Proposed Approach

The implementation adds a new classification layer (Step 3b) that runs after the existing three-bucket classification in Step 3 (MISSING_REQUIRED / UNEXPECTED / PRESENT) but before Step 4's plan presentation. This layer iterates over items in `UNEXPECTED` and, for each item whose name matches a known legacy pattern, reclassifies it into a new `LEGACY_MIGRATIONS` collection, removing it from `UNEXPECTED`. Items that match no legacy pattern remain in `UNEXPECTED` (the existing "review manually" behavior is preserved for genuinely unknown items).

Each entry in `LEGACY_MIGRATIONS` carries: the source path, the destination path(s), the migration strategy (copy / append / scaffold / delegate), and the confirmation requirement. Step 4 is extended to render a new "Legacy migrations" section in the dry-run plan. Step 5 gains a new sub-step (5.7) that applies legacy migrations in strategy order, with per-category confirmation gates. Step 6 captures outcomes in a new "Legacy migrations" subsection of the report.

The `commands/` delegation path is the most complex: qualifying `.md` files are not copied but instead presented to the user with a prompt to invoke `/skill-create` — the organizer prepares the content summary and the recommended skill name, and the user initiates skill creation separately. This avoids the organizer assuming orchestration authority it does not currently have; instead it acts as an advisor.

## Affected Areas

| Area/Module | Type of Change | Impact |
|-------------|----------------|--------|
| `skills/project-claude-organizer/SKILL.md` | Modified | High — adds Step 3b (classification), extends Steps 4/5/6 |
| Step 3 (classification logic) | Modified | Medium — UNEXPECTED bucket is now the fallthrough, not the primary bucket |
| Step 4 (dry-run plan format) | Modified | Low — additive new section |
| Step 5 (apply logic) | Modified | Medium — new sub-step 5.7 with per-category gates |
| Step 6 (report format) | Modified | Low — additive new subsection |
| Skill orchestration model | New pattern | Medium — `commands/` delegation introduces skill-to-skill advisory for first time |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Legacy pattern false positives — a directory named `docs/` or `system/` may not follow the expected convention | Medium | Medium | Each legacy category requires explicit user confirmation before applying; no writes happen without confirmation |
| `commands/` delegation complexity — content analysis heuristic to identify "reusable workflow" may misclassify | Medium | Low | The skill only presents a recommendation; user decides whether to invoke `/skill-create`; no automated skill creation |
| Append strategy for `system/` merges could produce malformed `ai-context/` files if source content is unstructured | Low | Medium | Append is bounded to a clearly labeled section separator; destination review is always recommended post-migration |
| Step 3b increases SKILL.md length significantly, risking readability regression | Medium | Low | Organize the new step with clear sub-sections per pattern; lean on a pattern table for the quick-scan view |
| Scope creep during implementation — temptation to handle subdirectories or additional patterns | Low | Medium | Excluded scope is explicitly listed; tasks.md will bound implementation to the 8 defined patterns |

## Rollback Plan

The change modifies only `skills/project-claude-organizer/SKILL.md`. Rollback is:

1. `git revert <commit>` — restores the SKILL.md to the pre-change version
2. `bash install.sh` — redeploys the reverted skill to `~/.claude/`
3. Verify: run `/project-claude-organizer` on a test project — confirm the skill no longer emits legacy migration suggestions

No database, external API, or data files are modified by this change. The skill writes only `claude-organizer-report.md` (runtime artifact, never committed), so there is no persistent data to roll back.

## Dependencies

- `skills/project-claude-organizer/SKILL.md` must be read in full before implementation (the new step must integrate cleanly into the existing step numbering and report format)
- `skills/skill-creator/SKILL.md` must be consulted to understand what information the `commands/` delegation advisory needs to surface for the user (skill name, trigger summary, format suggestion)
- No external dependencies — the change is self-contained within the `claude-config` repo

## Success Criteria

- [ ] Running `/project-claude-organizer` on a project with any of the 8 legacy patterns produces a migration suggestion with a concrete destination path — no item matching a known pattern outputs "review manually"
- [ ] The `commands/` pattern produces an advisory that names the recommended skill and suggests invoking `/skill-create` — it does NOT auto-create anything
- [ ] All 8 legacy pattern migrations are additive: source files/directories are never deleted or modified; destination writes are copy-only or scaffold-only
- [ ] Each legacy migration category is gated by an explicit user confirmation prompt before any write occurs
- [ ] Items that do not match any of the 8 known patterns continue to fall through to `UNEXPECTED` with the "review manually" flag (regression test for unknown patterns)
- [ ] The dry-run plan (Step 4 output) includes a "Legacy migrations" section listing each legacy item with its proposed destination
- [ ] The `claude-organizer-report.md` includes a "Legacy migrations" subsection capturing outcomes per category
- [ ] `/project-audit` score on `claude-config` is >= score before this change

## Effort Estimate

Medium (1–2 days) — the specification logic for 8 patterns is detailed, but the implementation is contained to a single SKILL.md file with no code dependencies.
