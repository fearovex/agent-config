# Technical Design: enhance-project-audit-skill-review

Date: 2026-02-26
Proposal: openspec/changes/enhance-project-audit-skill-review/proposal.md

---

## General Approach

This change makes three additive modifications to the existing skill system. Dimension 9 is appended as a new section to `project-audit/SKILL.md`, following the identical structural pattern already used by D1–D8. A new Phase 5 handler block is appended to `project-fix/SKILL.md` using the established Phase 1–4 pattern. Two new files are created: `ai-context/onboarding.md` (documentation-only, no skill reads it programmatically) and `ai-context/architecture.md` receives a single row addition to its artifact table. No existing logic is altered; no interfaces are removed or renamed.

---

## Technical Decisions

| Decision | Choice | Discarded Alternatives | Justification |
|----------|--------|------------------------|---------------|
| Dimension numbering | D9 (appended after D8) | Re-number existing dimensions, insert as D5 (skills sub-group) | Appending preserves all existing FIX_MANIFEST IDs and audit-report references. Re-numbering would break any tooling or docs referencing D1–D8 by number. |
| D9 scoring | Additive findings only — no score deduction in first iteration | Deduct from Skills (D4) max points, add separate D9 score column | The proposal explicitly excludes score integration in iteration 1. Findings must still appear in FIX_MANIFEST under a new key so project-fix can consume them. Additive-only avoids invalidating existing 96/100 baselines. |
| FIX_MANIFEST extension | New top-level key `skill_quality_actions` | Embed in existing `required_actions`, use a flat `violations` list | `required_actions` uses severity buckets that imply automated correction priority. `skill_quality_actions` items have a distinct handler type (disposition-based) that project-fix Phase 5 must dispatch differently. Separate key avoids ambiguity for the parser. Existing consumers only read their own keys — additive. |
| Language compliance heuristic | Reuse the D4e heuristic verbatim — reference it by name, do not duplicate it | Copy-paste the heuristic into D9, define a new independent heuristic | D4e defines a concrete scan target (Spanish prose markers: accented characters, specific Spanish keywords, section titles in Spanish). Referencing it by name in D9 keeps both checks in sync when D4e's heuristic is later updated. Duplication would create two implementations that can diverge. |
| Stack relevance cross-check | Conservative: flag only if tech name is absent from BOTH `ai-context/stack.md` AND `package.json` / `pyproject.toml` | Flag if absent from stack.md only | stack.md may be incomplete or stale. Using both sources reduces false positives. Emit as INFO (not WARNING) per proposal. |
| Duplicate detection scope | Exact directory name match between `.claude/skills/<name>/` and `~/.claude/skills/<name>/` | Content hash comparison, semantic similarity | Name match is unambiguous and fast. Content comparison requires reading two files per skill — adds complexity not warranted for a first iteration. Disposition for name-match duplicates is `delete` or `move-to-global`, presented with both paths so user can verify before acting. |
| `add_missing_section` handler | Append stub at end of local SKILL.md | Insert in correct structural position, refuse to modify | Appending is idempotent and safe — it cannot overwrite existing content. Inserting at the "correct" position requires parsing Markdown structure, which is fragile. The stub includes a `<!-- AUDIT: stub added by project-fix -->` marker so it is identifiable and removable. |
| `onboarding.md` location | `ai-context/onboarding.md` | `skills/onboarding/SKILL.md`, `docs/onboarding.md` | The proposal specifies ai-context/ explicitly. The onboarding document is static reference documentation, not a skill Claude executes. Placing it in ai-context/ keeps it alongside other project-memory files that Claude reads at session start. A `docs/` directory does not exist in this project. |
| `onboarding.md` consumption | Read-only documentation — no skill reads it programmatically | Add a `## Reads` entry in memory-manager, make it machine-parseable | The proposal says "read-only documentation — not consumed by any skill programmatically." Adding a machine-readable format would be scope creep and require its own SDD cycle. |

---

## Data Flow

### D9 audit check flow (inside project-audit)

