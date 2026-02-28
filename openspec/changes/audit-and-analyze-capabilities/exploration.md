# Exploration: audit-and-analyze-capabilities

## Current State

The system has three skills that share responsibility for understanding and managing a project's state:

1. **`project-audit`** (921 lines) — Deep diagnostic of Claude/SDD configuration. Read-only. Produces `audit-report.md` with a FIX_MANIFEST consumed by `/project-fix`. Scores 100 points across 8 scored dimensions (D1-D4, D6-D8) and 3 informational dimensions (D9-D11).

2. **`project-analyze`** (464 lines) — Deep framework-agnostic codebase analysis. Read-only. Produces `analysis-report.md` at project root and updates `[auto-updated]` sections in `ai-context/` files. Never scores, never produces FIX_MANIFEST.

3. **`memory-manager`** (274 lines) — Initializes (`/memory-init`) and updates (`/memory-update`) the `ai-context/` memory layer. Two distinct modes of operation.

Additionally, **`project-update`** (170 lines) overlaps with `memory-manager` and `project-analyze` in its `ai-context/` update capabilities.

---

## Detailed Skill Analysis

### project-audit — 11 Dimensions

| Dimension | Name | Max Pts | What it checks |
|-----------|------|---------|----------------|
| D1 | CLAUDE.md | 20 | Exists, >50 lines, has Stack/Architecture/Skills/Rules/Plan Mode/SDD mentions, stack matches package.json |
| D2 | Memory (ai-context/) | 15+10=25 | 5 core files exist (15 pts) + substantial content + coherence with code (10 pts). Also checks `scenarios.md` and `quick-reference.md` freshness (LOW, no score impact) |
| D3 | SDD Orchestrator | 20 | 8 global SDD skills exist, openspec/ + config.yaml present, CLAUDE.md mentions SDD, orphaned changes detection |
| D4 | Skills Quality | 20 | Registry vs disk bidirectional check (10 pts) + global tech skills coverage (10 pts) |
| D6 | Cross-reference Integrity | 5 | Docs/templates/paths referenced in CLAUDE.md and skills actually exist on disk |
| D7 | Architecture Compliance | 5 | Reads `analysis-report.md` drift summary. 0 if absent, 2 if no architecture.md, 5 if none, 3 if minor, 0 if significant |
| D8 | Testing & Verification | 5 | config.yaml has testing block, archived changes have verify-report.md with [x] items, verify rules executable |
| D9 | Project Skills Quality | N/A | Local skills: duplicate detection vs global, structural completeness, language compliance, stack relevance. Informational only |
| D10 | Feature Docs Coverage | N/A | Config-driven or heuristic feature detection, coverage/structure/freshness/registry checks per feature. Informational only |
| D11 | Internal Coherence | N/A | Count claims in headings match body, section numbering continuity, frontmatter-body alignment. Informational only |

**Total scored: 100 points** (D1:20 + D2:25 + D3:20 + D4:20 + D6:5 + D7:5 + D8:5)

**Note**: D5 was removed (commands deprecation). Dimensions skip from D4 to D6.

**Key outputs**:
- `.claude/audit-report.md` — structured report with FIX_MANIFEST YAML block
- Consumed by `/project-fix`

**Execution constraints**:
- Maximum 3 Bash calls per run (Phase A discovery script)
- Read-only — never modifies files
- Uses Read/Glob/Grep tools for dimension evaluation after Phase A

---

### project-analyze — 6 Steps

| Step | What it does | Bash calls | Output |
|------|-------------|------------|--------|
| 1 | Read config (openspec/config.yaml analysis block) | Shared with Step 2 | Config values |
| 2 | Stack detection (manifest-first, fallback to file-extension sampling) | Shared with Step 1 (1 call total) | Stack section in report |
| 3 | Structure mapping (2-level folder tree, org pattern classification) | 1 call | Structure section in report |
| 4 | Convention sampling (file naming, function naming, import style, error handling) | 1 call | Conventions section in report |
| 5 | Architecture drift detection (compares observed vs architecture.md) | 0 (Read tool) | Architecture Drift section in report |
| 6 | Write outputs (analysis-report.md + ai-context/ auto-updated sections) | 0 (Write tool) | Final artifacts |

**Total: max 3 Bash calls**

**Key outputs**:
- `analysis-report.md` at project root (consumed by project-audit D7)
- Updates `[auto-updated]` sections in:
  - `ai-context/stack.md` — section-id: `stack-detection`
  - `ai-context/architecture.md` — section-ids: `structure-mapping`, `drift-summary`
  - `ai-context/conventions.md` — section-id: `observed-conventions`