```
project-audit detects .claude/skills/ in target project
        |
        v
For each subdirectory <name> in .claude/skills/:
        |
        +--[1. Duplicate check]---------------------------+
        |   Does ~/.claude/skills/<name>/SKILL.md exist?  |
        |   YES → candidate disposition: delete|move-to-global
        |   NO  → not a duplicate
        |
        +--[2. Structural completeness]-------------------+
        |   Read local SKILL.md                           |
        |   Search for: **Triggers** or ## Triggers       |
        |               ## Process or ### Step            |
        |               ## Rules or ## Execution rules    |
        |   All 3 found → PASS                            |
        |   Any missing → disposition: update             |
        |     → action_type: add_missing_section          |
        |
        +--[3. Language compliance]------------------------+
        |   Apply D4e heuristic to local SKILL.md         |
        |   Non-English prose found → disposition: update |
        |     → action_type: flag_language                |
        |     (INFO only — no auto-fix, no score impact)  |
        |
        +--[4. Stack relevance]----------------------------+
            Tech refs in SKILL.md vs stack.md + package.json
            Tech absent from BOTH sources → disposition: update
              → action_type: flag_irrelevant (INFO only)
            At least one source confirms tech → PASS
        |
        v
Emit:  ## Dimension 9 section in audit-report.md
       skill_quality_actions key in FIX_MANIFEST
```

### D9 fix handler flow (inside project-fix Phase 5)

```
project-fix reads FIX_MANIFEST.skill_quality_actions[]
        |
        v
Present Phase 5 summary to user — wait for confirmation
        |
        v
For each action in skill_quality_actions:

  action_type == delete_duplicate:
    Show: local path + global counterpart path
    Ask: "Delete local copy? (y/N)"
    On y: delete .claude/skills/<name>/ recursively
          → log in changelog-ai.md

  action_type == add_missing_section:
    Read current local SKILL.md
    Append stub for each missing section:
      ## Rules
      <!-- AUDIT: stub added by project-fix YYYY-MM-DD -->
      > TODO: define constraints for this skill
    Write file
    → log in changelog-ai.md

  action_type == flag_irrelevant:
    Prepend comment block to local SKILL.md:
      <!-- AUDIT: skill may be irrelevant to current stack -->
    Write file
    → log in changelog-ai.md

  action_type == flag_language:
    Report to user (INFO) — no file modification
    User must translate manually
```

---

## File Change Matrix

| File | Action | What is added / modified |
|------|--------|--------------------------|
| `skills/project-audit/SKILL.md` | Modify | Append `### Dimension 9 — Project Skills Quality` section after D8, following the exact D1–D8 structural pattern. Add `skill_quality_actions` key to FIX_MANIFEST format block. Add D9 row to the Report Format score table. Add D9 row to the Detailed Scoring table. |
| `skills/project-fix/SKILL.md` | Modify | Append `#### Phase 5 — Dimension 9 Corrections (Project Skills Quality)` block after Phase 4. Document four action handlers: `delete_duplicate`, `add_missing_section`, `flag_irrelevant`, `flag_language`. Phase 5 follows the established Phase checkpoint pattern. |
| `ai-context/onboarding.md` | Create | New file. Documents canonical four-step onboarding sequence (`/project-setup → /memory-init → /project-audit → /project-fix`), prerequisites, what each command produces, at least one verifiable success criterion per step, and common failure modes. |
| `ai-context/architecture.md` | Modify | Add `onboarding.md` row to the "Communication between skills via artifacts" table. Add reference in the "Key architectural decisions" or a new "Memory layer artifact table" note. |

**Files NOT modified** (confirmed out of scope):
- `CLAUDE.md` — The memory layer table in CLAUDE.md lists only the 5 ai-context/ files by role, not individual filenames. `onboarding.md` is documentation, not a skill command, so no new entry in the Available Commands table is needed. The Skills Registry is unaffected.
- `openspec/config.yaml` — `required_artifacts_per_change` currently lists `proposal.md`, `tasks.md`, `verify-report.md`. `onboarding.md` is a one-time project-level document, not a per-change artifact. No config change needed.

---

## Interfaces and Contracts

### FIX_MANIFEST extension — `skill_quality_actions` key

```yaml
# New top-level key appended to FIX_MANIFEST YAML block
skill_quality_actions:
  - id: "D9-<skill-name>-<action-type>"          # unique, stable
    skill_name: "<name>"                           # directory name
    local_path: ".claude/skills/<name>/SKILL.md"  # absolute resolved at runtime
    global_counterpart: "~/.claude/skills/<name>/SKILL.md"  # only for duplicates
    action_type: "delete_duplicate|add_missing_section|flag_irrelevant|flag_language"
    disposition: "delete|move-to-global|update|keep"
    missing_sections: ["## Rules", "## Process"]  # only for add_missing_section
    detail: "<human-readable reason>"
    severity: "info|warning"
```

### Dimension 9 report section format

```markdown
## Dimension 9 — Project Skills Quality [OK|WARNING|INFO]

**Local skills directory**: `.claude/skills/` — [N] skills found

| Skill | Duplicate of global | Structural complete | Language OK | Stack relevant | Disposition |
|-------|--------------------|--------------------|-------------|----------------|-------------|
| skill-a | ⚠️ YES (move-to-global) | ✅ | ✅ | ✅ | move-to-global |
| skill-b | ❌ | ✅ | ✅ | ℹ️ UNKNOWN | keep |
| skill-c | ❌ | ⚠️ (missing ## Rules) | ✅ | ✅ | update |

**Skills with missing structural sections:**
[list or "none"]

**Language violations (INFO):**
[list or "none"]

**Stack relevance issues (INFO):**
[list or "none"]

**No local .claude/skills/ directory found — Dimension 9 skipped.**
[This line replaces the table when .claude/skills/ is absent]
```

### Stub sections appended by `add_missing_section`

```markdown
<!-- AUDIT: stub added by project-fix YYYY-MM-DD — fill in before using this skill -->

## Rules

> TODO: define constraints and invariants for this skill.
```

```markdown
<!-- AUDIT: stub added by project-fix YYYY-MM-DD -->

## Process

> TODO: add step-by-step process instructions.
```

```markdown
<!-- AUDIT: stub added by project-fix YYYY-MM-DD -->

**Triggers**: TODO — define when this skill is invoked.
```

### Flag comment prepended by `flag_irrelevant`

```markdown
<!-- AUDIT: skill may be irrelevant to current project stack. Review and delete if unused. Added by project-fix YYYY-MM-DD -->
```

---

## Testing Strategy

| Layer | What to test | Tool |
|-------|-------------|------|
| Integration — D9 positive | Run `/project-audit` on a project that has `.claude/skills/` with a directory name matching a global skill. Verify audit-report.md contains a Dimension 9 section listing that skill with disposition `delete` or `move-to-global` and a `skill_quality_actions` entry of type `delete_duplicate`. | Manual — Audiio V3 test project |
| Integration — D9 structural | Run `/project-audit` on a project whose local SKILL.md is missing `## Rules`. Verify the Dimension 9 section lists the skill with disposition `update` and `add_missing_section` action in FIX_MANIFEST. | Manual — Audiio V3 test project (inject a stub skill) |
| Integration — D9 absent | Run `/project-audit` on a project with no `.claude/skills/` directory. Verify Dimension 9 emits the "skipped" note and no `skill_quality_actions` key is added to FIX_MANIFEST. | Manual — any project without local skills |
| Integration — project-fix Phase 5 | Run `/project-fix` on a report with `skill_quality_actions.delete_duplicate`. Verify user is prompted, upon `y` the skill directory is deleted, and changelog-ai.md is updated. | Manual — controlled test directory |
| Integration — project-fix add_missing_section | Run `/project-fix` on a report with `skill_quality_actions.add_missing_section`. Verify stub is appended without overwriting existing content; second run must be idempotent (stub already present → no second append). | Manual — controlled test directory |
| Regression | Run `/project-audit` on `claude-config` itself after applying this change. Verify score >= 96/100. Verify D9 is either skipped (no `.claude/skills/` in claude-config) or produces no blocking findings. | Manual |

---

## Migration Plan

No data migration required. All changes are file edits (append/create). No existing SKILL.md content is removed or reordered. No database, no schema, no external dependency.

---

## Open Questions

1. **D9 on global-config repos**: `claude-config` itself has `skills/` at the root, not `.claude/skills/`. Should D9 run on the root `skills/` directory when the repo is detected as global-config type?
   - **Impact if unresolved**: D9 will silently skip for `claude-config` itself (no `.claude/skills/` found), which is acceptable for iteration 1 since the proposal scope is external project onboarding. The design adopts this conservative behavior; a follow-on change can extend D9 to global-config repos.

2. **`move-to-global` disposition is informational only**: The design (and proposal) explicitly exclude auto-promotion of local skills to `~/.claude/skills/`. The disposition is surfaced as a recommendation. If a user expects project-fix to handle `move-to-global` actions automatically, they will find no handler.
   - **Impact if unresolved**: Low. The Phase 5 handler must emit a clear message for `move-to-global` actions: "Manual action required — see proposal for promotion workflow." This must be explicit in the SKILL.md text.