- NEVER writes to `known-issues.md` or `changelog-ai.md`
- NEVER creates `ai-context/` directory if absent

**Critical boundaries**:
- Never scores, never produces FIX_MANIFEST entries
- Only writes within `[auto-updated]` markers
- Overwrites if report already exists

---

### memory-manager — 2 Modes

**`/memory-init`** (6 steps):
1. Project inventory (reads package.json, folder structure, README, code, tests, CI)
2. Generate `stack.md` — full template with language, framework, DB, testing, build, key deps, quality tools
3. Generate `architecture.md` — overview, pattern, folder structure, decisions, main flow, entry points, integrations
4. Generate `conventions.md` — naming, file organization, code patterns, commits, branches
5. Generate `known-issues.md` — detected tech debt, gotchas, limitations, workarounds
6. Generate `changelog-ai.md` — initial empty structure

Creates ALL 5 files from scratch. This is the first-time setup.

**`/memory-update`** (7 steps):
1. Analyze what changed in session (files created/modified, decisions, problems, stack changes)
2. Determine which files to update
3. Update `stack.md` (incremental — add/remove/update deps)
4. Update `architecture.md` (new decisions, folder changes)
5. Update `known-issues.md` (resolved → moved, new → added)
6. Add entry to `changelog-ai.md` (always, chronological descending)
7. Summary for user

**Key behaviors**:
- `/memory-init` creates from scratch, `/memory-update` is incremental
- `memory-update` does NOT update `conventions.md` explicitly (gap?)
- Session-aware: reviews what happened in current session
- Preserves history: resolved items moved, not deleted

---

### project-update — Overlapping Capabilities

`/project-update` does four things:
- **Case A**: Update stack in ai-context/ (reads package.json, compares with stack.md)
- **Case B**: Update project CLAUDE.md (sync SDD commands, skills registry)
- **Case C**: Add missing memory files
- **Case D**: Migrate old structure (legacy formats)

Also checks freshness of `onboarding.md`, `scenarios.md`, `quick-reference.md` (90-day threshold).

---

## Interaction Map

### project-analyze -> project-audit (D7)

```
project-analyze produces:
  analysis-report.md
    ├── Last analyzed: date     → D7 staleness check (>7 days = warning)
    ├── ## Summary
    │   └── Architecture drift: [value]  → D7 quick status
    ├── ## Architecture Drift
    │   ├── ### Drift Summary    → D7 scoring (none=5, minor=3, significant=0)
    │   └── Drift entries:       → D7 violations list
    └── (other sections)         → Not consumed by audit
```

**D7 scoring table** (from analysis-report.md):
| Condition | Score |
|-----------|-------|
| analysis-report.md absent | 0/5 |
| Present + no architecture.md | 2/5 |
| Drift = none | 5/5 |
| Drift = minor | 3/5 |
| Drift = significant | 0/5 |

This is a clean, well-defined interface. The contract is documented in both skills and in `openspec/specs/project-analysis/spec.md`.

### project-analyze -> ai-context/

```
project-analyze writes [auto-updated] sections to:
  ai-context/stack.md         → stack-detection
  ai-context/architecture.md  → structure-mapping, drift-summary
  ai-context/conventions.md   → observed-conventions
```

Uses HTML comment markers for boundaries. Merge algorithm is deterministic and idempotent.

### memory-manager -> ai-context/

```
/memory-init creates ALL 5 files from scratch:
  ai-context/stack.md
  ai-context/architecture.md
  ai-context/conventions.md
  ai-context/known-issues.md
  ai-context/changelog-ai.md

/memory-update incrementally updates:
  ai-context/stack.md         (if deps changed)
  ai-context/architecture.md  (if decisions made)
  ai-context/conventions.md   (NOT explicitly listed — gap)
  ai-context/known-issues.md  (if bugs found/resolved)
  ai-context/changelog-ai.md  (always)
```

### project-update -> ai-context/

```
/project-update can:
  Update ai-context/stack.md    (Case A — reads package.json)
  Create missing ai-context/*   (Case C — generates from code)
```

---

## Identified Gaps, Overlaps, and Inconsistencies

### GAP-1: `/memory-update` does not explicitly update conventions.md

In `memory-manager/SKILL.md`, the Step 2 table for `/memory-update` lists which files get updated based on session events. The table has rows for `stack.md`, `architecture.md`, `known-issues.md`, and `changelog-ai.md`. There is no row for `conventions.md`. The only skill that writes to `conventions.md` is `project-analyze` (via `[auto-updated]` markers).

**Impact**: If a team adopts a new naming convention or changes their import style, `/memory-update` has no mechanism to capture this. The user must run `/project-analyze` for convention updates or manually edit `conventions.md`.

**Severity**: Medium. Conventions tend to be stable, but the gap is undocumented.

---

### GAP-2: `project-analyze` does NOT create `ai-context/` directory

From the SKILL.md rule 4: "NEVER creates ai-context/ if it does not exist." If a project has no ai-context/ at all, project-analyze only writes `analysis-report.md` and tells the user to run `/memory-init`.

However, the master spec (`openspec/specs/project-analysis/spec.md`) says in Part 1, Requirement "project-analyze updates ai-context/":
> **Scenario**: "First run creates [auto-updated] sections when ai-context/ files are absent — GIVEN the target project has no ai-context/ directory (or has empty files) — WHEN /project-analyze runs — THEN it creates ai-context/stack.md, ai-context/architecture.md, and ai-context/conventions.md if they do not exist"

**This is a CONTRADICTION.** The spec says it should create the files; the SKILL.md says it never creates the directory. The SKILL.md implementation takes precedence (it is the runtime artifact), but the spec is out of date or was never reconciled.

**Severity**: High. The spec and SKILL.md disagree on a core behavior. This will cause confusion during verification.

---

### GAP-3: Three skills can write to `ai-context/stack.md` — no conflict resolution

The following skills can all write to `ai-context/stack.md`:
1. `project-analyze` — overwrites `[auto-updated]: stack-detection` section
2. `memory-manager` (`/memory-update`) — updates sections incrementally
3. `project-update` (Case A) — reads package.json and updates

There is no defined priority or conflict resolution. If the user runs `/memory-update` right after `/project-analyze`, the incremental update from memory-manager does not know about `[auto-updated]` markers and could potentially write to a section that project-analyze considers "human-written" (or vice versa).

**Severity**: Medium-High. In practice, the `[auto-updated]` markers from `project-analyze` partition the file, but `memory-manager` and `project-update` are not aware of this marker system. They could overwrite marker boundaries or create duplicate content.

---

### GAP-4: `project-analyze` writes to `ai-context/architecture.md` — `memory-manager` also writes to it

Both skills write to `architecture.md`:
- `project-analyze` writes `[auto-updated]: structure-mapping` and `[auto-updated]: drift-summary`
- `memory-manager` (`/memory-update`) updates the decisions table and folder structure

Same marker-awareness gap as GAP-3. `memory-manager` has no concept of `[auto-updated]` markers.

**Severity**: Medium. Could cause marker corruption if both are run in sequence.

---

### GAP-5: `/memory-update` is session-aware but has no actual mechanism for session state

The `/memory-update` process says "I review the context of the current session" (Step 1), but there is no formal mechanism to detect what changed. It relies on the LLM's conversation context, which means:
- If invoked as a standalone command in a new session, it has no session context to review
- The quality depends entirely on how much context the LLM can recall
- There is no artifact (like a session log) that captures changes

**Severity**: Low-Medium. This is inherent to the LLM-based approach, but worth noting as a design limitation.

---

### GAP-6: `project-audit` D2 checks file existence for `scenarios.md` and `quick-reference.md` but these are not part of the core 5 memory files

D2 has sub-checks for `ai-context/scenarios.md` and `ai-context/quick-reference.md` freshness, but the core memory file list (in CLAUDE.md, in memory-manager, in the D2 existence table) only documents 5 files: `stack.md`, `architecture.md`, `conventions.md`, `known-issues.md`, `changelog-ai.md`.

The additional files (`scenarios.md`, `quick-reference.md`, `onboarding.md`) are documented in the architecture.md artifact table as optional files. D2 correctly assigns LOW severity to their absence, so there is no scoring issue, but the discrepancy between "5 core files" and "actually 8 known files in ai-context/" is undocumented.

**Severity**: Low. No functional impact, but creates confusion about what belongs in ai-context/.

---

### GAP-7: Spec-SKILL.md misalignment for `project-analyze` auto-updated marker format

The SKILL.md uses this marker format:
```markdown
<!-- [auto-updated]: section-id -- last run: YYYY-MM-DD -->
...content...
<!-- [/auto-updated] -->
```

The spec (`openspec/specs/project-analysis/spec.md`) uses:
```markdown
<!-- [auto-updated] start: <section-name> -->
...content...
<!-- [auto-updated] end: <section-name> -->
```

**This is a format mismatch.** The SKILL.md marker format (which is what actually runs) differs from the spec. The existing `ai-context/` files in the repo use the SKILL.md format, confirming that is the real implementation.

**Severity**: Medium. The spec is wrong / outdated. The SKILL.md is the source of truth.

---

### GAP-8: No `/memory-update` as standalone command — it routes through `memory-manager`

CLAUDE.md lists `/memory-update` as a command, and the routing table maps both `/memory-init` and `/memory-update` to `~/.claude/skills/memory-manager/SKILL.md`. This works because `memory-manager` has two distinct process sections for each mode. However, the trigger differentiation relies on the LLM understanding which mode was invoked.

This is actually correct as designed, but worth noting: there is no separate `memory-update/SKILL.md` file. The routing is:
- `/memory-init` -> `memory-manager/SKILL.md` (reads the `/memory-init` process section)
- `/memory-update` -> `memory-manager/SKILL.md` (reads the `/memory-update` process section)

**Severity**: None (works as designed). But worth documenting that this is a two-mode-one-file pattern, unique among the skills.

---

### GAP-9: `project-update` overlaps with both `memory-manager` and `project-analyze`

| Capability | project-analyze | memory-manager | project-update |
|-----------|-----------------|----------------|----------------|
| Detect stack from manifest | Yes (Step 2) | Yes (memory-init Step 2) | Yes (Case A) |
| Update stack.md | Yes (auto-updated section) | Yes (incremental) | Yes (incremental) |
| Update architecture.md | Yes (auto-updated sections) | Yes (new decisions) | No |
| Update conventions.md | Yes (auto-updated section) | No | No |
| Create missing ai-context/ files | No | Yes (memory-init) | Yes (Case C) |
| Update CLAUDE.md | No | No | Yes (Case B) |
| Freshness check on user docs | No | No | Yes (Step 1b) |
| Migrate legacy structure | No | No | Yes (Case D) |

The overlap is in the first column: stack detection and stack.md updates are done by all three skills. This is not necessarily wrong (different use cases), but the user has no clear guidance on which to use when.

**Recommended mental model** (currently undocumented):
- `/project-analyze` = re-scan the entire codebase, produce a fresh snapshot, update auto-detected sections
- `/memory-update` = record what happened in this session into ai-context/
- `/project-update` = sync project config with global catalog changes and detect staleness

**Severity**: Medium. User confusion is likely. No documentation explains when to use each.

---

### GAP-10: `project-audit` describes "10 Dimensions" in its frontmatter description but has 11

The frontmatter says:
```yaml
description: >
  Deep diagnostic of Claude/SDD configuration. Read-only. Produces audit-report.md consumed by /project-fix.
```

And the file heading says "Audit Process -- 10 Dimensions" but actually implements D1-D4, D6-D11 (totaling 10 numbered but 11 if you count from the section headers; the numbering skips D5). The actual dimension count is:
- Scored: D1, D2, D3, D4, D6, D7, D8 = 7 dimensions
- Informational: D9, D10, D11 = 3 dimensions
- Total: 10 sections (since D5 is removed)

The heading "10 Dimensions" is correct but can be confusing since D5 is skipped. D11 was just added, and the heading may not have been updated. Let me verify.

From the SKILL.md line 42: "## Audit Process -- 10 Dimensions"

But the file contains D1, D2, D3, D4, D6, D7, D8, D9, D10, D11 = 10 numbered sections. However, "10 Dimensions" was written before D11 was added. Now there are actually 10 sections (D5 removed, D11 added, net 10). So the count is coincidentally correct.

**Severity**: None currently (coincidental match), but fragile if another dimension is added.

---

### GAP-11: D7 FIX_MANIFEST rule says violations go to `violations[]` only

D7 spec says: "D7 violations go in violations[] only -- NOT in required_actions. The /project-fix skill does not auto-fix architecture drift."

But in `project-fix/SKILL.md` Phase 4 (4.2), it says: "Violations found in Dimension 7 are NOT auto-corrected -- they are code changes that require human review."

This is actually consistent -- both agree D7 is informational in the fix context. The fix skill notifies but does not act. This is correct behavior.

**Severity**: None.

---

### GAP-12: `project-analyze` spec says it "complements memory-manager but does not replace it"

From `openspec/specs/project-analysis/spec.md` Out of Scope item 5:
> "Changes to memory-manager -- memory-init and memory-update are unchanged. project-analyze complements memory-manager but does not replace it."

And item 8:
> "project-analyze replacing memory-init -- On a project with no ai-context/ at all, memory-init remains the recommended first-time initializer."

This is the intended relationship, but it is not documented anywhere in CLAUDE.md or in the skills themselves. A user reading CLAUDE.md would not know whether to run `/project-analyze` or `/memory-init` first.

**Severity**: Medium. User guidance gap.

---

## Affected Areas

| File/Module | Impact | Notes |
|-------------|--------|-------|
| `skills/project-audit/SKILL.md` | Central | 921 lines, 10 dimensions, well-specified but very long |
| `skills/project-analyze/SKILL.md` | Central | 464 lines, well-structured, clean boundaries |
| `skills/memory-manager/SKILL.md` | Central | 274 lines, two-mode design, missing conventions.md update |
| `skills/project-update/SKILL.md` | Peripheral | 170 lines, overlaps with above three skills |
| `skills/project-fix/SKILL.md` | Consumer | Reads audit-report.md FIX_MANIFEST, 5-phase fix process |
| `openspec/specs/project-analysis/spec.md` | Reference | Contains spec-SKILL.md misalignments (GAP-2, GAP-7) |
| `openspec/specs/audit-dimensions/spec.md` | Reference | Comprehensive, up to date through D11 |
| `ai-context/architecture.md` | Written by | project-analyze (auto-updated), memory-manager |
| `ai-context/stack.md` | Written by | project-analyze (auto-updated), memory-manager, project-update |
| `ai-context/conventions.md` | Written by | project-analyze (auto-updated) only |
| `CLAUDE.md` | References all | Command routing, skill registry, SDD flow documentation |

---

## Analyzed Approaches

### Approach A: Document and Clarify (minimal intervention)

**Description**: Fix spec-SKILL.md misalignments, add a "When to use which skill" section to CLAUDE.md, add conventions.md to memory-manager's update list.

**Pros**: Low risk, minimal disruption, addresses most user-facing confusion
**Cons**: Does not solve the marker-awareness gap (GAP-3/GAP-4), leaves three skills writing to the same files
**Estimated effort**: Low
**Risk**: Low

### Approach B: Define ai-context/ Ownership Model

**Description**: Establish clear ownership per section of each ai-context/ file. `project-analyze` owns `[auto-updated]` sections exclusively. `memory-manager` owns everything else. `project-update` delegates to the appropriate skill rather than writing directly.

**Pros**: Eliminates conflict potential, establishes clear responsibility boundaries
**Cons**: Requires modifying three skill files, may break existing behavior if not carefully done
**Estimated effort**: Medium
**Risk**: Medium

### Approach C: Merge memory-manager into project-analyze

**Description**: Since `project-analyze` already does stack detection, structure mapping, and convention sampling, extend it to also handle known-issues and changelog entries. Make `memory-manager` a thin wrapper that calls `project-analyze` for the observation part and only handles the changelog/session recording.

**Pros**: Eliminates overlap entirely, single source of truth for all ai-context/ writes
**Cons**: Major refactor, would require re-specifying both skills, potentially very long SKILL.md
**Estimated effort**: High
**Risk**: High

---

## Recommendation

**Approach A (Document and Clarify)** is the recommended first step. It addresses the most impactful gaps with minimal risk:

1. Fix spec-SKILL.md misalignments (GAP-2, GAP-7)
2. Add `/memory-update` conventions.md support to memory-manager (GAP-1)
3. Add "When to use which skill" guidance to CLAUDE.md or ai-context/ (GAP-9, GAP-12)
4. Verify the dimension count heading in project-audit stays accurate (GAP-10)

Approach B could be a follow-on change if marker conflicts are observed in practice.

---

## Identified Risks

- **GAP-2 (spec contradiction)**: The project-analysis spec says project-analyze creates ai-context/ files; the SKILL.md says it never creates the directory. This MUST be reconciled before any changes that touch project-analyze behavior. **Mitigation**: Update the spec to match the SKILL.md (which is the runtime truth).

- **GAP-3/GAP-4 (concurrent writes)**: Three skills writing to the same files without marker awareness could cause data loss or marker corruption. **Mitigation**: In practice this has not been reported, but it should be documented as a known limitation.

- **GAP-7 (marker format mismatch)**: The spec uses a different marker format than the SKILL.md. Any tool that tries to parse using the spec format will fail. **Mitigation**: Update the spec to match the actual format.

---

## Open Questions

1. Has GAP-3 (concurrent ai-context/ writes) actually caused problems in practice?
2. Should `project-update` be deprecated in favor of a combination of `/project-analyze` + `/memory-update`?
3. Should `conventions.md` be added to memory-manager's update list, or should it remain project-analyze-exclusive?
4. Is there a need for a higher-level "refresh everything" command that orchestrates analyze + audit + fix in sequence?

---

## Ready for Proposal

**Yes** — The exploration has identified concrete, actionable gaps. The recommended approach (A) is well-scoped and low-risk. A proposal can define the specific changes to each skill file and the spec reconciliation needed.
